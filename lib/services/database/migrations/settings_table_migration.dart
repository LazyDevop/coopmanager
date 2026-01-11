/// Migration pour la table settings complète
/// Version 21 - Table settings avec tous les champs requis

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

class SettingsTableMigration {
  /// Créer la table settings complète avec tous les champs requis
  static Future<void> createSettingsTable(Database db) async {
    try {
      // Vérifier si la table cooperatives existe, sinon la créer d'abord
      final coopTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='cooperatives'"
      );
      
      if (coopTables.isEmpty) {
        print('Table cooperatives n\'existe pas, création...');
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
        
        // Créer une coopérative par défaut
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
      }
      
      // Vérifier si la table settings existe déjà
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'"
      );
      
      if (tables.isNotEmpty) {
        print('Table settings existe déjà, vérification des colonnes...');
        await _ensureAllColumns(db);
        return;
      }
      
      print('Création de la table settings...');
      
      // Créer la table settings avec tous les champs requis
      // Note: On utilise IF NOT EXISTS pour éviter les erreurs si la table existe déjà
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
      
      // Créer les index pour optimiser les performances
      await db.execute('CREATE INDEX idx_settings_cooperative ON settings(cooperative_id)');
      await db.execute('CREATE INDEX idx_settings_category ON settings(category)');
      await db.execute('CREATE INDEX idx_settings_key ON settings(key)');
      await db.execute('CREATE INDEX idx_settings_active ON settings(is_active)');
      await db.execute('CREATE INDEX idx_settings_category_active ON settings(category, is_active)');
      
