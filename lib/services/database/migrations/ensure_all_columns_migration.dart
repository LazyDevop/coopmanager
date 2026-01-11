/// Migration globale pour s'assurer que toutes les colonnes nécessaires existent
/// 
/// Cette migration vérifie et ajoute toutes les colonnes manquantes dans toutes les tables
/// pour éviter les erreurs "no such column"

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class EnsureAllColumnsMigration {
  /// Vérifier et ajouter toutes les colonnes manquantes
  static Future<void> ensureAllColumns(Database db) async {
    print('🔄 Vérification de toutes les colonnes de la base de données...');
    
    try {
      // Vérifier et corriger la table clients
      await _ensureClientsColumns(db);
      
      // Vérifier et corriger la table adherents
      await _ensureAdherentsColumns(db);
      
      // Vérifier et corriger la table ventes
      await _ensureVentesColumns(db);
      
      // Vérifier et corriger la table stock_depots
      await _ensureStockDepotsColumns(db);
      
      // Vérifier et corriger la table stock_mouvements
      await _ensureStockMouvementsColumns(db);
      
      // Vérifier et corriger la table recettes
      await _ensureRecettesColumns(db);
      
      // Vérifier et corriger la table factures
      await _ensureFacturesColumns(db);
      
      // Vérifier et corriger la table coop_settings
      await _ensureCoopSettingsColumns(db);
      
      // Vérifier et corriger la table champs_parcelles
      await _ensureChampsParcellesColumns(db);
      
      print('✅ Vérification des colonnes terminée');
    } catch (e) {
      print('⚠️ Erreur lors de la vérification des colonnes: $e');
      // Ne pas faire échouer l'application si la vérification échoue
    }
  }
  
  /// Vérifier et ajouter les colonnes manquantes dans la table clients
  static Future<void> _ensureClientsColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(clients)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
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
      
      for (final entry in requiredColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à clients');
            
            // Mettre à jour les valeurs par défaut si nécessaire
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
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
    } catch (e) {
      // Table n'existe peut-être pas encore, c'est normal
      if (!e.toString().contains('no such table')) {
        print('⚠️ Erreur lors de la vérification de clients: $e');
      }
    }
  }
  
  /// Vérifier et ajouter les colonnes manquantes dans la table adherents
  static Future<void> _ensureAdherentsColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(adherents)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      final requiredColumns = {
        'categorie': 'ALTER TABLE adherents ADD COLUMN categorie TEXT',
        'statut': 'ALTER TABLE adherents ADD COLUMN statut TEXT',
        'date_statut': 'ALTER TABLE adherents ADD COLUMN date_statut TEXT',
        'site_cooperative': 'ALTER TABLE adherents ADD COLUMN site_cooperative TEXT',
        'section': 'ALTER TABLE adherents ADD COLUMN section TEXT',
        'sexe': 'ALTER TABLE adherents ADD COLUMN sexe TEXT',
        'lieu_naissance': 'ALTER TABLE adherents ADD COLUMN lieu_naissance TEXT',
        'nationalite': 'ALTER TABLE adherents ADD COLUMN nationalite TEXT',
        'type_piece': 'ALTER TABLE adherents ADD COLUMN type_piece TEXT',
        'numero_piece': 'ALTER TABLE adherents ADD COLUMN numero_piece TEXT',
        'nom_pere': 'ALTER TABLE adherents ADD COLUMN nom_pere TEXT',
        'nom_mere': 'ALTER TABLE adherents ADD COLUMN nom_mere TEXT',
        'conjoint': 'ALTER TABLE adherents ADD COLUMN conjoint TEXT',
        'nombre_enfants': 'ALTER TABLE adherents ADD COLUMN nombre_enfants INTEGER',
        'superficie_totale_cultivee': 'ALTER TABLE adherents ADD COLUMN superficie_totale_cultivee REAL',
        'nombre_champs': 'ALTER TABLE adherents ADD COLUMN nombre_champs INTEGER',
        'rendement_moyen_ha': 'ALTER TABLE adherents ADD COLUMN rendement_moyen_ha REAL',
        'tonnage_total_produit': 'ALTER TABLE adherents ADD COLUMN tonnage_total_produit REAL',
        'tonnage_total_vendu': 'ALTER TABLE adherents ADD COLUMN tonnage_total_vendu REAL',
        'photo_path': 'ALTER TABLE adherents ADD COLUMN photo_path TEXT',
      };
      
      // Ajouter les colonnes manquantes
      for (final entry in requiredColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à adherents');
          } catch (e) {
            // Ignorer les erreurs de colonne déjà existante
            if (!e.toString().contains('duplicate column') && 
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
      
      // Vérifier à nouveau après ajout pour créer les index
      final columnsAfter = await db.rawQuery('PRAGMA table_info(adherents)');
      final columnNamesAfter = columnsAfter.map((c) => c['name'] as String).toList();
      
      // Créer l'index UNIQUE sur le code pour garantir l'unicité
      try {
        await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_adherents_code_unique ON adherents(code)');
        print('✅ Index UNIQUE créé sur adherents.code');
      } catch (e) {
        // Ignorer si l'index existe déjà
        if (!e.toString().contains('already exists') && !e.toString().contains('duplicate')) {
          print('⚠️ Erreur lors de la création de idx_adherents_code_unique: $e');
        }
      }
      
      // Créer les index uniquement si les colonnes existent
      if (columnNamesAfter.contains('categorie')) {
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_categorie ON adherents(categorie)');
        } catch (e) {
          print('⚠️ Erreur lors de la création de idx_adherents_categorie: $e');
        }
      }
      
      if (columnNamesAfter.contains('statut')) {
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_statut ON adherents(statut)');
        } catch (e) {
          print('⚠️ Erreur lors de la création de idx_adherents_statut: $e');
        }
      }
      
      if (columnNamesAfter.contains('section')) {
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_section ON adherents(section)');
        } catch (e) {
          print('⚠️ Erreur lors de la création de idx_adherents_section: $e');
        }
      }
      
      if (columnNamesAfter.contains('site_cooperative')) {
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_site ON adherents(site_cooperative)');
        } catch (e) {
          print('⚠️ Erreur lors de la création de idx_adherents_site: $e');
        }
      }
      
      if (columnNamesAfter.contains('numero_piece')) {
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_numero_piece ON adherents(numero_piece)');
        } catch (e) {
          print('⚠️ Erreur lors de la création de idx_adherents_numero_piece: $e');
        }
      }
    } catch (e) {
      if (!e.toString().contains('no such table')) {
        print('⚠️ Erreur lors de la vérification de adherents: $e');
      }
    }
  }
  
  /// Vérifier et ajouter les colonnes manquantes dans la table ventes
  static Future<void> _ensureVentesColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(ventes)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      // Colonnes de base (devraient toujours exister)
      final baseColumns = {
        'adherent_id': 'ALTER TABLE ventes ADD COLUMN adherent_id INTEGER',
        'type': 'ALTER TABLE ventes ADD COLUMN type TEXT',
        'quantite_total': 'ALTER TABLE ventes ADD COLUMN quantite_total REAL',
        'prix_unitaire': 'ALTER TABLE ventes ADD COLUMN prix_unitaire REAL',
        'montant_total': 'ALTER TABLE ventes ADD COLUMN montant_total REAL',
        'date_vente': 'ALTER TABLE ventes ADD COLUMN date_vente TEXT',
        'acheteur': 'ALTER TABLE ventes ADD COLUMN acheteur TEXT',
        'mode_paiement': 'ALTER TABLE ventes ADD COLUMN mode_paiement TEXT',
        'statut': 'ALTER TABLE ventes ADD COLUMN statut TEXT DEFAULT \'valide\'',
        'notes': 'ALTER TABLE ventes ADD COLUMN notes TEXT',
        'created_by': 'ALTER TABLE ventes ADD COLUMN created_by INTEGER',
        'created_at': 'ALTER TABLE ventes ADD COLUMN created_at TEXT',
      };
      
      // Colonnes V2 (nouvelles fonctionnalités)
      final v2Columns = {
        'client_id': 'ALTER TABLE ventes ADD COLUMN client_id INTEGER',
        'ecriture_comptable_id': 'ALTER TABLE ventes ADD COLUMN ecriture_comptable_id INTEGER',
        'qr_code_hash': 'ALTER TABLE ventes ADD COLUMN qr_code_hash TEXT',
        'campagne_id': 'ALTER TABLE ventes ADD COLUMN campagne_id INTEGER',
        'statut_paiement': 'ALTER TABLE ventes ADD COLUMN statut_paiement TEXT DEFAULT \'non_payee\'',
        'montant_commission': 'ALTER TABLE ventes ADD COLUMN montant_commission REAL DEFAULT 0.0',
        'montant_net': 'ALTER TABLE ventes ADD COLUMN montant_net REAL DEFAULT 0.0',
        'facture_pdf_path': 'ALTER TABLE ventes ADD COLUMN facture_pdf_path TEXT',
        'facture_id': 'ALTER TABLE ventes ADD COLUMN facture_id INTEGER',
      };
      
      // Ajouter les colonnes de base manquantes
      for (final entry in baseColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à ventes');
            
            // Mettre à jour les valeurs par défaut si nécessaire
            if (entry.key == 'statut') {
              await db.execute("UPDATE ventes SET statut = 'valide' WHERE statut IS NULL");
            } else if (entry.key == 'date_vente' && columnNames.contains('created_at')) {
              await db.execute("UPDATE ventes SET date_vente = created_at WHERE date_vente IS NULL");
            }
          } catch (e) {
            if (!e.toString().contains('duplicate column') && 
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
      
      // Ajouter les colonnes V2 manquantes
      for (final entry in v2Columns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à ventes');
          } catch (e) {
            if (!e.toString().contains('duplicate column') && 
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
    } catch (e) {
      if (!e.toString().contains('no such table')) {
        print('⚠️ Erreur lors de la vérification de ventes: $e');
      }
    }
  }
  
  /// Vérifier et ajouter les colonnes manquantes dans la table stock_depots
  static Future<void> _ensureStockDepotsColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(stock_depots)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      final requiredColumns = {
        'stock_brut': 'ALTER TABLE stock_depots ADD COLUMN stock_brut REAL DEFAULT 0.0',
        'poids_sac': 'ALTER TABLE stock_depots ADD COLUMN poids_sac REAL',
        'poids_dechets': 'ALTER TABLE stock_depots ADD COLUMN poids_dechets REAL',
        'autres': 'ALTER TABLE stock_depots ADD COLUMN autres REAL',
        'poids_net': 'ALTER TABLE stock_depots ADD COLUMN poids_net REAL DEFAULT 0.0',
        'qualite': 'ALTER TABLE stock_depots ADD COLUMN qualite TEXT',
        'humidite': 'ALTER TABLE stock_depots ADD COLUMN humidite REAL',
        'densite_arbres_associes': 'ALTER TABLE stock_depots ADD COLUMN densite_arbres_associes REAL',
        'photo_path': 'ALTER TABLE stock_depots ADD COLUMN photo_path TEXT',
        'notes': 'ALTER TABLE stock_depots ADD COLUMN notes TEXT',
      };
      
      for (final entry in requiredColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à stock_depots');
            
            // Calculer poids_net si nécessaire
            if (entry.key == 'poids_net') {
              await db.execute('''
                UPDATE stock_depots 
                SET poids_net = COALESCE(stock_brut, quantite) - COALESCE(poids_sac, 0) - COALESCE(poids_dechets, 0) - COALESCE(autres, 0)
                WHERE poids_net IS NULL OR poids_net = 0
              ''');
            }
          } catch (e) {
            if (!e.toString().contains('duplicate column') && 
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
    } catch (e) {
      if (!e.toString().contains('no such table')) {
        print('⚠️ Erreur lors de la vérification de stock_depots: $e');
      }
    }
  }
  
  /// Vérifier et ajouter les colonnes manquantes dans la table stock_mouvements
  static Future<void> _ensureStockMouvementsColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(stock_mouvements)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      final requiredColumns = {
        'adherent_id': 'ALTER TABLE stock_mouvements ADD COLUMN adherent_id INTEGER',
        'stock_depot_id': 'ALTER TABLE stock_mouvements ADD COLUMN stock_depot_id INTEGER',
      };
      
      for (final entry in requiredColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à stock_mouvements');
          } catch (e) {
            if (!e.toString().contains('duplicate column') && 
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
    } catch (e) {
      if (!e.toString().contains('no such table')) {
        print('⚠️ Erreur lors de la vérification de stock_mouvements: $e');
      }
    }
  }
  
  /// Vérifier et ajouter les colonnes manquantes dans la table recettes
  static Future<void> _ensureRecettesColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(recettes)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      // Colonnes de base requises
      final requiredColumns = {
        'adherent_id': 'ALTER TABLE recettes ADD COLUMN adherent_id INTEGER NOT NULL',
        'vente_id': 'ALTER TABLE recettes ADD COLUMN vente_id INTEGER',
        'montant_brut': 'ALTER TABLE recettes ADD COLUMN montant_brut REAL NOT NULL',
        'commission_rate': 'ALTER TABLE recettes ADD COLUMN commission_rate REAL NOT NULL',
        'commission_amount': 'ALTER TABLE recettes ADD COLUMN commission_amount REAL NOT NULL',
        'montant_net': 'ALTER TABLE recettes ADD COLUMN montant_net REAL NOT NULL',
        'date_recette': 'ALTER TABLE recettes ADD COLUMN date_recette TEXT NOT NULL',
        'notes': 'ALTER TABLE recettes ADD COLUMN notes TEXT',
        'created_by': 'ALTER TABLE recettes ADD COLUMN created_by INTEGER',
        'created_at': 'ALTER TABLE recettes ADD COLUMN created_at TEXT NOT NULL',
      };
      
      // Colonnes V2 (nouvelles fonctionnalités)
      final v2Columns = {
        'ecriture_comptable_id': 'ALTER TABLE recettes ADD COLUMN ecriture_comptable_id INTEGER',
        'qr_code_hash': 'ALTER TABLE recettes ADD COLUMN qr_code_hash TEXT',
        'campagne_id': 'ALTER TABLE recettes ADD COLUMN campagne_id INTEGER',
      };
      
      // Ajouter les colonnes de base manquantes
      for (final entry in requiredColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à recettes');
          } catch (e) {
            if (!e.toString().contains('duplicate column') && 
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
      
      // Ajouter les colonnes V2 manquantes
      for (final entry in v2Columns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à recettes');
          } catch (e) {
            if (!e.toString().contains('duplicate column') && 
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
      
      // Créer les index si nécessaire
      try {
        await db.execute('CREATE INDEX IF NOT EXISTS idx_recettes_adherent ON recettes(adherent_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_recettes_vente ON recettes(vente_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_recettes_date ON recettes(date_recette)');
      } catch (e) {
        print('⚠️ Erreur lors de la création des index recettes: $e');
      }
    } catch (e) {
      if (!e.toString().contains('no such table')) {
        print('⚠️ Erreur lors de la vérification de recettes: $e');
      }
    }
  }
  
  /// Vérifier et ajouter les colonnes manquantes dans la table factures
  static Future<void> _ensureFacturesColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(factures)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      final requiredColumns = {
        'qr_code_hash': 'ALTER TABLE factures ADD COLUMN qr_code_hash TEXT',
        'document_securise_id': 'ALTER TABLE factures ADD COLUMN document_securise_id INTEGER',
      };
      
      for (final entry in requiredColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à factures');
          } catch (e) {
            if (!e.toString().contains('duplicate column') && 
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
    } catch (e) {
      if (!e.toString().contains('no such table')) {
        print('⚠️ Erreur lors de la vérification de factures: $e');
      }
    }
  }
  
  /// Vérifier et ajouter les colonnes manquantes dans la table coop_settings
  static Future<void> _ensureCoopSettingsColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(coop_settings)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      final requiredColumns = {
        'code_cooperative': 'ALTER TABLE coop_settings ADD COLUMN code_cooperative TEXT',
        'commission_rate_actionnaire': 'ALTER TABLE coop_settings ADD COLUMN commission_rate_actionnaire REAL',
        'commission_rate_producteur': 'ALTER TABLE coop_settings ADD COLUMN commission_rate_producteur REAL',
      };
      
      for (final entry in requiredColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à coop_settings');
          } catch (e) {
            if (!e.toString().contains('duplicate column') && 
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
    } catch (e) {
      if (!e.toString().contains('no such table')) {
        print('⚠️ Erreur lors de la vérification de coop_settings: $e');
      }
    }
  }
  
  /// Vérifier et ajouter les colonnes manquantes dans la table champs_parcelles
  static Future<void> _ensureChampsParcellesColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(champs_parcelles)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      final requiredColumns = {
        'densite_arbres_associes': 'ALTER TABLE champs_parcelles ADD COLUMN densite_arbres_associes REAL',
      };
      
      for (final entry in requiredColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à champs_parcelles');
          } catch (e) {
            if (!e.toString().contains('duplicate column') && 
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
    } catch (e) {
      if (!e.toString().contains('no such table')) {
        print('⚠️ Erreur lors de la vérification de champs_parcelles: $e');
      }
    }
  }
}

