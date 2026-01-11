/// Migrations pour le module de paramétrage complet
/// Version 19 - Module de paramétrage transversal

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ParametrageCompletMigrations {
  /// Migrer vers la version 19 - Module de paramétrage complet
  static Future<void> migrateToV19(Database db) async {
    try {
      // 1. Table cooperative_entity (remplace/étend coop_settings)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cooperative_entity (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          raison_sociale TEXT NOT NULL,
          sigle TEXT,
          type_cooperative TEXT NOT NULL DEFAULT 'agricole',
          forme_juridique TEXT NOT NULL DEFAULT 'scoops',
          numero_agrement TEXT,
          date_creation TEXT,
          registre_commerce TEXT,
          statut_juridique TEXT NOT NULL DEFAULT 'actif',
          region TEXT,
          departement TEXT,
          arrondissement TEXT,
          village_quartier TEXT,
          adresse TEXT,
          telephone TEXT,
          email TEXT,
          site_web TEXT,
          logo_path TEXT,
          devise_principale TEXT NOT NULL DEFAULT 'xaf',
          langue_par_defaut TEXT NOT NULL DEFAULT 'fr',
          fuseau_horaire TEXT NOT NULL DEFAULT 'Africa/Douala',
          slogan TEXT,
          qr_code_coop TEXT,
          niveau_maturite TEXT NOT NULL DEFAULT 'debutant',
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 2. Table sections
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sections (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          nom TEXT NOT NULL,
          localisation TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 3. Table sites
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          nom TEXT NOT NULL,
          section_id INTEGER NOT NULL,
          localisation TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (section_id) REFERENCES sections(id)
        )
      ''');

      // 4. Table magasins
      await db.execute('''
        CREATE TABLE IF NOT EXISTS magasins (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          nom TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'depot',
          capacite REAL,
          site_id INTEGER NOT NULL,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (site_id) REFERENCES sites(id)
        )
      ''');

      // 5. Table comites
      await db.execute('''
        CREATE TABLE IF NOT EXISTS comites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          role TEXT NOT NULL,
          description TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 6. Table produits
      await db.execute('''
        CREATE TABLE IF NOT EXISTS produits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code_produit TEXT UNIQUE NOT NULL,
          nom_produit TEXT NOT NULL,
          unite_mesure TEXT NOT NULL DEFAULT 'kg',
          rendement_moyen REAL,
          seuil_alerte REAL,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 7. Table prix_marche
      await db.execute('''
        CREATE TABLE IF NOT EXISTS prix_marche (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          produit_id INTEGER NOT NULL,
          prix_min REAL,
          prix_max REAL,
          prix_jour REAL,
          marche_reference TEXT NOT NULL DEFAULT 'local',
          variation_autorisee REAL,
          date_debut TEXT,
          date_fin TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (produit_id) REFERENCES produits(id)
        )
      ''');

      // 8. Table capital_social
      await db.execute('''
        CREATE TABLE IF NOT EXISTS capital_social (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          valeur_part REAL NOT NULL,
          parts_min INTEGER NOT NULL,
          parts_max INTEGER,
          liberation_obligatoire INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 9. Table parametres_comptables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS parametres_comptables (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plan_comptable TEXT NOT NULL DEFAULT 'SYSCOHADA',
          exercice_actif INTEGER NOT NULL,
          compte_caisse TEXT,
          compte_banque TEXT,
          taux_frais_gestion REAL DEFAULT 0,
          taux_reserve REAL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 10. Table retenues
      await db.execute('''
        CREATE TABLE IF NOT EXISTS retenues (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type_retenue TEXT NOT NULL,
          mode_calcul TEXT NOT NULL DEFAULT 'pourcentage',
          valeur REAL NOT NULL,
          plafond_retenue REAL,
          retenue_auto INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 11. Table parametres_documents
      await db.execute('''
        CREATE TABLE IF NOT EXISTS parametres_documents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          prefix_facture TEXT NOT NULL DEFAULT 'FAC',
          prefix_recu TEXT NOT NULL DEFAULT 'REC',
          prefix_vente TEXT NOT NULL DEFAULT 'VNT',
          format_numero TEXT NOT NULL DEFAULT '{PREFIX}-{YEAR}-{NUM}',
          signature_auto INTEGER DEFAULT 0,
          format_defaut TEXT NOT NULL DEFAULT 'A4',
          pied_page TEXT,
          cachet_numerique INTEGER DEFAULT 0,
          export_excel INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 12. Table parametres_securite
      await db.execute('''
        CREATE TABLE IF NOT EXISTS parametres_securite (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          validation_double INTEGER DEFAULT 0,
          seuil_validation_double REAL,
          journal_audit INTEGER DEFAULT 1,
          verrouillage_exercice INTEGER DEFAULT 0,
          sauvegarde_auto INTEGER DEFAULT 1,
          frequence_sauvegarde TEXT DEFAULT 'quotidienne',
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 13. Table parametres_ia
      await db.execute('''
        CREATE TABLE IF NOT EXISTS parametres_ia (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          seuil_anomalie REAL,
          prediction_prix INTEGER DEFAULT 0,
          scoring_adherent INTEGER DEFAULT 0,
          alerte_performance INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 14. Table settings (générique)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          key TEXT NOT NULL,
          value TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'string',
          editable INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          UNIQUE(category, key)
        )
      ''');

      // Créer les index pour améliorer les performances
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sections_code ON sections(code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sites_code ON sites(code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sites_section ON sites(section_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_magasins_code ON magasins(code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_magasins_site ON magasins(site_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_produits_code ON produits(code_produit)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_prix_marche_produit ON prix_marche(produit_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_prix_marche_active ON prix_marche(is_active)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_retenues_active ON retenues(is_active)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_settings_category ON settings(category)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_settings_key ON settings(key)');

      // Insérer les paramètres par défaut pour documents
      await db.insert('parametres_documents', {
        'prefix_facture': 'FAC',
        'prefix_recu': 'REC',
        'prefix_vente': 'VNT',
        'format_numero': '{PREFIX}-{YEAR}-{NUM}',
        'signature_auto': 0,
        'format_defaut': 'A4',
        'cachet_numerique': 0,
        'export_excel': 1,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Insérer les paramètres par défaut pour sécurité
      await db.insert('parametres_securite', {
        'validation_double': 0,
        'journal_audit': 1,
        'verrouillage_exercice': 0,
        'sauvegarde_auto': 1,
        'frequence_sauvegarde': 'quotidienne',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('Migration vers la version 19 (Paramétrage complet) réussie');
    } catch (e) {
      print('Erreur lors de la migration vers la version 19: $e');
      rethrow;
    }
  }

  /// Migrer les données existantes de coop_settings vers cooperative_entity
  static Future<void> migrateCoopSettingsToEntity(Database db) async {
    try {
      // Vérifier si cooperative_entity existe déjà avec des données
      final existing = await db.query('cooperative_entity', limit: 1);
      if (existing.isNotEmpty) {
        print('cooperative_entity contient déjà des données, migration ignorée');
        return;
      }

      // Récupérer les données de coop_settings
      final coopSettings = await db.query('coop_settings', limit: 1);
      if (coopSettings.isEmpty) {
        // Créer une entité par défaut
        await db.insert('cooperative_entity', {
          'raison_sociale': 'Coopérative de Cacaoculteurs',
          'type_cooperative': 'agricole',
          'forme_juridique': 'scoops',
          'statut_juridique': 'actif',
          'devise_principale': 'xaf',
          'langue_par_defaut': 'fr',
          'fuseau_horaire': 'Africa/Douala',
          'niveau_maturite': 'debutant',
          'created_at': DateTime.now().toIso8601String(),
        });
        return;
      }

      final settings = coopSettings.first;
      await db.insert('cooperative_entity', {
        'raison_sociale': settings['nom_cooperative'] ?? 'Coopérative de Cacaoculteurs',
        'adresse': settings['adresse'],
        'telephone': settings['telephone'],
        'email': settings['email'],
        'logo_path': settings['logo_path'],
        'type_cooperative': 'agricole',
        'forme_juridique': 'scoops',
        'statut_juridique': 'actif',
        'devise_principale': 'xaf',
        'langue_par_defaut': 'fr',
        'fuseau_horaire': 'Africa/Douala',
        'niveau_maturite': 'debutant',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': settings['updated_at'],
      });

      print('Migration des données coop_settings vers cooperative_entity réussie');
    } catch (e) {
      print('Erreur lors de la migration des données: $e');
      // Ne pas faire échouer la migration principale
    }
  }
}

