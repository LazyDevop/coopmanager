import 'package:sqflite_common/sqlite_api.dart';
import '../database/db_initializer.dart';
import '../../data/models/stock_model.dart';
import '../../data/models/stock_movement_model.dart';
import '../auth/audit_service.dart';
import '../../data/models/audit_log_model.dart';
import '../notification/notification_service.dart';

class StockService {
  final AuditService _auditService = AuditService();
  final NotificationService _notificationService = NotificationService();

  /// Créer un nouveau dépôt de stock
  Future<StockDepotModel> createDepot({
    required int adherentId,
    double? quantite, // Pour compatibilité avec l'ancien code
    required double stockBrut,
    double? poidsSac,
    double? poidsDechets,
    double? autres,
    required double poidsNet,
    double? prixUnitaire,
    required DateTime dateDepot,
    String? qualite,
    double? humidite,
    double? densiteArbresAssocies,
    String? photoPath,
    String? observations,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final depot = StockDepotModel(
        adherentId: adherentId,
        quantite: quantite ?? poidsNet, // Pour compatibilité
        stockBrut: stockBrut,
        poidsSac: poidsSac,
        poidsDechets: poidsDechets,
        autres: autres,
        poidsNet: poidsNet,
        prixUnitaire: prixUnitaire,
        dateDepot: dateDepot,
        qualite: qualite,
        humidite: humidite,
        densiteArbresAssocies: densiteArbresAssocies,
        photoPath: photoPath,
        observations: observations,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final dataToInsert = depot.toMap();
      print('Données à insérer: $dataToInsert'); // Debug
      
      final id = await db.insert('stock_depots', dataToInsert);

      // Créer un mouvement de stock pour le dépôt (utiliser poids_net)
      await _createMovement(
        adherentId: adherentId,
        type: 'depot',
        quantite: poidsNet,
        depotId: id,
        dateMouvement: dateDepot,
        commentaire: 'Dépôt: ${stockBrut.toStringAsFixed(2)} kg brut → ${poidsNet.toStringAsFixed(2)} kg net${qualite != null ? ' ($qualite)' : ''}',
        createdBy: createdBy,
      );

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_STOCK_DEPOT',
        entityType: 'stock_depots',
        entityId: id,
        details: 'Dépôt: ${stockBrut.toStringAsFixed(2)} kg brut → ${poidsNet.toStringAsFixed(2)} kg net pour adhérent $adherentId',
      );

      // Notification : Dépôt ajouté
      await _notificationService.notifyDepotAdded(
        adherentId: adherentId,
        quantite: poidsNet,
        userId: createdBy,
      );

      // Vérifier les alertes de stock après dépôt (le stock peut toujours être faible après ajout)
      await getStockActuel(adherentId, checkAlerts: true);

      return depot.copyWith(id: id);
    } catch (e, stackTrace) {
      print('Erreur détaillée lors de la création du dépôt: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la création du dépôt: $e');
    }
  }

