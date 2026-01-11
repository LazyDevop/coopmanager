/// Migration pour le module Social complet
/// Système flexible de gestion des aides sociales paramétrables

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SocialModuleMigration {
  /// Créer les tables pour le module social
  static Future<void> createSocialTables(Database db) async {
    try {
      print('🔄 Création des tables du module social...');
      
      // Table maîtresse des types d'aides sociales
      await db.execute('''
        CREATE TABLE IF NOT EXISTS social_aide_types (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          libelle TEXT NOT NULL,
          categorie TEXT NOT NULL CHECK(categorie IN ('FINANCIERE', 'MATERIELLE', 'SOCIALE', 'TECHNIQUE')),
          est_remboursable INTEGER NOT NULL DEFAULT 0 CHECK(est_remboursable IN (0, 1)),
          plafond_montant REAL,
          duree_max_mois INTEGER,
          mode_remboursement TEXT CHECK(mode_remboursement IN ('RETENUE_RECETTE', 'MANUEL', 'AUCUN')),
          activation INTEGER NOT NULL DEFAULT 1 CHECK(activation IN (0, 1)),
          description TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          created_by INTEGER,
          updated_by INTEGER,
          FOREIGN KEY (created_by) REFERENCES users(id),
          FOREIGN KEY (updated_by) REFERENCES users(id)
        )
      ''');

      // Table des aides accordées
      await db.execute('''
        CREATE TABLE IF NOT EXISTS social_aides (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          aide_type_id INTEGER NOT NULL,
          adherent_id INTEGER NOT NULL,
          montant REAL NOT NULL,
          date_octroi TEXT NOT NULL,
          date_debut TEXT,
          date_fin TEXT,
          statut TEXT NOT NULL DEFAULT 'accordee' CHECK(statut IN ('accordee', 'en_cours', 'remboursée', 'annulée')),
          observations TEXT,
          created_by INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (aide_type_id) REFERENCES social_aide_types(id),
          FOREIGN KEY (adherent_id) REFERENCES adherents(id),
          FOREIGN KEY (created_by) REFERENCES users(id)
        )
      ''');

      // Table des remboursements
      await db.execute('''
        CREATE TABLE IF NOT EXISTS social_remboursements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          aide_id INTEGER NOT NULL,
          montant REAL NOT NULL,
          date_remboursement TEXT NOT NULL,
          source TEXT NOT NULL CHECK(source IN ('RETENUE_RECETTE', 'CAISSE')),
          recette_id INTEGER,
          notes TEXT,
          created_at TEXT NOT NULL,
          created_by INTEGER,
          FOREIGN KEY (aide_id) REFERENCES social_aides(id) ON DELETE CASCADE,
          FOREIGN KEY (recette_id) REFERENCES recettes(id),
          FOREIGN KEY (created_by) REFERENCES users(id)
        )
      ''');

      // Table d'historique des modifications (audit)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS social_aide_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          aide_id INTEGER NOT NULL,
          action TEXT NOT NULL CHECK(action IN ('CREATE', 'UPDATE', 'STATUS_CHANGE', 'REMBURSEMENT', 'CANCEL')),
          old_statut TEXT,
          new_statut TEXT,
          old_montant REAL,
          new_montant REAL,
          details TEXT,
          changed_by INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (aide_id) REFERENCES social_aides(id) ON DELETE CASCADE,
          FOREIGN KEY (changed_by) REFERENCES users(id)
        )
      ''');

      // Créer les index pour optimiser les performances
      await db.execute('CREATE INDEX IF NOT EXISTS idx_social_aide_types_code ON social_aide_types(code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_social_aide_types_activation ON social_aide_types(activation)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_social_aide_types_categorie ON social_aide_types(categorie)');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_social_aides_type ON social_aides(aide_type_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_social_aides_adherent ON social_aides(adherent_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_social_aides_statut ON social_aides(statut)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_social_aides_date_octroi ON social_aides(date_octroi)');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_social_remboursements_aide ON social_remboursements(aide_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_social_remboursements_recette ON social_remboursements(recette_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_social_remboursements_date ON social_remboursements(date_remboursement)');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_social_aide_history_aide ON social_aide_history(aide_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_social_aide_history_created ON social_aide_history(created_at)');

      // Vérifier que les tables ont bien été créées
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('social_aide_types', 'social_aides', 'social_remboursements', 'social_aide_history')",
      );
      
      print('✅ Tables du module social créées avec succès');
      print('📊 Tables créées: ${tables.map((t) => t['name']).join(', ')}');
      
      if (tables.length < 4) {
        throw Exception('Certaines tables sociales n\'ont pas été créées. Tables trouvées: ${tables.length}/4');
      }
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la création des tables social: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Migrer vers la version avec module social
  static Future<void> migrateToSocialModule(Database db) async {
    try {
      print('🔄 Migration vers le module Social...');
      
      await createSocialTables(db);
      
      print('✅ Migration vers le module Social terminée avec succès');
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la migration vers le module Social: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

