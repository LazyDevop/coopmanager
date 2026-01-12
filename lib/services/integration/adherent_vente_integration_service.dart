import '../database/db_initializer.dart';
import '../auth/audit_service.dart';
import '../notification/notification_service.dart';
import '../../data/models/adherent_model.dart';
import '../../data/models/vente_adherent_model.dart';
import '../../data/models/recette_model.dart';
import '../../config/app_config.dart';
import '../recette/recette_service.dart';
import '../adherent/adherent_service.dart';
import '../stock/stock_service.dart';

class AdherentVenteIntegrationService {
  final AuditService _auditService = AuditService();
  final NotificationService _notificationService = NotificationService();
  final RecetteService _recetteService = RecetteService();
  final AdherentService _adherentService = AdherentService();
  final StockService _stockService = StockService();

  /// Valider qu'un adhérent peut vendre
  /// 
  /// Vérifie :
  /// - Statut actif
  /// - Stock disponible
  /// - Campagne active
  Future<Map<String, dynamic>> validateAdherentForVente({
    required int adherentId,
    required double quantiteDemandee,
    int? campagneId,
    String? qualite,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // 1. Vérifier l'adhérent existe et est actif
      final adherentResult = await db.query(
        'adherents',
        where: 'id = ?',
        whereArgs: [adherentId],
        limit: 1,
      );

      if (adherentResult.isEmpty) {
        return {
          'isValid': false,
          'error': 'Adhérent introuvable',
        };
      }

      final adherent = AdherentModel.fromMap(adherentResult.first);

      // Vérifier statut actif
      if (!adherent.isActive || adherent.isStatutSuspendu || adherent.isStatutRadie) {
        return {
          'isValid': false,
          'error': 'Adhérent ${adherent.isStatutSuspendu ? "suspendu" : "radié"} - Vente impossible',
          'adherent': adherent,
        };
      }

      // 2. Vérifier le stock disponible
      double stockDisponible = 0.0;
      
      if (campagneId != null) {
        // Stock par campagne
        final stockResult = await db.rawQuery('''
          SELECT COALESCE(SUM(quantite), 0) as total
          FROM stocks
          WHERE adherent_id = ? 
          AND campagne_id = ?
          ${qualite != null ? 'AND qualite = ?' : ''}
        ''', qualite != null ? [adherentId, campagneId, qualite] : [adherentId, campagneId]);
        
        stockDisponible = (stockResult.first['total'] as num?)?.toDouble() ?? 0.0;
      } else {
        // Stock total
        final stockResult = await db.rawQuery('''
          SELECT COALESCE(SUM(quantite), 0) as total
          FROM stocks
          WHERE adherent_id = ?
          ${qualite != null ? 'AND qualite = ?' : ''}
        ''', qualite != null ? [adherentId, qualite] : [adherentId]);
        
        stockDisponible = (stockResult.first['total'] as num?)?.toDouble() ?? 0.0;
      }

      if (stockDisponible < quantiteDemandee) {
        return {
          'isValid': false,
          'error': 'Stock insuffisant: ${stockDisponible.toStringAsFixed(2)} kg disponible (demandé: ${quantiteDemandee.toStringAsFixed(2)} kg)',
          'adherent': adherent,
          'stockDisponible': stockDisponible,
        };
      }

      // 3. Obtenir le taux de commission selon la catégorie
      final commissionRate = await _getCommissionRateForAdherent(adherent);

      return {
        'isValid': true,
        'adherent': adherent,
        'stockDisponible': stockDisponible,
        'commissionRate': commissionRate,
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': 'Erreur lors de la validation: ${e.toString()}',
      };
    }
  }

  /// Obtenir le taux de commission selon la catégorie de l'adhérent
  Future<double> _getCommissionRateForAdherent(AdherentModel adherent) async {
    try {
      final db = await DatabaseInitializer.database;

      // Récupérer les paramètres de commission par catégorie
      final settingsResult = await db.query('coop_settings', limit: 1);
      
      if (settingsResult.isEmpty) {
        return AppConfig.defaultCommissionRate;
      }

      final settings = settingsResult.first;

      // Commission différenciée selon catégorie
      if (adherent.isActionnaire) {
        // Actionnaires : commission réduite ou paramétrable
        final rate = settings['commission_rate_actionnaire'] as num?;
        return rate?.toDouble() ?? (AppConfig.defaultCommissionRate * 0.8); // 20% de réduction par défaut
      } else if (adherent.isAdherent) {
        // Adhérents : commission standard
        return (settings['commission_rate'] as num).toDouble();
      } else {
        // Producteurs non adhérents : commission plus élevée
        final rate = settings['commission_rate_producteur'] as num?;
        return rate?.toDouble() ?? (AppConfig.defaultCommissionRate * 1.2); // 20% d'augmentation par défaut
      }
    } catch (e) {
      print('Erreur lors de la récupération du taux de commission: $e');
      return AppConfig.defaultCommissionRate;
    }
  }

