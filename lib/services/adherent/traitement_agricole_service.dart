import '../database/db_initializer.dart';
import '../../data/models/adherent_expert/traitement_agricole_model.dart';
import '../auth/audit_service.dart';

/// Service pour gérer les traitements agricoles
class TraitementAgricoleService {
  final AuditService _auditService = AuditService();

  /// Créer un traitement agricole
  Future<TraitementAgricoleModel> createTraitement({
    required int champId,
    required String typeTraitement,
    required String produitUtilise,
    required double quantite,
    String uniteQuantite = 'kg',
    required DateTime dateTraitement,
    double coutTraitement = 0.0,
    String? operateur,
    String? observation,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final traitement = TraitementAgricoleModel(
        champId: champId,
        typeTraitement: typeTraitement,
        produitUtilise: produitUtilise,
        quantite: quantite,
        uniteQuantite: uniteQuantite,
        dateTraitement: dateTraitement,
        coutTraitement: coutTraitement,
        operateur: operateur,
        observation: observation,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      final id = await db.insert('traitements_agricoles', traitement.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_TRAITEMENT',
        entityType: 'traitements_agricoles',
        entityId: id,
        details: 'Création traitement: $typeTraitement - $produitUtilise pour champ $champId',
      );

      return traitement.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création du traitement: $e');
    }
  }

  /// Mettre à jour un traitement
  Future<TraitementAgricoleModel> updateTraitement({
    required int id,
    String? typeTraitement,
    String? produitUtilise,
    double? quantite,
    String? uniteQuantite,
    DateTime? dateTraitement,
    double? coutTraitement,
    String? operateur,
    String? observation,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer le traitement existant
      final existing = await getTraitementById(id);
      if (existing == null) {
        throw Exception('Traitement non trouvé');
      }

      final updated = existing.copyWith(
        typeTraitement: typeTraitement,
        produitUtilise: produitUtilise,
        quantite: quantite,
        uniteQuantite: uniteQuantite,
        dateTraitement: dateTraitement,
        coutTraitement: coutTraitement,
        operateur: operateur,
        observation: observation,
      );

      await db.update(
        'traitements_agricoles',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_TRAITEMENT',
        entityType: 'traitements_agricoles',
        entityId: id,
        details: 'Modification traitement: ${updated.produitUtilise}',
      );

      return updated;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du traitement: $e');
    }
  }

  /// Supprimer un traitement
  Future<void> deleteTraitement(int id, int deletedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      await db.delete(
        'traitements_agricoles',
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: deletedBy,
        action: 'DELETE_TRAITEMENT',
        entityType: 'traitements_agricoles',
        entityId: id,
        details: 'Suppression traitement $id',
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression du traitement: $e');
    }
  }

  /// Récupérer un traitement par ID
  Future<TraitementAgricoleModel?> getTraitementById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'traitements_agricoles',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return TraitementAgricoleModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du traitement: $e');
    }
  }

  /// Récupérer tous les traitements d'un champ
  Future<List<TraitementAgricoleModel>> getTraitementsByChamp(int champId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'traitements_agricoles',
        where: 'champ_id = ?',
        whereArgs: [champId],
        orderBy: 'date_traitement DESC',
      );

      return result.map((map) => TraitementAgricoleModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des traitements: $e');
    }
  }

  /// Récupérer tous les traitements d'un adhérent (via ses champs)
  Future<List<TraitementAgricoleModel>> getTraitementsByAdherent(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.rawQuery('''
        SELECT t.*
        FROM traitements_agricoles t
        INNER JOIN champs_parcelles c ON t.champ_id = c.id
        WHERE c.adherent_id = ? AND c.is_deleted = 0
        ORDER BY t.date_traitement DESC
      ''', [adherentId]);

      return result.map((map) => TraitementAgricoleModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des traitements: $e');
    }
  }

  /// Récupérer tous les traitements avec informations du champ
  Future<List<Map<String, dynamic>>> getTraitementsWithChampInfo(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.rawQuery('''
        SELECT 
          t.*,
          c.code_champ,
          c.nom_champ,
          c.superficie
        FROM traitements_agricoles t
        INNER JOIN champs_parcelles c ON t.champ_id = c.id
        WHERE c.adherent_id = ? AND c.is_deleted = 0
        ORDER BY t.date_traitement DESC
      ''', [adherentId]);

      return result;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des traitements avec infos champ: $e');
    }
  }
}

