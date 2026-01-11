/// Migration pour le module Recettes & Commissions
/// Version 22 - Système flexible de commissions paramétrables

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class CommissionsModuleMigration {
  /// Créer les tables pour le module commissions
  static Future<void> createCommissionsTables(Database db) async {
    try {
      // Table des commissions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS commissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          libelle TEXT NOT NULL,
          montant_fixe REAL NOT NULL,
          type_application TEXT NOT NULL CHECK(type_application IN ('PAR_KG', 'PAR_VENTE')),
          date_debut TEXT NOT NULL,
          date_fin TEXT,
          reconductible INTEGER DEFAULT 0 CHECK(reconductible IN (0, 1)),
          periode_reconduction_days INTEGER,
          statut TEXT DEFAULT 'active' CHECK(statut IN ('active', 'inactive')),
          description TEXT,
          created_by INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          updated_by INTEGER,
          FOREIGN KEY (created_by) REFERENCES users(id),
          FOREIGN KEY (updated_by) REFERENCES users(id)
        )
      ''');

      // Table de snapshot des commissions appliquées aux recettes
      // Garantit que les recettes passées ne changent jamais
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recette_commissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          recette_id INTEGER NOT NULL,
          commission_code TEXT NOT NULL,
          commission_libelle TEXT NOT NULL,
          montant_applique REAL NOT NULL,
          type_application TEXT NOT NULL,
          poids_vendu REAL,
          montant_fixe_utilise REAL NOT NULL,
          date_application TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (recette_id) REFERENCES recettes(id) ON DELETE CASCADE
        )
      ''');

      // Table d'historique des modifications de commissions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS commission_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          commission_id INTEGER NOT NULL,
          commission_code TEXT NOT NULL,
          action TEXT NOT NULL CHECK(action IN ('CREATE', 'UPDATE', 'ACTIVATE', 'DEACTIVATE', 'RECONDUCTION')),
          old_montant_fixe REAL,
          new_montant_fixe REAL,
          old_date_debut TEXT,
          new_date_debut TEXT,
          old_date_fin TEXT,
          new_date_fin TEXT,
          changed_by INTEGER,
          change_reason TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (commission_id) REFERENCES commissions(id) ON DELETE CASCADE,
          FOREIGN KEY (changed_by) REFERENCES users(id)
        )
      ''');

      // Créer les index pour optimiser les performances
      await db.execute('CREATE INDEX IF NOT EXISTS idx_commissions_code ON commissions(code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_commissions_statut ON commissions(statut)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_commissions_dates ON commissions(date_debut, date_fin)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_commissions_actives ON commissions(statut, date_debut, date_fin)');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_recette_commissions_recette ON recette_commissions(recette_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_recette_commissions_code ON recette_commissions(commission_code)');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_commission_history_commission ON commission_history(commission_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_commission_history_code ON commission_history(commission_code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_commission_history_created ON commission_history(created_at)');

      print('✅ Tables du module commissions créées avec succès');
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la création des tables commissions: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Migrer vers la version 22 - Module commissions
  static Future<void> migrateToV22(Database db) async {
    try {
      print('🔄 Migration vers la version 22 (Module commissions)...');
      
      await createCommissionsTables(db);
      
      print('✅ Migration vers la version 22 terminée avec succès');
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la migration vers la version 22: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

