/// Migration pour l'intégration Adhérents ↔ Ventes
/// 
/// Crée la table pivot vente_adherents et ajoute les colonnes nécessaires
/// pour une traçabilité complète

import 'package:sqflite_common/sqlite_api.dart';

class AdherentVenteIntegrationMigrations {
  /// Migration vers la version 14
  /// 
  /// Ajoute :
  /// - Table vente_adherents (pivot)
  /// - Colonnes de commission différenciée dans coop_settings
  /// - Index pour performance
  static Future<void> migrateToV14(Database db) async {
    // 1. Créer la table pivot vente_adherents
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vente_adherents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vente_id INTEGER NOT NULL,
        adherent_id INTEGER NOT NULL,
        poids_utilise REAL NOT NULL,
        prix_kg REAL NOT NULL,
        montant_brut REAL NOT NULL,
        commission_rate REAL NOT NULL,
        commission_amount REAL NOT NULL,
        montant_net REAL NOT NULL,
        campagne_id INTEGER,
        qualite TEXT,
        created_at TEXT NOT NULL,
        created_by INTEGER,
        FOREIGN KEY (vente_id) REFERENCES ventes(id) ON DELETE CASCADE,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id),
        FOREIGN KEY (campagne_id) REFERENCES campagnes(id),
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');

    // 2. Créer les index pour performance
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_vente_adherents_vente_id 
      ON vente_adherents(vente_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_vente_adherents_adherent_id 
      ON vente_adherents(adherent_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_vente_adherents_campagne_id 
      ON vente_adherents(campagne_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_vente_adherents_created_at 
      ON vente_adherents(created_at)
    ''');

    // 3. Ajouter les colonnes de commission différenciée dans coop_settings
    try {
      await db.execute('''
        ALTER TABLE coop_settings 
        ADD COLUMN commission_rate_actionnaire REAL
      ''');
    } catch (e) {
      // Colonne peut déjà exister
      print('Note: commission_rate_actionnaire peut déjà exister: $e');
    }

    try {
      await db.execute('''
        ALTER TABLE coop_settings 
        ADD COLUMN commission_rate_producteur REAL
      ''');
    } catch (e) {
      // Colonne peut déjà exister
      print('Note: commission_rate_producteur peut déjà exister: $e');
    }

    // 4. Migrer les données existantes de vente_details vers vente_adherents
    // (pour compatibilité avec les ventes existantes)
    try {
      await db.execute('''
        INSERT INTO vente_adherents (
          vente_id,
          adherent_id,
          poids_utilise,
          prix_kg,
          montant_brut,
          commission_rate,
          commission_amount,
          montant_net,
          created_at,
          created_by
        )
        SELECT 
          vd.vente_id,
          vd.adherent_id,
          vd.quantite as poids_utilise,
          vd.prix_unitaire as prix_kg,
          vd.montant as montant_brut,
          COALESCE(
            (SELECT commission_rate FROM recettes WHERE vente_id = vd.vente_id AND adherent_id = vd.adherent_id LIMIT 1),
            0.05
          ) as commission_rate,
          COALESCE(
            (SELECT commission_amount FROM recettes WHERE vente_id = vd.vente_id AND adherent_id = vd.adherent_id LIMIT 1),
            vd.montant * 0.05
          ) as commission_amount,
          COALESCE(
            (SELECT montant_net FROM recettes WHERE vente_id = vd.vente_id AND adherent_id = vd.adherent_id LIMIT 1),
            vd.montant * 0.95
          ) as montant_net,
          COALESCE(
            (SELECT created_at FROM ventes WHERE id = vd.vente_id),
            datetime('now')
          ) as created_at,
          (SELECT created_by FROM ventes WHERE id = vd.vente_id) as created_by
        FROM vente_details vd
        WHERE NOT EXISTS (
          SELECT 1 FROM vente_adherents va 
          WHERE va.vente_id = vd.vente_id 
          AND va.adherent_id = vd.adherent_id
        )
      ''');
    } catch (e) {
      print('Note: Migration des données vente_details peut avoir échoué (normal si table vide): $e');
    }

    // 5. Migrer aussi les ventes individuelles
    try {
      await db.execute('''
        INSERT INTO vente_adherents (
          vente_id,
          adherent_id,
          poids_utilise,
          prix_kg,
          montant_brut,
          commission_rate,
          commission_amount,
          montant_net,
          campagne_id,
          created_at,
          created_by
        )
        SELECT 
          v.id as vente_id,
          v.adherent_id,
          v.quantite_total as poids_utilise,
          v.prix_unitaire as prix_kg,
          v.montant_total as montant_brut,
          COALESCE(
            (SELECT commission_rate FROM recettes WHERE vente_id = v.id LIMIT 1),
            0.05
          ) as commission_rate,
          COALESCE(
            (SELECT commission_amount FROM recettes WHERE vente_id = v.id LIMIT 1),
            v.montant_total * 0.05
          ) as commission_amount,
          COALESCE(
            (SELECT montant_net FROM recettes WHERE vente_id = v.id LIMIT 1),
            v.montant_total * 0.95
          ) as montant_net,
          v.campagne_id,
          v.created_at,
          v.created_by
        FROM ventes v
        WHERE v.type = 'individuelle'
        AND v.adherent_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM vente_adherents va 
          WHERE va.vente_id = v.id
        )
      ''');
    } catch (e) {
      print('Note: Migration des ventes individuelles peut avoir échoué: $e');
    }
  }
}

