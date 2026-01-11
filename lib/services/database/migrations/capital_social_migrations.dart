/// Migrations de base de données pour le Module Capital Social (V18)
/// 
/// Ces migrations ajoutent :
/// - Table actionnaires (adhérents actionnaires)
/// - Table parts_sociales (valeur des parts)
/// - Table souscriptions_capital (souscriptions de parts)
/// - Table liberations_capital (libérations de capital)
/// - Table mouvements_capital (historique des mouvements)

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class CapitalSocialMigrations {
  /// Migrer vers la version 18 (Module Capital Social)
  static Future<void> migrateToV18(Database db) async {
    try {
      print('🔄 Début de la migration vers V18 (Module Capital Social)...');
      
      // 1. Créer la table parts_sociales (doit être créée en premier)
      await _createPartsSocialesTable(db);
      
      // 2. Créer la table actionnaires
      await _createActionnairesTable(db);
      
      // 3. Créer la table souscriptions_capital
      await _createSouscriptionsCapitalTable(db);
      
      // 4. Créer la table liberations_capital
      await _createLiberationsCapitalTable(db);
      
      // 5. Créer la table mouvements_capital
      await _createMouvementsCapitalTable(db);
      
      // 6. Insérer la valeur de part par défaut
      await _insertDefaultPartSociale(db);
      
      // 7. Créer les index pour performance
      await _createIndexes(db);
      
      print('✅ Migration vers V18 (Module Capital Social) réussie');
    } catch (e) {
      print('❌ Erreur lors de la migration vers V18: $e');
      rethrow;
    }
  }

  /// Créer la table parts_sociales
  static Future<void> _createPartsSocialesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parts_sociales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valeur_part REAL NOT NULL,
        devise TEXT NOT NULL DEFAULT 'FCFA',
        date_effet TEXT NOT NULL,
        active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        created_by INTEGER,
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');
    print('✅ Table parts_sociales créée');
  }

  /// Créer la table actionnaires
  static Future<void> _createActionnairesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS actionnaires (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        code_actionnaire TEXT UNIQUE NOT NULL,
        date_entree TEXT NOT NULL,
        statut TEXT NOT NULL DEFAULT 'actif',
        droits_vote INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        created_by INTEGER,
        updated_at TEXT,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');
    print('✅ Table actionnaires créée');
  }

  /// Créer la table souscriptions_capital
  static Future<void> _createSouscriptionsCapitalTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS souscriptions_capital (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actionnaire_id INTEGER NOT NULL,
        nombre_parts_souscrites INTEGER NOT NULL,
        montant_souscrit REAL NOT NULL,
        date_souscription TEXT NOT NULL,
        campagne_id INTEGER,
        statut TEXT NOT NULL DEFAULT 'en_cours',
        notes TEXT,
        certificat_pdf_path TEXT,
        qr_code_hash TEXT,
        created_at TEXT NOT NULL,
        created_by INTEGER NOT NULL,
        FOREIGN KEY (actionnaire_id) REFERENCES actionnaires(id) ON DELETE CASCADE,
        FOREIGN KEY (campagne_id) REFERENCES campagnes(id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');
    print('✅ Table souscriptions_capital créée');
  }

  /// Créer la table liberations_capital
  static Future<void> _createLiberationsCapitalTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS liberations_capital (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        souscription_id INTEGER NOT NULL,
        montant_libere REAL NOT NULL,
        mode_paiement TEXT NOT NULL,
        reference TEXT,
        date_paiement TEXT NOT NULL,
        notes TEXT,
        recu_pdf_path TEXT,
        qr_code_hash TEXT,
        ecriture_comptable_id INTEGER,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (souscription_id) REFERENCES souscriptions_capital(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id),
        FOREIGN KEY (ecriture_comptable_id) REFERENCES ecritures_comptables(id) ON DELETE SET NULL
      )
    ''');
    print('✅ Table liberations_capital créée');
  }

  /// Créer la table mouvements_capital
  static Future<void> _createMouvementsCapitalTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mouvements_capital (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actionnaire_id INTEGER NOT NULL,
        type_mouvement TEXT NOT NULL,
        nombre_parts INTEGER,
        montant REAL NOT NULL,
        date_operation TEXT NOT NULL,
        justification TEXT,
        souscription_id INTEGER,
        liberation_id INTEGER,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (actionnaire_id) REFERENCES actionnaires(id) ON DELETE CASCADE,
        FOREIGN KEY (souscription_id) REFERENCES souscriptions_capital(id) ON DELETE SET NULL,
        FOREIGN KEY (liberation_id) REFERENCES liberations_capital(id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');
    print('✅ Table mouvements_capital créée');
  }

  /// Insérer la valeur de part par défaut (5000 FCFA)
  static Future<void> _insertDefaultPartSociale(Database db) async {
    try {
      // Vérifier si une part active existe déjà
      final existing = await db.query(
        'parts_sociales',
        where: 'active = 1',
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(
          'parts_sociales',
          {
            'valeur_part': 5000.0, // Valeur par défaut : 5000 FCFA
            'devise': 'FCFA',
            'date_effet': DateTime.now().toIso8601String(),
            'active': 1,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
        print('✅ Valeur de part par défaut insérée (5000 FCFA)');
      }
    } catch (e) {
      print('⚠️ Erreur lors de l\'insertion de la part par défaut: $e');
    }
  }

  /// Créer les index pour performance
  static Future<void> _createIndexes(Database db) async {
    // Index pour actionnaires
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_actionnaires_adherent 
      ON actionnaires(adherent_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_actionnaires_code 
      ON actionnaires(code_actionnaire)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_actionnaires_statut 
      ON actionnaires(statut)
    ''');

    // Index pour souscriptions
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_souscriptions_actionnaire 
      ON souscriptions_capital(actionnaire_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_souscriptions_statut 
      ON souscriptions_capital(statut)
    ''');

    // Index pour libérations
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_liberations_souscription 
      ON liberations_capital(souscription_id)
    ''');

    // Index pour mouvements
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_mouvements_actionnaire 
      ON mouvements_capital(actionnaire_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_mouvements_type 
      ON mouvements_capital(type_mouvement)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_mouvements_date 
      ON mouvements_capital(date_operation)
    ''');

    print('✅ Index créés');
  }
}

