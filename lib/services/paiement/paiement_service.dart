import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/db_initializer.dart';
import '../../data/models/paiement_model.dart';
import '../../data/models/compte_financier_adherent_model.dart';
import '../auth/audit_service.dart';
import '../notification/notification_service.dart';
import '../comptabilite/comptabilite_service.dart';
import '../qrcode/document_security_service.dart';

class PaiementService {
  final AuditService _auditService = AuditService();
  final NotificationService _notificationService = NotificationService();
  final ComptabiliteService _comptabiliteService = ComptabiliteService();

  /// Créer un paiement (partiel ou total)
  /// 
  /// Vérifie le solde disponible avant de créer le paiement
  /// Met à jour automatiquement le compte financier
  /// Génère un reçu PDF avec QR Code
  Future<PaiementModel> createPaiement({
    required int adherentId,
    required double montant,
    int? recetteId, // Si null, paiement global
    required String modePaiement,
    String? numeroCheque,
    String? referenceVirement,
    String? notes,
    required int createdBy,
    bool generateRecu = true,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      // Démarrer une transaction
      await db.execute('BEGIN TRANSACTION');
      
      try {
        // 1. Vérifier le solde disponible
        final compte = await getCompteFinancier(adherentId);
        if (montant > compte.soldeTotal) {
          throw Exception('Montant supérieur au solde disponible (${compte.soldeTotal.toStringAsFixed(2)} FCFA)');
        }
        
        // 2. Créer le paiement
        final paiement = PaiementModel(
          adherentId: adherentId,
          recetteId: recetteId,
          montant: montant,
          datePaiement: DateTime.now(),
          modePaiement: modePaiement,
          numeroCheque: numeroCheque,
          referenceVirement: referenceVirement,
          notes: notes,
          createdBy: createdBy,
          createdAt: DateTime.now(),
        );
        
        final paiementId = await db.insert('paiements', paiement.toMap());
        
        // 3. Générer QR Code hash
        final qrCodeHash = await DocumentSecurityService.generateQRCodeHash(
          type: 'paiement',
          id: paiementId,
          adherentId: adherentId,
          montant: montant,
        );
        
        await db.update(
          'paiements',
          {'qr_code_hash': qrCodeHash},
          where: 'id = ?',
          whereArgs: [paiementId],
        );
        
        // 4. Mettre à jour le compte financier
        await _updateCompteAfterPaiement(adherentId, montant);
        
        // 5. Journaliser l'opération
        await _logJournalFinancier(
          adherentId: adherentId,
          typeOperation: 'PAIEMENT',
          operationId: paiementId,
          operationType: 'paiement',
          montant: montant,
          description: 'Paiement de $montant FCFA (${modePaiement})',
          createdBy: createdBy,
        );
        
        // 6. Générer écriture comptable
        try {
          final ecritureId = await _comptabiliteService.generateEcritureForPaiement(
            paiementId: paiementId,
            montant: montant,
            createdBy: createdBy,
          );
          
          await db.update(
            'paiements',
            {'ecriture_comptable_id': ecritureId},
            where: 'id = ?',
            whereArgs: [paiementId],
          );
        } catch (e) {
          print('Erreur lors de la génération de l\'écriture comptable: $e');
        }
        
        // 7. Générer reçu PDF si demandé
        if (generateRecu) {
          try {
            final pdfPath = await _generateRecuPDF(paiementId, adherentId, montant, qrCodeHash);
            await db.update(
              'paiements',
              {'pdf_recu_path': pdfPath},
              where: 'id = ?',
              whereArgs: [paiementId],
            );
          } catch (e) {
            print('Erreur lors de la génération du reçu PDF: $e');
          }
        }
        
        // 8. Créer événement timeline
        await _createTimelineEvent(
          adherentId: adherentId,
          type: 'paiement',
          operationId: paiementId,
          titre: 'Paiement reçu',
          description: 'Paiement de ${montant.toStringAsFixed(2)} FCFA par $modePaiement',
          montant: montant,
        );
        
        // 9. Audit et notification
        await _auditService.logAction(
          userId: createdBy,
          action: 'CREATE_PAIEMENT',
          entityType: 'paiements',
          entityId: paiementId,
          details: 'Paiement de $montant FCFA pour adhérent $adherentId',
        );
        
        await _notificationService.notifyPaiementEffectue(
          paiementId: paiementId,
          montant: montant,
          userId: createdBy,
        );
        
        // Commit transaction
        await db.execute('COMMIT');
        
        return paiement.copyWith(id: paiementId, qrCodeHash: qrCodeHash);
      } catch (e) {
        // Rollback en cas d'erreur
        await db.execute('ROLLBACK');
        rethrow;
      }
    } catch (e) {
      throw Exception('Erreur lors de la création du paiement: $e');
    }
  }

