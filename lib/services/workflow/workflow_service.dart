import 'package:sqflite_common/sqlite_api.dart';
import '../database/db_initializer.dart';
import '../auth/audit_service.dart';
import '../notification/notification_service.dart';
import '../stock/stock_service.dart';
import '../vente/vente_service.dart';
import '../recette/recette_service.dart';
import '../facture/facture_service.dart';
import '../adherent/adherent_service.dart';
import '../../data/models/vente_model.dart';
import '../../data/models/vente_detail_model.dart';
import '../../data/models/recette_model.dart';
import '../../data/models/stock_model.dart';
import '../../data/models/stock_movement_model.dart';
import '../../data/models/facture_model.dart';

/// Service global pour orchestrer toutes les opérations critiques via transactions SQLite
/// Garantit l'intégrité des données avec commit/rollback automatique
class WorkflowService {
  final AuditService _auditService = AuditService();
  final NotificationService _notificationService = NotificationService();
  final StockService _stockService = StockService();
  final VenteService _venteService = VenteService();
  final RecetteService _recetteService = RecetteService();
  final FactureService _factureService = FactureService();
  final AdherentService _adherentService = AdherentService();

  /// Helper : Créer une facture directement dans une transaction
  Future<FactureModel> _createFactureInTransaction({
    required Database db,
    required int adherentId,
    required String type,
    required double montantTotal,
    required DateTime dateFacture,
    int? venteId,
    int? recetteId,
    String? notes,
    required int createdBy,
  }) async {
    // Générer le numéro unique
    final year = dateFacture.year;
    final month = dateFacture.month;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final countResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM factures
      WHERE type = ? 
      AND date_facture >= ? 
      AND date_facture <= ?
    ''', [type, startDate.toIso8601String(), endDate.toIso8601String()]);

    final sequence = (countResult.first['count'] as int? ?? 0) + 1;
    final numero = FactureModel.generateNumero(
      type: type,
      date: dateFacture,
      sequence: sequence,
    );

    final facture = FactureModel(
      numero: numero,
      adherentId: adherentId,
      type: type,
      montantTotal: montantTotal,
      dateFacture: dateFacture,
      statut: 'validee',
      notes: notes,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      venteId: venteId,
      recetteId: recetteId,
    );

    final factureId = await db.insert('factures', facture.toMap());
    return facture.copyWith(id: factureId);
  }

  /// Exécuter une opération dans une transaction SQLite
  /// Si une erreur survient, la transaction est automatiquement annulée (rollback)
  Future<T> executeTransaction<T>({
    required Future<T> Function(Database db) operation,
    String? operationName,
    int? userId,
  }) async {
    final db = await DatabaseInitializer.database;
    final batch = db.batch();
    
    try {
      // Démarrer la transaction
      await db.execute('BEGIN TRANSACTION');
      
      // Exécuter l'opération
      final result = await operation(db);
      
      // Si tout s'est bien passé, commit
      await db.execute('COMMIT');
      
      // Logger l'audit si nécessaire
      if (operationName != null && userId != null) {
        await _auditService.logAction(
          userId: userId,
          action: 'TRANSACTION_SUCCESS',
          entityType: 'workflow',
          details: 'Transaction réussie: $operationName',
        );
      }
      
      return result;
    } catch (e) {
      // En cas d'erreur, rollback automatique
      try {
        await db.execute('ROLLBACK');
      } catch (rollbackError) {
        print('Erreur lors du rollback: $rollbackError');
      }
      
      // Logger l'erreur dans l'audit
      if (operationName != null && userId != null) {
        await _auditService.logAction(
          userId: userId,
          action: 'TRANSACTION_FAILED',
          entityType: 'workflow',
          details: 'Transaction échouée: $operationName - Erreur: $e',
        );
      }
      
      // Afficher une notification d'erreur
      await _notificationService.notify(
        type: 'error',
        titre: 'Erreur transactionnelle',
        message: 'L\'opération "$operationName" a échoué: ${e.toString()}',
        module: 'workflow',
        userId: userId,
        priority: 'high',
        showToast: true,
        showSystem: true,
      );
      
      // Relancer l'erreur pour que l'appelant puisse la gérer
      rethrow;
    }
  }

  // ========== WORKFLOW COMPLET : CRÉATION DE VENTE ==========

  /// Workflow complet pour créer une vente individuelle avec toutes les opérations associées
  /// Transaction atomique : Vérification stock → Vente → Déduction stock → Recette → Facture → Notifications
  Future<Map<String, dynamic>> workflowCreateVenteIndividuelle({
    required int adherentId,
    required double quantite,
    required double prixUnitaire,
    String? acheteur,
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
    bool generateFacture = true,
    bool generateBordereau = false,
  }) async {
    return await executeTransaction<Map<String, dynamic>>(
      operationName: 'CREATE_VENTE_INDIVIDUELLE',
      userId: createdBy,
      operation: (db) async {
        // 1. Vérifier le stock disponible
        final stockDisponible = await _stockService.getStockActuel(adherentId);
        if (stockDisponible < quantite) {
          throw Exception(
            'Stock insuffisant. Stock disponible: ${stockDisponible.toStringAsFixed(2)} kg, Quantité demandée: ${quantite.toStringAsFixed(2)} kg',
          );
        }

        // 2. Créer la vente
        final montantTotal = quantite * prixUnitaire;
        final vente = VenteModel(
          type: 'individuelle',
          adherentId: adherentId,
          quantiteTotal: quantite,
          prixUnitaire: prixUnitaire,
          montantTotal: montantTotal,
          acheteur: acheteur,
          modePaiement: modePaiement,
          dateVente: dateVente,
          notes: notes,
          statut: 'valide',
          createdBy: createdBy,
          createdAt: DateTime.now(),
        );

        final venteId = await db.insert('ventes', vente.toMap());

        // 3. Déduire du stock (créer mouvement de stock)
        final movement = StockMovementModel(
          adherentId: adherentId,
          type: 'vente',
          quantite: -quantite, // Négatif pour déduction
          venteId: venteId,
          dateMouvement: dateVente,
          commentaire: 'Vente de $quantite kg',
          createdBy: createdBy,
          createdAt: DateTime.now(),
        );
        await db.insert('stock_mouvements', movement.toMap());

        // 4. Enregistrer dans l'historique de l'adhérent
        await _adherentService.logVente(
          adherentId: adherentId,
          venteId: venteId,
          quantite: quantite,
          montant: montantTotal,
          dateVente: dateVente,
          createdBy: createdBy,
        );

        // 5. Calculer et créer la recette
        final commissionRate = await _recetteService.getCommissionRate();
        final commissionAmount = RecetteModel.calculateCommissionAmount(montantTotal, commissionRate);
        final montantNet = RecetteModel.calculateMontantNet(montantTotal, commissionRate);

        final recette = RecetteModel(
          adherentId: adherentId,
          venteId: venteId,
          montantBrut: montantTotal,
          commissionRate: commissionRate,
          commissionAmount: commissionAmount,
          montantNet: montantNet,
          dateRecette: dateVente,
          notes: notes,
          createdBy: createdBy,
          createdAt: DateTime.now(),
        );
        final recetteId = await db.insert('recettes', recette.toMap());

        // 6. Créer la facture si demandée
        int? factureId;
        String? factureNumero;
        if (generateFacture) {
          final facture = await _createFactureInTransaction(
            db: db,
            adherentId: adherentId,
            type: 'vente',
            montantTotal: montantTotal,
            dateFacture: dateVente,
            venteId: venteId,
            notes: notes,
            createdBy: createdBy,
          );
          factureId = facture.id;
          factureNumero = facture.numero;
        }

        // 7. Logger l'audit
        await _auditService.logAction(
          userId: createdBy,
          action: 'WORKFLOW_CREATE_VENTE',
          entityType: 'ventes',
          entityId: venteId,
          details: 'Vente individuelle créée: $quantite kg pour ${montantTotal.toStringAsFixed(0)} FCFA',
        );

        // 8. Notifications (hors transaction pour éviter les problèmes)
        // Ces notifications seront envoyées après le commit
        Future.microtask(() async {
          await _notificationService.notifyVenteCreated(
            venteId: venteId,
            montant: montantTotal,
            userId: createdBy,
          );
          await _notificationService.notifyRecetteCalculated(
            recetteId: recetteId,
            montantNet: montantNet,
            userId: createdBy,
          );
        });

        return {
          'vente': vente.copyWith(id: venteId),
          'recette': recette.copyWith(id: recetteId),
          'factureId': factureId,
          'factureNumero': factureNumero,
          'stockRestant': stockDisponible - quantite,
        };
      },
    );
  }

  /// Workflow complet pour créer une vente groupée
  Future<Map<String, dynamic>> workflowCreateVenteGroupee({
    required List<VenteDetailModel> details,
    required double prixUnitaire,
    String? acheteur,
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
    bool generateFacture = true,
  }) async {
    return await executeTransaction<Map<String, dynamic>>(
      operationName: 'CREATE_VENTE_GROUPEE',
      userId: createdBy,
      operation: (db) async {
        // 1. Vérifier les stocks pour tous les adhérents
        for (final detail in details) {
          final stockDisponible = await _stockService.getStockActuel(detail.adherentId);
          if (stockDisponible < detail.quantite) {
            throw Exception(
              'Stock insuffisant pour l\'adhérent ${detail.adherentId}. Stock disponible: ${stockDisponible.toStringAsFixed(2)} kg, Quantité demandée: ${detail.quantite.toStringAsFixed(2)} kg',
            );
          }
        }

        // 2. Calculer le total
        final quantiteTotal = details.fold<double>(0.0, (sum, detail) => sum + detail.quantite);
        final montantTotal = quantiteTotal * prixUnitaire;

        // 3. Créer la vente groupée
        final vente = VenteModel(
          type: 'groupee',
          quantiteTotal: quantiteTotal,
          prixUnitaire: prixUnitaire,
          montantTotal: montantTotal,
          acheteur: acheteur,
          modePaiement: modePaiement,
          dateVente: dateVente,
          notes: notes,
          statut: 'valide',
          createdBy: createdBy,
          createdAt: DateTime.now(),
        );
        final venteId = await db.insert('ventes', vente.toMap());

        // 4. Créer les détails et déduire les stocks
        final recettes = <RecetteModel>[];
        for (final detail in details) {
          // Insérer le détail
          await db.insert('vente_details', detail.copyWith(venteId: venteId).toMap());

          // Déduire du stock
          final movement = StockMovementModel(
            adherentId: detail.adherentId,
            type: 'vente',
            quantite: -detail.quantite,
            venteId: venteId,
            dateMouvement: dateVente,
            commentaire: 'Vente groupée de ${detail.quantite} kg',
            createdBy: createdBy,
            createdAt: DateTime.now(),
          );
          await db.insert('stock_mouvements', movement.toMap());

          // Enregistrer dans l'historique
          await _adherentService.logVente(
            adherentId: detail.adherentId,
            venteId: venteId,
            quantite: detail.quantite,
            montant: detail.montant,
            dateVente: dateVente,
            createdBy: createdBy,
          );

          // Calculer et créer la recette pour chaque adhérent
          final commissionRate = await _recetteService.getCommissionRate();
          final commissionAmount = RecetteModel.calculateCommissionAmount(detail.montant, commissionRate);
          final montantNet = RecetteModel.calculateMontantNet(detail.montant, commissionRate);

          final recette = RecetteModel(
            adherentId: detail.adherentId,
            venteId: venteId,
            montantBrut: detail.montant,
            commissionRate: commissionRate,
            commissionAmount: commissionAmount,
            montantNet: montantNet,
            dateRecette: dateVente,
            notes: notes,
            createdBy: createdBy,
            createdAt: DateTime.now(),
          );
          final recetteId = await db.insert('recettes', recette.toMap());
          recettes.add(recette.copyWith(id: recetteId));
        }

        // 5. Créer la facture si demandée
        int? factureId;
        String? factureNumero;
        if (generateFacture) {
          final facture = await _createFactureInTransaction(
            db: db,
            adherentId: details.first.adherentId, // Premier adhérent comme référence
            type: 'vente',
            montantTotal: montantTotal,
            dateFacture: dateVente,
            venteId: venteId,
            notes: notes,
            createdBy: createdBy,
          );
          factureId = facture.id;
          factureNumero = facture.numero;
        }

        // 6. Logger l'audit
        await _auditService.logAction(
          userId: createdBy,
          action: 'WORKFLOW_CREATE_VENTE_GROUPEE',
          entityType: 'ventes',
          entityId: venteId,
          details: 'Vente groupée créée: $quantiteTotal kg pour ${montantTotal.toStringAsFixed(0)} FCFA',
        );

        // 7. Notifications
        Future.microtask(() async {
          await _notificationService.notifyVenteCreated(
            venteId: venteId,
            montant: montantTotal,
            userId: createdBy,
          );
        });

        return {
          'vente': vente.copyWith(id: venteId),
          'recettes': recettes,
          'factureId': factureId,
          'factureNumero': factureNumero,
        };
      },
    );
  }

  // ========== WORKFLOW COMPLET : DÉPÔT DE STOCK ==========

  /// Workflow complet pour créer un dépôt de stock
  /// Transaction atomique : Dépôt → Mouvement stock → Notification
  Future<Map<String, dynamic>> workflowCreateDepot({
    required int adherentId,
    required double quantite,
    double? prixUnitaire,
    required DateTime dateDepot,
    String? qualite,
    String? observations,
    required int createdBy,
  }) async {
    return await executeTransaction<Map<String, dynamic>>(
      operationName: 'CREATE_DEPOT',
      userId: createdBy,
      operation: (db) async {
        // 1. Créer le dépôt
        final depot = StockDepotModel(
          adherentId: adherentId,
          quantite: quantite,
          prixUnitaire: prixUnitaire,
          dateDepot: dateDepot,
          qualite: qualite,
          observations: observations,
          createdBy: createdBy,
          createdAt: DateTime.now(),
        );
        final depotId = await db.insert('stock_depots', depot.toMap());

        // 2. Créer le mouvement de stock
        final movement = StockMovementModel(
          adherentId: adherentId,
          type: 'depot',
          quantite: quantite,
          depotId: depotId,
          dateMouvement: dateDepot,
          commentaire: 'Dépôt de $quantite kg${qualite != null ? ' ($qualite)' : ''}',
          createdBy: createdBy,
          createdAt: DateTime.now(),
        );
        await db.insert('stock_mouvements', movement.toMap());

        // 3. Enregistrer dans l'historique de l'adhérent
        await _adherentService.logDepot(
          adherentId: adherentId,
          depotId: depotId,
          quantite: quantite,
          montant: prixUnitaire != null ? quantite * prixUnitaire : 0,
          dateDepot: dateDepot,
          createdBy: createdBy,
        );

        // 4. Calculer le nouveau stock
        final stockActuel = await _stockService.getStockActuel(adherentId);

        // 5. Logger l'audit
        await _auditService.logAction(
          userId: createdBy,
          action: 'WORKFLOW_CREATE_DEPOT',
          entityType: 'stock_depots',
          entityId: depotId,
          details: 'Dépôt de $quantite kg pour adhérent $adherentId',
        );

        // 6. Notifications
        Future.microtask(() async {
          await _notificationService.notifyDepotAdded(
            adherentId: adherentId,
            quantite: quantite,
            userId: createdBy,
          );
        });

        return {
          'depot': depot.copyWith(id: depotId),
          'stockActuel': stockActuel,
        };
      },
    );
  }

  // ========== WORKFLOW COMPLET : ANNULATION DE VENTE ==========

  /// Workflow complet pour annuler une vente
  /// Transaction atomique : Annulation vente → Restauration stock → Suppression recette → Notification
  Future<Map<String, dynamic>> workflowAnnulerVente({
    required int venteId,
    required int annulePar,
    String? raison,
  }) async {
    return await executeTransaction<Map<String, dynamic>>(
      operationName: 'ANNULER_VENTE',
      userId: annulePar,
      operation: (db) async {
        // 1. Récupérer la vente
        final venteResult = await db.query(
          'ventes',
          where: 'id = ?',
          whereArgs: [venteId],
          limit: 1,
        );

        if (venteResult.isEmpty) {
          throw Exception('Vente non trouvée');
        }

        final vente = VenteModel.fromMap(venteResult.first);

        if (vente.isAnnulee) {
          throw Exception('Cette vente est déjà annulée');
        }

        // 2. Marquer la vente comme annulée
        await db.update(
          'ventes',
          {'statut': 'annulee'},
          where: 'id = ?',
          whereArgs: [venteId],
        );

        // 3. Restaurer le stock et supprimer les recettes
        if (vente.isIndividuelle && vente.adherentId != null) {
          // Restaurer le stock
          final movement = StockMovementModel(
            adherentId: vente.adherentId!,
            type: 'ajustement',
            quantite: vente.quantiteTotal,
            dateMouvement: DateTime.now(),
            commentaire: 'Annulation de vente #$venteId${raison != null ? ': $raison' : ''}',
            createdBy: annulePar,
            createdAt: DateTime.now(),
          );
          await db.insert('stock_mouvements', movement.toMap());

          // Supprimer la recette associée
          final recetteResult = await db.query(
            'recettes',
            where: 'vente_id = ?',
            whereArgs: [venteId],
            limit: 1,
          );
          if (recetteResult.isNotEmpty) {
            await db.delete('recettes', where: 'vente_id = ?', whereArgs: [venteId]);
          }

          // Enregistrer dans l'historique
          await _adherentService.logVente(
            adherentId: vente.adherentId!,
            venteId: venteId,
            quantite: -vente.quantiteTotal,
            montant: -vente.montantTotal,
            dateVente: DateTime.now(),
            createdBy: annulePar,
          );
        } else if (vente.isGroupee) {
          // Récupérer les détails
          final detailsResult = await db.query(
            'vente_details',
            where: 'vente_id = ?',
            whereArgs: [venteId],
          );

          for (final detailMap in detailsResult) {
            final detail = VenteDetailModel.fromMap(detailMap);

            // Restaurer le stock pour chaque adhérent
            final movement = StockMovementModel(
              adherentId: detail.adherentId,
              type: 'ajustement',
              quantite: detail.quantite,
              dateMouvement: DateTime.now(),
              commentaire: 'Annulation de vente groupée #$venteId${raison != null ? ': $raison' : ''}',
              createdBy: annulePar,
              createdAt: DateTime.now(),
            );
            await db.insert('stock_mouvements', movement.toMap());

            // Supprimer la recette associée
            await db.delete(
              'recettes',
              where: 'vente_id = ? AND adherent_id = ?',
              whereArgs: [venteId, detail.adherentId],
            );

            // Enregistrer dans l'historique
            await _adherentService.logVente(
              adherentId: detail.adherentId,
              venteId: venteId,
              quantite: -detail.quantite,
              montant: -detail.montant,
              dateVente: DateTime.now(),
              createdBy: annulePar,
            );
          }
        }

        // 4. Logger l'audit
        await _auditService.logAction(
          userId: annulePar,
          action: 'WORKFLOW_ANNULER_VENTE',
          entityType: 'ventes',
          entityId: venteId,
          details: 'Annulation de vente${raison != null ? ': $raison' : ''}',
        );

        // 5. Notifications
        Future.microtask(() async {
          await _notificationService.notifyVenteAnnulee(
            venteId: venteId,
            raison: raison ?? '',
            userId: annulePar,
          );
        });

        return {
          'vente': vente.copyWith(statut: 'annulee'),
          'message': 'Vente annulée avec succès',
        };
      },
    );
  }

  // ========== WORKFLOW COMPLET : MODIFICATION DE VENTE ==========

  /// Workflow complet pour modifier une vente
  /// Transaction atomique : Récupération ancienne vente → Annulation → Création nouvelle vente
  Future<Map<String, dynamic>> workflowModifierVente({
    required int venteId,
    required int adherentId,
    required double nouvelleQuantite,
    required double nouveauPrixUnitaire,
    String? nouveauAcheteur,
    String? nouveauModePaiement,
    DateTime? nouvelleDateVente,
    String? nouvellesNotes,
    required int modifiePar,
  }) async {
    return await executeTransaction<Map<String, dynamic>>(
      operationName: 'MODIFIER_VENTE',
      userId: modifiePar,
      operation: (db) async {
        // 1. Récupérer l'ancienne vente
        final ancienneVenteResult = await db.query(
          'ventes',
          where: 'id = ?',
          whereArgs: [venteId],
          limit: 1,
        );

        if (ancienneVenteResult.isEmpty) {
          throw Exception('Vente non trouvée');
        }

        final ancienneVente = VenteModel.fromMap(ancienneVenteResult.first);

        if (ancienneVente.isAnnulee) {
          throw Exception('Impossible de modifier une vente annulée');
        }

        // 2. Vérifier le stock disponible pour la nouvelle quantité
        final stockDisponible = await _stockService.getStockActuel(adherentId);
        final differenceQuantite = nouvelleQuantite - ancienneVente.quantiteTotal;
        
        if (differenceQuantite > 0 && stockDisponible < differenceQuantite) {
          throw Exception(
            'Stock insuffisant pour la modification. Stock disponible: ${stockDisponible.toStringAsFixed(2)} kg, Quantité supplémentaire nécessaire: ${differenceQuantite.toStringAsFixed(2)} kg',
          );
        }

        // 3. Annuler l'ancienne vente (restaurer le stock)
        if (ancienneVente.adherentId != null) {
          final movementRestore = StockMovementModel(
            adherentId: ancienneVente.adherentId!,
            type: 'ajustement',
            quantite: ancienneVente.quantiteTotal,
            dateMouvement: DateTime.now(),
            commentaire: 'Modification de vente #$venteId - Restauration ancienne quantité',
            createdBy: modifiePar,
            createdAt: DateTime.now(),
          );
          await db.insert('stock_mouvements', movementRestore.toMap());
        }

        // 4. Supprimer l'ancienne recette
        await db.delete('recettes', where: 'vente_id = ?', whereArgs: [venteId]);

        // 5. Créer la nouvelle vente avec les nouvelles données
        final nouveauMontantTotal = nouvelleQuantite * nouveauPrixUnitaire;
        final nouvelleVente = VenteModel(
          id: venteId, // Garder le même ID
          type: ancienneVente.type,
          adherentId: adherentId,
          quantiteTotal: nouvelleQuantite,
          prixUnitaire: nouveauPrixUnitaire,
          montantTotal: nouveauMontantTotal,
          acheteur: nouveauAcheteur ?? ancienneVente.acheteur,
          modePaiement: nouveauModePaiement ?? ancienneVente.modePaiement,
          dateVente: nouvelleDateVente ?? ancienneVente.dateVente,
          notes: nouvellesNotes ?? ancienneVente.notes,
          statut: 'valide',
          createdBy: modifiePar,
          createdAt: ancienneVente.createdAt,
        );

        await db.update(
          'ventes',
          nouvelleVente.toMap(),
          where: 'id = ?',
          whereArgs: [venteId],
        );

        // 6. Déduire la nouvelle quantité du stock
        final movementDeduction = StockMovementModel(
          adherentId: adherentId,
          type: 'vente',
          quantite: -nouvelleQuantite,
          venteId: venteId,
          dateMouvement: nouvelleDateVente ?? DateTime.now(),
          commentaire: 'Modification de vente #$venteId - Nouvelle quantité',
          createdBy: modifiePar,
          createdAt: DateTime.now(),
        );
        await db.insert('stock_mouvements', movementDeduction.toMap());

        // 7. Créer la nouvelle recette
        final commissionRate = await _recetteService.getCommissionRate();
        final commissionAmount = RecetteModel.calculateCommissionAmount(nouveauMontantTotal, commissionRate);
        final montantNet = RecetteModel.calculateMontantNet(nouveauMontantTotal, commissionRate);

        final nouvelleRecette = RecetteModel(
          adherentId: adherentId,
          venteId: venteId,
          montantBrut: nouveauMontantTotal,
          commissionRate: commissionRate,
          commissionAmount: commissionAmount,
          montantNet: montantNet,
          dateRecette: nouvelleDateVente ?? DateTime.now(),
          notes: nouvellesNotes,
          createdBy: modifiePar,
          createdAt: DateTime.now(),
        );
        final nouvelleRecetteId = await db.insert('recettes', nouvelleRecette.toMap());

        // 8. Mettre à jour l'historique
        await _adherentService.logVente(
          adherentId: adherentId,
          venteId: venteId,
          quantite: nouvelleQuantite,
          montant: nouveauMontantTotal,
          dateVente: nouvelleDateVente ?? DateTime.now(),
          createdBy: modifiePar,
        );

        // 9. Logger l'audit
        await _auditService.logAction(
          userId: modifiePar,
          action: 'WORKFLOW_MODIFIER_VENTE',
          entityType: 'ventes',
          entityId: venteId,
          details: 'Vente modifiée: ${ancienneVente.quantiteTotal} kg → $nouvelleQuantite kg',
        );

        // 10. Notifications
        Future.microtask(() async {
          await _notificationService.notify(
            type: 'info',
            titre: 'Vente modifiée',
            message: 'La vente #$venteId a été modifiée avec succès',
            module: 'ventes',
            entityType: 'vente',
            entityId: venteId,
            userId: modifiePar,
            priority: 'normal',
            showToast: true,
            showSystem: false,
          );
        });

        return {
          'vente': nouvelleVente,
          'recette': nouvelleRecette.copyWith(id: nouvelleRecetteId),
          'stockRestant': stockDisponible - differenceQuantite,
        };
      },
    );
  }

  // ========== WORKFLOW COMPLET : AJUSTEMENT DE STOCK ==========

  /// Workflow complet pour créer un ajustement de stock
  Future<Map<String, dynamic>> workflowCreateAjustement({
    required int adherentId,
    required double quantite, // positif pour ajout, négatif pour retrait
    required String raison,
    required int createdBy,
  }) async {
    return await executeTransaction<Map<String, dynamic>>(
      operationName: 'CREATE_AJUSTEMENT',
      userId: createdBy,
      operation: (db) async {
        // 1. Créer le mouvement d'ajustement
        final ajustement = StockMovementModel(
          adherentId: adherentId,
          type: 'ajustement',
          quantite: quantite,
          dateMouvement: DateTime.now(),
          commentaire: raison,
          createdBy: createdBy,
          createdAt: DateTime.now(),
        );
        final ajustementId = await db.insert('stock_mouvements', ajustement.toMap());

        // 2. Calculer le nouveau stock et vérifier les alertes (avec vérification des doublons)
        final stockActuel = await _stockService.getStockActuel(adherentId, checkAlerts: true);

        // 3. Logger l'audit
        await _auditService.logAction(
          userId: createdBy,
          action: 'WORKFLOW_CREATE_AJUSTEMENT',
          entityType: 'stock_mouvements',
          entityId: ajustementId,
          details: 'Ajustement de $quantite kg pour adhérent $adherentId. Raison: $raison',
        );

        return {
          'ajustement': ajustement.copyWith(id: ajustementId),
          'stockActuel': stockActuel,
        };
      },
    );
  }
}