  /// Créer un mouvement de stock
  Future<StockMovementModel> _createMovement({
    required int adherentId,
    required String type,
    required double quantite,
    int? depotId,
    int? venteId,
    required DateTime dateMouvement,
    String? commentaire,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final movement = StockMovementModel(
        adherentId: adherentId,
        type: type,
        quantite: quantite,
        depotId: depotId,
        venteId: venteId,
        dateMouvement: dateMouvement,
        commentaire: commentaire,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final movementMap = movement.toMap();
      print('📝 Insertion mouvement: type=$type, adherent=$adherentId, quantite=$quantite, venteId=$venteId');
      
      final id = await db.insert('stock_mouvements', movementMap);
      
      if (id == null || id <= 0) {
        throw Exception('Échec de l\'insertion du mouvement: ID invalide ($id)');
      }
      
      print('✅ Mouvement inséré avec succès: ID $id');
      return movement.copyWith(id: id);
    } catch (e, stackTrace) {
      print('❌ ERREUR lors de la création du mouvement: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la création du mouvement: $e');
    }
  }

  /// Créer un ajustement de stock (admin/gestionnaire uniquement)
  Future<StockMovementModel> createAjustement({
    required int adherentId,
    required double quantite, // positif pour ajout, négatif pour retrait
    required String raison,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final ajustement = StockMovementModel(
        adherentId: adherentId,
        type: 'ajustement',
        quantite: quantite,
        dateMouvement: DateTime.now(),
        commentaire: raison,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final id = await db.insert('stock_mouvements', ajustement.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'STOCK_AJUSTEMENT',
        entityType: 'stock_mouvements',
        entityId: id,
        details: 'Ajustement de $quantite kg pour adhérent $adherentId. Raison: $raison',
      );

      // Vérifier les alertes de stock après ajustement
      await getStockActuel(adherentId, checkAlerts: true);

      return ajustement.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de l\'ajustement: $e');
    }
  }

  /// Déduire du stock lors d'une vente
  Future<void> deductStockForVente({
    required int adherentId,
    required double quantite,
    required int venteId,
    required int createdBy,
  }) async {
    try {
      print('🔴 DÉDUCTION STOCK: Adhérent $adherentId, Quantité: $quantite kg, Vente: $venteId');
      
      // Créer le mouvement de déduction directement
      final movement = await _createMovement(
        adherentId: adherentId,
        type: 'vente',
        quantite: -quantite, // Négatif pour déduction
        venteId: venteId,
        dateMouvement: DateTime.now(),
        commentaire: 'Vente de $quantite kg',
        createdBy: createdBy,
      );

      print('✅ Mouvement créé: ID ${movement.id}, Quantité: ${movement.quantite}');

      await _auditService.logAction(
        userId: createdBy,
        action: 'STOCK_DEDUCTION',
        entityType: 'stock_mouvements',
        entityId: venteId,
        details: 'Déduction de $quantite kg pour vente $venteId',
      );

      // Vérifier le stock après déduction et les alertes
      final stockApres = await getStockActuel(adherentId, checkAlerts: true);
      print('📊 Stock après déduction: $stockApres kg');
    } catch (e, stackTrace) {
      print('❌ ERREUR lors de la déduction du stock: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la déduction du stock: $e');
    }
  }

  /// Calculer le stock actuel d'un adhérent
  Future<double> getStockActuel(int adherentId, {bool checkAlerts = false}) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Somme des dépôts
      final depotsResult = await db.rawQuery('''
        SELECT COALESCE(SUM(quantite), 0) as total
        FROM stock_depots
        WHERE adherent_id = ?
      ''', [adherentId]);
      
      final totalDepots = (depotsResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // Somme des mouvements (ventes et ajustements)
      final mouvementsResult = await db.rawQuery('''
        SELECT COALESCE(SUM(quantite), 0) as total
        FROM stock_mouvements
        WHERE adherent_id = ? AND type IN ('vente', 'ajustement')
      ''', [adherentId]);
      
      final totalMouvements = (mouvementsResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      final stockActuel = totalDepots + totalMouvements; // totalMouvements est négatif pour les ventes
      
      // Vérifier le stock et envoyer des notifications si nécessaire (seulement si demandé)
      if (checkAlerts) {
        await _checkStockAndNotify(adherentId, stockActuel);
      }
      
      return stockActuel;
    } catch (e) {
      throw Exception('Erreur lors du calcul du stock: $e');
    }
  }

  /// Vérifier le stock et envoyer des notifications si nécessaire
  /// Évite les notifications en double en vérifiant les notifications récentes
  Future<void> _checkStockAndNotify(int adherentId, double stockActuel) async {
    try {
      // Seuils de stock (à configurer dans les paramètres)
      const seuilFaible = 50.0; // kg
      const seuilCritique = 10.0; // kg

      final db = await DatabaseInitializer.database;
      
      // Vérifier si une notification similaire a déjà été envoyée dans les dernières 24 heures
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      
      // Vérifier pour stock critique
      if (stockActuel <= seuilCritique) {
        final existingCritical = await db.rawQuery('''
          SELECT COUNT(*) as count
          FROM notifications
          WHERE entity_type = 'adherent'
            AND entity_id = ?
            AND type = 'critical'
            AND module = 'stock'
            AND created_at > ?
        ''', [adherentId, yesterday.toIso8601String()]);
        
        final count = (existingCritical.first['count'] as int?) ?? 0;
        
        // Envoyer seulement si aucune notification critique n'a été envoyée récemment
        if (count == 0) {
          await _notificationService.notifyStockCritical(
            adherentId: adherentId,
            stockActuel: stockActuel,
          );
        }
      } 
      // Vérifier pour stock faible (seulement si pas critique)
      else if (stockActuel <= seuilFaible) {
        final existingLow = await db.rawQuery('''
          SELECT COUNT(*) as count
          FROM notifications
          WHERE entity_type = 'adherent'
            AND entity_id = ?
            AND type = 'warning'
            AND module = 'stock'
            AND created_at > ?
        ''', [adherentId, yesterday.toIso8601String()]);
        
        final count = (existingLow.first['count'] as int?) ?? 0;
        
        // Envoyer seulement si aucune notification faible n'a été envoyée récemment
        if (count == 0) {
          await _notificationService.notifyStockLow(
            adherentId: adherentId,
            stockActuel: stockActuel,
            seuil: seuilFaible,
          );
        }
      }
    } catch (e) {
      // Ne pas faire échouer le calcul de stock si la notification échoue
      print('Erreur lors de la vérification des alertes de stock: $e');
    }
  }

  /// Obtenir le stock actuel par qualité pour un adhérent
  Future<Map<String, double>> getStockByQualite(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.rawQuery('''
        SELECT 
          COALESCE(qualite, 'standard') as qualite,
          SUM(sd.quantite) as total_depots,
          COALESCE(SUM(CASE WHEN sm.type IN ('vente', 'ajustement') THEN sm.quantite ELSE 0 END), 0) as total_mouvements
        FROM stock_depots sd
        LEFT JOIN stock_mouvements sm ON sm.adherent_id = sd.adherent_id
        WHERE sd.adherent_id = ?
        GROUP BY qualite
      ''', [adherentId]);
      
      final stockByQualite = <String, double>{};
      
      for (final row in result) {
        final qualite = row['qualite'] as String? ?? 'standard';
        final depots = (row['total_depots'] as num?)?.toDouble() ?? 0.0;
        final mouvements = (row['total_mouvements'] as num?)?.toDouble() ?? 0.0;
        stockByQualite[qualite] = depots + mouvements;
      }
      
      return stockByQualite;
    } catch (e) {
      throw Exception('Erreur lors du calcul du stock par qualité: $e');
    }
  }