  /// Obtenir le compte financier d'un adhérent
  Future<CompteFinancierAdherentModel> getCompteFinancier(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer les informations de l'adhérent
      final adherentResult = await db.query(
        'adherents',
        where: 'id = ?',
        whereArgs: [adherentId],
        limit: 1,
      );
      
      if (adherentResult.isEmpty) {
        throw Exception('Adhérent non trouvé');
      }
      
      final adherent = adherentResult.first;
      
      // Récupérer ou créer le compte
      final compteResult = await db.query(
        'comptes_adherents',
        where: 'adherent_id = ?',
        whereArgs: [adherentId],
        limit: 1,
      );
      
      if (compteResult.isEmpty) {
        // Créer le compte s'il n'existe pas
        await _initializeCompte(adherentId);
        return await getCompteFinancier(adherentId); // Récursif pour récupérer le compte créé
      }
      
      final compte = compteResult.first;
      
      return CompteFinancierAdherentModel.fromMap({
        'adherent_id': adherentId,
        'adherent_code': adherent['code'] as String,
        'adherent_nom': adherent['nom'] as String,
        'adherent_prenom': adherent['prenom'] as String,
        'solde_total': compte['solde_total'] as double,
        'total_recettes_generees': compte['total_recettes_generees'] as double,
        'total_paye': compte['total_paye'] as double,
        'total_en_attente': compte['total_en_attente'] as double,
        'total_retenues_sociales': compte['total_retenues_sociales'] as double,
        'date_derniere_recette': compte['date_derniere_recette'] as String?,
        'date_dernier_paiement': compte['date_dernier_paiement'] as String?,
        'date_derniere_retenue': compte['date_derniere_retenue'] as String?,
        'nombre_recettes': compte['nombre_recettes'] as int,
        'nombre_paiements': compte['nombre_paiements'] as int,
        'nombre_retenues': compte['nombre_retenues'] as int,
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération du compte: $e');
    }
  }

  /// Obtenir tous les paiements d'un adhérent
  Future<List<PaiementModel>> getPaiementsByAdherent(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'paiements',
        where: 'adherent_id = ?',
        whereArgs: [adherentId],
        orderBy: 'date_paiement DESC',
      );
      
      return result.map((map) => PaiementModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paiements: $e');
    }
  }

  /// Mettre à jour le compte après un paiement
  Future<void> _updateCompteAfterPaiement(int adherentId, double montant) async {
    final db = await DatabaseInitializer.database;
    
    // Récupérer le compte actuel
    final compteResult = await db.query(
      'comptes_adherents',
      where: 'adherent_id = ?',
      whereArgs: [adherentId],
      limit: 1,
    );
    
    if (compteResult.isEmpty) {
      await _initializeCompte(adherentId);
      return;
    }
    
    final compte = compteResult.first;
    final nouveauTotalPaye = (compte['total_paye'] as num).toDouble() + montant;
    final nouveauSoldeTotal = (compte['solde_total'] as num).toDouble() - montant;
    final nouveauTotalEnAttente = (compte['total_en_attente'] as num).toDouble() - montant;
    final nouveauNombrePaiements = (compte['nombre_paiements'] as int) + 1;
    
    await db.update(
      'comptes_adherents',
      {
        'total_paye': nouveauTotalPaye,
        'solde_total': nouveauSoldeTotal,
        'total_en_attente': nouveauTotalEnAttente,
        'nombre_paiements': nouveauNombrePaiements,
        'date_dernier_paiement': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'adherent_id = ?',
      whereArgs: [adherentId],
    );
  }

  /// Initialiser le compte d'un adhérent
  Future<void> _initializeCompte(int adherentId) async {
    final db = await DatabaseInitializer.database;
    
    // Calculer les totaux depuis les recettes existantes
    final recettesResult = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(montant_net), 0) as total_recettes,
        COUNT(*) as nombre_recettes,
        MAX(date_recette) as derniere_recette
      FROM recettes
      WHERE adherent_id = ?
    ''', [adherentId]);
    
    final totalRecettes = (recettesResult.first['total_recettes'] as num?)?.toDouble() ?? 0.0;
    final nombreRecettes = recettesResult.first['nombre_recettes'] as int? ?? 0;
    final derniereRecette = recettesResult.first['derniere_recette'] as String?;
    
    // Calculer les paiements
    final paiementsResult = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(montant), 0) as total_paye,
        COUNT(*) as nombre_paiements,
        MAX(date_paiement) as dernier_paiement
      FROM paiements
      WHERE adherent_id = ?
    ''', [adherentId]);
    
