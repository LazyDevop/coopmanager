/// Migrations de base de données pour la version 2.0
/// 
/// Ces migrations ajoutent :
/// - Gestion des clients
/// - Catégorisation des adhérents
/// - Capital social et parts
/// - Comptabilité simplifiée
/// - Module social
/// - Sécurité documentaire (QR Code)

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class V2Migrations {
  /// Migrer de la version 6 vers la version 7 (V2)
  static Future<void> migrateToV7(Database db) async {
    try {
      // 1. Créer la table clients
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          nom TEXT NOT NULL,
          type TEXT NOT NULL,
          telephone TEXT,
          email TEXT,
          adresse TEXT,
          ville TEXT,
          pays TEXT DEFAULT 'Cameroun',
          siret TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 2. Créer la table adherent_categories
      await db.execute('''
        CREATE TABLE IF NOT EXISTS adherent_categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          adherent_id INTEGER NOT NULL,
          categorie TEXT NOT NULL,
          date_debut TEXT NOT NULL,
          date_fin TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (adherent_id) REFERENCES adherents(id)
        )
      ''');

      // 3. Créer la table parts_sociales
      await db.execute('''
        CREATE TABLE IF NOT EXISTS parts_sociales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          adherent_id INTEGER NOT NULL,
          nombre_parts INTEGER NOT NULL,
          valeur_unitaire REAL NOT NULL,
          date_acquisition TEXT NOT NULL,
          date_cession TEXT,
          statut TEXT DEFAULT 'actif',
          created_by INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (adherent_id) REFERENCES adherents(id),
          FOREIGN KEY (created_by) REFERENCES users(id)
        )
      ''');

      // 4. Créer la table ecritures_comptables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ecritures_comptables (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          numero TEXT UNIQUE NOT NULL,
          date_ecriture TEXT NOT NULL,
          type_operation TEXT NOT NULL,
          operation_id INTEGER,
          compte_debit TEXT NOT NULL,
          compte_credit TEXT NOT NULL,
          montant REAL NOT NULL,
          libelle TEXT NOT NULL,
          reference TEXT,
          is_valide INTEGER DEFAULT 1,
          created_by INTEGER,
          created_at TEXT NOT NULL,
          FOREIGN KEY (created_by) REFERENCES users(id)
        )
      ''');

      // 5. Créer la table aides_sociales
      await db.execute('''
        CREATE TABLE IF NOT EXISTS aides_sociales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          adherent_id INTEGER NOT NULL,
          type_aide TEXT NOT NULL,
          montant REAL NOT NULL,
          date_aide TEXT NOT NULL,
          description TEXT NOT NULL,
          statut TEXT DEFAULT 'en_attente',
          approuve_par INTEGER,
          date_approbation TEXT,
          notes TEXT,
          created_by INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (adherent_id) REFERENCES adherents(id),
          FOREIGN KEY (approuve_par) REFERENCES users(id),
          FOREIGN KEY (created_by) REFERENCES users(id)
        )
      ''');

      // 6. Créer la table documents_securises
      await db.execute('''
        CREATE TABLE IF NOT EXISTS documents_securises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          document_type TEXT NOT NULL,
          document_id INTEGER NOT NULL,
          qr_code_data TEXT NOT NULL,
          hash_verification TEXT NOT NULL,
          qr_code_image_path TEXT,
          date_generation TEXT NOT NULL,
          created_by INTEGER,
          FOREIGN KEY (created_by) REFERENCES users(id)
        )
      ''');

      // 7. Étendre la table adherents
      await _extendAdherentsTable(db);

      // 8. Étendre la table ventes
      await _extendVentesTable(db);

      // 9. Étendre la table recettes
      await _extendRecettesTable(db);

      // 10. Étendre la table factures
      await _extendFacturesTable(db);

      // 11. Créer les index pour performance
      await _createIndexes(db);

      // 12. Migrer les données existantes
      await _migrateExistingData(db);

      print('✅ Migration vers V7 (V2) réussie');
    } catch (e) {
      print('❌ Erreur lors de la migration vers V7: $e');
      rethrow;
    }
  }

  /// Étendre la table adherents
  static Future<void> _extendAdherentsTable(Database db) async {
    try {
      // Vérifier si les colonnes existent déjà
      final columns = await db.rawQuery('PRAGMA table_info(adherents)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      if (!columnNames.contains('categorie')) {
        await db.execute('ALTER TABLE adherents ADD COLUMN categorie TEXT DEFAULT \'producteur\'');
      }
      if (!columnNames.contains('statut')) {
        await db.execute('ALTER TABLE adherents ADD COLUMN statut TEXT DEFAULT \'actif\'');
      }
      if (!columnNames.contains('date_statut')) {
        await db.execute('ALTER TABLE adherents ADD COLUMN date_statut TEXT');
      }
    } catch (e) {
      print('Erreur lors de l\'extension de la table adherents: $e');
      // Continuer même en cas d'erreur (colonnes peut-être déjà présentes)
    }
  }

  /// Étendre la table ventes
  static Future<void> _extendVentesTable(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(ventes)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      if (!columnNames.contains('client_id')) {
        await db.execute('ALTER TABLE ventes ADD COLUMN client_id INTEGER');
      }
      if (!columnNames.contains('ecriture_comptable_id')) {
        await db.execute('ALTER TABLE ventes ADD COLUMN ecriture_comptable_id INTEGER');
      }
      if (!columnNames.contains('qr_code_hash')) {
        await db.execute('ALTER TABLE ventes ADD COLUMN qr_code_hash TEXT');
      }
    } catch (e) {
      print('Erreur lors de l\'extension de la table ventes: $e');
    }
  }

  /// Étendre la table recettes
  static Future<void> _extendRecettesTable(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(recettes)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      if (!columnNames.contains('ecriture_comptable_id')) {
        await db.execute('ALTER TABLE recettes ADD COLUMN ecriture_comptable_id INTEGER');
      }
      if (!columnNames.contains('qr_code_hash')) {
        await db.execute('ALTER TABLE recettes ADD COLUMN qr_code_hash TEXT');
      }
    } catch (e) {
      print('Erreur lors de l\'extension de la table recettes: $e');
    }
  }

  /// Étendre la table factures
  static Future<void> _extendFacturesTable(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(factures)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      if (!columnNames.contains('qr_code_hash')) {
        await db.execute('ALTER TABLE factures ADD COLUMN qr_code_hash TEXT');
      }
      if (!columnNames.contains('document_securise_id')) {
        await db.execute('ALTER TABLE factures ADD COLUMN document_securise_id INTEGER');
      }
    } catch (e) {
      print('Erreur lors de l\'extension de la table factures: $e');
    }
  }

  /// Créer les index pour améliorer les performances
  static Future<void> _createIndexes(Database db) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_clients_code ON clients(code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_clients_type ON clients(type)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_clients_active ON clients(is_active)');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_adherent_categories_adherent ON adherent_categories(adherent_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_adherent_categories_categorie ON adherent_categories(categorie)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_adherent_categories_active ON adherent_categories(is_active)');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_parts_sociales_adherent ON parts_sociales(adherent_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_parts_sociales_statut ON parts_sociales(statut)');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ecritures_comptables_numero ON ecritures_comptables(numero)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ecritures_comptables_date ON ecritures_comptables(date_ecriture)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ecritures_comptables_type ON ecritures_comptables(type_operation)');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_aides_sociales_adherent ON aides_sociales(adherent_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_aides_sociales_statut ON aides_sociales(statut)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_aides_sociales_type ON aides_sociales(type_aide)');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_documents_securises_type ON documents_securises(document_type)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_documents_securises_document ON documents_securises(document_type, document_id)');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ventes_client ON ventes(client_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_recettes_ecriture ON recettes(ecriture_comptable_id)');
    } catch (e) {
      print('Erreur lors de la création des index: $e');
    }
  }

  /// Migrer les données existantes
  static Future<void> _migrateExistingData(Database db) async {
    try {
      // Mettre à jour tous les adhérents existants avec la catégorie par défaut
      await db.execute('''
        UPDATE adherents 
        SET categorie = 'producteur', statut = 'actif'
        WHERE categorie IS NULL OR statut IS NULL
      ''');

      // Créer les catégories historiques pour les adhérents existants
      final adherents = await db.query('adherents');
      for (final adherent in adherents) {
        final adherentId = adherent['id'] as int;
        final dateAdhesion = adherent['date_adhesion'] as String;
        
        // Vérifier si une catégorie existe déjà
        final existing = await db.query(
          'adherent_categories',
          where: 'adherent_id = ? AND is_active = 1',
          whereArgs: [adherentId],
        );
        
        if (existing.isEmpty) {
          await db.insert('adherent_categories', {
            'adherent_id': adherentId,
            'categorie': 'producteur',
            'date_debut': dateAdhesion,
            'is_active': 1,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      print('✅ Migration des données existantes réussie');
    } catch (e) {
      print('Erreur lors de la migration des données: $e');
      // Ne pas faire échouer la migration pour cette étape
    }
  }
}

