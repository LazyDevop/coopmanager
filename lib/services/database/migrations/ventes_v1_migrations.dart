/// Migrations de base de données pour le Module Ventes V1
/// 
/// Ces migrations ajoutent :
/// - Table vente_lignes (gestion FIFO des stocks)
/// - Table journal_ventes (audit des ventes)
/// - Colonnes obligatoires : campagne_id, client_id, statut_paiement
/// - Index pour performance

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class VentesV1Migrations {
  /// Migrer vers la version 12 (Module Ventes V1)
  static Future<void> migrateToV12(Database db) async {
    try {
      print('🔄 Début de la migration vers V12 (Module Ventes V1)...');
      
      // 1. Étendre la table ventes avec les colonnes V1
      await _extendVentesTableV1(db);
      
      // 2. Créer la table vente_lignes (gestion FIFO)
      await _createVenteLignesTable(db);
      
      // 3. Créer la table journal_ventes (audit)
      await _createJournalVentesTable(db);
      
      // 4. Créer les index pour performance
      await _createIndexesV1(db);
      
      print('✅ Migration vers V12 (Module Ventes V1) réussie');
    } catch (e) {
      print('❌ Erreur lors de la migration vers V12: $e');
      rethrow;
    }
  }

  /// Étendre la table ventes avec les colonnes V1
  static Future<void> _extendVentesTableV1(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(ventes)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      // Ajouter campagne_id si n'existe pas
      if (!columnNames.contains('campagne_id')) {
        await db.execute('ALTER TABLE ventes ADD COLUMN campagne_id INTEGER');
        print('✅ Colonne campagne_id ajoutée à ventes');
      }

      // Ajouter statut_paiement si n'existe pas
      if (!columnNames.contains('statut_paiement')) {
        await db.execute('ALTER TABLE ventes ADD COLUMN statut_paiement TEXT DEFAULT \'non_payee\'');
        print('✅ Colonne statut_paiement ajoutée à ventes');
      }

      // Ajouter montant_commission si n'existe pas
      if (!columnNames.contains('montant_commission')) {
        await db.execute('ALTER TABLE ventes ADD COLUMN montant_commission REAL DEFAULT 0.0');
        print('✅ Colonne montant_commission ajoutée à ventes');
      }

      // Ajouter montant_net si n'existe pas
      if (!columnNames.contains('montant_net')) {
        await db.execute('ALTER TABLE ventes ADD COLUMN montant_net REAL DEFAULT 0.0');
        print('✅ Colonne montant_net ajoutée à ventes');
      }

      // Ajouter facture_pdf_path si n'existe pas
      if (!columnNames.contains('facture_pdf_path')) {
        await db.execute('ALTER TABLE ventes ADD COLUMN facture_pdf_path TEXT');
        print('✅ Colonne facture_pdf_path ajoutée à ventes');
      }

      // Vérifier que client_id existe (déjà ajouté en V7 mais peut être NULL)
      // On ne peut pas rendre client_id NOT NULL car il y a peut-être des ventes existantes sans client
      // Mais on ajoutera une contrainte dans le code applicatif
    } catch (e) {
      print('⚠️ Erreur lors de l\'extension de la table ventes: $e');
      // Continuer même en cas d'erreur (colonnes peut-être déjà présentes)
    }
  }

  /// Créer la table vente_lignes (gestion FIFO des stocks)
  static Future<void> _createVenteLignesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vente_lignes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vente_id INTEGER NOT NULL,
        stock_depot_id INTEGER NOT NULL,
        adherent_id INTEGER NOT NULL,
        quantite REAL NOT NULL,
        prix_unitaire REAL NOT NULL,
        montant REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (vente_id) REFERENCES ventes(id) ON DELETE CASCADE,
        FOREIGN KEY (stock_depot_id) REFERENCES stock_depots(id),
        FOREIGN KEY (adherent_id) REFERENCES adherents(id)
      )
    ''');
    print('✅ Table vente_lignes créée');
  }

  /// Créer la table journal_ventes (audit)
  static Future<void> _createJournalVentesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_ventes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vente_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        ancien_statut TEXT,
        nouveau_statut TEXT,
        ancien_montant REAL,
        nouveau_montant REAL,
        details TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (vente_id) REFERENCES ventes(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');
    print('✅ Table journal_ventes créée');
  }

  /// Créer les index pour améliorer les performances
  static Future<void> _createIndexesV1(Database db) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ventes_campagne ON ventes(campagne_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ventes_client_v1 ON ventes(client_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ventes_statut_paiement ON ventes(statut_paiement)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_vente_lignes_vente ON vente_lignes(vente_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_vente_lignes_stock_depot ON vente_lignes(stock_depot_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_vente_lignes_adherent ON vente_lignes(adherent_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_ventes_vente ON journal_ventes(vente_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_ventes_date ON journal_ventes(created_at)');
      print('✅ Index créés pour Module Ventes V1');
    } catch (e) {
      print('⚠️ Erreur lors de la création des index: $e');
    }
  }
}

