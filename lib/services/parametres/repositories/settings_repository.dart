import '../../../data/models/backend/setting_model.dart';
import '../../database/db_initializer.dart';

abstract class ISettingsRepository {
  /// Récupérer un setting par ID
  Future<SettingModel?> getById(String id);
  
  /// Récupérer un setting par cooperative_id, category et key
  Future<SettingModel?> getByKey(String? cooperativeId, String category, String key);
  
  /// Récupérer tous les settings d'une catégorie
  Future<List<SettingModel>> getByCategory(String? cooperativeId, String category, {bool onlyActive = true});
  
  /// Récupérer tous les settings d'une coopérative
  Future<List<SettingModel>> getByCooperative(String cooperativeId, {bool onlyActive = true});
  
  /// Créer un nouveau setting
  Future<SettingModel> create(SettingModel setting);
  
  /// Mettre à jour un setting
  Future<SettingModel> update(SettingModel setting);
  
  /// Activer/Désactiver un setting
  Future<bool> setActive(String id, bool isActive);
  
  /// Supprimer un setting
  Future<bool> delete(String id);
  
  /// Vérifier si la table existe
  Future<bool> tableExists();
}

class SettingsRepository implements ISettingsRepository {
  /// Vérifier si la table settings existe
  @override
  Future<bool> tableExists() async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'"
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification de la table settings: $e');
      return false;
    }
  }
  
  @override
  Future<SettingModel?> getById(String id) async {
    try {
      if (!await tableExists()) {
        throw Exception('Table settings n\'existe pas');
      }
      
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'settings',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      return SettingModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du setting: $e');
    }
  }
  
  @override
  Future<SettingModel?> getByKey(String? cooperativeId, String category, String key) async {
    try {
      if (!await tableExists()) {
        throw Exception('Table settings n\'existe pas');
      }
      
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'settings',
        where: 'cooperative_id = ? AND category = ? AND key = ?',
        whereArgs: [cooperativeId, category, key],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      return SettingModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du setting: $e');
    }
  }
  
  @override
  Future<List<SettingModel>> getByCategory(
    String? cooperativeId,
    String category, {
    bool onlyActive = true,
  }) async {
    try {
      if (!await tableExists()) {
        throw Exception('Table settings n\'existe pas');
      }
      
      final db = await DatabaseInitializer.database;
      final where = onlyActive
          ? 'cooperative_id = ? AND category = ? AND is_active = 1'
          : 'cooperative_id = ? AND category = ?';
      final whereArgs = [cooperativeId, category];
      
      final result = await db.query(
        'settings',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'key ASC',
      );
      
      return result.map((map) => SettingModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des settings par catégorie: $e');
    }
  }
  
  @override
  Future<List<SettingModel>> getByCooperative(
    String cooperativeId, {
    bool onlyActive = true,
  }) async {
    try {
      if (!await tableExists()) {
        throw Exception('Table settings n\'existe pas');
      }
      
      final db = await DatabaseInitializer.database;
      final where = onlyActive
          ? 'cooperative_id = ? AND is_active = 1'
          : 'cooperative_id = ?';
      
      final result = await db.query(
        'settings',
        where: where,
        whereArgs: [cooperativeId],
        orderBy: 'category ASC, key ASC',
      );
      
      return result.map((map) => SettingModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des settings par coopérative: $e');
    }
  }
  
  @override
  Future<SettingModel> create(SettingModel setting) async {
    try {
      if (!await tableExists()) {
        throw Exception('Table settings n\'existe pas');
      }
      
      final db = await DatabaseInitializer.database;
      await db.insert('settings', setting.toMap());
      return setting;
    } catch (e) {
      throw Exception('Erreur lors de la création du setting: $e');
    }
  }
  
  @override
  Future<SettingModel> update(SettingModel setting) async {
    try {
      if (!await tableExists()) {
        throw Exception('Table settings n\'existe pas');
      }
      
      final db = await DatabaseInitializer.database;
      final updated = setting.copyWith(updatedAt: DateTime.now());
      await db.update(
        'settings',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [setting.id],
      );
      return updated;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du setting: $e');
    }
  }
  
  @override
  Future<bool> setActive(String id, bool isActive) async {
    try {
      if (!await tableExists()) {
        throw Exception('Table settings n\'existe pas');
      }
      
      final db = await DatabaseInitializer.database;
      final count = await db.update(
        'settings',
        {
          'is_active': isActive ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      throw Exception('Erreur lors de l\'activation/désactivation du setting: $e');
    }
  }
  
  @override
  Future<bool> delete(String id) async {
    try {
      if (!await tableExists()) {
        throw Exception('Table settings n\'existe pas');
      }
      
      final db = await DatabaseInitializer.database;
      final count = await db.delete(
        'settings',
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      throw Exception('Erreur lors de la suppression du setting: $e');
    }
  }
}

