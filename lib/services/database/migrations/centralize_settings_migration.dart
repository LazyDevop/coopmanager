/// Migration pour centraliser tous les paramètres dans la table settings
/// Cette migration migre toutes les données de coop_settings vers settings
/// et s'assure que tous les paramètres sont accessibles depuis une seule table

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

class CentralizeSettingsMigration {
  /// Migrer toutes les données de coop_settings vers settings
  static Future<void> migrateCoopSettingsToSettings(Database db) async {
    try {
      print('🔄 Migration des paramètres coop_settings vers settings...');
      
      // Vérifier si la table coop_settings existe
      final coopSettingsTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='coop_settings'"
      );
      
      if (coopSettingsTables.isEmpty) {
        print('ℹ️ Table coop_settings n\'existe pas, aucune migration nécessaire');
        return;
      }
      
      // Vérifier si la table settings existe
      final settingsTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'"
      );
      
      if (settingsTables.isEmpty) {
        print('⚠️ Table settings n\'existe pas, création...');
        await _createSettingsTable(db);
      }
      
      // Récupérer la coopérative active
      String? cooperativeId;
      final cooperatives = await db.query('cooperatives', limit: 1);
      if (cooperatives.isNotEmpty) {
        cooperativeId = cooperatives.first['id'] as String?;
      }
      
      // Si aucune coopérative n'existe, créer une par défaut
      if (cooperativeId == null) {
        cooperativeId = 'coop-default-${DateTime.now().millisecondsSinceEpoch}';
        await db.insert('cooperatives', {
          'id': cooperativeId,
          'raison_sociale': 'Coopérative de Cacaoculteurs',
          'devise': 'XAF',
          'langue': 'FR',
          'statut': 'ACTIVE',
          'created_at': DateTime.now().toIso8601String(),
        });
        print('✅ Coopérative par défaut créée: $cooperativeId');
      }
      
      // Récupérer les données de coop_settings
      final coopSettings = await db.query('coop_settings', limit: 1);
      
      if (coopSettings.isEmpty) {
        print('ℹ️ Aucune donnée dans coop_settings, aucune migration nécessaire');
        return;
      }
      
      final settings = coopSettings.first;
      final uuid = const Uuid();
      
      // Mapper les champs de coop_settings vers settings (category: cooperative)
      final cooperativeMappings = {
        'raison_sociale': settings['nom_cooperative'],
        'logo_path': settings['logo_path'],
        'adresse': settings['adresse'],
        'telephone': settings['telephone'],
        'email': settings['email'],
        'sigle': null,
        'forme_juridique': null,
        'numero_agrement': null,
        'rccm': null,
        'date_creation': null,
        'region': null,
        'departement': null,
      };
      
      // Insérer les paramètres coopératifs
      for (final entry in cooperativeMappings.entries) {
        if (entry.value != null) {
          await _insertOrUpdateSetting(
            db,
            uuid: uuid,
            cooperativeId: cooperativeId,
            category: 'cooperative',
            key: entry.key,
            value: entry.value.toString(),
            valueType: 'string',
          );
        }
      }
      
      // Mapper les paramètres généraux
      final generalMappings = {
        'commission_rate': settings['commission_rate'],
        'periode_campagne_days': settings['periode_campagne_days'],
      };
      
      for (final entry in generalMappings.entries) {
        if (entry.value != null) {
          await _insertOrUpdateSetting(
            db,
            uuid: uuid,
            cooperativeId: cooperativeId,
            category: 'general',
            key: entry.key,
            value: entry.value.toString(),
            valueType: entry.key.contains('rate') ? 'double' : 'int',
          );
        }
      }
      
      // Mapper les dates de campagne
      if (settings['date_debut_campagne'] != null) {
        await _insertOrUpdateSetting(
          db,
          uuid: uuid,
          cooperativeId: cooperativeId,
          category: 'general',
          key: 'date_debut_campagne',
          value: settings['date_debut_campagne'].toString(),
          valueType: 'datetime',
        );
      }
      
      if (settings['date_fin_campagne'] != null) {
        await _insertOrUpdateSetting(
          db,
          uuid: uuid,
          cooperativeId: cooperativeId,
          category: 'general',
          key: 'date_fin_campagne',
          value: settings['date_fin_campagne'].toString(),
          valueType: 'datetime',
        );
      }
      
      print('✅ Migration des paramètres coop_settings vers settings terminée');
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la migration: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Insérer ou mettre à jour un paramètre dans settings
  static Future<void> _insertOrUpdateSetting(
    Database db, {
    required Uuid uuid,
    required String? cooperativeId,
    required String category,
    required String key,
    required String value,
    required String valueType,
  }) async {
    try {
      // Vérifier si le paramètre existe déjà
      final existing = await db.query(
        'settings',
        where: 'cooperative_id = ? AND category = ? AND key = ?',
        whereArgs: [cooperativeId, category, key],
        limit: 1,
      );
      
      if (existing.isNotEmpty) {
        // Mettre à jour
        await db.update(
          'settings',
          {
            'value': value,
            'value_type': valueType,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'cooperative_id = ? AND category = ? AND key = ?',
          whereArgs: [cooperativeId, category, key],
        );
      } else {
        // Insérer
        await db.insert('settings', {
          'id': uuid.v4(),
          'cooperative_id': cooperativeId,
          'category': category,
          'key': key,
          'value': value,
          'value_type': valueType,
          'is_active': 1,
          'editable': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('⚠️ Erreur lors de l\'insertion/mise à jour du paramètre $category.$key: $e');
    }
  }
  
  /// Créer la table settings si elle n'existe pas
  static Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id TEXT PRIMARY KEY,
        cooperative_id TEXT,
        category TEXT NOT NULL,
        key TEXT NOT NULL,
        value TEXT,
        value_type TEXT DEFAULT 'string',
        description TEXT,
        is_active INTEGER DEFAULT 1,
        editable INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id) ON DELETE CASCADE,
        UNIQUE (cooperative_id, category, key)
      )
    ''');
    
    // Créer les index
    await db.execute('CREATE INDEX IF NOT EXISTS idx_settings_cooperative ON settings(cooperative_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_settings_category ON settings(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_settings_key ON settings(key)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_settings_active ON settings(is_active)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_settings_category_active ON settings(category, is_active)');
  }
  
  /// Migrer vers la version centralisée
  static Future<void> migrateToCentralized(Database db) async {
    try {
      print('🔄 Migration vers le système centralisé de paramètres...');
      
      // S'assurer que la table settings existe
      await _createSettingsTable(db);
      
      // Migrer les données de coop_settings
      await migrateCoopSettingsToSettings(db);
      
      print('✅ Migration vers le système centralisé terminée avec succès');
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la migration centralisée: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

