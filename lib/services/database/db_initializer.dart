import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../config/app_config.dart';
import '../auth/auth_service.dart';
import 'migrations/v2_migrations.dart';
import 'migrations/adherent_expert_migrations.dart';

class DatabaseInitializer {
  static Database? _database;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  static Future<Database> _initDatabase() async {
    // Initialiser sqflite_common_ffi pour Windows
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    // Obtenir le chemin du répertoire de documents
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConfig.databaseName);
    
    final database = await openDatabase(
      path,
      version: AppConfig.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
    // Vérifier et créer l'admin par défaut après ouverture (pour les bases existantes)
    await _ensureDefaultAdminUser(database);
    
    // Vérifier et ajouter les colonnes manquantes pour stock_depots (sécurité supplémentaire)
    await _ensureStockDepotsColumns(database);
    
    // Vérifier et ajouter les colonnes manquantes pour social_credits (sécurité supplémentaire)
    await AdherentExpertMigrations.ensureSocialCreditsColumns(database);
    
    return database;
  }
  
  /// S'assurer que l'utilisateur admin existe (pour bases existantes)
  static Future<void> _ensureDefaultAdminUser(Database db) async {
    try {
      final result = await db.query('users', limit: 1);
      if (result.isEmpty) {
        await _createDefaultAdminUser(db);
      }
    } catch (e) {
      print('Erreur lors de la vérification de l\'utilisateur admin: $e');
    }
  }
  
