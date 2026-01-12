import '../database/db_initializer.dart';
import '../../data/models/capital_social_model.dart';
import '../auth/audit_service.dart';
import '../comptabilite/comptabilite_service.dart';
import '../qrcode/document_security_service.dart';
import '../document/pdf_generator_service.dart';

/// Service pour la gestion des libérations de capital
class LiberationService {
  final AuditService _auditService = AuditService();
  final ComptabiliteService _comptabiliteService = ComptabiliteService();
  final PdfGeneratorService _pdfGeneratorService = PdfGeneratorService();

  /// Enregistrer une libération de capital
  Future<LiberationCapitalModel> createLiberation({
    required int souscriptionId,
    required double montantLibere,
    required String modePaiement,
    String? reference,
    DateTime? datePaiement,
    String? notes,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      await db.execute('BEGIN TRANSACTION');
      
      try {
        // Vérifier la souscription
        final souscriptionResult = await db.query(
          'souscriptions_capital',
          where: 'id = ?',
          whereArgs: [souscriptionId],
          limit: 1,
        );
        
        if (souscriptionResult.isEmpty) {
          throw Exception('Souscription non trouvée');
        }
        
        final souscription = SouscriptionCapitalModel.fromMap(souscriptionResult.first);
        
        // Calculer le montant déjà libéré
        final liberationsResult = await db.rawQuery('''
          SELECT COALESCE(SUM(montant_libere), 0) as total_libere
          FROM liberations_capital
          WHERE souscription_id = ?
        ''', [souscriptionId]);
        
        final totalLibere = (liberationsResult.first['total_libere'] as num?)?.toDouble() ?? 0.0;
        final nouveauTotal = totalLibere + montantLibere;
        
        // Vérifier que le montant ne dépasse pas le capital souscrit
        if (nouveauTotal > souscription.montantSouscrit) {
          throw Exception(
            'Le montant libéré ($nouveauTotal FCFA) dépasse le capital souscrit (${souscription.montantSouscrit} FCFA)'
          );
        }
        
        // Créer la libération
        final liberation = LiberationCapitalModel(
          souscriptionId: souscriptionId,
          montantLibere: montantLibere,
          modePaiement: modePaiement,
          reference: reference,
          datePaiement: datePaiement ?? DateTime.now(),
          notes: notes,
          createdBy: createdBy,
          createdAt: DateTime.now(),
        );
        
        final id = await db.insert('liberations_capital', liberation.toMap());
        
        // Générer QR Code hash
        final qrCodeHash = await DocumentSecurityService.generateQRCodeHash(
          type: 'liberation_capital',
          id: id,
          adherentId: 0,
          montant: montantLibere,
        );
        
        await db.update(
          'liberations_capital',
          {'qr_code_hash': qrCodeHash},
          where: 'id = ?',
          whereArgs: [id],
        );
        
        // Créer mouvement de capital
        await _createMouvementCapital(
          actionnaireId: souscription.actionnaireId,
          typeMouvement: MouvementCapitalModel.typeLiberation,
          montant: montantLibere,
          justification: 'Libération de capital - Souscription #$souscriptionId',
          liberationId: id,
          createdBy: createdBy,
        );
        
        // Générer écriture comptable
        try {
          final ecritureId = await _comptabiliteService.generateEcritureForLiberationCapital(
            liberationId: id,
            montant: montantLibere,
            createdBy: createdBy,
          );
          
          await db.update(
            'liberations_capital',
            {'ecriture_comptable_id': ecritureId},
            where: 'id = ?',
            whereArgs: [id],
          );
        } catch (e) {
          print('Erreur lors de la génération de l\'écriture comptable: $e');
        }
        
        // Générer reçu PDF
        try {
          final recuPath = await _genererRecuPDF(id, souscriptionId, montantLibere, qrCodeHash);
          await db.update(
            'liberations_capital',
            {'recu_pdf_path': recuPath},
            where: 'id = ?',
            whereArgs: [id],
          );
        } catch (e) {
          print('Erreur lors de la génération du reçu PDF: $e');
        }
        
        // Si le capital est entièrement libéré, clôturer la souscription
        if (nouveauTotal >= souscription.montantSouscrit) {
          await db.update(
            'souscriptions_capital',
            {'statut': SouscriptionCapitalModel.statutCloture},
            where: 'id = ?',
            whereArgs: [souscriptionId],
          );
        }
        
        await _auditService.logAction(
          userId: createdBy,
          action: 'CREATE_LIBERATION',
          entityType: 'liberations_capital',
          entityId: id,
          details: 'Libération de $montantLibere FCFA pour souscription #$souscriptionId',
        );
        
        await db.execute('COMMIT');
        
        return liberation.copyWith(id: id, qrCodeHash: qrCodeHash);
      } catch (e) {
        await db.execute('ROLLBACK');
        rethrow;
      }
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  /// Obtenir toutes les libérations d'une souscription
  Future<List<LiberationCapitalModel>> getLiberationsBySouscription(int souscriptionId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'liberations_capital',
        where: 'souscription_id = ?',
        whereArgs: [souscriptionId],
        orderBy: 'date_paiement DESC',
      );
      
      return result.map((map) => LiberationCapitalModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Obtenir tous les mouvements d'un actionnaire
  Future<List<MouvementCapitalModel>> getMouvementsByActionnaire(int actionnaireId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'mouvements_capital',
        where: 'actionnaire_id = ?',
        whereArgs: [actionnaireId],
        orderBy: 'date_operation DESC',
      );
      
      return result.map((map) => MouvementCapitalModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Créer un mouvement de capital
  Future<void> _createMouvementCapital({
    required int actionnaireId,
    required String typeMouvement,
    required double montant,
    String? justification,
    int? liberationId,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    final mouvement = MouvementCapitalModel(
      actionnaireId: actionnaireId,
      typeMouvement: typeMouvement,
      montant: montant,
      dateOperation: DateTime.now(),
      justification: justification,
      liberationId: liberationId,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
    
    await db.insert('mouvements_capital', mouvement.toMap());
  }

  /// Générer le reçu PDF (placeholder)
  Future<String> _genererRecuPDF(int liberationId, int souscriptionId, double montant, String qrCodeHash) async {
    // TODO: Implémenter avec PdfGeneratorService
    return 'recus/liberation_$liberationId.pdf';
  }
}

