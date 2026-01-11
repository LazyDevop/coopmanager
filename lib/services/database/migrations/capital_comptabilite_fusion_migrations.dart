import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration pour la fusion Capital Social + Comptabilité Simplifiée
class CapitalComptabiliteFusionMigrations {
  /// Migration vers la version 18 : Fusion Capital + Comptabilité
  static Future<void> migrateToV18(Database db) async {
    print('Exécution de la migration vers la version 18 (Fusion Capital + Comptabilité)...');
    
    try {
      // 1. Table journal_comptable (journal unifié)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS journal_comptable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date_operation TEXT NOT NULL,
          type_journal TEXT NOT NULL,
          reference TEXT NOT NULL,
          libelle TEXT NOT NULL,
          debit REAL NOT NULL DEFAULT 0.0,
          credit REAL NOT NULL DEFAULT 0.0,
          solde_apres REAL NOT NULL DEFAULT 0.0,
          source_module TEXT NOT NULL,
          source_id INTEGER,
          created_by INTEGER,
          created_at TEXT NOT NULL,
          FOREIGN KEY (created_by) REFERENCES users(id)
        )
      ''');
      
      // 2. Table comptes_comptables (plan de comptes simplifié)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS comptes_comptables (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code_compte TEXT UNIQUE NOT NULL,
          libelle TEXT NOT NULL,
          type TEXT NOT NULL,
          solde REAL NOT NULL DEFAULT 0.0
        )
      ''');
      
      // 3. Table ecritures_capital (liaison capital-comptabilité)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ecritures_capital (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          actionnaire_id INTEGER NOT NULL,
          type_operation TEXT NOT NULL,
          montant REAL NOT NULL,
          compte_debit TEXT NOT NULL,
          compte_credit TEXT NOT NULL,
          journal_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          reference TEXT,
          notes TEXT,
          created_by INTEGER,
          created_at TEXT NOT NULL,
          FOREIGN KEY (actionnaire_id) REFERENCES adherents(id),
          FOREIGN KEY (journal_id) REFERENCES journal_comptable(id),
          FOREIGN KEY (created_by) REFERENCES users(id)
        )
      ''');
      
      // 4. Table tresorerie (suivi trésorerie)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tresorerie (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          solde_initial REAL NOT NULL DEFAULT 0.0,
          solde_actuel REAL NOT NULL DEFAULT 0.0,
          date_reference TEXT NOT NULL,
          periode TEXT,
          updated_at TEXT
        )
      ''');
      
      // Créer les index pour améliorer les performances
      await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_date ON journal_comptable(date_operation)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_type ON journal_comptable(type_journal)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_source ON journal_comptable(source_module, source_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_comptes_code ON comptes_comptables(code_compte)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ecritures_capital_actionnaire ON ecritures_capital(actionnaire_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ecritures_capital_journal ON ecritures_capital(journal_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tresorerie_date ON tresorerie(date_reference)');
      
      // Initialiser les comptes comptables de base
      await _initializeComptesComptables(db);
      
      // Initialiser la trésorerie
      await _initializeTresorerie(db);
      
      print('Migration vers la version 18 terminée avec succès');
    } catch (e, stackTrace) {
      print('Erreur lors de la migration vers la version 18: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Initialiser les comptes comptables de base
  static Future<void> _initializeComptesComptables(Database db) async {
    final comptes = [
      // Classe 1 - Financement
      {'code': '1011', 'libelle': 'Capital souscrit', 'type': 'Passif'},
      {'code': '1012', 'libelle': 'Capital libéré', 'type': 'Passif'},
      {'code': '106', 'libelle': 'Réserves', 'type': 'Passif'},
      {'code': '107', 'libelle': 'Fonds social', 'type': 'Passif'},
      
      // Classe 2 - Immobilisations
      {'code': '200', 'libelle': 'Immobilisations', 'type': 'Actif'},
      
      // Classe 3 - Stocks
      {'code': '310', 'libelle': 'Stock cacao', 'type': 'Actif'},
      
      // Classe 4 - Tiers
      {'code': '411', 'libelle': 'Clients', 'type': 'Actif'},
      {'code': '412', 'libelle': 'Adhérents', 'type': 'Actif'},
      {'code': '413', 'libelle': 'Actionnaires', 'type': 'Actif'},
      
      // Classe 5 - Trésorerie
      {'code': '530', 'libelle': 'Caisse', 'type': 'Actif'},
      {'code': '512', 'libelle': 'Banque', 'type': 'Actif'},
      
      // Classe 6 - Charges
      {'code': '600', 'libelle': 'Achats', 'type': 'Charge'},
      {'code': '650', 'libelle': 'Aides sociales', 'type': 'Charge'},
      {'code': '651', 'libelle': 'Charges sociales', 'type': 'Charge'},
      
      // Classe 7 - Produits
      {'code': '700', 'libelle': 'Ventes', 'type': 'Produit'},
      {'code': '706', 'libelle': 'Commissions', 'type': 'Produit'},
    ];
    
    for (final compte in comptes) {
      try {
        await db.insert(
          'comptes_comptables',
          {
            'code_compte': compte['code'],
            'libelle': compte['libelle'],
            'type': compte['type'],
            'solde': 0.0,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        // Ignorer si le compte existe déjà
        print('Compte ${compte['code']} existe déjà ou erreur: $e');
      }
    }
  }
  
  /// Initialiser la trésorerie
  static Future<void> _initializeTresorerie(Database db) async {
    try {
      final result = await db.query('tresorerie', limit: 1);
      if (result.isEmpty) {
        await db.insert('tresorerie', {
          'solde_initial': 0.0,
          'solde_actuel': 0.0,
          'date_reference': DateTime.now().toIso8601String(),
          'periode': 'Mois',
        });
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation de la trésorerie: $e');
    }
  }
}