  /// Obtenir tous les stocks actuels avec informations adhérents
  Future<List<StockActuelModel>> getAllStocksActuels() async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Utiliser des sous-requêtes pour éviter les problèmes de duplication avec JOIN
      final result = await db.rawQuery('''
        SELECT 
          a.id as adherent_id,
          a.code as adherent_code,
          a.nom as adherent_nom,
          a.prenom as adherent_prenom,
          COALESCE((
            SELECT SUM(quantite) 
            FROM stock_depots 
            WHERE adherent_id = a.id
          ), 0) as total_depots,
          COALESCE((
            SELECT SUM(quantite) 
            FROM stock_mouvements 
            WHERE adherent_id = a.id AND type IN ('vente', 'ajustement')
          ), 0) as total_mouvements,
          (
            SELECT MAX(date_depot) 
            FROM stock_depots 
            WHERE adherent_id = a.id
          ) as dernier_depot,
          (
            SELECT MAX(date_mouvement) 
            FROM stock_mouvements 
            WHERE adherent_id = a.id
          ) as dernier_mouvement
        FROM adherents a
        WHERE a.is_active = 1
        ORDER BY a.nom, a.prenom
      ''');
      
      final stocks = <StockActuelModel>[];
      
      for (final row in result) {
        final adherentId = row['adherent_id'] as int;
        final totalDepots = (row['total_depots'] as num?)?.toDouble() ?? 0.0;
        final totalMouvements = (row['total_mouvements'] as num?)?.toDouble() ?? 0.0;
        final stockTotal = totalDepots + totalMouvements;
        
        // Obtenir le stock par qualité
        final stockByQualite = await getStockByQualite(adherentId);
        
        stocks.add(StockActuelModel(
          adherentId: adherentId,
          adherentCode: row['adherent_code'] as String,
          adherentNom: row['adherent_nom'] as String,
          adherentPrenom: row['adherent_prenom'] as String,
          stockTotal: stockTotal,
          stockStandard: stockByQualite['standard'] ?? 0,
          stockPremium: stockByQualite['premium'] ?? 0,
          stockBio: stockByQualite['bio'] ?? 0,
          dernierDepot: row['dernier_depot'] != null
              ? DateTime.parse(row['dernier_depot'] as String)
              : null,
          dernierMouvement: row['dernier_mouvement'] != null
              ? DateTime.parse(row['dernier_mouvement'] as String)
              : null,
        ));
      }
      