  /// Créer une entrée dans vente_adherents avec calcul automatique
  Future<int> createVenteAdherent({
    required int venteId,
    required int adherentId,
    required double poidsUtilise,
    required double prixKg,
    int? campagneId,
    String? qualite,
    double? commissionRateOverride,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Obtenir l'adhérent pour calculer la commission
      final adherentResult = await db.query(
        'adherents',
        where: 'id = ?',
        whereArgs: [adherentId],
        limit: 1,
      );

      if (adherentResult.isEmpty) {
        throw Exception('Adhérent introuvable');
      }

      final adherent = AdherentModel.fromMap(adherentResult.first);

      // Calculer les montants
      final montantBrut = poidsUtilise * prixKg;
      final commissionRate = commissionRateOverride ?? await _getCommissionRateForAdherent(adherent);
      final commissionAmount = RecetteModel.calculateCommissionAmount(montantBrut, commissionRate);
      final montantNet = RecetteModel.calculateMontantNet(montantBrut, commissionRate);

      final venteAdherent = VenteAdherentModel(
        venteId: venteId,
        adherentId: adherentId,
        poidsUtilise: poidsUtilise,
        prixKg: prixKg,
        montantBrut: montantBrut,
        commissionRate: commissionRate,
        commissionAmount: commissionAmount,
        montantNet: montantNet,
        campagneId: campagneId,
        qualite: qualite,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      final id = await db.insert('vente_adherents', venteAdherent.toMap());

      // Logger l'audit
      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_VENTE_ADHERENT',
        entityType: 'vente_adherents',
        entityId: id,
        details: 'Répartition vente #$venteId - Adhérent #$adherentId: ${poidsUtilise.toStringAsFixed(2)} kg = ${montantNet.toStringAsFixed(0)} FCFA',
      );

      return id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la répartition adhérent: $e');
    }
  }

  /// Obtenir la répartition complète d'une vente par adhérents
  Future<List<VenteAdherentModel>> getRepartitionVente(int venteId) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.query(
        'vente_adherents',
        where: 'vente_id = ?',
        whereArgs: [venteId],
        orderBy: 'created_at ASC',
      );

