import 'package:sqflite_common/sqlite_api.dart';
import '../database/db_initializer.dart';
import '../../data/models/adherent_expert/champ_parcelle_model.dart';
import '../auth/audit_service.dart';

/// Service pour gérer les champs/parcelles des adhérents
class ChampParcelleService {
  final AuditService _auditService = AuditService();

  /// Générer un code unique pour un champ
  Future<String> generateCodeChamp(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer le code de l'adhérent
      final adherentResult = await db.query(
        'adherents',
        where: 'id = ?',
        whereArgs: [adherentId],
        limit: 1,
      );
      
      if (adherentResult.isEmpty) {
        throw Exception('Adhérent non trouvé');
      }
      
      final adherentCode = adherentResult.first['code'] as String;
      
      // Compter les champs existants pour cet adhérent
      final countResult = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM champs_parcelles
        WHERE adherent_id = ? AND is_deleted = 0
      ''', [adherentId]);
      
      final count = (countResult.first['count'] as int) ?? 0;
      final nextNumber = count + 1;
      
      // Format: CH-{CODE_ADHERENT}-{NUMERO}
      return 'CH-$adherentCode-${nextNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      throw Exception('Erreur lors de la génération du code champ: $e');
    }
  }

  /// Créer un champ
  Future<ChampParcelleModel> createChamp({
    required int adherentId,
    String? codeChamp,
    String? nomChamp,
    String? localisation,
    double? latitude,
    double? longitude,
    required double superficie,
    String? typeSol,
    int? anneeMiseEnCulture,
    String etatChamp = 'actif',
    double rendementEstime = 0.0,
    String? campagneAgricole,
    String? varieteCacao,
    int? nombreArbres,
    int? ageMoyenArbres,
    String? systemeIrrigation,
    String? notes,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Générer le code si non fourni
      final finalCodeChamp = codeChamp ?? await generateCodeChamp(adherentId);
      
      final champ = ChampParcelleModel(
        adherentId: adherentId,
        codeChamp: finalCodeChamp,
        nomChamp: nomChamp,
        localisation: localisation,
        latitude: latitude,
        longitude: longitude,
        superficie: superficie,
        typeSol: typeSol,
        anneeMiseEnCulture: anneeMiseEnCulture,
        etatChamp: etatChamp,
        rendementEstime: rendementEstime,
        campagneAgricole: campagneAgricole,
        varieteCacao: varieteCacao,
        nombreArbres: nombreArbres,
        ageMoyenArbres: ageMoyenArbres,
        systemeIrrigation: systemeIrrigation,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final id = await db.insert('champs_parcelles', champ.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_CHAMP',
        entityType: 'champs_parcelles',
        entityId: id,
        details: 'Création champ: $finalCodeChamp pour adhérent $adherentId',
      );

      return champ.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création du champ: $e');
    }
  }

  /// Mettre à jour un champ
  Future<ChampParcelleModel> updateChamp({
    required int id,
    String? nomChamp,
    String? localisation,
    double? latitude,
    double? longitude,
    double? superficie,
    String? typeSol,
    int? anneeMiseEnCulture,
    String? etatChamp,
    double? rendementEstime,
    String? campagneAgricole,
    String? varieteCacao,
    int? nombreArbres,
    int? ageMoyenArbres,
    String? systemeIrrigation,
    String? notes,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer le champ existant
      final existing = await getChampById(id);
      if (existing == null) {
        throw Exception('Champ non trouvé');
      }

      final updated = existing.copyWith(
        nomChamp: nomChamp,
        localisation: localisation,
        latitude: latitude,
        longitude: longitude,
        superficie: superficie,
        typeSol: typeSol,
        anneeMiseEnCulture: anneeMiseEnCulture,
        etatChamp: etatChamp,
        rendementEstime: rendementEstime,
        campagneAgricole: campagneAgricole,
        varieteCacao: varieteCacao,
        nombreArbres: nombreArbres,
        ageMoyenArbres: ageMoyenArbres,
        systemeIrrigation: systemeIrrigation,
        notes: notes,
        updatedAt: DateTime.now(),
      );

      await db.update(
        'champs_parcelles',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_CHAMP',
        entityType: 'champs_parcelles',
        entityId: id,
        details: 'Modification champ: ${updated.codeChamp}',
      );

      return updated;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du champ: $e');
    }
  }

  /// Supprimer un champ (suppression logique)
  Future<void> deleteChamp(int id, int deletedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      await db.update(
        'champs_parcelles',
        {
          'is_deleted': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: deletedBy,
        action: 'DELETE_CHAMP',
        entityType: 'champs_parcelles',
        entityId: id,
        details: 'Suppression champ $id',
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression du champ: $e');
    }
  }

  /// Récupérer un champ par ID
  Future<ChampParcelleModel?> getChampById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'champs_parcelles',
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return ChampParcelleModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du champ: $e');
    }
  }

  /// Récupérer tous les champs d'un adhérent
  Future<List<ChampParcelleModel>> getChampsByAdherent(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'champs_parcelles',
        where: 'adherent_id = ? AND is_deleted = 0',
        whereArgs: [adherentId],
        orderBy: 'code_champ ASC',
      );

      return result.map((map) => ChampParcelleModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des champs: $e');
    }
  }

  /// Calculer les statistiques des champs pour un adhérent
  Future<Map<String, dynamic>> getChampsStats(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as nombre_champs,
          COALESCE(SUM(superficie), 0) as superficie_totale,
          COALESCE(AVG(rendement_estime), 0) as rendement_moyen
        FROM champs_parcelles
        WHERE adherent_id = ? AND is_deleted = 0
      ''', [adherentId]);

      if (result.isEmpty) {
        return {
          'nombreChamps': 0,
          'superficieTotale': 0.0,
          'rendementMoyen': 0.0,
        };
      }

      return {
        'nombreChamps': result.first['nombre_champs'] as int? ?? 0,
        'superficieTotale': (result.first['superficie_totale'] as num?)?.toDouble() ?? 0.0,
        'rendementMoyen': (result.first['rendement_moyen'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }
}

