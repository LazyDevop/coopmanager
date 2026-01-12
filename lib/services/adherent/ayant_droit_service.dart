import '../database/db_initializer.dart';
import '../../data/models/adherent_expert/ayant_droit_model.dart';
import '../auth/audit_service.dart';

/// Service pour gérer les ayants droit des adhérents
class AyantDroitService {
  final AuditService _auditService = AuditService();

  /// Créer un ayant droit
  Future<AyantDroitModel> createAyantDroit({
    required int adherentId,
    required String nomComplet,
    required String lienFamilial,
    DateTime? dateNaissance,
    String? contact,
    String? email,
    bool beneficiaireSocial = false,
    int prioriteSuccession = 999,
    String? numeroPiece,
    String? typePiece,
    String? notes,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final ayantDroit = AyantDroitModel(
        adherentId: adherentId,
        nomComplet: nomComplet,
        lienFamilial: lienFamilial,
        dateNaissance: dateNaissance,
        contact: contact,
        email: email,
        beneficiaireSocial: beneficiaireSocial,
        prioriteSuccession: prioriteSuccession,
        numeroPiece: numeroPiece,
        typePiece: typePiece,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final id = await db.insert('ayants_droit', ayantDroit.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_AYANT_DROIT',
        entityType: 'ayants_droit',
        entityId: id,
        details: 'Création ayant droit: $nomComplet pour adhérent $adherentId',
      );

      return ayantDroit.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'ayant droit: $e');
    }
  }

  /// Mettre à jour un ayant droit
  Future<AyantDroitModel> updateAyantDroit({
    required int id,
    String? nomComplet,
    String? lienFamilial,
    DateTime? dateNaissance,
    String? contact,
    String? email,
    bool? beneficiaireSocial,
    int? prioriteSuccession,
    String? numeroPiece,
    String? typePiece,
    String? notes,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer l'ayant droit existant
      final existing = await getAyantDroitById(id);
      if (existing == null) {
        throw Exception('Ayant droit non trouvé');
      }

      final updated = existing.copyWith(
        nomComplet: nomComplet,
        lienFamilial: lienFamilial,
        dateNaissance: dateNaissance,
        contact: contact,
        email: email,
        beneficiaireSocial: beneficiaireSocial,
        prioriteSuccession: prioriteSuccession,
        numeroPiece: numeroPiece,
        typePiece: typePiece,
        notes: notes,
        updatedAt: DateTime.now(),
      );

      await db.update(
        'ayants_droit',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_AYANT_DROIT',
        entityType: 'ayants_droit',
        entityId: id,
        details: 'Modification ayant droit: ${updated.nomComplet}',
      );

      return updated;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'ayant droit: $e');
    }
  }

  /// Supprimer un ayant droit (suppression logique)
  Future<void> deleteAyantDroit(int id, int deletedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      await db.update(
        'ayants_droit',
        {
          'is_deleted': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: deletedBy,
        action: 'DELETE_AYANT_DROIT',
        entityType: 'ayants_droit',
        entityId: id,
        details: 'Suppression ayant droit $id',
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'ayant droit: $e');
    }
  }

  /// Récupérer un ayant droit par ID
  Future<AyantDroitModel?> getAyantDroitById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'ayants_droit',
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return AyantDroitModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'ayant droit: $e');
    }
  }

  /// Récupérer tous les ayants droit d'un adhérent
  Future<List<AyantDroitModel>> getAyantsDroitByAdherent(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'ayants_droit',
        where: 'adherent_id = ? AND is_deleted = 0',
        whereArgs: [adherentId],
        orderBy: 'priorite_succession ASC, nom_complet ASC',
      );

      return result.map((map) => AyantDroitModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des ayants droit: $e');
    }
  }

  /// Récupérer tous les ayants droit (pour admin)
  Future<List<AyantDroitModel>> getAllAyantsDroit() async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'ayants_droit',
        where: 'is_deleted = 0',
        orderBy: 'adherent_id ASC, priorite_succession ASC',
      );

      return result.map((map) => AyantDroitModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des ayants droit: $e');
    }
  }
}

