/// Migration pour le module de paramétrage backend (multi-coopérative)
/// Version 20 - Architecture backend API REST

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ParametrageBackendMigrations {
  /// Migrer vers la version 20 - Architecture backend multi-coopérative
  static Future<void> migrateToV20(Database db) async {
    try {
      print('Exécution de la migration vers la version 20 (Backend Multi-Coopérative)...');

      // 1. Table cooperatives (multi-coopérative)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cooperatives (
          id TEXT PRIMARY KEY,
          raison_sociale TEXT NOT NULL,
          sigle TEXT,
          forme_juridique TEXT,
          numero_agrement TEXT,
          rccm TEXT,
          date_creation TEXT,
          telephone TEXT,
          email TEXT,
          adresse TEXT,
          region TEXT,
          departement TEXT,
          devise TEXT DEFAULT 'XAF',
          langue TEXT DEFAULT 'FR',
          logo TEXT,
          statut TEXT DEFAULT 'ACTIVE',
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 2. Table settings (générique avec support multi-coopérative)
      // Vérifier si la table settings existe déjà (créée en version 19)
      final settingsTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'"
      );
      
      if (settingsTables.isEmpty) {
        // Créer la table settings si elle n'existe pas
        await db.execute('''
          CREATE TABLE settings (
            id TEXT PRIMARY KEY,
            cooperative_id TEXT,
            category TEXT NOT NULL,
            key TEXT NOT NULL,
            value TEXT,
            value_type TEXT DEFAULT 'string',
            editable INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id) ON DELETE CASCADE,
            UNIQUE (cooperative_id, category, key)
          )
        ''');
      } else {
        // La table existe déjà, ajouter les colonnes manquantes
        final columns = await db.rawQuery('PRAGMA table_info(settings)');
        final columnNames = columns.map((c) => c['name'] as String).toList();
        
        // Ajouter cooperative_id si elle n'existe pas
        if (!columnNames.contains('cooperative_id')) {
          await db.execute('ALTER TABLE settings ADD COLUMN cooperative_id TEXT');
        }
        
        // Ajouter value_type si elle n'existe pas
        if (!columnNames.contains('value_type')) {
          await db.execute('ALTER TABLE settings ADD COLUMN value_type TEXT DEFAULT \'string\'');
        }
        
        // Ajouter editable si elle n'existe pas
        if (!columnNames.contains('editable')) {
          await db.execute('ALTER TABLE settings ADD COLUMN editable INTEGER DEFAULT 1');
        }
        
        // Ajouter description si elle n'existe pas
        if (!columnNames.contains('description')) {
          await db.execute('ALTER TABLE settings ADD COLUMN description TEXT');
        }
        
        // Ajouter is_active si elle n'existe pas
        if (!columnNames.contains('is_active')) {
          await db.execute('ALTER TABLE settings ADD COLUMN is_active INTEGER DEFAULT 1');
        }
        
        // Supprimer l'ancienne contrainte UNIQUE si elle existe (sans cooperative_id)
        try {
          await db.execute('DROP INDEX IF EXISTS idx_settings_unique');
        } catch (e) {
          // Ignorer si l'index n'existe pas
        }
        
        // Recréer la contrainte UNIQUE avec cooperative_id
        try {
          await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_settings_unique ON settings(cooperative_id, category, key)');
        } catch (e) {
          // La contrainte peut déjà exister, ignorer
        }
      }

      // 3. Table capital_settings (paramétrage capital social)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS capital_settings (
          id TEXT PRIMARY KEY,
          cooperative_id TEXT NOT NULL,
          valeur_part REAL NOT NULL,
          parts_min INTEGER NOT NULL,
          parts_max INTEGER,
          liberation_obligatoire INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id) ON DELETE CASCADE,
          UNIQUE (cooperative_id)
        )
      ''');

      // 4. Table accounting_settings (paramétrage comptabilité)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS accounting_settings (
          id TEXT PRIMARY KEY,
          cooperative_id TEXT NOT NULL,
          exercice_actif INTEGER NOT NULL,
          plan_comptable TEXT NOT NULL DEFAULT 'SYSCOHADA',
          taux_reserve REAL DEFAULT 0,
          taux_frais_gestion REAL DEFAULT 0,
          compte_caisse TEXT,
          compte_banque TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id) ON DELETE CASCADE,
          UNIQUE (cooperative_id)
        )
      ''');

      // 5. Table document_settings (paramétrage documents)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS document_settings (
          id TEXT PRIMARY KEY,
          cooperative_id TEXT NOT NULL,
          type_document TEXT NOT NULL,
          prefix TEXT NOT NULL,
          format_numero TEXT NOT NULL,
          pied_page TEXT,
          signature_auto INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id) ON DELETE CASCADE,
          UNIQUE (cooperative_id, type_document)
        )
      ''');

      // 6. Table setting_history (historique pour IA et audit)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS setting_history (
          id TEXT PRIMARY KEY,
          setting_id TEXT NOT NULL,
          cooperative_id TEXT,
          old_value TEXT,
          new_value TEXT,
          changed_by TEXT,
          change_reason TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (setting_id) REFERENCES settings(id) ON DELETE CASCADE,
          FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id) ON DELETE CASCADE
        )
      ''');

      // Créer les index pour optimiser les performances
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cooperatives_statut ON cooperatives(statut)');
      
      // Vérifier que la colonne cooperative_id existe avant de créer l'index
      try {
        final settingsColumns = await db.rawQuery('PRAGMA table_info(settings)');
        final settingsColumnNames = settingsColumns.map((c) => c['name'] as String).toList();
        
        if (settingsColumnNames.contains('cooperative_id')) {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_settings_cooperative ON settings(cooperative_id)');
        }
        
        await db.execute('CREATE INDEX IF NOT EXISTS idx_settings_category ON settings(category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_settings_key ON settings(key)');
        
        if (settingsColumnNames.contains('is_active')) {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_settings_active ON settings(is_active)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_settings_category_active ON settings(category, is_active)');
        }
      } catch (e) {
        print('⚠️ Erreur lors de la création des index settings: $e');
        // Continuer même si les index échouent
      }
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_capital_settings_coop ON capital_settings(cooperative_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_accounting_settings_coop ON accounting_settings(cooperative_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_document_settings_coop ON document_settings(cooperative_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_setting_history_setting ON setting_history(setting_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_setting_history_coop ON setting_history(cooperative_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_setting_history_created ON setting_history(created_at)');

      // Migrer les données existantes de cooperative_entity vers cooperatives
      await _migrateExistingCooperativeData(db);

      // Créer la coopérative par défaut si aucune n'existe
      await _createDefaultCooperative(db);

      // Migrer les paramètres existants vers la table settings
      await _migrateExistingSettings(db);

      print('Migration vers la version 20 terminée avec succès');
    } catch (e, stackTrace) {
      print('Erreur lors de la migration vers la version 20: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Migrer les données existantes de cooperative_entity vers cooperatives
  static Future<void> _migrateExistingCooperativeData(Database db) async {
    try {
      // Vérifier si cooperatives contient déjà des données
      final existing = await db.query('cooperatives', limit: 1);
      if (existing.isNotEmpty) {
        print('cooperatives contient déjà des données, migration ignorée');
        return;
      }

      // Vérifier si cooperative_entity existe
      try {
        final coopEntity = await db.query('cooperative_entity', limit: 1);
        if (coopEntity.isEmpty) {
          return;
        }

        final entity = coopEntity.first;
        final coopId = 'coop-${DateTime.now().millisecondsSinceEpoch}';

        await db.insert('cooperatives', {
          'id': coopId,
          'raison_sociale': entity['raison_sociale'] ?? 'Coopérative de Cacaoculteurs',
          'sigle': entity['sigle'],
          'forme_juridique': entity['forme_juridique'] ?? 'scoops',
          'numero_agrement': entity['numero_agrement'],
          'rccm': entity['registre_commerce'],
          'date_creation': entity['date_creation'],
          'telephone': entity['telephone'],
          'email': entity['email'],
          'adresse': entity['adresse'],
          'region': entity['region'],
          'departement': entity['departement'],
          'devise': entity['devise_principale'] ?? 'XAF',
          'langue': entity['langue_par_defaut'] ?? 'FR',
          'logo': entity['logo_path'],
          'statut': 'ACTIVE',
          'created_at': DateTime.now().toIso8601String(),
        });

        print('Migration des données cooperative_entity vers cooperatives réussie');
      } catch (e) {
        // Table n'existe pas encore, ignorer
        print('Table cooperative_entity n\'existe pas: $e');
      }
    } catch (e) {
      print('Erreur lors de la migration des données coopérative: $e');
    }
  }

  /// Créer la coopérative par défaut
  static Future<void> _createDefaultCooperative(Database db) async {
    try {
      final existing = await db.query('cooperatives', limit: 1);
      if (existing.isNotEmpty) return;

      final coopId = 'coop-default-${DateTime.now().millisecondsSinceEpoch}';
      await db.insert('cooperatives', {
        'id': coopId,
        'raison_sociale': 'Coopérative de Cacaoculteurs',
        'devise': 'XAF',
        'langue': 'FR',
        'statut': 'ACTIVE',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('Coopérative par défaut créée: $coopId');
    } catch (e) {
      print('Erreur lors de la création de la coopérative par défaut: $e');
    }
  }

  /// Migrer les paramètres existants vers la table settings
  static Future<void> _migrateExistingSettings(Database db) async {
    try {
      // Récupérer la coopérative par défaut
      final cooperatives = await db.query('cooperatives', limit: 1);
      if (cooperatives.isEmpty) return;

      final coopId = cooperatives.first['id'] as String;

      // Migrer les paramètres de coop_settings vers settings
      try {
        final coopSettings = await db.query('coop_settings', limit: 1);
        if (coopSettings.isNotEmpty) {
          final settings = coopSettings.first;
          
          // Commission rate
          await _insertSettingIfNotExists(db, coopId, 'finance', 'commission_rate', 
            settings['commission_rate']?.toString() ?? '0.05', 'double');
          
          // Période campagne
          await _insertSettingIfNotExists(db, coopId, 'campagne', 'periode_days', 
            settings['periode_campagne_days']?.toString() ?? '365', 'int');
        }
      } catch (e) {
        print('Erreur migration coop_settings: $e');
      }

      // Migrer les paramètres de parametres_comptables
      try {
        final accounting = await db.query('parametres_comptables', limit: 1);
        if (accounting.isNotEmpty) {
          final acc = accounting.first;
          await _insertSettingIfNotExists(db, coopId, 'accounting', 'plan_comptable', 
            acc['plan_comptable']?.toString() ?? 'SYSCOHADA', 'string');
          await _insertSettingIfNotExists(db, coopId, 'accounting', 'exercice_actif', 
            acc['exercice_actif']?.toString() ?? DateTime.now().year.toString(), 'int');
        }
      } catch (e) {
        print('Erreur migration parametres_comptables: $e');
      }

      print('Migration des paramètres existants terminée');
    } catch (e) {
      print('Erreur lors de la migration des paramètres: $e');
    }
  }

  /// Insérer un setting s'il n'existe pas déjà
  static Future<void> _insertSettingIfNotExists(
    Database db,
    String cooperativeId,
    String category,
    String key,
    String value,
    String valueType,
  ) async {
    try {
      final existing = await db.query(
        'settings',
        where: 'cooperative_id = ? AND category = ? AND key = ?',
        whereArgs: [cooperativeId, category, key],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert('settings', {
          'id': 'setting-${DateTime.now().millisecondsSinceEpoch}-${category}-$key',
          'cooperative_id': cooperativeId,
          'category': category,
          'key': key,
          'value': value,
          'value_type': valueType,
          'editable': 1,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Erreur insertion setting $category.$key: $e');
    }
  }
}

