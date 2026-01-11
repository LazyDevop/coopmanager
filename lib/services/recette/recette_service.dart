import '../database/db_initializer.dart';
import '../../data/models/recette_model.dart';
import '../auth/audit_service.dart';
import '../../config/app_config.dart';
import '../notification/notification_service.dart';
// V2: Nouveaux imports
import '../comptabilite/comptabilite_service.dart';
import '../social/social_service.dart';
import '../database/migrations/ensure_all_columns_migration.dart';

class RecetteService {
  final AuditService _auditService = AuditService();
  final NotificationService _notificationService = NotificationService();
  // V2: Nouveaux services
  final ComptabiliteService _comptabiliteService = ComptabiliteService();
  final SocialService _socialService = SocialService();

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
      print('💰 Création de recette pour vente #$venteId, adhérent #$adherentId, montant brut: $montantBrut');
      final db = await DatabaseInitializer.database;
      
      // Obtenir le taux de commission si non fourni
      final tauxCommission = commissionRate ?? await getCommissionRate();
      print('💰 Taux de commission: $tauxCommission');
      
      // Calculer la commission et le montant net
      final commissionAmount = RecetteModel.calculateCommissionAmount(montantBrut, tauxCommission);
      var montantNet = RecetteModel.calculateMontantNet(montantBrut, tauxCommission);
      print('💰 Commission: $commissionAmount, Montant net initial: $montantNet');
      
      // Intégration Social: Calculer les retenues automatiques sur les aides remboursables
      Map<int, double> retenuesSociales = {};
      try {
        retenuesSociales = await _calculerRetenuesSociales(
          adherentId: adherentId,
          montantRecette: montantNet,
        );
        
        if (retenuesSociales.isNotEmpty) {
          final totalRetenues = retenuesSociales.values.fold<double>(
            0.0,
            (sum, montant) => sum + montant,
          );
          montantNet -= totalRetenues;
          print('💰 Retenues sociales: $totalRetenues, Montant net final: $montantNet');
        }
      } catch (e) {
        print('⚠️ Erreur lors du calcul des retenues sociales: $e');
        // Ne pas faire échouer la création de recette
      }
      
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

      print('💰 Insertion de la recette dans la base de données...');
      print('💰 Données de la recette: ${recette.toMap()}');
      
      // Vérifier que la table existe et a les bonnes colonnes
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(recettes)');
        final columnNames = tableInfo.map((c) => c['name'] as String).toList();
        print('💰 Colonnes de la table recettes: $columnNames');
        
