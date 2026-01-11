/// Repository pour la gestion des settings (Clean Architecture)
import '../../../data/models/backend/setting_model.dart';
import '../../database/db_initializer.dart';

abstract class ISettingRepository {
  Future<SettingModel?> getById(String id);
  Future<SettingModel?> getByKey(String? cooperativeId, String category, String key);
  Future<List<SettingModel>> getByCategory(String? cooperativeId, String category);
  Future<List<SettingModel>> getAll(String? cooperativeId);
  Future<SettingModel> create(SettingModel setting);
  Future<SettingModel> update(SettingModel setting);
  Future<bool> delete(String id);
  Future<bool> deleteByKey(String? cooperativeId, String category, String key);
  Future<void> logHistory(String settingId, String? cooperativeId, String? oldValue, String? newValue, String? changedBy, String? reason);
}

class SettingRepository implements ISettingRepository {
  /// Vérifier si la table settings existe
  Future<bool> _tableExists() async {
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
      if (!await _tableExists()) {
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
      if (!await _tableExists()) {
        throw Exception('Table settings n\'existe pas');
      }
      
      final db = await DatabaseInitializer.database;
      String where;
      List<dynamic> whereArgs;
      
      if (cooperativeId != null) {
        where = 'cooperative_id = ? AND category = ? AND key = ? AND is_active = 1';
        whereArgs = [cooperativeId, category, key];
      } else {
        where = 'cooperative_id IS NULL AND category = ? AND key = ? AND is_active = 1';
        whereArgs = [category, key];
      }
      
      final result = await db.query(
        'settings',
        where: where,
        whereArgs: whereArgs,
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      return SettingModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du setting: $e');
    }
  }

  @override
  Future<List<SettingModel>> getByCategory(String? cooperativeId, String category) async {
    try {
      if (!await _tableExists()) {
        throw Exception('Table settings n\'existe pas');
      }
      
      final db = await DatabaseInitializer.database;
      String? where;
      List<dynamic>? whereArgs;
      
      if (cooperativeId != null) {
        where = 'cooperative_id = ? AND category = ? AND is_active = 1';
        whereArgs = [cooperativeId, category];
      } else {
        where = 'cooperative_id IS NULL AND category = ? AND is_active = 1';
        whereArgs = [category];
      }
      
      final result = await db.query(
        'settings',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'key',
      );
      
      return result.map((map) => SettingModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des settings: $e');
    }
  }

  @override
  Future<List<SettingModel>> getAll(String? cooperativeId) async {
    try {
      final db = await DatabaseInitializer.database;
      String? where;
      List<dynamic>? whereArgs;
      
      if (cooperativeId != null) {
        where = 'cooperative_id = ?';
        whereArgs = [cooperativeId];
      } else {
        where = 'cooperative_id IS NULL';
      }
      
      final result = await db.query(
        'settings',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'category, key',
      );
      
      return result.map((map) => SettingModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des settings: $e');
    }
  }

  @override
  Future<SettingModel> create(SettingModel setting) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Vérifier l'unicité
      final existing = await getByKey(setting.cooperativeId, setting.category, setting.key);
      if (existing != null) {
        throw Exception('Un setting avec cette clé existe déjà pour cette coopérative');
      }
      
      await db.insert('settings', setting.toMap());
      return (await getById(setting.id))!;
    } catch (e) {
      throw Exception('Erreur lors de la création du setting: $e');
    }
  }

  @override
  Future<SettingModel> update(SettingModel setting) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final existing = await getById(setting.id);
      if (existing == null) {
        throw Exception('Setting introuvable');
      }
      
      if (!existing.editable) {
        throw Exception('Ce paramètre n\'est pas modifiable');
      }
      
      // Logger l'historique
      await logHistory(
        setting.id,
        setting.cooperativeId,
        existing.value,
        setting.value,
        null, // changedBy sera ajouté par le service
        null,
      );
      
      await db.update(
        'settings',
        setting.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [setting.id],
      );
      
      return (await getById(setting.id))!;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du setting: $e');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final setting = await getById(id);
      if (setting == null) return false;
      
      if (!setting.editable) {
        throw Exception('Ce paramètre ne peut pas être supprimé');
      }
      
      await db.delete('settings', where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression du setting: $e');
    }
  }

  @override
  Future<bool> deleteByKey(String? cooperativeId, String category, String key) async {
    try {
      final setting = await getByKey(cooperativeId, category, key);
      if (setting == null) return false;
      return await delete(setting.id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du setting: $e');
    }
  }

  @override
  Future<void> logHistory(
    String settingId,
    String? cooperativeId,
    String? oldValue,
    String? newValue,
    String? changedBy,
    String? reason,
  ) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.insert('setting_history', {
        'id': 'hist-${DateTime.now().millisecondsSinceEpoch}',
        'setting_id': settingId,
        'cooperative_id': cooperativeId,
        'old_value': oldValue,
        'new_value': newValue,
        'changed_by': changedBy,
        'change_reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ne pas faire échouer l'opération principale si l'historique échoue
      print('Erreur lors de l\'enregistrement de l\'historique: $e');
    }
  }
}

