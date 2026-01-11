/// Service pour le calcul des recettes avec le système de commissions flexibles
/// Remplace l'ancien système basé sur les taux de commission

import '../database/db_initializer.dart';
import '../commissions/commission_service.dart';
import '../../data/models/recette_model.dart';
import '../../data/models/recette_commission_model.dart';
import '../../data/models/commission_model.dart';
import '../auth/audit_service.dart';

/// Résultat du calcul d'une recette avec commissions
class RecetteCalculResult {
  final RecetteModel recette;
  final List<RecetteCommissionModel> commissionsAppliquees;
  final double totalCommissions;
  final double montantBrut;
  final double montantNet;

  RecetteCalculResult({
    required this.recette,
    required this.commissionsAppliquees,
    required this.totalCommissions,
    required this.montantBrut,
    required this.montantNet,
  });
}

class RecetteCommissionService {
  final CommissionService _commissionService = CommissionService();
  final AuditService _auditService = AuditService();

  /// Calculer une recette avec toutes les commissions actives
  /// 
  /// Règles métier :
  /// - Récupère toutes les commissions actives à la date de la vente
  /// - Calcule le montant de chaque commission selon son type
  /// - Crée un snapshot des commissions appliquées
  /// - Calcule la recette nette = brut - total commissions
  Future<RecetteCalculResult> calculerRecette({
    required int adherentId,
    required int? venteId,
    required double poidsVendu, // en kg
    required double prixUnitaire, // FCFA/kg
    required DateTime dateVente,
    required int userId,
    String? notes,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Calculer le montant brut
      final montantBrut = poidsVendu * prixUnitaire;

      // Récupérer toutes les commissions actives à la date de la vente
      final commissionsActives = await _commissionService.getCommissionsActives(
        date: dateVente,
      );

      // Calculer le montant de chaque commission
      final commissionsAppliquees = <RecetteCommissionModel>[];
      double totalCommissions = 0.0;

      for (final commission in commissionsActives) {
        final montantCommission = commission.calculateMontant(
          poidsVendu: poidsVendu,
          nombreVentes: 1, // Pour l'instant, une seule vente
        );

        totalCommissions += montantCommission;

        // Créer le snapshot de la commission appliquée
        final recetteCommission = RecetteCommissionModel(
          recetteId: 0, // Sera mis à jour après création de la recette
          commissionCode: commission.code,
          commissionLibelle: commission.libelle,
          montantApplique: montantCommission,
          typeApplication: commission.typeApplication,
          poidsVendu: commission.typeApplication == CommissionTypeApplication.parKg
              ? poidsVendu
              : null,
          montantFixeUtilise: commission.montantFixe,
          dateApplication: dateVente,
          createdAt: DateTime.now(),
        );

        commissionsAppliquees.add(recetteCommission);
      }

      // Calculer le montant net
      final montantNet = montantBrut - totalCommissions;

      // Créer la recette (utiliser l'ancien modèle pour compatibilité)
      // Note: commissionRate et commissionAmount sont conservés pour compatibilité
      // mais ne sont plus utilisés pour le calcul réel
      final recette = RecetteModel(
        adherentId: adherentId,
        venteId: venteId,
        montantBrut: montantBrut,
        commissionRate: totalCommissions / montantBrut, // Pour compatibilité
        commissionAmount: totalCommissions,
        montantNet: montantNet,
        dateRecette: dateVente,
        notes: notes,
        createdBy: userId,
        createdAt: DateTime.now(),
      );

      // Insérer la recette dans la base de données
      final recetteId = await db.insert('recettes', {
        'adherent_id': recette.adherentId,
        'vente_id': recette.venteId,
        'montant_brut': recette.montantBrut,
        'commission_rate': recette.commissionRate,
        'commission_amount': recette.commissionAmount,
        'montant_net': recette.montantNet,
        'date_recette': recette.dateRecette.toIso8601String(),
        'notes': recette.notes,
        'created_by': recette.createdBy,
        'created_at': recette.createdAt.toIso8601String(),
      });

      // Insérer les snapshots des commissions appliquées
      for (final commissionAppliquee in commissionsAppliquees) {
        await db.insert('recette_commissions', {
          'recette_id': recetteId,
          'commission_code': commissionAppliquee.commissionCode,
          'commission_libelle': commissionAppliquee.commissionLibelle,
          'montant_applique': commissionAppliquee.montantApplique,
          'type_application': commissionAppliquee.typeApplication.value,
          'poids_vendu': commissionAppliquee.poidsVendu,
          'montant_fixe_utilise': commissionAppliquee.montantFixeUtilise,
          'date_application': commissionAppliquee.dateApplication.toIso8601String(),
          'created_at': commissionAppliquee.createdAt.toIso8601String(),
        });
      }

      // Logger l'audit
      await _auditService.logAction(
        userId: userId,
        action: 'CREATE_RECETTE',
        entityType: 'recette',
        entityId: recetteId,
        details: 'Recette calculée: ${commissionsActives.length} commissions appliquées, total: $totalCommissions FCFA',
      );

      return RecetteCalculResult(
        recette: recette.copyWith(id: recetteId),
        commissionsAppliquees: commissionsAppliquees
            .map((c) => c.copyWith(recetteId: recetteId))
            .toList(),
        totalCommissions: totalCommissions,
        montantBrut: montantBrut,
        montantNet: montantNet,
      );
    } catch (e) {
      throw Exception('Erreur lors du calcul de la recette: $e');
    }
  }