      print('✅ Table settings créée avec succès');
    } catch (e) {
      print('❌ Erreur lors de la création de la table settings: $e');
      rethrow;
    }
  }
  
  /// Vérifier et ajouter les colonnes manquantes
  static Future<void> _ensureAllColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(settings)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      // Vérifier le type de la colonne id
      final idColumn = columns.firstWhere(
        (c) => c['name'] == 'id',
        orElse: () => {},
      );
      
      if (idColumn.isNotEmpty) {
        final idType = idColumn['type'] as String?;
        if (idType != null && idType.toUpperCase().contains('INTEGER')) {
          // La colonne id est INTEGER, il faut la convertir en TEXT
          print('⚠️ La colonne id est INTEGER, migration vers TEXT nécessaire...');
          await _migrateIdColumnToText(db);
        }
      }
      
      final requiredColumns = {
        'description': 'ALTER TABLE settings ADD COLUMN description TEXT',
        'is_active': 'ALTER TABLE settings ADD COLUMN is_active INTEGER DEFAULT 1',
        'value_type': 'ALTER TABLE settings ADD COLUMN value_type TEXT DEFAULT \'string\'',
        'editable': 'ALTER TABLE settings ADD COLUMN editable INTEGER DEFAULT 1',
      };
      
      for (final entry in requiredColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à settings');
            
            // Mettre à jour les valeurs par défaut si nécessaire
            if (entry.key == 'is_active') {
              await db.execute('UPDATE settings SET is_active = 1 WHERE is_active IS NULL');
            } else if (entry.key == 'editable') {
              await db.execute('UPDATE settings SET editable = 1 WHERE editable IS NULL');
            }
          } catch (e) {
            if (!e.toString().contains('duplicate column') && 
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
      
      // Vérifier et créer les index manquants
      await _ensureIndexes(db);
    } catch (e) {
      print('⚠️ Erreur lors de la vérification des colonnes: $e');
    }
  }
  
  /// Migrer la colonne id de INTEGER vers TEXT
  static Future<void> _migrateIdColumnToText(Database db) async {
    try {
      print('🔄 Migration de la colonne id vers TEXT...');
      
      // SQLite ne supporte pas ALTER COLUMN, il faut recréer la table
      await db.execute('BEGIN TRANSACTION');
      
      try {
        // Créer une table temporaire avec le bon schéma
        await db.execute('''
          CREATE TABLE settings_new (
            id TEXT PRIMARY KEY,
            cooperative_id TEXT,
            category TEXT NOT NULL,
            "key" TEXT NOT NULL,
            value TEXT,
            value_type TEXT DEFAULT 'string',
            description TEXT,
            is_active INTEGER DEFAULT 1,
            editable INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id) ON DELETE CASCADE,
            UNIQUE (cooperative_id, category, "key")
          )
        ''');
        
        // Copier les données en convertissant les IDs INTEGER en TEXT (UUID)
        final oldSettings = await db.query('settings');
        for (final setting in oldSettings) {
          final oldId = setting['id'];
          String newId;
          
          // Si l'ID est un entier, générer un UUID
          if (oldId is int) {
            newId = const Uuid().v4();
          } else {
            newId = oldId.toString();
          }
          
          await db.insert('settings_new', {
            'id': newId,
            'cooperative_id': setting['cooperative_id'],
            'category': setting['category'],
            'key': setting['key'],
            'value': setting['value'],
            'value_type': setting['value_type'] ?? 'string',
            'description': setting['description'],
            'is_active': setting['is_active'] ?? 1,
            'editable': setting['editable'] ?? 1,
            'created_at': setting['created_at'],
            'updated_at': setting['updated_at'],
          });
        }
        
        // Supprimer l'ancienne table et renommer la nouvelle
        await db.execute('DROP TABLE settings');
        await db.execute('ALTER TABLE settings_new RENAME TO settings');
        
        // Recréer les index
        await db.execute('CREATE INDEX idx_settings_cooperative ON settings(cooperative_id)');
        await db.execute('CREATE INDEX idx_settings_category ON settings(category)');
        await db.execute('CREATE INDEX idx_settings_key ON settings(key)');
        await db.execute('CREATE INDEX idx_settings_active ON settings(is_active)');
        await db.execute('CREATE INDEX idx_settings_category_active ON settings(category, is_active)');
        
        await db.execute('COMMIT');
        print('✅ Migration de la colonne id vers TEXT terminée avec succès');
      } catch (e) {
        await db.execute('ROLLBACK');
        rethrow;
      }
    } catch (e) {
      print('❌ Erreur lors de la migration de la colonne id: $e');
      // Ne pas faire échouer l'application, mais loguer l'erreur
    }
  }
  
  /// Vérifier et créer les index manquants
  static Future<void> _ensureIndexes(Database db) async {
    try {
      final indexes = [
        'CREATE INDEX IF NOT EXISTS idx_settings_cooperative ON settings(cooperative_id)',
        'CREATE INDEX IF NOT EXISTS idx_settings_category ON settings(category)',
        'CREATE INDEX IF NOT EXISTS idx_settings_key ON settings(key)',
        'CREATE INDEX IF NOT EXISTS idx_settings_active ON settings(is_active)',
        'CREATE INDEX IF NOT EXISTS idx_settings_category_active ON settings(category, is_active)',
      ];
      
      for (final indexSql in indexes) {
        try {
          await db.execute(indexSql);
        } catch (e) {
          print('⚠️ Erreur lors de la création de l\'index: $e');
        }
      }
    } catch (e) {
      print('⚠️ Erreur lors de la vérification des index: $e');
    }
  }
  
  /// Migrer vers la version 21 - Table settings complète
  static Future<void> migrateToV21(Database db) async {
    try {
      print('🔄 Migration vers la version 21 (Table settings complète)...');
      
      // Créer la table settings si elle n'existe pas
      await createSettingsTable(db);
      
      // Créer la table setting_history si elle n'existe pas
      await _createSettingHistoryTable(db);
      
      print('✅ Migration vers la version 21 terminée avec succès');
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la migration vers la version 21: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Créer la table setting_history pour l'historique des modifications
  static Future<void> _createSettingHistoryTable(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='setting_history'"
      );
      
      if (tables.isNotEmpty) {
        return; // Table existe déjà
      }
      
      await db.execute('''
        CREATE TABLE setting_history (
          id TEXT PRIMARY KEY,
          setting_id TEXT NOT NULL,
          cooperative_id TEXT,
          category TEXT NOT NULL,
          key TEXT NOT NULL,
          old_value TEXT,
          new_value TEXT,
          changed_by TEXT,
          change_reason TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (setting_id) REFERENCES settings(id) ON DELETE CASCADE,
          FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id) ON DELETE CASCADE
        )
      ''');
      
      // Créer les index
      await db.execute('CREATE INDEX idx_setting_history_setting ON setting_history(setting_id)');
      await db.execute('CREATE INDEX idx_setting_history_coop ON setting_history(cooperative_id)');
      await db.execute('CREATE INDEX idx_setting_history_created ON setting_history(created_at)');
      await db.execute('CREATE INDEX idx_setting_history_category ON setting_history(category)');
      
      print('✅ Table setting_history créée avec succès');
    } catch (e) {
      print('⚠️ Erreur lors de la création de setting_history: $e');
    }
  }
}