  static Future<void> _onCreate(Database db, int version) async {
    // Table des utilisateurs
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        role TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        is_active INTEGER DEFAULT 1,
        dernier_login TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    
    // Table des logs d'audit
    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        action TEXT NOT NULL,
        entity_type TEXT,
        entity_id INTEGER,
        details TEXT,
        ip_address TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
    
    // Table des adhérents
    await db.execute('''
      CREATE TABLE adherents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        telephone TEXT,
        email TEXT,
        village TEXT,
        adresse TEXT,
        cnib TEXT,
        date_naissance TEXT,
        date_adhesion TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    
    // Table du stock (dépôts)
    await db.execute('''
      CREATE TABLE stock_depots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        quantite REAL NOT NULL,
        stock_brut REAL DEFAULT 0.0,
        poids_sac REAL,
        poids_dechets REAL,
        autres REAL,
        poids_net REAL DEFAULT 0.0,
        prix_unitaire REAL,
        date_depot TEXT NOT NULL,
        qualite TEXT,
        humidite REAL,
        photo_path TEXT,
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id),
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');
    
    // Table des mouvements de stock
    await db.execute('''
      CREATE TABLE stock_mouvements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantite REAL NOT NULL,
        stock_depot_id INTEGER,
        vente_id INTEGER,
        date_mouvement TEXT NOT NULL,
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id),
        FOREIGN KEY (stock_depot_id) REFERENCES stock_depots(id),
        FOREIGN KEY (vente_id) REFERENCES ventes(id),
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');
    
    // Table des ventes
    await db.execute('''
      CREATE TABLE ventes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        adherent_id INTEGER,
        quantite_total REAL NOT NULL,
        prix_unitaire REAL NOT NULL,
        montant_total REAL NOT NULL,
        acheteur TEXT,
        mode_paiement TEXT,
        date_vente TEXT NOT NULL,
        notes TEXT,
        statut TEXT DEFAULT 'valide',
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id),
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');
    
    // Table des détails de vente (pour ventes groupées)
    await db.execute('''
      CREATE TABLE vente_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vente_id INTEGER NOT NULL,
        adherent_id INTEGER NOT NULL,
        quantite REAL NOT NULL,
        prix_unitaire REAL NOT NULL,
        montant REAL NOT NULL,
        FOREIGN KEY (vente_id) REFERENCES ventes(id),
        FOREIGN KEY (adherent_id) REFERENCES adherents(id)
      )
    ''');
    
    // Table des recettes
    await db.execute('''
      CREATE TABLE recettes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        vente_id INTEGER,
        montant_brut REAL NOT NULL,
        commission_rate REAL NOT NULL,
        commission_amount REAL NOT NULL,
        montant_net REAL NOT NULL,
        date_recette TEXT NOT NULL,
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id),
        FOREIGN KEY (vente_id) REFERENCES ventes(id),
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');
    
    // Table des factures
    await db.execute('''
      CREATE TABLE factures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero TEXT UNIQUE NOT NULL,
        adherent_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        montant_total REAL NOT NULL,
        date_facture TEXT NOT NULL,
        date_echeance TEXT,
        statut TEXT NOT NULL,
        notes TEXT,
        pdf_path TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id),
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');
    
    // Table de l'historique des opérations des adhérents
    await db.execute('''
      CREATE TABLE adherent_historique (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        type_operation TEXT NOT NULL,
        operation_id INTEGER,
        description TEXT NOT NULL,
        montant REAL,
        quantite REAL,
        date_operation TEXT NOT NULL,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id),
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');

    // Table des paramètres de la coopérative
    await db.execute('''
      CREATE TABLE coop_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom_cooperative TEXT NOT NULL,
        logo_path TEXT,
        adresse TEXT,
        telephone TEXT,
        email TEXT,
        commission_rate REAL NOT NULL,
        periode_campagne_days INTEGER NOT NULL,
        date_debut_campagne TEXT,
        date_fin_campagne TEXT,
        updated_at TEXT
      )
    ''');
    
    // Table des campagnes
    await db.execute('''
      CREATE TABLE campagnes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        date_debut TEXT NOT NULL,
        date_fin TEXT NOT NULL,
        description TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    
    // Table des barèmes de qualité
    await db.execute('''
      CREATE TABLE baremes_qualite (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        qualite TEXT NOT NULL UNIQUE,
        prix_min REAL,
        prix_max REAL,
        commission_rate REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    
    // Table des notifications
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        titre TEXT NOT NULL,
        message TEXT NOT NULL,
        module TEXT,
        entity_type TEXT,
        entity_id INTEGER,
        user_id INTEGER,
        is_read INTEGER DEFAULT 0,
        priority TEXT DEFAULT 'normal',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
    
    // Créer les index pour améliorer les performances
    await db.execute('CREATE INDEX idx_audit_logs_user ON audit_logs(user_id)');
    await db.execute('CREATE INDEX idx_audit_logs_created ON audit_logs(created_at)');
    await db.execute('CREATE INDEX idx_users_username ON users(username)');
    await db.execute('CREATE INDEX idx_users_role ON users(role)');
    
    // Créer les paramètres par défaut
    await db.insert('coop_settings', {
      'nom_cooperative': 'Coopérative de Cacaoculteurs',
      'commission_rate': AppConfig.defaultCommissionRate,
      'periode_campagne_days': 365,
      'updated_at': DateTime.now().toIso8601String(),
    });
    
    // Créer les index pour améliorer les performances
    await db.execute('CREATE INDEX idx_adherents_code ON adherents(code)');
    await db.execute('CREATE INDEX idx_stock_depots_adherent ON stock_depots(adherent_id)');
    await db.execute('CREATE INDEX idx_ventes_adherent ON ventes(adherent_id)');
    await db.execute('CREATE INDEX idx_ventes_date ON ventes(date_vente)');
    await db.execute('CREATE INDEX idx_recettes_adherent ON recettes(adherent_id)');
    await db.execute('CREATE INDEX idx_factures_adherent ON factures(adherent_id)');
    await db.execute('CREATE INDEX idx_factures_numero ON factures(numero)');
    await db.execute('CREATE INDEX idx_adherent_historique_adherent ON adherent_historique(adherent_id)');
    await db.execute('CREATE INDEX idx_adherent_historique_date ON adherent_historique(date_operation)');
    await db.execute('CREATE INDEX idx_adherents_village ON adherents(village)');
    await db.execute('CREATE INDEX idx_campagnes_active ON campagnes(is_active)');
    await db.execute('CREATE INDEX idx_campagnes_dates ON campagnes(date_debut, date_fin)');
    await db.execute('CREATE INDEX idx_baremes_qualite ON baremes_qualite(qualite)');
    await db.execute('CREATE INDEX idx_notifications_user ON notifications(user_id)');
    await db.execute('CREATE INDEX idx_notifications_type ON notifications(type)');
    await db.execute('CREATE INDEX idx_notifications_read ON notifications(is_read)');
    await db.execute('CREATE INDEX idx_notifications_created ON notifications(created_at)');
    
    // Créer l'utilisateur admin par défaut
    await _createDefaultAdminUser(db);
  }
  
  /// Créer l'utilisateur admin par défaut si la table users est vide
  static Future<void> _createDefaultAdminUser(Database db) async {
    try {
      // Vérifier si des utilisateurs existent déjà
      final result = await db.query('users', limit: 1);
      
      if (result.isEmpty) {
        // Créer l'utilisateur admin par défaut
        final authService = AuthService();
        final now = DateTime.now();
        
        await db.insert('users', {
          'username': 'admin',
          'password_hash': authService.hashPassword('Admin@123'),
          'nom': 'Administrateur',
          'prenom': 'Système',
          'role': AppConfig.roleAdmin,
          'email': 'admin@cooperative.local',
          'is_active': 1,
          'created_at': now.toIso8601String(),
        });
      }
    } catch (e) {
      // Ne pas faire échouer l'initialisation si la création de l'admin échoue
      print('Erreur lors de la création de l\'utilisateur admin: $e');
    }
  }
  
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gérer les migrations de base de données ici
    if (oldVersion < 2) {
      // Migration vers la version 2 : Ajouter village et cnib à la table adherents
      try {
        await db.execute('ALTER TABLE adherents ADD COLUMN village TEXT');
        await db.execute('ALTER TABLE adherents ADD COLUMN cnib TEXT');
        
        // Créer la table d'historique si elle n'existe pas
        await db.execute('''
          CREATE TABLE IF NOT EXISTS adherent_historique (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            adherent_id INTEGER NOT NULL,
            type_operation TEXT NOT NULL,
            operation_id INTEGER,
            description TEXT NOT NULL,
            montant REAL,
            quantite REAL,
            date_operation TEXT NOT NULL,
            created_by INTEGER,
            created_at TEXT NOT NULL,
            FOREIGN KEY (adherent_id) REFERENCES adherents(id),
            FOREIGN KEY (created_by) REFERENCES users(id)
          )
        ''');
        
        // Créer les index
        await db.execute('CREATE INDEX IF NOT EXISTS idx_adherent_historique_adherent ON adherent_historique(adherent_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_adherent_historique_date ON adherent_historique(date_operation)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_village ON adherents(village)');
      } catch (e) {
        print('Erreur lors de la migration vers la version 2: $e');
      }
    }
    
    if (oldVersion < 3) {
      // Migration vers la version 3 : Ajouter qualite à stock_depots et adherent_id à stock_mouvements
      try {
        await db.execute('ALTER TABLE stock_depots ADD COLUMN qualite TEXT');
        await db.execute('ALTER TABLE stock_mouvements ADD COLUMN adherent_id INTEGER');
        
        // Créer index pour adherent_id dans stock_mouvements
        await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_mouvements_adherent ON stock_mouvements(adherent_id)');
      } catch (e) {
        print('Erreur lors de la migration vers la version 3: $e');
      }
    }
    
    if (oldVersion < 4) {
      // Migration vers la version 4 : Ajouter acheteur, mode_paiement et statut à ventes
      try {
        await db.execute('ALTER TABLE ventes ADD COLUMN acheteur TEXT');
        await db.execute('ALTER TABLE ventes ADD COLUMN mode_paiement TEXT');
        await db.execute('ALTER TABLE ventes ADD COLUMN statut TEXT DEFAULT \'valide\'');
      } catch (e) {
        print('Erreur lors de la migration vers la version 4: $e');
      }
    }
    
    if (oldVersion < 5) {
      // Migration vers la version 5 : Ajouter tables campagnes et barèmes
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS campagnes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL,
            date_debut TEXT NOT NULL,
            date_fin TEXT NOT NULL,
            description TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS baremes_qualite (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            qualite TEXT NOT NULL UNIQUE,
            prix_min REAL,
            prix_max REAL,
            commission_rate REAL,
            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');
        
        await db.execute('CREATE INDEX IF NOT EXISTS idx_campagnes_active ON campagnes(is_active)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_campagnes_dates ON campagnes(date_debut, date_fin)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_baremes_qualite ON baremes_qualite(qualite)');
      } catch (e) {
        print('Erreur lors de la migration vers la version 5: $e');
      }
    }
    
    if (oldVersion < 6) {
      // Migration vers la version 6 : Ajouter table notifications
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            titre TEXT NOT NULL,
            message TEXT NOT NULL,
            module TEXT,
            entity_type TEXT,
            entity_id INTEGER,
            user_id INTEGER,
            is_read INTEGER DEFAULT 0,
            priority TEXT DEFAULT 'normal',
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');
        
        await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at)');
      } catch (e) {
        print('Erreur lors de la migration vers la version 6: $e');
      }
    }
    
    if (oldVersion < 7) {
      // Migration vers la version 7 (V2) : Nouvelles fonctionnalités
      try {
        await V2Migrations.migrateToV7(db);
      } catch (e) {
        print('Erreur lors de la migration vers la version 7 (V2): $e');
        rethrow;
      }
    }
    
    if (oldVersion < 8) {
      // Migration vers la version 8 : Module Adhérents Expert
      try {
        await AdherentExpertMigrations.apply(db, oldVersion, 8);
      } catch (e) {
        print('Erreur lors de la migration vers la version 8 (Adhérents Expert): $e');
        rethrow;
      }
    }
    
    if (oldVersion < 9) {
      // Migration vers la version 9 : Extension complète des champs adhérents
      try {
        await _migrateToV9(db);
      } catch (e) {
        print('Erreur lors de la migration vers la version 9: $e');
        rethrow;
      }
    }
    
    if (oldVersion < 10) {
      // Migration vers la version 10 : Ajout des champs de calcul poids net pour stock_depots
      try {
        print('Exécution de la migration vers la version 10...');
        await _migrateToV10(db);
        print('Migration vers la version 10 terminée avec succès');
      } catch (e, stackTrace) {
        print('Erreur lors de la migration vers la version 10: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    }
    
    if (oldVersion < 11) {
      // Migration vers la version 11 : Ajout des champs humidite et photo_path pour stock_depots
      try {
        print('Exécution de la migration vers la version 11...');
        await _migrateToV11(db);
        print('Migration vers la version 11 terminée avec succès');
      } catch (e, stackTrace) {
        print('Erreur lors de la migration vers la version 11: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    }
  }
  
  /// Migration vers la version 9 : Ajouter tous les champs manquants à la table adherents
  static Future<void> _migrateToV9(Database db) async {
    // Fonction helper pour ajouter une colonne si elle n'existe pas
    Future<void> addColumnIfNotExists(String columnName, String columnDefinition) async {
      try {
        await db.execute('ALTER TABLE adherents ADD COLUMN $columnName $columnDefinition');
      } catch (e) {
        // Ignorer l'erreur si la colonne existe déjà
        if (!e.toString().contains('duplicate column name') && 
            !e.toString().contains('already exists')) {
          print('Avertissement lors de l\'ajout de la colonne $columnName: $e');
        }
      }
    }
    
    // Identification complémentaire
    await addColumnIfNotExists('site_cooperative', 'TEXT');
    await addColumnIfNotExists('section', 'TEXT');
    
    // Identité personnelle complémentaire
    await addColumnIfNotExists('sexe', 'TEXT');
    await addColumnIfNotExists('lieu_naissance', 'TEXT');
    await addColumnIfNotExists('nationalite', 'TEXT');
    await addColumnIfNotExists('type_piece', 'TEXT');
    await addColumnIfNotExists('numero_piece', 'TEXT');
    
    // Situation familiale
    await addColumnIfNotExists('nom_pere', 'TEXT');
    await addColumnIfNotExists('nom_mere', 'TEXT');
    await addColumnIfNotExists('conjoint', 'TEXT');
    await addColumnIfNotExists('nombre_enfants', 'INTEGER DEFAULT 0');
    
    // Indicateurs agricoles
    await addColumnIfNotExists('superficie_totale_cultivee', 'REAL DEFAULT 0.0');
    await addColumnIfNotExists('nombre_champs', 'INTEGER DEFAULT 0');
    await addColumnIfNotExists('rendement_moyen_ha', 'REAL DEFAULT 0.0');
    await addColumnIfNotExists('tonnage_total_produit', 'REAL DEFAULT 0.0');
    await addColumnIfNotExists('tonnage_total_vendu', 'REAL DEFAULT 0.0');
    
    // Créer des index pour les nouveaux champs
    await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_section ON adherents(section)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_site ON adherents(site_cooperative)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_numero_piece ON adherents(numero_piece)');
  }
  
  /// Migration vers la version 10 : Ajouter les champs de calcul poids net à stock_depots
  static Future<void> _migrateToV10(Database db) async {
    // Fonction helper pour ajouter une colonne si elle n'existe pas
    Future<void> addColumnIfNotExists(String columnName, String columnDefinition) async {
      try {
        await db.execute('ALTER TABLE stock_depots ADD COLUMN $columnName $columnDefinition');
        print('Colonne $columnName ajoutée avec succès');
      } catch (e) {
        // Ignorer l'erreur si la colonne existe déjà
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('duplicate column name') || 
            errorStr.contains('already exists') ||
            errorStr.contains('duplicate column')) {
          print('Colonne $columnName existe déjà, ignorée');
        } else {
          print('Erreur lors de l\'ajout de la colonne $columnName: $e');
          rethrow;
        }
      }
    }
    
    print('Ajout des colonnes pour le calcul du poids net...');
    // Ajouter les nouveaux champs pour le calcul du poids net
    await addColumnIfNotExists('stock_brut', 'REAL DEFAULT 0.0');
    await addColumnIfNotExists('poids_sac', 'REAL');
    await addColumnIfNotExists('poids_dechets', 'REAL');
    await addColumnIfNotExists('autres', 'REAL');
    await addColumnIfNotExists('poids_net', 'REAL DEFAULT 0.0');
    
    // Mettre à jour les données existantes : stock_brut = quantite, poids_net = quantite
    try {
      print('Mise à jour des données existantes...');
      await db.execute('''
        UPDATE stock_depots 
        SET stock_brut = COALESCE(stock_brut, quantite), 
            poids_net = COALESCE(poids_net, quantite)
        WHERE stock_brut IS NULL OR poids_net IS NULL
      ''');
      print('Données existantes mises à jour avec succès');
    } catch (e) {
      print('Avertissement lors de la mise à jour des données existantes: $e');
      // Ne pas faire échouer la migration si la mise à jour échoue
    }
  }
  
  /// Vérifier et ajouter les colonnes manquantes pour stock_depots (sécurité supplémentaire)
  static Future<void> _ensureStockDepotsColumns(Database db) async {
    try {
      // Vérifier si les colonnes existent
      final result = await db.rawQuery("PRAGMA table_info(stock_depots)");
      final columnNames = result.map((row) => row['name'] as String).toList();
      
      // Fonction helper pour ajouter une colonne si elle n'existe pas
      Future<void> addColumnIfNotExists(String columnName, String columnDefinition) async {
        if (!columnNames.contains(columnName)) {
          try {
            print('Colonne $columnName manquante, ajout...');
            await db.execute('ALTER TABLE stock_depots ADD COLUMN $columnName $columnDefinition');
            print('Colonne $columnName ajoutée avec succès');
            // Mettre à jour la liste pour éviter les doublons
            columnNames.add(columnName);
          } catch (e) {
            final errorStr = e.toString().toLowerCase();
            if (errorStr.contains('duplicate column name') || 
                errorStr.contains('already exists') ||
                errorStr.contains('duplicate column')) {
              print('Colonne $columnName existe déjà, ignorée');
            } else {
              print('Erreur lors de l\'ajout de la colonne $columnName: $e');
              rethrow;
            }
          }
        }
      }
      
      // Colonnes de la migration V10
      await addColumnIfNotExists('stock_brut', 'REAL DEFAULT 0.0');
      await addColumnIfNotExists('poids_sac', 'REAL');
      await addColumnIfNotExists('poids_dechets', 'REAL');
      await addColumnIfNotExists('autres', 'REAL');
      await addColumnIfNotExists('poids_net', 'REAL DEFAULT 0.0');
      
      // Colonnes de la migration V11
      await addColumnIfNotExists('humidite', 'REAL');
      await addColumnIfNotExists('photo_path', 'TEXT');
      
      // Mettre à jour les données existantes si nécessaire
      try {
        await db.execute('''
          UPDATE stock_depots 
          SET stock_brut = COALESCE(stock_brut, quantite), 
              poids_net = COALESCE(poids_net, quantite)
          WHERE stock_brut IS NULL OR poids_net IS NULL
        ''');
      } catch (e) {
        print('Avertissement lors de la mise à jour des données existantes: $e');
      }
    } catch (e) {
      print('Erreur lors de la vérification des colonnes stock_depots: $e');
      // Ne pas faire échouer l'initialisation si la vérification échoue
    }
  }
  
  /// Migration vers la version 11 : Ajouter les champs humidite et photo_path à stock_depots
  static Future<void> _migrateToV11(Database db) async {
    // Fonction helper pour vérifier si une colonne existe
    Future<bool> columnExists(String tableName, String columnName) async {
      try {
        final result = await db.rawQuery(
          "PRAGMA table_info($tableName)",
        );
        return result.any((column) => column['name'] == columnName);
      } catch (e) {
        print('Erreur lors de la vérification de la colonne $columnName: $e');
        return false;
      }
    }
    
    // Fonction helper pour ajouter une colonne si elle n'existe pas
    Future<void> addColumnIfNotExists(String columnName, String columnDefinition) async {
      try {
        // Vérifier d'abord si la colonne existe
        final exists = await columnExists('stock_depots', columnName);
        if (exists) {
          print('Colonne $columnName existe déjà, ignorée');
          return;
        }
        
        await db.execute('ALTER TABLE stock_depots ADD COLUMN $columnName $columnDefinition');
        print('Colonne $columnName ajoutée avec succès');
      } catch (e) {
        // Ignorer l'erreur si la colonne existe déjà
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('duplicate column name') || 
            errorStr.contains('already exists') ||
            errorStr.contains('duplicate column')) {
          print('Colonne $columnName existe déjà, ignorée');
        } else {
          print('Erreur lors de l\'ajout de la colonne $columnName: $e');
          rethrow;
        }
      }
    }
    
    print('Ajout des colonnes humidite et photo_path...');
    // Ajouter les nouveaux champs
    await addColumnIfNotExists('humidite', 'REAL');
    await addColumnIfNotExists('photo_path', 'TEXT');
    print('Colonnes humidite et photo_path ajoutées avec succès');
  }
  
  /// Vérifier et ajouter les colonnes manquantes (pour les bases existantes)
  static Future<void> ensureColumnsExist() async {
    try {
      final db = await database;
      await _migrateToV11(db);
    } catch (e) {
      print('Erreur lors de la vérification des colonnes: $e');
    }
  }
  
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
