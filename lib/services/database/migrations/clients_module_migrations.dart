/// Migrations de base de données pour le Module Clients (V17)
/// 
/// Ces migrations ajoutent :
/// - Table clients (acheteurs de cacao)
/// - Table ventes_clients (liaison vente-client)
/// - Table paiements_clients (paiements des clients)
/// - Index pour performance et recherche

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ClientsModuleMigrations {
  /// Migrer vers la version 17 (Module Clients)
  static Future<void> migrateToV17(Database db) async {
    try {
      print('🔄 Début de la migration vers V17 (Module Clients)...');
      
      // 1. Créer la table clients
      await _createClientsTable(db);
      
      // 2. S'assurer que TOUTES les colonnes sont ajoutées AVANT de créer les index
      await _ensureAllClientsColumns(db);
      
      // 3. Créer la table ventes_clients
      await _createVentesClientsTable(db);
      
      // 4. Créer la table paiements_clients
      await _createPaiementsClientsTable(db);
      
      // 5. Ajouter client_id à la table ventes si nécessaire
      await _extendVentesTable(db);
      
      // 6. Créer les index pour performance (MAINTENANT que toutes les colonnes existent)
      await _createIndexes(db);
      
      print('✅ Migration vers V17 (Module Clients) réussie');
    } catch (e) {
      print('❌ Erreur lors de la migration vers V17: $e');
      rethrow;
    }
  }
  
  /// S'assurer que toutes les colonnes de la table clients existent
  static Future<void> _ensureAllClientsColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(clients)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      // Liste complète des colonnes requises avec leurs définitions
      final requiredColumns = {
        'code_client': 'ALTER TABLE clients ADD COLUMN code_client TEXT',
        'type_client': 'ALTER TABLE clients ADD COLUMN type_client TEXT',
        'raison_sociale': 'ALTER TABLE clients ADD COLUMN raison_sociale TEXT',
        'nom_responsable': 'ALTER TABLE clients ADD COLUMN nom_responsable TEXT',
        'telephone': 'ALTER TABLE clients ADD COLUMN telephone TEXT',
        'email': 'ALTER TABLE clients ADD COLUMN email TEXT',
        'adresse': 'ALTER TABLE clients ADD COLUMN adresse TEXT',
        'pays': 'ALTER TABLE clients ADD COLUMN pays TEXT',
        'ville': 'ALTER TABLE clients ADD COLUMN ville TEXT',
        'nrc': 'ALTER TABLE clients ADD COLUMN nrc TEXT',
        'ifu': 'ALTER TABLE clients ADD COLUMN ifu TEXT',
        'plafond_credit': 'ALTER TABLE clients ADD COLUMN plafond_credit REAL',
        'solde_client': 'ALTER TABLE clients ADD COLUMN solde_client REAL DEFAULT 0.0',
        'statut': 'ALTER TABLE clients ADD COLUMN statut TEXT DEFAULT \'actif\'',
        'date_blocage': 'ALTER TABLE clients ADD COLUMN date_blocage TEXT',
        'raison_blocage': 'ALTER TABLE clients ADD COLUMN raison_blocage TEXT',
        'date_creation': 'ALTER TABLE clients ADD COLUMN date_creation TEXT',
        'created_by': 'ALTER TABLE clients ADD COLUMN created_by INTEGER',
        'updated_at': 'ALTER TABLE clients ADD COLUMN updated_at TEXT',
        'updated_by': 'ALTER TABLE clients ADD COLUMN updated_by INTEGER',
      };
      
      // Ajouter les colonnes manquantes
      for (final entry in requiredColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à clients');
            
            // Pour les colonnes NOT NULL, mettre à jour les valeurs NULL si nécessaire
            if (entry.key == 'statut') {
              await db.execute("UPDATE clients SET statut = 'actif' WHERE statut IS NULL");
            } else if (entry.key == 'raison_sociale') {
              await db.execute("UPDATE clients SET raison_sociale = 'Client ' || id WHERE raison_sociale IS NULL");
            } else if (entry.key == 'type_client') {
              await db.execute("UPDATE clients SET type_client = 'entreprise' WHERE type_client IS NULL");
            } else if (entry.key == 'code_client') {
              await db.execute("UPDATE clients SET code_client = 'CLI' || id WHERE code_client IS NULL");
            } else if (entry.key == 'date_creation') {
              await db.execute("UPDATE clients SET date_creation = datetime('now') WHERE date_creation IS NULL");
            }
          } catch (e) {
            // Ignorer les erreurs de colonne déjà existante
            if (!e.toString().contains('duplicate column') && 
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de la colonne ${entry.key}: $e');
            }
          }
        }
      }
    } catch (e) {
      // Table n'existe peut-être pas encore, c'est normal
      if (!e.toString().contains('no such table')) {
        print('⚠️ Erreur lors de la vérification des colonnes clients: $e');
      }
    }
  }

  /// Créer la table clients
  static Future<void> _createClientsTable(Database db) async {
    // Créer la table si elle n'existe pas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code_client TEXT UNIQUE NOT NULL,
        type_client TEXT NOT NULL,
        raison_sociale TEXT NOT NULL,
        nom_responsable TEXT,
        telephone TEXT,
        email TEXT,
        adresse TEXT,
        pays TEXT,
        ville TEXT,
        nrc TEXT,
        ifu TEXT,
        plafond_credit REAL,
        solde_client REAL DEFAULT 0.0,
        statut TEXT NOT NULL DEFAULT 'actif',
        date_blocage TEXT,
        raison_blocage TEXT,
        date_creation TEXT NOT NULL,
        created_by INTEGER,
        updated_at TEXT,
        updated_by INTEGER,
        FOREIGN KEY (created_by) REFERENCES users(id),
        FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');
    
    // La vérification complète des colonnes est maintenant faite dans _ensureAllClientsColumns
    // qui est appelée APRÈS la création de la table mais AVANT la création des index
    
    print('✅ Table clients créée/vérifiée');
  }

  /// Créer la table ventes_clients
  static Future<void> _createVentesClientsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ventes_clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        vente_id INTEGER NOT NULL,
        montant_total REAL NOT NULL,
        montant_paye REAL DEFAULT 0.0,
        solde_restant REAL NOT NULL,
        statut_paiement TEXT NOT NULL DEFAULT 'impaye',
        date_vente TEXT NOT NULL,
        date_echeance TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
        FOREIGN KEY (vente_id) REFERENCES ventes(id) ON DELETE CASCADE,
        UNIQUE(client_id, vente_id)
      )
    ''');
    print('✅ Table ventes_clients créée');
  }

  /// Créer la table paiements_clients
  static Future<void> _createPaiementsClientsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS paiements_clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        vente_id INTEGER,
        montant REAL NOT NULL,
        mode_paiement TEXT NOT NULL,
        reference TEXT,
        date_paiement TEXT NOT NULL,
        notes TEXT,
        recu_pdf_path TEXT,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        qr_code_hash TEXT,
        ecriture_comptable_id INTEGER,
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
        FOREIGN KEY (vente_id) REFERENCES ventes(id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES users(id),
        FOREIGN KEY (ecriture_comptable_id) REFERENCES ecritures_comptables(id) ON DELETE SET NULL
      )
    ''');
    print('✅ Table paiements_clients créée');
  }

  /// Étendre la table ventes avec client_id si nécessaire
  static Future<void> _extendVentesTable(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(ventes)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      // Vérifier si client_id existe déjà (peut avoir été ajouté dans une migration précédente)
      if (!columnNames.contains('client_id')) {
        await db.execute('ALTER TABLE ventes ADD COLUMN client_id INTEGER');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_ventes_client 
          ON ventes(client_id)
        ''');
        print('✅ Colonne client_id ajoutée à ventes');
      }
    } catch (e) {
      print('⚠️ Erreur lors de l\'extension de la table ventes: $e');
    }
  }

  /// Créer les index pour performance
  /// IMPORTANT: Cette méthode doit être appelée APRÈS que toutes les colonnes soient ajoutées
  static Future<void> _createIndexes(Database db) async {
    try {
      // Vérifier que la table clients existe
      try {
        final columns = await db.rawQuery('PRAGMA table_info(clients)');
        final columnNames = columns.map((c) => c['name'] as String).toList();
        
        // Index pour clients - vérifier que chaque colonne existe avant de créer l'index
        if (columnNames.contains('code_client')) {
          try {
            await db.execute('''
              CREATE INDEX IF NOT EXISTS idx_clients_code 
              ON clients(code_client)
            ''');
          } catch (e) {
            print('⚠️ Erreur lors de la création de idx_clients_code: $e');
          }
        }
        
        if (columnNames.contains('type_client')) {
          try {
            await db.execute('''
              CREATE INDEX IF NOT EXISTS idx_clients_type 
              ON clients(type_client)
            ''');
          } catch (e) {
            print('⚠️ Erreur lors de la création de idx_clients_type: $e');
          }
        }
        
        if (columnNames.contains('statut')) {
          try {
            await db.execute('''
              CREATE INDEX IF NOT EXISTS idx_clients_statut 
              ON clients(statut)
            ''');
          } catch (e) {
            print('⚠️ Erreur lors de la création de idx_clients_statut: $e');
          }
        }
        
        if (columnNames.contains('solde_client')) {
          try {
            await db.execute('''
              CREATE INDEX IF NOT EXISTS idx_clients_solde 
              ON clients(solde_client)
            ''');
          } catch (e) {
            print('⚠️ Erreur lors de la création de idx_clients_solde: $e');
          }
        }
      } catch (e) {
        print('⚠️ Erreur lors de la vérification de la table clients: $e');
      }

      // Index pour ventes_clients
      try {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_ventes_clients_client 
          ON ventes_clients(client_id)
        ''');
      } catch (e) {
        print('⚠️ Erreur lors de la création de idx_ventes_clients_client: $e');
      }
      
      try {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_ventes_clients_vente 
          ON ventes_clients(vente_id)
        ''');
      } catch (e) {
        print('⚠️ Erreur lors de la création de idx_ventes_clients_vente: $e');
      }
      
      try {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_ventes_clients_statut 
          ON ventes_clients(statut_paiement)
        ''');
      } catch (e) {
        print('⚠️ Erreur lors de la création de idx_ventes_clients_statut: $e');
      }

      // Index pour paiements_clients
      try {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_paiements_clients_client 
          ON paiements_clients(client_id)
        ''');
      } catch (e) {
        print('⚠️ Erreur lors de la création de idx_paiements_clients_client: $e');
      }
      
      try {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_paiements_clients_vente 
          ON paiements_clients(vente_id)
        ''');
      } catch (e) {
        print('⚠️ Erreur lors de la création de idx_paiements_clients_vente: $e');
      }
      
      try {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_paiements_clients_date 
          ON paiements_clients(date_paiement)
        ''');
      } catch (e) {
        print('⚠️ Erreur lors de la création de idx_paiements_clients_date: $e');
      }

      print('✅ Index créés');
    } catch (e) {
      print('⚠️ Erreur générale lors de la création des index: $e');
      // Ne pas faire échouer la migration si les index échouent
    }
  }
}
