/// Migrations de base de données pour le Module Documents Officiels (V16)
/// 
/// Ces migrations ajoutent :
/// - Table documents (tous les documents officiels)
/// - Table document_types (types de documents configurables)
/// - Table document_numerotation (gestion numérotation séquentielle)
/// - Table document_verifications (historique vérifications QR Code)
/// - Index pour performance et recherche

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DocumentsOfficielsMigrations {
  /// Migrer vers la version 16 (Module Documents Officiels)
  static Future<void> migrateToV16(Database db) async {
    try {
      print('🔄 Début de la migration vers V16 (Module Documents Officiels)...');
      
      // 1. Créer la table document_types
      await _createDocumentTypesTable(db);
      
      // 2. Créer la table documents
      await _createDocumentsTable(db);
      
      // 3. Créer la table document_numerotation
      await _createDocumentNumerotationTable(db);
      
      // 4. Créer la table document_verifications
      await _createDocumentVerificationsTable(db);
      
      // 5. Initialiser les types de documents par défaut
      await _initializeDocumentTypes(db);
      
      // 6. Initialiser les numérotations par défaut
      await _initializeDocumentNumerotation(db);
      
      // 7. Créer les index pour performance
      await _createIndexes(db);
      
      print('✅ Migration vers V16 (Module Documents Officiels) réussie');
    } catch (e) {
      print('❌ Erreur lors de la migration vers V16: $e');
      rethrow;
    }
  }

  /// Créer la table document_types
  static Future<void> _createDocumentTypesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS document_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        libelle TEXT NOT NULL,
        description TEXT,
        prefixe TEXT NOT NULL,
        format TEXT NOT NULL,
        est_actif INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    print('✅ Table document_types créée');
  }

  /// Créer la table documents
  static Future<void> _createDocumentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        campagne_id INTEGER,
        adherent_id INTEGER,
        client_id INTEGER,
        operation_id INTEGER,
        operation_type TEXT NOT NULL,
        contenu TEXT NOT NULL, -- JSON
        pdf_path TEXT NOT NULL,
        qr_code_hash TEXT,
        qr_code_image_path TEXT,
        statut TEXT NOT NULL DEFAULT 'brouillon',
        est_immuable INTEGER DEFAULT 0,
        date_generation TEXT NOT NULL,
        date_annulation TEXT,
        raison_annulation TEXT,
        document_annule_id INTEGER,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_by INTEGER,
        updated_at TEXT,
        nombre_verifications INTEGER DEFAULT 0,
        derniere_verification TEXT,
        FOREIGN KEY (campagne_id) REFERENCES campagnes(id) ON DELETE SET NULL,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE SET NULL,
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES users(id),
        FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
        FOREIGN KEY (document_annule_id) REFERENCES documents(id) ON DELETE SET NULL
      )
    ''');
    print('✅ Table documents créée');
  }

  /// Créer la table document_numerotation
  static Future<void> _createDocumentNumerotationTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS document_numerotation (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_document TEXT NOT NULL,
        campagne_id INTEGER,
        dernier_numero INTEGER NOT NULL DEFAULT 0,
        prefixe TEXT NOT NULL,
        format TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(type_document, campagne_id),
        FOREIGN KEY (campagne_id) REFERENCES campagnes(id) ON DELETE CASCADE
      )
    ''');
    print('✅ Table document_numerotation créée');
  }

  /// Créer la table document_verifications
  static Future<void> _createDocumentVerificationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS document_verifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        hash_verifie TEXT NOT NULL,
        est_valide INTEGER NOT NULL DEFAULT 1,
        date_verification TEXT NOT NULL,
        ip_address TEXT,
        user_agent TEXT,
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');
    print('✅ Table document_verifications créée');
  }

  /// Initialiser les types de documents par défaut
  static Future<void> _initializeDocumentTypes(Database db) async {
    final types = [
      {'code': 'recu_depot', 'libelle': 'Reçu de dépôt', 'prefixe': 'DEP', 'format': 'DEP-{YYYY}-{NUM}'},
      {'code': 'bordereau_pesee', 'libelle': 'Bordereau de pesée', 'prefixe': 'PES', 'format': 'PES-{YYYY}-{NUM}'},
      {'code': 'facture_client', 'libelle': 'Facture client', 'prefixe': 'FAC', 'format': 'FAC-{YYYY}-{NUM}'},
      {'code': 'bon_livraison', 'libelle': 'Bon de livraison', 'prefixe': 'BL', 'format': 'BL-{YYYY}-{NUM}'},
      {'code': 'bordereau_paiement', 'libelle': 'Bordereau de paiement', 'prefixe': 'BPA', 'format': 'BPA-{YYYY}-{NUM}'},
      {'code': 'recu_paiement', 'libelle': 'Reçu de paiement', 'prefixe': 'REC', 'format': 'REC-{YYYY}-{NUM}'},
      {'code': 'etat_compte', 'libelle': 'État de compte', 'prefixe': 'EC', 'format': 'EC-{YYYY}-{NUM}'},
      {'code': 'etat_participation', 'libelle': 'État de participation', 'prefixe': 'EP', 'format': 'EP-{YYYY}-{NUM}'},
      {'code': 'journal_ventes', 'libelle': 'Journal des ventes', 'prefixe': 'JV', 'format': 'JV-{YYYY}-{NUM}'},
      {'code': 'journal_caisse', 'libelle': 'Journal de caisse', 'prefixe': 'JC', 'format': 'JC-{YYYY}-{NUM}'},
      {'code': 'journal_paiements', 'libelle': 'Journal des paiements', 'prefixe': 'JP', 'format': 'JP-{YYYY}-{NUM}'},
      {'code': 'rapport_social', 'libelle': 'Rapport social', 'prefixe': 'RS', 'format': 'RS-{YYYY}-{NUM}'},
    ];

    for (final type in types) {
      try {
        await db.insert('document_types', {
          'code': type['code'],
          'libelle': type['libelle'],
          'prefixe': type['prefixe'],
          'format': type['format'],
          'est_actif': 1,
          'created_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        print('⚠️ Erreur lors de l\'insertion du type ${type['code']}: $e');
      }
    }
    
    print('✅ Types de documents initialisés');
  }

  /// Initialiser les numérotations par défaut
  static Future<void> _initializeDocumentNumerotation(Database db) async {
    final types = [
      'recu_depot', 'bordereau_pesee', 'facture_client', 'bon_livraison',
      'bordereau_paiement', 'recu_paiement', 'etat_compte', 'etat_participation',
      'journal_ventes', 'journal_caisse', 'journal_paiements', 'rapport_social',
    ];

    for (final type in types) {
      try {
        // Récupérer le type pour obtenir le prefixe et format
        final typeResult = await db.query(
          'document_types',
          where: 'code = ?',
          whereArgs: [type],
          limit: 1,
        );
        
        if (typeResult.isNotEmpty) {
          final prefixe = typeResult.first['prefixe'] as String;
          final format = typeResult.first['format'] as String;
          
          await db.insert('document_numerotation', {
            'type_document': type,
            'campagne_id': null, // Numérotation globale
            'dernier_numero': 0,
            'prefixe': prefixe,
            'format': format,
            'updated_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      } catch (e) {
        print('⚠️ Erreur lors de l\'initialisation de la numérotation pour $type: $e');
      }
    }
    
    print('✅ Numérotations initialisées');
  }

  /// Créer les index pour performance
  static Future<void> _createIndexes(Database db) async {
    // Index pour documents
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_type 
      ON documents(type)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_numero 
      ON documents(numero)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_adherent 
      ON documents(adherent_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_client 
      ON documents(client_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_operation 
      ON documents(operation_type, operation_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_date 
      ON documents(date_generation)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_statut 
      ON documents(statut)
    ''');

    // Index pour document_numerotation
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_numerotation_type 
      ON document_numerotation(type_document)
    ''');

    // Index pour document_verifications
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_verifications_document 
      ON document_verifications(document_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_verifications_date 
      ON document_verifications(date_verification)
    ''');

    print('✅ Index créés');
  }
}

