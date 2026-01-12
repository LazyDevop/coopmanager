import '../database/db_initializer.dart';
import '../../data/models/adherent_expert/production_model.dart';
import '../auth/audit_service.dart';

/// Service pour gérer les productions agricoles
class ProductionService {
  final AuditService _auditService = AuditService();

  /// Créer une production
  Future<ProductionModel> createProduction({
    required int adherentId,
    int? champId,
    required String campagne,
    required double tonnageBrut,
    required double tonnageNet,
    double tauxHumidite = 0.0,
    required DateTime dateRecolte,
    String qualite = 'standard',
    String? observation,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Vérifier les contraintes
      if (tonnageNet > tonnageBrut) {
        throw Exception('Le tonnage net ne peut pas être supérieur au tonnage brut');
      }
      if (tauxHumidite < 0 || tauxHumidite > 100) {
        throw Exception('Le taux d\'humidité doit être entre 0 et 100%');
      }
      
      final production = ProductionModel(
        adherentId: adherentId,
        champId: champId,
        campagne: campagne,
        tonnageBrut: tonnageBrut,
        tonnageNet: tonnageNet,
        tauxHumidite: tauxHumidite,
        dateRecolte: dateRecolte,
        qualite: qualite,
        observation: observation,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      final id = await db.insert('productions', production.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_PRODUCTION',
        entityType: 'productions',
        entityId: id,
        details: 'Création production: $tonnageNet t ($qualite) pour adhérent $adherentId',
      );

      return production.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création de la production: $e');
    }
  }

  /// Mettre à jour une production
  Future<ProductionModel> updateProduction({
    required int id,
    int? champId,
    String? campagne,
    double? tonnageBrut,
    double? tonnageNet,
    double? tauxHumidite,
    DateTime? dateRecolte,
    String? qualite,
    String? observation,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer la production existante
      final existing = await getProductionById(id);
      if (existing == null) {
        throw Exception('Production non trouvée');
      }

      final updatedTonnageBrut = tonnageBrut ?? existing.tonnageBrut;
      final updatedTonnageNet = tonnageNet ?? existing.tonnageNet;
      
      // Vérifier les contraintes
      if (updatedTonnageNet > updatedTonnageBrut) {
        throw Exception('Le tonnage net ne peut pas être supérieur au tonnage brut');
      }
      if (tauxHumidite != null && (tauxHumidite < 0 || tauxHumidite > 100)) {
        throw Exception('Le taux d\'humidité doit être entre 0 et 100%');
      }

      final updated = existing.copyWith(
        champId: champId,
        campagne: campagne,
        tonnageBrut: tonnageBrut,
        tonnageNet: tonnageNet,
        tauxHumidite: tauxHumidite,
        dateRecolte: dateRecolte,
        qualite: qualite,
        observation: observation,
      );

      await db.update(
        'productions',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_PRODUCTION',
        entityType: 'productions',
        entityId: id,
        details: 'Modification production: ${updated.tonnageNet} t',
      );

      return updated;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la production: $e');
    }
  }

  /// Supprimer une production
  Future<void> deleteProduction(int id, int deletedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      await db.delete(
        'productions',
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: deletedBy,
        action: 'DELETE_PRODUCTION',
        entityType: 'productions',
        entityId: id,
        details: 'Suppression production $id',
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la production: $e');
    }
  }

  /// Récupérer une production par ID
  Future<ProductionModel?> getProductionById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'productions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return ProductionModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la production: $e');
    }
  }

  /// Récupérer toutes les productions d'un adhérent
  Future<List<ProductionModel>> getProductionsByAdherent(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'productions',
        where: 'adherent_id = ?',
        whereArgs: [adherentId],
        orderBy: 'date_recolte DESC',
      );

      return result.map((map) => ProductionModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des productions: $e');
    }
  }

  /// Récupérer toutes les productions avec informations du champ
  Future<List<Map<String, dynamic>>> getProductionsWithChampInfo(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.rawQuery('''
        SELECT 
          p.*,
          c.code_champ,
          c.nom_champ
        FROM productions p
        LEFT JOIN champs_parcelles c ON p.champ_id = c.id
        WHERE p.adherent_id = ?
        ORDER BY p.date_recolte DESC
      ''', [adherentId]);

      return result;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des productions avec infos champ: $e');
    }
  }

  /// Calculer les statistiques de production pour un adhérent
  Future<Map<String, dynamic>> getProductionStats(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as nombre_productions,
          COALESCE(SUM(tonnage_brut), 0) as tonnage_brut_total,
          COALESCE(SUM(tonnage_net), 0) as tonnage_net_total,
          COALESCE(AVG(taux_humidite), 0) as taux_humidite_moyen
        FROM productions
        WHERE adherent_id = ?
      ''', [adherentId]);

      if (result.isEmpty) {
        return {
          'nombreProductions': 0,
          'tonnageBrutTotal': 0.0,
          'tonnageNetTotal': 0.0,
          'tauxHumiditeMoyen': 0.0,
        };
      }

      return {
        'nombreProductions': result.first['nombre_productions'] as int? ?? 0,
        'tonnageBrutTotal': (result.first['tonnage_brut_total'] as num?)?.toDouble() ?? 0.0,
        'tonnageNetTotal': (result.first['tonnage_net_total'] as num?)?.toDouble() ?? 0.0,
        'tauxHumiditeMoyen': (result.first['taux_humidite_moyen'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }
}