      return result.map((map) => VenteAdherentModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la répartition: $e');
    }
  }

  /// Obtenir toutes les ventes d'un adhérent
  Future<List<VenteAdherentModel>> getVentesByAdherent({
    required int adherentId,
    int? campagneId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = 'adherent_id = ?';
      List<dynamic> whereArgs = [adherentId];

      if (campagneId != null) {
        where += ' AND campagne_id = ?';
        whereArgs.add(campagneId);
      }

      if (startDate != null) {
        where += ' AND created_at >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND created_at <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.query(
        'vente_adherents',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );

      return result.map((map) => VenteAdherentModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des ventes adhérent: $e');
    }
  }

  /// Obtenir le stock disponible d'un adhérent par campagne
  Future<Map<String, dynamic>> getStockDisponibleByCampagne({
    required int adherentId,
    int? campagneId,
    String? qualite,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = 'adherent_id = ?';
      List<dynamic> whereArgs = [adherentId];

      if (campagneId != null) {
        where += ' AND campagne_id = ?';
        whereArgs.add(campagneId);
      }

      if (qualite != null) {
        where += ' AND qualite = ?';
        whereArgs.add(qualite);
      }

      final result = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(quantite), 0) as total_kg,
          campagne_id,
          qualite
        FROM stocks
        WHERE $where
        GROUP BY campagne_id, qualite
      ''', whereArgs);

      final stocks = <String, double>{};
      double totalGeneral = 0.0;

      for (final row in result) {
        final total = (row['total_kg'] as num).toDouble();
        final campId = row['campagne_id'] as int?;
        final qual = row['qualite'] as String?;
        
        final key = '${campId ?? 'all'}_${qual ?? 'all'}';
        stocks[key] = total;
        totalGeneral += total;
      }

      return {
        'stocks': stocks,
        'total': totalGeneral,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération du stock: $e');
    }
  }

  /// Calculer les statistiques de vente d'un adhérent
  Future<Map<String, dynamic>> getStatistiquesVentesAdherent({
    required int adherentId,
    int? campagneId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = 'adherent_id = ?';
      List<dynamic> whereArgs = [adherentId];

      if (campagneId != null) {
        where += ' AND campagne_id = ?';
        whereArgs.add(campagneId);
      }

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as nombre_ventes,
          COALESCE(SUM(poids_utilise), 0) as poids_total,
          COALESCE(SUM(montant_brut), 0) as montant_brut_total,
          COALESCE(SUM(commission_amount), 0) as commission_totale,
          COALESCE(SUM(montant_net), 0) as montant_net_total
        FROM vente_adherents
        WHERE $where
      ''', whereArgs);

      if (result.isEmpty) {
        return {
          'nombreVentes': 0,
          'poidsTotal': 0.0,
          'montantBrutTotal': 0.0,
          'commissionTotale': 0.0,
          'montantNetTotal': 0.0,
        };
      }

      final row = result.first;
      return {
        'nombreVentes': row['nombre_ventes'] as int,
        'poidsTotal': (row['poids_total'] as num).toDouble(),
        'montantBrutTotal': (row['montant_brut_total'] as num).toDouble(),
        'commissionTotale': (row['commission_totale'] as num).toDouble(),
        'montantNetTotal': (row['montant_net_total'] as num).toDouble(),
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  /// Répartir automatiquement une vente sur plusieurs adhérents selon critères
  /// 
  /// Utilise FIFO et priorités de catégorie
  Future<List<VenteAdherentModel>> repartirVenteAutomatique({
    required int venteId,
    required double quantiteTotal,
    required double prixUnitaire,
    int? campagneId,
    String? qualite,
    String? categoriePrioritaire, // 'actionnaire', 'adherent', 'producteur'
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // 1. Construire la requête pour trouver les stocks disponibles
      String stockWhere = 's.adherent_id = a.id AND s.quantite > 0';
      List<dynamic> stockArgs = [];

      if (campagneId != null) {
        stockWhere += ' AND s.campagne_id = ?';
        stockArgs.add(campagneId);
      }

      if (qualite != null) {
        stockWhere += ' AND s.qualite = ?';
        stockArgs.add(qualite);
      }

      // 2. Trouver les adhérents avec stock disponible, triés par priorité
      String orderBy = 'a.created_at ASC'; // FIFO par défaut
      
      if (categoriePrioritaire != null) {
        // Prioriser selon catégorie
        orderBy = '''
          CASE 
            WHEN a.categorie = ? THEN 1
            WHEN a.categorie = 'adherent' THEN 2
            WHEN a.categorie = 'producteur' OR a.categorie IS NULL THEN 3
            ELSE 4
          END,
          a.created_at ASC
        ''';
        stockArgs.insert(0, categoriePrioritaire);
      }

      final adherentsResult = await db.rawQuery('''
        SELECT DISTINCT
          a.id,
          a.categorie,
          a.statut,
          a.is_active,
          COALESCE(SUM(s.quantite), 0) as stock_total
        FROM adherents a
        LEFT JOIN stocks s ON $stockWhere
        WHERE a.is_active = 1 
        AND (a.statut IS NULL OR a.statut = 'actif')
        GROUP BY a.id, a.categorie, a.statut, a.is_active
        HAVING stock_total > 0
        ORDER BY $orderBy
      ''', stockArgs);

      if (adherentsResult.isEmpty) {
        throw Exception('Aucun adhérent avec stock disponible trouvé');
      }

      // 3. Répartir la quantité sur les adhérents disponibles (FIFO)
      final repartitions = <VenteAdherentModel>[];
      double quantiteRestante = quantiteTotal;

      for (final row in adherentsResult) {
        if (quantiteRestante <= 0) break;

        final adherentId = row['id'] as int;
        final stockTotal = (row['stock_total'] as num).toDouble();
        final quantitePourAdherent = quantiteRestante > stockTotal ? stockTotal : quantiteRestante;

        // Créer la répartition
        final venteAdherentId = await createVenteAdherent(
          venteId: venteId,
          adherentId: adherentId,
          poidsUtilise: quantitePourAdherent,
          prixKg: prixUnitaire,
          campagneId: campagneId,
          qualite: qualite,
          createdBy: createdBy,
        );

        // Récupérer l'entité créée
        final created = await db.query(
          'vente_adherents',
          where: 'id = ?',
          whereArgs: [venteAdherentId],
          limit: 1,
        );

        if (created.isNotEmpty) {
          repartitions.add(VenteAdherentModel.fromMap(created.first));
        }

        quantiteRestante -= quantitePourAdherent;
      }

      if (quantiteRestante > 0) {
        throw Exception('Stock insuffisant pour répartir toute la quantité. Restant: ${quantiteRestante.toStringAsFixed(2)} kg');
      }

      return repartitions;
    } catch (e) {
      throw Exception('Erreur lors de la répartition automatique: $e');
    }
  }
}

