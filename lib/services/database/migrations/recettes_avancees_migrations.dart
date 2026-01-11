/// Migrations de base de données pour le Module Recettes Avancé (V15)
/// 
/// Ces migrations ajoutent :
/// - Table comptes_adherents (compte financier par adhérent)
/// - Table paiements (paiements partiels/totaux)
/// - Table retenues_sociales (retenues pour crédit, aide sociale, etc.)
/// - Table journal_financier (journalisation des opérations financières)
/// - Table timeline_events (chronologie des événements)
/// - Colonnes supplémentaires dans recettes (campagne_id, qr_code_hash amélioré)
/// - Index pour performance

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class RecettesAvanceesMigrations {
  /// Migrer vers la version 15 (Module Recettes Avancé)
  static Future<void> migrateToV15(Database db) async {
    try {
      print('🔄 Début de la migration vers V15 (Module Recettes Avancé)...');
      
      // 1. Créer la table comptes_adherents
      await _createComptesAdherentsTable(db);
      
      // 2. Créer la table paiements
      await _createPaiementsTable(db);
      
      // 3. Créer la table retenues_sociales
      await _createRetenuesSocialesTable(db);
      
      // 4. Créer la table journal_financier
      await _createJournalFinancierTable(db);
      
      // 5. Créer la table timeline_events
      await _createTimelineEventsTable(db);
      
      // 6. Étendre la table recettes avec campagne_id si nécessaire
      await _extendRecettesTable(db);
      
      // 7. Créer les index pour performance
      await _createIndexes(db);
      
      // 8. Initialiser les comptes pour les adhérents existants
      await _initializeComptesForExistingAdherents(db);
      
      print('✅ Migration vers V15 (Module Recettes Avancé) réussie');
    } catch (e) {
      print('❌ Erreur lors de la migration vers V15: $e');
      rethrow;
    }
  }

  /// Créer la table comptes_adherents
  static Future<void> _createComptesAdherentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS comptes_adherents (
        adherent_id INTEGER PRIMARY KEY,
        solde_total REAL DEFAULT 0.0,
        total_recettes_generees REAL DEFAULT 0.0,
        total_paye REAL DEFAULT 0.0,
        total_en_attente REAL DEFAULT 0.0,
        total_retenues_sociales REAL DEFAULT 0.0,
        solde_par_campagne TEXT, -- JSON: {campagne_id: solde}
        date_derniere_recette TEXT,
        date_dernier_paiement TEXT,
        date_derniere_retenue TEXT,
        nombre_recettes INTEGER DEFAULT 0,
        nombre_paiements INTEGER DEFAULT 0,
        nombre_retenues INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE
      )
    ''');
    print('✅ Table comptes_adherents créée');
  }

  /// Créer la table paiements
  static Future<void> _createPaiementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS paiements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        recette_id INTEGER,
        montant REAL NOT NULL,
        date_paiement TEXT NOT NULL,
        mode_paiement TEXT NOT NULL,
        numero_cheque TEXT,
        reference_virement TEXT,
        notes TEXT,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        qr_code_hash TEXT,
        pdf_recu_path TEXT,
        ecriture_comptable_id INTEGER,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
        FOREIGN KEY (recette_id) REFERENCES recettes(id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES users(id),
        FOREIGN KEY (ecriture_comptable_id) REFERENCES ecritures_comptables(id) ON DELETE SET NULL
      )
    ''');
    print('✅ Table paiements créée');
  }

  /// Créer la table retenues_sociales
  static Future<void> _createRetenuesSocialesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS retenues_sociales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        recette_id INTEGER,
        type TEXT NOT NULL,
        montant REAL NOT NULL,
        date_retenue TEXT NOT NULL,
        justification TEXT,
        est_volontaire INTEGER DEFAULT 0,
        est_consentement INTEGER DEFAULT 0,
        notes TEXT,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        campagne_id INTEGER,
        qr_code_hash TEXT,
        ecriture_comptable_id INTEGER,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
        FOREIGN KEY (recette_id) REFERENCES recettes(id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES users(id),
        FOREIGN KEY (campagne_id) REFERENCES campagnes(id) ON DELETE SET NULL,
        FOREIGN KEY (ecriture_comptable_id) REFERENCES ecritures_comptables(id) ON DELETE SET NULL
      )
    ''');
    print('✅ Table retenues_sociales créée');
  }

  /// Créer la table journal_financier
  static Future<void> _createJournalFinancierTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_financier (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        type_operation TEXT NOT NULL,
        operation_id INTEGER,
        operation_type TEXT NOT NULL, -- 'recette', 'paiement', 'retenue'
        montant REAL NOT NULL,
        solde_avant REAL NOT NULL,
        solde_apres REAL NOT NULL,
        description TEXT NOT NULL,
        date_operation TEXT NOT NULL,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');
    print('✅ Table journal_financier créée');
  }

  /// Créer la table timeline_events
  static Future<void> _createTimelineEventsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS timeline_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        operation_id INTEGER,
        titre TEXT NOT NULL,
        description TEXT NOT NULL,
        montant REAL,
        date_evenement TEXT NOT NULL,
        document_path TEXT,
        qr_code_hash TEXT,
        metadata TEXT, -- JSON
        created_at TEXT NOT NULL,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE
      )
    ''');
    print('✅ Table timeline_events créée');
  }

  /// Étendre la table recettes avec campagne_id si nécessaire
  static Future<void> _extendRecettesTable(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(recettes)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      // Ajouter campagne_id si n'existe pas
      if (!columnNames.contains('campagne_id')) {
        await db.execute('ALTER TABLE recettes ADD COLUMN campagne_id INTEGER');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_recettes_campagne 
          ON recettes(campagne_id)
        ''');
        print('✅ Colonne campagne_id ajoutée à recettes');
      }

      // Améliorer qr_code_hash si nécessaire (déjà présent en V2 mais vérifier)
      if (!columnNames.contains('qr_code_hash')) {
        await db.execute('ALTER TABLE recettes ADD COLUMN qr_code_hash TEXT');
        print('✅ Colonne qr_code_hash ajoutée à recettes');
      }
    } catch (e) {
      print('⚠️ Erreur lors de l\'extension de la table recettes: $e');
    }
  }

  /// Créer les index pour performance
  static Future<void> _createIndexes(Database db) async {
    // Index pour paiements
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_paiements_adherent 
      ON paiements(adherent_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_paiements_recette 
      ON paiements(recette_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_paiements_date 
      ON paiements(date_paiement)
    ''');

    // Index pour retenues_sociales
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_retenues_adherent 
      ON retenues_sociales(adherent_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_retenues_recette 
      ON retenues_sociales(recette_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_retenues_campagne 
      ON retenues_sociales(campagne_id)
    ''');

    // Index pour journal_financier
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_journal_adherent 
      ON journal_financier(adherent_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_journal_date 
      ON journal_financier(date_operation)
    ''');

    // Index pour timeline_events
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_timeline_adherent 
      ON timeline_events(adherent_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_timeline_date 
      ON timeline_events(date_evenement)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_timeline_type 
      ON timeline_events(type)
    ''');

    print('✅ Index créés');
  }

  /// Initialiser les comptes pour les adhérents existants
  static Future<void> _initializeComptesForExistingAdherents(Database db) async {
    try {
      // Récupérer tous les adhérents actifs
      final adherents = await db.query('adherents', where: 'is_active = 1');
      
      for (final adherent in adherents) {
        final adherentId = adherent['id'] as int;
        
        // Calculer les totaux depuis les recettes existantes
        final recettesResult = await db.rawQuery('''
          SELECT 
            COALESCE(SUM(montant_net), 0) as total_recettes,
            COUNT(*) as nombre_recettes,
            MAX(date_recette) as derniere_recette
          FROM recettes
          WHERE adherent_id = ?
        ''', [adherentId]);
        
        final totalRecettes = (recettesResult.first['total_recettes'] as num?)?.toDouble() ?? 0.0;
        final nombreRecettes = recettesResult.first['nombre_recettes'] as int? ?? 0;
        final derniereRecette = recettesResult.first['derniere_recette'] as String?;
        
        // Calculer les paiements
        final paiementsResult = await db.rawQuery('''
          SELECT 
            COALESCE(SUM(montant), 0) as total_paye,
            COUNT(*) as nombre_paiements,
            MAX(date_paiement) as dernier_paiement
          FROM paiements
          WHERE adherent_id = ?
        ''', [adherentId]);
        
        final totalPaye = (paiementsResult.first['total_paye'] as num?)?.toDouble() ?? 0.0;
        final nombrePaiements = paiementsResult.first['nombre_paiements'] as int? ?? 0;
        final dernierPaiement = paiementsResult.first['dernier_paiement'] as String?;
        
        // Calculer les retenues
        final retenuesResult = await db.rawQuery('''
          SELECT 
            COALESCE(SUM(montant), 0) as total_retenues,
            COUNT(*) as nombre_retenues,
            MAX(date_retenue) as derniere_retenue
          FROM retenues_sociales
          WHERE adherent_id = ?
        ''', [adherentId]);
        
        final totalRetenues = (retenuesResult.first['total_retenues'] as num?)?.toDouble() ?? 0.0;
        final nombreRetenues = retenuesResult.first['nombre_retenues'] as int? ?? 0;
        final derniereRetenue = retenuesResult.first['derniere_retenue'] as String?;
        
        // Calculer le solde
        final soldeTotal = totalRecettes - totalPaye - totalRetenues;
        final totalEnAttente = totalRecettes - totalPaye;
        
        // Insérer ou mettre à jour le compte
        await db.insert('comptes_adherents', {
          'adherent_id': adherentId,
          'solde_total': soldeTotal,
          'total_recettes_generees': totalRecettes,
          'total_paye': totalPaye,
          'total_en_attente': totalEnAttente,
          'total_retenues_sociales': totalRetenues,
          'date_derniere_recette': derniereRecette,
          'date_dernier_paiement': dernierPaiement,
          'date_derniere_retenue': derniereRetenue,
          'nombre_recettes': nombreRecettes,
          'nombre_paiements': nombrePaiements,
          'nombre_retenues': nombreRetenues,
          'updated_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      print('✅ Comptes initialisés pour les adhérents existants');
    } catch (e) {
      print('⚠️ Erreur lors de l\'initialisation des comptes: $e');
      // Ne pas faire échouer la migration si l'initialisation échoue
    }
  }
}

