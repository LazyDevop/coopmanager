import '../database/db_initializer.dart';
import '../../data/models/capital_social_model.dart';
import '../auth/audit_service.dart';
import '../capital/capital_service.dart';
import '../qrcode/document_security_service.dart';
import '../document/pdf_generator_service.dart';

/// Service pour la gestion des souscriptions de capital
class SouscriptionService {
  final AuditService _auditService = AuditService();
  final CapitalService _capitalService = CapitalService();
  final PdfGeneratorService _pdfGeneratorService = PdfGeneratorService();

  /// Créer une souscription de capital
  Future<SouscriptionCapitalModel> createSouscription({
    required int actionnaireId,
    required int nombreParts,
    DateTime? dateSouscription,
    int? campagneId,
    String? notes,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      await db.execute('BEGIN TRANSACTION');
      
      try {
        // Obtenir la valeur actuelle d'une part
        final valeurPart = await _capitalService.getValeurPartActuelle();
        final montantSouscrit = nombreParts * valeurPart;
        
        final souscription = SouscriptionCapitalModel(
          actionnaireId: actionnaireId,
          nombrePartsSouscrites: nombreParts,
          montantSouscrit: montantSouscrit,
          dateSouscription: dateSouscription ?? DateTime.now(),
          campagneId: campagneId,
          statut: SouscriptionCapitalModel.statutEnCours,
          notes: notes,
          createdAt: DateTime.now(),
          createdBy: createdBy,
        );
        
        final id = await db.insert('souscriptions_capital', souscription.toMap());
        
        // Générer QR Code hash
        final qrCodeHash = await DocumentSecurityService.generateQRCodeHash(
          type: 'souscription_capital',
          id: id,
          adherentId: 0,
          montant: montantSouscrit,
        );
        
        await db.update(
          'souscriptions_capital',
          {'qr_code_hash': qrCodeHash},
          where: 'id = ?',
          whereArgs: [id],
        );
        
        // Créer un mouvement de capital
        await _createMouvementCapital(
          actionnaireId: actionnaireId,
          typeMouvement: MouvementCapitalModel.typeSouscription,
          nombreParts: nombreParts,
          montant: montantSouscrit,
          justification: 'Souscription de $nombreParts parts',
          souscriptionId: id,
          createdBy: createdBy,
        );
        
        // Générer certificat PDF
        try {
          final certificatPath = await _genererCertificatPDF(id, actionnaireId, nombreParts, montantSouscrit);
          await db.update(
            'souscriptions_capital',
            {'certificat_pdf_path': certificatPath},
            where: 'id = ?',
            whereArgs: [id],
          );
        } catch (e) {
          print('Erreur lors de la génération du certificat PDF: $e');
        }
        
        await _auditService.logAction(
          userId: createdBy,
          action: 'CREATE_SOUSCRIPTION',
          entityType: 'souscriptions_capital',
          entityId: id,
          details: 'Souscription de $nombreParts parts pour ${montantSouscrit} FCFA',
        );
        
        await db.execute('COMMIT');
        
        return souscription.copyWith(id: id, qrCodeHash: qrCodeHash);
      } catch (e) {
        await db.execute('ROLLBACK');
        rethrow;
      }
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  /// Obtenir toutes les souscriptions d'un actionnaire
  Future<List<SouscriptionCapitalModel>> getSouscriptionsByActionnaire(int actionnaireId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'souscriptions_capital',
        where: 'actionnaire_id = ?',
        whereArgs: [actionnaireId],
        orderBy: 'date_souscription DESC',
      );
      
      return result.map((map) => SouscriptionCapitalModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Obtenir une souscription par ID
  Future<SouscriptionCapitalModel?> getSouscriptionById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'souscriptions_capital',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      return SouscriptionCapitalModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Clôturer une souscription
  Future<SouscriptionCapitalModel> cloturerSouscription({
    required int id,
    required int closedBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      await db.update(
        'souscriptions_capital',
        {
          'statut': SouscriptionCapitalModel.statutCloture,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      await _auditService.logAction(
        userId: closedBy,
        action: 'CLOSE_SOUSCRIPTION',
        entityType: 'souscriptions_capital',
        entityId: id,
        details: 'Souscription clôturée',
      );
      
      return (await getSouscriptionById(id))!;
    } catch (e) {
      throw Exception('Erreur lors de la clôture: $e');
    }
  }

  /// Créer un mouvement de capital
  Future<void> _createMouvementCapital({
    required int actionnaireId,
    required String typeMouvement,
    int? nombreParts,
    required double montant,
    String? justification,
    int? souscriptionId,
    int? liberationId,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    final mouvement = MouvementCapitalModel(
      actionnaireId: actionnaireId,
      typeMouvement: typeMouvement,
      nombreParts: nombreParts,
      montant: montant,
      dateOperation: DateTime.now(),
      justification: justification,
      souscriptionId: souscriptionId,
      liberationId: liberationId,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
    
    await db.insert('mouvements_capital', mouvement.toMap());
  }

  /// Générer le certificat PDF (placeholder)
  Future<String> _genererCertificatPDF(int souscriptionId, int actionnaireId, int nombreParts, double montant) async {
    // TODO: Implémenter avec PdfGeneratorService
    return 'certificats/souscription_$souscriptionId.pdf';
  }
}

