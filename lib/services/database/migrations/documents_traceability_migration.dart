/// Migration pour la table de traçabilité des documents générés
/// Version: Ajoutée dans la prochaine version de la base de données

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DocumentsTraceabilityMigration {
  /// Créer la table documents pour la traçabilité
  static Future<void> createDocumentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        reference TEXT NOT NULL UNIQUE,
        cooperative_id INTEGER NOT NULL,
        hash TEXT NOT NULL,
        generated_at TEXT NOT NULL,
        generated_by INTEGER NOT NULL,
        file_path TEXT,
        metadata TEXT, -- JSON string
        qr_code_data TEXT, -- JSON string
        is_verified INTEGER DEFAULT 0,
        verified_at TEXT,
        verified_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id),
        FOREIGN KEY (generated_by) REFERENCES users(id),
        FOREIGN KEY (verified_by) REFERENCES users(id)
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_type 
      ON documents(type)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_reference 
      ON documents(reference)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_cooperative 
      ON documents(cooperative_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_generated_at 
      ON documents(generated_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_hash 
      ON documents(hash)
    ''');
  }

  /// Migrer vers cette version
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await createDocumentsTable(db);
    }
  }
}