    final totalPaye = (paiementsResult.first['total_paye'] as num?)?.toDouble() ?? 0.0;
    final nombrePaiements = paiementsResult.first['nombre_paiements'] as int? ?? 0;
    final dernierPaiement = paiementsResult.first['dernier_paiement'] as String?;
    
    // Calculer les retenues
    final retenuesResult = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(montant), 0) as total_retenues,
        COUNT(*) as nombre_retenues,
        MAX(date_retenue) as derniere_retenue
      FROM retenues_sociales
      WHERE adherent_id = ?
    ''', [adherentId]);
    
    final totalRetenues = (retenuesResult.first['total_retenues'] as num?)?.toDouble() ?? 0.0;
    final nombreRetenues = retenuesResult.first['nombre_retenues'] as int? ?? 0;
    final derniereRetenue = retenuesResult.first['derniere_retenue'] as String?;
    
    // Calculer le solde
    final soldeTotal = totalRecettes - totalPaye - totalRetenues;
    final totalEnAttente = totalRecettes - totalPaye;
    
    // Insérer le compte
    await db.insert('comptes_adherents', {
      'adherent_id': adherentId,
      'solde_total': soldeTotal,
      'total_recettes_generees': totalRecettes,
      'total_paye': totalPaye,
      'total_en_attente': totalEnAttente,
      'total_retenues_sociales': totalRetenues,
      'date_derniere_recette': derniereRecette,
      'date_dernier_paiement': dernierPaiement,
      'date_derniere_retenue': derniereRetenue,
      'nombre_recettes': nombreRecettes,
      'nombre_paiements': nombrePaiements,
      'nombre_retenues': nombreRetenues,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Journaliser une opération financière
  Future<void> _logJournalFinancier({
    required int adherentId,
    required String typeOperation,
    required int operationId,
    required String operationType,
    required double montant,
    required String description,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    // Récupérer le solde avant
    final compte = await getCompteFinancier(adherentId);
    final soldeAvant = compte.soldeTotal;
    
    // Calculer le solde après (sera mis à jour après l'opération)
    final soldeApres = soldeAvant - montant;
    
    await db.insert('journal_financier', {
      'adherent_id': adherentId,
      'type_operation': typeOperation,
      'operation_id': operationId,
      'operation_type': operationType,
      'montant': montant,
      'solde_avant': soldeAvant,
      'solde_apres': soldeApres,
      'description': description,
      'date_operation': DateTime.now().toIso8601String(),
      'created_by': createdBy,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Créer un événement dans la timeline
  Future<void> _createTimelineEvent({
    required int adherentId,
    required String type,
    int? operationId,
    required String titre,
    required String description,
    double? montant,
  }) async {
    final db = await DatabaseInitializer.database;
    
    await db.insert('timeline_events', {
      'adherent_id': adherentId,
      'type': type,
      if (operationId != null) 'operation_id': operationId,
      'titre': titre,
      'description': description,
      if (montant != null) 'montant': montant,
      'date_evenement': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Générer le reçu PDF (placeholder - à implémenter avec pdf package)
  Future<String> _generateRecuPDF(int paiementId, int adherentId, double montant, String qrCodeHash) async {
    // TODO: Implémenter la génération PDF avec le package pdf
    // Pour l'instant, retourner un chemin placeholder
    return 'recus/paiement_$paiementId.pdf';
  }
}