      return stocks;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des stocks: $e');
    }
  }

  /// Obtenir les dépôts d'un adhérent
  Future<List<StockDepotModel>> getDepotsByAdherent(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'stock_depots',
        where: 'adherent_id = ?',
        whereArgs: [adherentId],
        orderBy: 'date_depot DESC',
      );
      
      return result.map((map) => StockDepotModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des dépôts: $e');
    }
  }

  /// Obtenir les dépôts disponibles en FIFO (First In First Out) pour un adhérent
  /// Retourne les dépôts avec leur quantité disponible (après déduction des ventes)
  /// Triés par date de dépôt (plus ancien en premier)
  Future<List<Map<String, dynamic>>> getDepotsDisponiblesFIFO(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer tous les dépôts de l'adhérent triés par date (FIFO)
      final depots = await db.query(
        'stock_depots',
        where: 'adherent_id = ?',
        whereArgs: [adherentId],
        orderBy: 'date_depot ASC, id ASC', // FIFO: plus ancien en premier
      );
      
      // Pour chaque dépôt, calculer la quantité disponible
      final depotsDisponibles = <Map<String, dynamic>>[];
      
      for (final depot in depots) {
        final depotId = depot['id'] as int;
        final quantiteDepot = (depot['quantite'] as num).toDouble();
        
        // Calculer la quantité déjà vendue depuis ce dépôt
        final ventesResult = await db.rawQuery('''
          SELECT COALESCE(SUM(vl.quantite), 0) as quantite_vendue
          FROM vente_lignes vl
          WHERE vl.stock_depot_id = ?
        ''', [depotId]);
        
        final quantiteVendue = (ventesResult.first['quantite_vendue'] as num?)?.toDouble() ?? 0.0;
        final quantiteDisponible = quantiteDepot - quantiteVendue;
        
        if (quantiteDisponible > 0) {
          depotsDisponibles.add({
            'depot': StockDepotModel.fromMap(depot),
            'quantite_disponible': quantiteDisponible,
            'depot_id': depotId,
          });
        }
      }
      
      return depotsDisponibles;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des dépôts FIFO: $e');
    }
  }

  /// Obtenir l'historique des mouvements
  Future<List<StockMovementModel>> getMouvements({
    int? adherentId,
    String? type,
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
      
      if (type != null) {
        where += ' AND type = ?';
        whereArgs.add(type);
      }
      
      if (startDate != null) {
        where += ' AND date_mouvement >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        where += ' AND date_mouvement <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      final result = await db.query(
        'stock_mouvements',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'date_mouvement DESC, created_at DESC',
        limit: limit,
      );
      
      return result.map((map) => StockMovementModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des mouvements: $e');
    }
  }

  /// Obtenir un dépôt par ID
  Future<StockDepotModel?> getDepotById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'stock_depots',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      return StockDepotModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du dépôt: $e');
    }
  }

  /// Supprimer un dépôt (avec vérification)
  Future<bool> deleteDepot(int id, int deletedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final depot = await getDepotById(id);
      if (depot == null) return false;
      
      // Vérifier si le dépôt a été utilisé dans des ventes
      final mouvements = await db.query(
        'stock_mouvements',
        where: 'stock_depot_id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (mouvements.isNotEmpty) {
        throw Exception('Ce dépôt ne peut pas être supprimé car il a été utilisé dans des opérations');
      }
      
      await db.delete(
        'stock_depots',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      await _auditService.logAction(
        userId: deletedBy,
        action: 'DELETE_STOCK_DEPOT',
        entityType: 'stock_depots',
        entityId: id,
        details: 'Suppression du dépôt $id',
      );
      
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}

