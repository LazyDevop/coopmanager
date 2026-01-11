/// Migrations de base de données pour le Module Ventes V2
/// 
/// Ajoute les tables pour :
/// - Lots de vente intelligents
/// - Simulations de vente
/// - Workflow de validation multi-niveaux
/// - Créances clients (paiement différé)
/// - Fonds social
/// - Historique des simulations

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class VentesV2Migrations {
  /// Migrer vers la version 13 (Module Ventes V2)
  static Future<void> migrateToV13(Database db) async {
    try {
      print('Exécution de la migration vers la version 13 (Module Ventes V2)...');

      // 1. Table lots_vente
      await db.execute('''
        CREATE TABLE IF NOT EXISTS lots_vente (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code_lot TEXT UNIQUE NOT NULL,
          campagne_id INTEGER,
          qualite TEXT,
          categorie_producteur TEXT,
          quantite_total REAL NOT NULL,
          prix_unitaire_propose REAL NOT NULL,
          client_id INTEGER,
          statut TEXT DEFAULT 'preparation',
          notes TEXT,
          created_by INTEGER,
          created_at TEXT NOT NULL,
          date_validation TEXT,
          date_vente TEXT,
          FOREIGN KEY (campagne_id) REFERENCES campagnes(id),
          FOREIGN KEY (client_id) REFERENCES clients(id),
          FOREIGN KEY (created_by) REFERENCES users(id)
        )
      ''');

      // 2. Table lot_vente_details
      await db.execute('''
        CREATE TABLE IF NOT EXISTS lot_vente_details (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          lot_vente_id INTEGER NOT NULL,
          adherent_id INTEGER NOT NULL,
          quantite REAL NOT NULL,
          is_exclu INTEGER DEFAULT 0,
          raison_exclusion TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (lot_vente_id) REFERENCES lots_vente(id),
          FOREIGN KEY (adherent_id) REFERENCES adherents(id)
        )
      ''');

      // 3. Table simulations_vente
      await db.execute('''
        CREATE TABLE IF NOT EXISTS simulations_vente (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          lot_vente_id INTEGER,
          client_id INTEGER,
          campagne_id INTEGER,
          quantite_total REAL NOT NULL,
          prix_unitaire_propose REAL NOT NULL,
          montant_brut REAL NOT NULL,
          montant_commission REAL NOT NULL,
          montant_net REAL NOT NULL,
          montant_fonds_social REAL DEFAULT 0.0,
          prix_moyen_jour REAL DEFAULT 0.0,
          prix_moyen_precedent REAL DEFAULT 0.0,
          marge_cooperative REAL DEFAULT 0.0,
          indicateurs TEXT,
          statut TEXT DEFAULT 'simulee',
          notes TEXT,
          created_by INTEGER,
          created_at TEXT NOT NULL,
          date_validation TEXT,
          FOREIGN KEY (lot_vente_id) REFERENCES lots_vente(id),
          FOREIGN KEY (client_id) REFERENCES clients(id),
          FOREIGN KEY (campagne_id) REFERENCES campagnes(id),
          FOREIGN KEY (created_by) REFERENCES users(id)
        )
      ''');

      // 4. Table validations_vente
      await db.execute('''
        CREATE TABLE IF NOT EXISTS validations_vente (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vente_id INTEGER NOT NULL,
          etape TEXT NOT NULL,
          statut TEXT DEFAULT 'en_attente',
          valide_par INTEGER,
          commentaire TEXT,
          created_at TEXT NOT NULL,
          date_validation TEXT,
          FOREIGN KEY (vente_id) REFERENCES ventes(id),
          FOREIGN KEY (valide_par) REFERENCES users(id)
        )
      ''');

      // 5. Table creances_clients
      await db.execute('''
        CREATE TABLE IF NOT EXISTS creances_clients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vente_id INTEGER NOT NULL,
          client_id INTEGER NOT NULL,
          montant_total REAL NOT NULL,
          montant_paye REAL DEFAULT 0.0,
          montant_restant REAL NOT NULL,
          date_vente TEXT NOT NULL,
          date_echeance TEXT NOT NULL,
          date_paiement TEXT,
          statut TEXT DEFAULT 'en_attente',
          jours_retard INTEGER,
          is_client_bloque INTEGER DEFAULT 0,
          notes TEXT,
          created_by INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (vente_id) REFERENCES ventes(id),
          FOREIGN KEY (client_id) REFERENCES clients(id),
          FOREIGN KEY (created_by) REFERENCES users(id)
        )
      ''');

      // 6. Table fonds_social
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fonds_social (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vente_id INTEGER,
          source TEXT NOT NULL,
          montant REAL NOT NULL,
          pourcentage REAL,
          description TEXT NOT NULL,
          date_contribution TEXT NOT NULL,
          notes TEXT,
          created_by INTEGER,
          created_at TEXT NOT NULL,
          ecriture_comptable_id INTEGER,
          FOREIGN KEY (vente_id) REFERENCES ventes(id),
          FOREIGN KEY (created_by) REFERENCES users(id),
          FOREIGN KEY (ecriture_comptable_id) REFERENCES ecritures_comptables(id)
        )
      ''');

      // 7. Table historiques_simulation
      await db.execute('''
        CREATE TABLE IF NOT EXISTS historiques_simulation (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          simulation_id INTEGER NOT NULL,
          action TEXT NOT NULL,
          donnees_avant TEXT,
          donnees_apres TEXT,
          commentaire TEXT,
          user_id INTEGER,
          created_at TEXT NOT NULL,
          FOREIGN KEY (simulation_id) REFERENCES simulations_vente(id),
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');

      // 8. Étendre la table ventes avec champs V2
      await _extendVentesTableV2(db);

      // 9. Créer les index pour performance
      await _createIndexesV2(db);

      print('✅ Migration vers la version 13 (Module Ventes V2) terminée avec succès');
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la migration vers la version 13: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Étendre la table ventes avec les champs V2
  static Future<void> _extendVentesTableV2(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(ventes)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      // Ajouter colonnes V2 si elles n'existent pas
      final newColumns = {
        'date_echeance': 'TEXT',
        'montant_fonds_social': 'REAL DEFAULT 0.0',
        'pourcentage_fonds_social': 'REAL',
        'workflow_etape': 'TEXT DEFAULT \'preparation\'',
        'workflow_statut': 'TEXT DEFAULT \'en_attente\'',
      };

      for (final entry in newColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(
              'ALTER TABLE ventes ADD COLUMN ${entry.key} ${entry.value}',
            );
            print('Colonne ${entry.key} ajoutée à la table ventes');
          } catch (e) {
            final errorStr = e.toString().toLowerCase();
            if (!errorStr.contains('duplicate column') &&
                !errorStr.contains('already exists')) {
              print('Avertissement lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Erreur lors de l\'extension de la table ventes V2: $e');
    }
  }

  /// Créer les index pour améliorer les performances
  static Future<void> _createIndexesV2(Database db) async {
    try {
      // Index pour lots_vente
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lots_vente_code ON lots_vente(code_lot)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lots_vente_campagne ON lots_vente(campagne_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lots_vente_statut ON lots_vente(statut)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lots_vente_client ON lots_vente(client_id)',
      );

      // Index pour lot_vente_details
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lot_vente_details_lot ON lot_vente_details(lot_vente_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lot_vente_details_adherent ON lot_vente_details(adherent_id)',
      );

      // Index pour simulations_vente
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_simulations_vente_lot ON simulations_vente(lot_vente_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_simulations_vente_client ON simulations_vente(client_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_simulations_vente_statut ON simulations_vente(statut)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_simulations_vente_created ON simulations_vente(created_at)',
      );

      // Index pour validations_vente
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_validations_vente_vente ON validations_vente(vente_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_validations_vente_etape ON validations_vente(etape)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_validations_vente_statut ON validations_vente(statut)',
      );

      // Index pour creances_clients
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_creances_clients_vente ON creances_clients(vente_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_creances_clients_client ON creances_clients(client_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_creances_clients_statut ON creances_clients(statut)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_creances_clients_echeance ON creances_clients(date_echeance)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_creances_clients_bloque ON creances_clients(is_client_bloque)',
      );

      // Index pour fonds_social
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_fonds_social_vente ON fonds_social(vente_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_fonds_social_source ON fonds_social(source)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_fonds_social_date ON fonds_social(date_contribution)',
      );

      // Index pour historiques_simulation
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_historiques_simulation_sim ON historiques_simulation(simulation_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_historiques_simulation_action ON historiques_simulation(action)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_historiques_simulation_created ON historiques_simulation(created_at)',
      );

      print('✅ Index V2 créés avec succès');
    } catch (e) {
      print('Erreur lors de la création des index V2: $e');
    }
  }
}