  /// Obtenir les détails des commissions appliquées à une recette
  Future<List<RecetteCommissionModel>> getCommissionsRecette(int recetteId) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'recette_commissions',
        where: 'recette_id = ?',
        whereArgs: [recetteId],
        orderBy: 'created_at',
      );

      return result.map((map) => RecetteCommissionModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des commissions de la recette: $e');
    }
  }

  /// Obtenir le détail complet d'une recette avec ses commissions
  Future<RecetteCalculResult?> getRecetteDetail(int recetteId) async {
    try {
      final db = await DatabaseInitializer.database;

      // Récupérer la recette
      final recetteResult = await db.query(
        'recettes',
        where: 'id = ?',
        whereArgs: [recetteId],
        limit: 1,
      );

      if (recetteResult.isEmpty) return null;

      final recette = RecetteModel.fromMap(recetteResult.first);

      // Récupérer les commissions appliquées
      final commissionsAppliquees = await getCommissionsRecette(recetteId);

      final totalCommissions = commissionsAppliquees.fold<double>(
        0.0,
        (sum, c) => sum + c.montantApplique,
      );

      return RecetteCalculResult(
        recette: recette,
        commissionsAppliquees: commissionsAppliquees,
        totalCommissions: totalCommissions,
        montantBrut: recette.montantBrut,
        montantNet: recette.montantNet,
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération du détail de la recette: $e');
    }
  }
}

// Extension pour copier avec recetteId
extension RecetteCommissionModelExtension on RecetteCommissionModel {
  RecetteCommissionModel copyWith({int? recetteId}) {
    return RecetteCommissionModel(
      id: id,
      recetteId: recetteId ?? this.recetteId,
      commissionCode: commissionCode,
      commissionLibelle: commissionLibelle,
      montantApplique: montantApplique,
      typeApplication: typeApplication,
      poidsVendu: poidsVendu,
      montantFixeUtilise: montantFixeUtilise,
      dateApplication: dateApplication,
      createdAt: createdAt,
    );
  }
}

// Extension pour RecetteModel
extension RecetteModelExtension on RecetteModel {
  RecetteModel copyWith({int? id}) {
    return RecetteModel(
      id: id ?? this.id,
      adherentId: adherentId,
      venteId: venteId,
      montantBrut: montantBrut,
      commissionRate: commissionRate,
      commissionAmount: commissionAmount,
      montantNet: montantNet,
      dateRecette: dateRecette,
      notes: notes,
      createdBy: createdBy,
      createdAt: createdAt,
      ecritureComptableId: ecritureComptableId,
      qrCodeHash: qrCodeHash,
    );
  }
}

