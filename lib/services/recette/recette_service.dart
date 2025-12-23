import '../database/db_initializer.dart';
import '../../data/models/recette_model.dart';
import '../auth/audit_service.dart';
import '../../config/app_config.dart';
import '../notification/notification_service.dart';
// V2: Nouveaux imports
import '../comptabilite/comptabilite_service.dart';

class RecetteService {
  final AuditService _auditService = AuditService();
  final NotificationService _notificationService = NotificationService();
  // V2: Nouveaux services
  final ComptabiliteService _comptabiliteService = ComptabiliteService();

  /// Obtenir le taux de commission depuis les paramètres de la coopérative
  Future<double> getCommissionRate() async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'coop_settings',
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return (result.first['commission_rate'] as num).toDouble();
      }
      
      // Retourner le taux par défaut si aucun paramètre n'est trouvé
      return AppConfig.defaultCommissionRate;
    } catch (e) {
      print('Erreur lors de la récupération du taux de commission: $e');
      return AppConfig.defaultCommissionRate;
    }
  }

  /// Créer une recette automatiquement après une vente
  Future<RecetteModel> createRecetteFromVente({
    required int adherentId,
    required int venteId,
    required double montantBrut,
    double? commissionRate,
    String? notes,
    required int createdBy,
    bool generateEcritureComptable = true, // V2: Générer écriture comptable
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Obtenir le taux de commission si non fourni
      final tauxCommission = commissionRate ?? await getCommissionRate();
      
      // Calculer la commission et le montant net
      final commissionAmount = RecetteModel.calculateCommissionAmount(montantBrut, tauxCommission);
      final montantNet = RecetteModel.calculateMontantNet(montantBrut, tauxCommission);
      
      final recette = RecetteModel(
        adherentId: adherentId,
        venteId: venteId,
        montantBrut: montantBrut,
        commissionRate: tauxCommission,
        commissionAmount: commissionAmount,
        montantNet: montantNet,
        dateRecette: DateTime.now(),
        notes: notes,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final id = await db.insert('recettes', recette.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_RECETTE',
        entityType: 'recettes',
        entityId: id,
        details: 'Recette créée pour adhérent $adherentId: ${montantNet.toStringAsFixed(2)} FCFA',
      );

      // Notification : Recette calculée
      await _notificationService.notifyRecetteCalculated(
        recetteId: id,
        montantNet: montantNet,
        userId: createdBy,
      );

      // V2: Générer écriture comptable
      if (generateEcritureComptable) {
        try {
          await _comptabiliteService.generateEcritureForRecette(
            recetteId: id,
            montant: montantNet,
            createdBy: createdBy,
          );
        } catch (e) {
          print('Erreur lors de la génération de l\'écriture comptable pour la recette: $e');
        }
      }

      return recette.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création de la recette: $e');
    }
  }

  /// Créer une recette manuelle (hors vente)
  Future<RecetteModel> createRecetteManuelle({
    required int adherentId,
    required double montantBrut,
    double? commissionRate,
    DateTime? dateRecette,
    String? notes,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Obtenir le taux de commission si non fourni
      final tauxCommission = commissionRate ?? await getCommissionRate();
      
      // Calculer la commission et le montant net
      final commissionAmount = RecetteModel.calculateCommissionAmount(montantBrut, tauxCommission);
      final montantNet = RecetteModel.calculateMontantNet(montantBrut, tauxCommission);
      
      final recette = RecetteModel(
        adherentId: adherentId,
        montantBrut: montantBrut,
        commissionRate: tauxCommission,
        commissionAmount: commissionAmount,
        montantNet: montantNet,
        dateRecette: dateRecette ?? DateTime.now(),
        notes: notes,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final id = await db.insert('recettes', recette.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_RECETTE_MANUELLE',
        entityType: 'recettes',
        entityId: id,
        details: 'Recette manuelle créée pour adhérent $adherentId: ${montantNet.toStringAsFixed(2)} FCFA',
      );

      // Notification : Recette calculée
      await _notificationService.notifyRecetteCalculated(
        recetteId: id,
        montantNet: montantNet,
        userId: createdBy,
      );

      // V2: Générer écriture comptable
      try {
        await _comptabiliteService.generateEcritureForRecette(
          recetteId: id,
          montant: montantNet,
          createdBy: createdBy,
        );
      } catch (e) {
        print('Erreur lors de la génération de l\'écriture comptable pour la recette manuelle: $e');
      }

      return recette.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création de la recette: $e');
    }
  }

  /// Mettre à jour une recette (si la vente est modifiée)
  Future<RecetteModel> updateRecette({
    required int id,
    double? montantBrut,
    double? commissionRate,
    String? notes,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer la recette actuelle
      final currentResult = await db.query(
        'recettes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (currentResult.isEmpty) {
        throw Exception('Recette non trouvée');
      }
      
      final currentRecette = RecetteModel.fromMap(currentResult.first);
      
      // Calculer les nouveaux montants si nécessaire
      final nouveauMontantBrut = montantBrut ?? currentRecette.montantBrut;
      final nouveauTauxCommission = commissionRate ?? currentRecette.commissionRate;
      final nouvelleCommission = RecetteModel.calculateCommissionAmount(nouveauMontantBrut, nouveauTauxCommission);
      final nouveauMontantNet = RecetteModel.calculateMontantNet(nouveauMontantBrut, nouveauTauxCommission);
      
      await db.update(
        'recettes',
        {
          'montant_brut': nouveauMontantBrut,
          'commission_rate': nouveauTauxCommission,
          'commission_amount': nouvelleCommission,
          'montant_net': nouveauMontantNet,
          if (notes != null) 'notes': notes,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_RECETTE',
        entityType: 'recettes',
        entityId: id,
        details: 'Recette mise à jour',
      );

      // Récupérer la recette mise à jour
      final updatedResult = await db.query(
        'recettes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return RecetteModel.fromMap(updatedResult.first);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Supprimer une recette (si la vente est annulée)
  Future<bool> deleteRecette(int id, int deletedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      await db.delete(
        'recettes',
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: deletedBy,
        action: 'DELETE_RECETTE',
        entityType: 'recettes',
        entityId: id,
        details: 'Recette supprimée',
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Obtenir toutes les recettes d'un adhérent
  Future<List<RecetteModel>> getRecettesByAdherent(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'recettes',
        where: 'adherent_id = ?',
        whereArgs: [adherentId],
        orderBy: 'date_recette DESC',
      );
      
      return result.map((map) => RecetteModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des recettes: $e');
    }
  }

  /// Obtenir une recette par ID
  Future<RecetteModel?> getRecetteById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'recettes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      return RecetteModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la recette: $e');
    }
  }

  /// Obtenir toutes les recettes avec filtres
  Future<List<RecetteModel>> getRecettes({
    int? adherentId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 1000,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String where = '1=1';
      List<dynamic> whereArgs = [];
      
      if (adherentId != null) {
        where += ' AND adherent_id = ?';
        whereArgs.add(adherentId);
      }
      
      if (startDate != null) {
        where += ' AND date_recette >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        where += ' AND date_recette <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      final result = await db.query(
        'recettes',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'date_recette DESC',
        limit: limit,
      );
      
      return result.map((map) => RecetteModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des recettes: $e');
    }
  }

  /// Obtenir le résumé des recettes par adhérent
  Future<List<RecetteSummaryModel>> getRecettesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      List<dynamic> whereArgs = [];
      String sqlWhere = 'WHERE a.is_active = 1';
      if (startDate != null) {
        sqlWhere += ' AND r.date_recette >= ?';
      }
      if (endDate != null) {
        sqlWhere += ' AND r.date_recette <= ?';
      }
      
      final result = await db.rawQuery('''
        SELECT 
          a.id as adherent_id,
          a.code as adherent_code,
          a.nom as adherent_nom,
          a.prenom as adherent_prenom,
          COALESCE(SUM(r.montant_brut), 0) as total_montant_brut,
          COALESCE(SUM(r.commission_amount), 0) as total_commission,
          COALESCE(SUM(r.montant_net), 0) as total_montant_net,
          COUNT(r.id) as nombre_recettes,
          MAX(r.date_recette) as derniere_recette
        FROM adherents a
        LEFT JOIN recettes r ON r.adherent_id = a.id
        $sqlWhere
        GROUP BY a.id, a.code, a.nom, a.prenom
        HAVING COUNT(r.id) > 0
        ORDER BY total_montant_net DESC
      ''', whereArgs.isEmpty ? null : whereArgs);
      
      return result.map((row) => RecetteSummaryModel(
        adherentId: row['adherent_id'] as int,
        adherentCode: row['adherent_code'] as String,
        adherentNom: row['adherent_nom'] as String,
        adherentPrenom: row['adherent_prenom'] as String,
        totalMontantBrut: (row['total_montant_brut'] as num?)?.toDouble() ?? 0.0,
        totalCommission: (row['total_commission'] as num?)?.toDouble() ?? 0.0,
        totalMontantNet: (row['total_montant_net'] as num?)?.toDouble() ?? 0.0,
        nombreRecettes: row['nombre_recettes'] as int,
        derniereRecette: row['derniere_recette'] != null
            ? DateTime.parse(row['derniere_recette'] as String)
            : null,
      )).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération du résumé: $e');
    }
  }

  /// Obtenir les ventes associées à une recette
  Future<Map<String, dynamic>?> getVenteForRecette(int recetteId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.rawQuery('''
        SELECT v.*
        FROM ventes v
        INNER JOIN recettes r ON r.vente_id = v.id
        WHERE r.id = ?
      ''', [recetteId]);
      
      if (result.isEmpty) return null;
      
      return result.first;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la vente: $e');
    }
  }

  /// Obtenir toutes les ventes d'un adhérent pour générer le bordereau
  Future<List<Map<String, dynamic>>> getVentesForBordereau(
    int adherentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String where = 'adherent_id = ? AND statut = ?';
      List<dynamic> whereArgs = [adherentId, 'valide'];
      
      if (startDate != null) {
        where += ' AND date_vente >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        where += ' AND date_vente <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      final result = await db.query(
        'ventes',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'date_vente ASC',
      );
      
      return result;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des ventes: $e');
    }
  }
}