        // Vérifier que toutes les colonnes nécessaires existent
        final requiredColumns = ['adherent_id', 'montant_brut', 'commission_rate', 'commission_amount', 'montant_net', 'date_recette', 'created_at'];
        final missingColumns = requiredColumns.where((col) => !columnNames.contains(col)).toList();
        if (missingColumns.isNotEmpty) {
          print('⚠️ Colonnes manquantes dans recettes: $missingColumns');
          throw Exception('Colonnes manquantes dans la table recettes: ${missingColumns.join(", ")}');
        }
      } catch (e) {
        print('❌ Erreur lors de la vérification de la table recettes: $e');
        // Ne pas faire échouer si c'est juste une vérification
        if (e.toString().contains('no such table')) {
          rethrow;
        }
      }
      
      // S'assurer que les colonnes existent avant l'insertion
      await EnsureAllColumnsMigration.ensureAllColumns(db);
      
      final recetteMap = recette.toMap();
      print('💰 Map à insérer: $recetteMap');
      
      final id = await db.insert('recettes', recetteMap);
      print('✅ Recette créée avec succès! ID: $id');
      
      // Vérifier que la recette a bien été insérée
      final verification = await db.query('recettes', where: 'id = ?', whereArgs: [id]);
      print('✅ Vérification: ${verification.length} recette(s) trouvée(s) avec ID $id');
      
      // Intégration Social: Enregistrer les remboursements automatiques après création de la recette
      if (retenuesSociales.isNotEmpty) {
        try {
          for (var entry in retenuesSociales.entries) {
            await _socialService.enregistrerRemboursement(
              aideId: entry.key,
              montant: entry.value,
              dateRemboursement: DateTime.now(),
              source: 'RETENUE_RECETTE',
              recetteId: id,
              notes: 'Retenue automatique sur recette #$id',
              createdBy: createdBy,
            );
          }
          print('✅ ${retenuesSociales.length} remboursement(s) automatique(s) enregistré(s)');
        } catch (e) {
          print('⚠️ Erreur lors de l\'enregistrement des remboursements: $e');
          // Ne pas faire échouer la création de recette
        }
      }

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
      
      print('🔍 getRecettesByAdherent - Recherche recettes pour adhérent ID: $adherentId');
      
      // Vérifier d'abord combien de recettes existent au total
      final totalCount = await db.rawQuery('SELECT COUNT(*) as count FROM recettes');
      print('🔍 Nombre total de recettes dans la base: ${totalCount.first['count']}');
      
      // Vérifier combien de recettes ont cet adherent_id
      final countForAdherent = await db.rawQuery(
        'SELECT COUNT(*) as count FROM recettes WHERE adherent_id = ?',
        [adherentId],
      );
      print('🔍 Nombre de recettes pour adhérent $adherentId: ${countForAdherent.first['count']}');
      
      final result = await db.query(
        'recettes',
        where: 'adherent_id = ?',
        whereArgs: [adherentId],
        orderBy: 'date_recette DESC',
      );
      
      print('🔍 Résultats de la requête: ${result.length} recettes trouvées');
      if (result.isNotEmpty) {
        for (final row in result) {
          print('  - Recette ID ${row['id']}: adherent_id=${row['adherent_id']}, montant_net=${row['montant_net']}');
        }
      }
      
      return result.map((map) => RecetteModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ Erreur getRecettesByAdherent: $e');
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
      
      // Vérifier d'abord si des recettes existent
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM recettes');
      final totalRecettes = (countResult.first['count'] as int?) ?? 0;
      print('📊 Nombre total de recettes dans la base: $totalRecettes');
      
      if (totalRecettes == 0) {
        print('⚠️ Aucune recette trouvée dans la base de données');
        return [];
      }
      
      List<dynamic> whereArgs = [];
      String sqlWhere = 'WHERE a.is_active = 1';
      if (startDate != null) {
        sqlWhere += ' AND r.date_recette >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        sqlWhere += ' AND r.date_recette <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      final query = '''
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
      ''';
      
      print('🔍 Requête SQL: $query');
      print('🔍 Arguments: $whereArgs');
      
      final result = await db.rawQuery(query, whereArgs.isEmpty ? null : whereArgs);
      
      print('✅ Nombre de résumés trouvés: ${result.length}');
      
      final summaries = result.map((row) {
        print('📋 Résumé pour adhérent ${row['adherent_code']}: ${row['nombre_recettes']} recettes, ${row['total_montant_net']} FCFA');
        return RecetteSummaryModel(
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
        );
      }).toList();
      
      return summaries;
    } catch (e) {
      print('❌ Erreur lors de la récupération du résumé: $e');
      print('❌ Stack trace: ${StackTrace.current}');
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

  /// Calculer les retenues sociales automatiques pour un adhérent
  /// Retourne une Map<aideId, montantRetenu>
  Future<Map<int, double>> _calculerRetenuesSociales({
    required int adherentId,
    required double montantRecette,
  }) async {
    try {
      final retenues = <int, double>{};
      
      // Obtenir toutes les aides en cours et remboursables avec retenue automatique
      final aides = await _socialService.getAllAides(
        adherentId: adherentId,
        statut: 'en_cours',
      );
      
      // Filtrer les aides avec retenue automatique
      final aidesAvecRetenue = aides.where((aide) {
        return aide.isRemboursable && 
               aide.aideType?.hasRetenueAutomatique == true;
      }).toList();
      
      // Pour chaque aide, calculer le montant à retenir
      for (var aide in aidesAvecRetenue) {
        final soldeRestant = await _socialService.getSoldeRestant(aide.id!);
        
        if (soldeRestant > 0.01) { // Tolérance pour arrondis
          // Retenir le minimum entre le solde restant et le montant de la recette disponible
          final montantARetenir = soldeRestant < montantRecette 
              ? soldeRestant 
              : montantRecette;
          
          if (montantARetenir > 0.01) {
            retenues[aide.id!] = montantARetenir;
            montantRecette -= montantARetenir; // Réduire le montant disponible
            
            // Si le montant disponible est épuisé, arrêter
            if (montantRecette <= 0.01) break;
          }
        }
      }
      
      return retenues;
    } catch (e) {
      print('Erreur lors du calcul des retenues sociales: $e');
      return {};
    }
  }
}

