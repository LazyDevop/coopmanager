/// MIGRATIONS BASE DE DONNÉES - MODULE ADHÉRENTS EXPERT
/// 
/// Ce fichier contient toutes les migrations SQL pour créer les tables
/// du module Adhérents avec TOUS les champs définis dans la conception

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AdherentExpertMigrations {
  /// Version de la base de données pour ce module
  static const int version = 8; // Incrémenter depuis la version 7 (V2)
  
  /// Appliquer toutes les migrations du module Adhérents Expert
  static Future<void> apply(Database db, int oldVersion, int newVersion) async {
    if (newVersion >= version) {
      await _createAdherentsTable(db);
      await _createAyantsDroitTable(db);
      await _createChampsTable(db);
      await _createTraitementsTable(db);
      await _createProductionsTable(db);
      await _createStocksTable(db);
      await _createVentesTable(db);
      await _createParametragePrixTable(db);
      await _createJournalPaieTable(db);
      await _createCapitalSocialTable(db);
      await _createSocialCreditsTable(db);
      await _createIndexes(db);
    }
  }
  
  /// Créer la table ADHERENTS avec TOUS les champs
  static Future<void> _createAdherentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS adherents_expert (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        
        -- SECTION 1 : IDENTIFICATION
        code_adherent TEXT UNIQUE NOT NULL,
        type_personne TEXT NOT NULL DEFAULT 'producteur',
        statut TEXT NOT NULL DEFAULT 'actif',
        date_adhesion TEXT NOT NULL,
        site_cooperative TEXT,
        section TEXT,
        village TEXT,
        
        -- SECTION 2 : IDENTITÉ PERSONNELLE
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        sexe TEXT,
        date_naissance TEXT,
        lieu_naissance TEXT,
        nationalite TEXT DEFAULT 'Camerounais',
        type_piece TEXT,
        numero_piece TEXT UNIQUE,
        telephone TEXT,
        telephone_secondaire TEXT,
        email TEXT,
        adresse TEXT,
        code_postal TEXT,
        
        -- SECTION 3 : SITUATION FAMILIALE
        nom_pere TEXT,
        nom_mere TEXT,
        conjoint TEXT,
        nombre_enfants INTEGER DEFAULT 0,
        situation_matrimoniale TEXT,
        
        -- SECTION 4 : INDICATEURS AGRICOLES (calculés automatiquement)
        superficie_totale_cultivee REAL DEFAULT 0.0,
        nombre_champs INTEGER DEFAULT 0,
        rendement_moyen_ha REAL DEFAULT 0.0,
        tonnage_total_produit REAL DEFAULT 0.0,
        tonnage_total_vendu REAL DEFAULT 0.0,
        tonnage_disponible_stock REAL DEFAULT 0.0,
        
        -- SECTION 5 : INDICATEURS FINANCIERS (calculés automatiquement)
        capital_social_souscrit REAL DEFAULT 0.0,
        capital_social_libere REAL DEFAULT 0.0,
        capital_social_restant REAL DEFAULT 0.0,
        montant_total_ventes REAL DEFAULT 0.0,
        montant_total_paye REAL DEFAULT 0.0,
        solde_crediteur REAL DEFAULT 0.0,
        solde_debiteur REAL DEFAULT 0.0,
        
        -- SECTION 6 : MÉTADONNÉES
        created_at TEXT NOT NULL,
        updated_at TEXT,
        created_by INTEGER,
        updated_by INTEGER,
        photo_path TEXT,
        notes TEXT,
        is_deleted INTEGER DEFAULT 0,
        deleted_at TEXT,
        
        FOREIGN KEY (created_by) REFERENCES users(id),
        FOREIGN KEY (updated_by) REFERENCES users(id),
        
        CHECK (type_personne IN ('producteur', 'adherent', 'adherent_actionnaire')),
        CHECK (statut IN ('actif', 'suspendu', 'radie')),
        CHECK (sexe IN ('M', 'F', 'Autre') OR sexe IS NULL),
        CHECK (superficie_totale_cultivee >= 0),
        CHECK (nombre_champs >= 0),
        CHECK (tonnage_total_produit >= 0),
        CHECK (tonnage_total_vendu >= 0),
        CHECK (capital_social_libere <= capital_social_souscrit)
      )
    ''');
  }
  
  /// Créer la table AYANTS_DROIT
  static Future<void> _createAyantsDroitTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ayants_droit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        nom_complet TEXT NOT NULL,
        lien_familial TEXT NOT NULL,
        date_naissance TEXT,
        contact TEXT,
        email TEXT,
        beneficiaire_social INTEGER DEFAULT 0,
        priorite_succession INTEGER DEFAULT 999,
        numero_piece TEXT,
        type_piece TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        is_deleted INTEGER DEFAULT 0,
        
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
        
        CHECK (lien_familial IN ('enfant', 'conjoint', 'parent', 'frere_soeur', 'autre')),
        CHECK (priorite_succession >= 1)
      )
    ''');
  }
  
  /// Créer la table CHAMPS / PARCELLES
  static Future<void> _createChampsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS champs_parcelles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        code_champ TEXT UNIQUE NOT NULL,
        nom_champ TEXT,
        localisation TEXT,
        latitude REAL,
        longitude REAL,
        superficie REAL NOT NULL,
        type_sol TEXT,
        annee_mise_en_culture INTEGER,
        etat_champ TEXT DEFAULT 'actif',
        rendement_estime REAL DEFAULT 0.0,
        campagne_agricole TEXT,
        variete_cacao TEXT,
        nombre_arbres INTEGER,
        age_moyen_arbres INTEGER,
        systeme_irrigation TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        is_deleted INTEGER DEFAULT 0,
        
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
        
        CHECK (superficie > 0),
        CHECK (etat_champ IN ('actif', 'repos', 'abandonne', 'en_preparation')),
        CHECK (rendement_estime >= 0)
      )
    ''');
  }
  
  /// Créer la table TRAITEMENTS AGRICOLES
  static Future<void> _createTraitementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS traitements_agricoles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        champ_id INTEGER NOT NULL,
        type_traitement TEXT NOT NULL,
        produit_utilise TEXT NOT NULL,
        quantite REAL NOT NULL,
        unite_quantite TEXT DEFAULT 'kg',
        date_traitement TEXT NOT NULL,
        cout_traitement REAL DEFAULT 0.0,
        operateur TEXT,
        observation TEXT,
        created_at TEXT NOT NULL,
        created_by INTEGER,
        
        FOREIGN KEY (champ_id) REFERENCES champs_parcelles(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id),
        
        CHECK (type_traitement IN ('engrais', 'pesticide', 'entretien', 'autre')),
        CHECK (quantite > 0),
        CHECK (cout_traitement >= 0)
      )
    ''');
  }
  
  /// Créer la table PRODUCTION / TONNAGE
  static Future<void> _createProductionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS productions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        champ_id INTEGER,
        campagne TEXT NOT NULL,
        tonnage_brut REAL NOT NULL,
        tonnage_net REAL NOT NULL,
        taux_humidite REAL DEFAULT 0.0,
        date_recolte TEXT NOT NULL,
        qualite TEXT DEFAULT 'standard',
        observation TEXT,
        created_at TEXT NOT NULL,
        created_by INTEGER,
        
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
        FOREIGN KEY (champ_id) REFERENCES champs_parcelles(id),
        FOREIGN KEY (created_by) REFERENCES users(id),
        
        CHECK (tonnage_brut > 0),
        CHECK (tonnage_net > 0),
        CHECK (tonnage_net <= tonnage_brut),
        CHECK (taux_humidite >= 0 AND taux_humidite <= 100),
        CHECK (qualite IN ('standard', 'premium', 'bio'))
      )
    ''');
  }
  
  /// Créer la table STOCK / DEPOT
  static Future<void> _createStocksTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stocks_depots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        production_id INTEGER NOT NULL,
        magasin TEXT NOT NULL,
        date_depot TEXT NOT NULL,
        quantite_deposee REAL NOT NULL,
        qualite TEXT DEFAULT 'standard',
        reference_document TEXT,
        qr_code TEXT,
        qr_code_hash TEXT,
        created_at TEXT NOT NULL,
        created_by INTEGER,
        
        FOREIGN KEY (production_id) REFERENCES productions(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id),
        
        CHECK (quantite_deposee > 0),
        CHECK (qualite IN ('standard', 'premium', 'bio'))
      )
    ''');
  }
  
  /// Créer la table VENTES
  static Future<void> _createVentesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ventes_expert (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        client_id INTEGER,
        campagne TEXT NOT NULL,
        quantite_vendue REAL NOT NULL,
        prix_marche REAL,
        prix_plancher REAL,
        prix_jour REAL NOT NULL,
        montant_brut REAL NOT NULL,
        date_vente TEXT NOT NULL,
        reference_vente TEXT UNIQUE,
        notes TEXT,
        created_at TEXT NOT NULL,
        created_by INTEGER,
        
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
        FOREIGN KEY (client_id) REFERENCES clients(id),
        FOREIGN KEY (created_by) REFERENCES users(id),
        
        CHECK (quantite_vendue > 0),
        CHECK (prix_jour > 0),
        CHECK (montant_brut > 0),
        CHECK (prix_jour >= prix_plancher OR prix_plancher IS NULL),
        CHECK (prix_jour <= prix_marche OR prix_marche IS NULL)
      )
    ''');
  }
  
  /// Créer la table PARAMÉTRAGE PRIX & RETENUES
  static Future<void> _createParametragePrixTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parametrage_prix_retenues (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        campagne TEXT NOT NULL,
        date_application TEXT NOT NULL,
        prix_min REAL NOT NULL,
        prix_max REAL NOT NULL,
        prix_jour REAL NOT NULL,
        taux_commission REAL DEFAULT 0.05,
        taux_frais_gestion REAL DEFAULT 0.02,
        taux_social REAL DEFAULT 0.01,
        taux_credit REAL DEFAULT 0.0,
        is_actif INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        created_by INTEGER,
        
        FOREIGN KEY (created_by) REFERENCES users(id),
        
        CHECK (prix_min > 0),
        CHECK (prix_max >= prix_min),
        CHECK (prix_jour >= prix_min AND prix_jour <= prix_max),
        CHECK (taux_commission >= 0 AND taux_commission <= 1),
        CHECK (taux_frais_gestion >= 0 AND taux_frais_gestion <= 1),
        CHECK (taux_social >= 0 AND taux_social <= 1),
        CHECK (taux_credit >= 0 AND taux_credit <= 1)
      )
    ''');
  }
  
  /// Créer la table JOURNAL DE PAIE / REGLEMENT VENTE
  static Future<void> _createJournalPaieTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_paie (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vente_id INTEGER NOT NULL,
        adherent_id INTEGER NOT NULL,
        montant_brut REAL NOT NULL,
        commission REAL DEFAULT 0.0,
        frais_gestion REAL DEFAULT 0.0,
        retenue_social REAL DEFAULT 0.0,
        retenue_credit REAL DEFAULT 0.0,
        total_retenues REAL NOT NULL,
        montant_net_paye REAL NOT NULL,
        mode_paiement TEXT NOT NULL,
        date_paiement TEXT NOT NULL,
        reference_paiement TEXT UNIQUE,
        qr_code TEXT,
        qr_code_hash TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        created_by INTEGER,
        
        FOREIGN KEY (vente_id) REFERENCES ventes_expert(id) ON DELETE CASCADE,
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id),
        
        CHECK (montant_brut > 0),
        CHECK (total_retenues >= 0),
        CHECK (montant_net_paye >= 0),
        CHECK (montant_net_paye = montant_brut - total_retenues),
        CHECK (mode_paiement IN ('especes', 'cheque', 'virement', 'mobile_money', 'autre'))
      )
    ''');
  }
  
  /// Créer la table CAPITAL SOCIAL / ACTIONS
  static Future<void> _createCapitalSocialTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS capital_social_expert (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        nombre_parts_souscrites INTEGER NOT NULL,
        nombre_parts_liberees INTEGER DEFAULT 0,
        nombre_parts_restantes INTEGER NOT NULL,
        valeur_part REAL NOT NULL,
        capital_total REAL NOT NULL,
        date_souscription TEXT NOT NULL,
        date_liberation TEXT,
        statut TEXT DEFAULT 'souscrit',
        notes TEXT,
        created_at TEXT NOT NULL,
        created_by INTEGER,
        
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id),
        
        CHECK (nombre_parts_souscrites > 0),
        CHECK (nombre_parts_liberees >= 0),
        CHECK (nombre_parts_restantes >= 0),
        CHECK (nombre_parts_restantes = nombre_parts_souscrites - nombre_parts_liberees),
        CHECK (valeur_part > 0),
        CHECK (capital_total = nombre_parts_souscrites * valeur_part),
        CHECK (statut IN ('souscrit', 'partiellement_libere', 'libere', 'annule'))
      )
    ''');
  }
  
  /// Créer la table SOCIAL & CRÉDITS
  static Future<void> _createSocialCreditsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS social_credits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adherent_id INTEGER NOT NULL,
        type_credit TEXT NOT NULL DEFAULT 'credit_argent',
        type_aide TEXT NOT NULL DEFAULT 'credit',
        montant REAL NOT NULL,
        quantite_produit REAL,
        type_produit TEXT,
        date_octroi TEXT NOT NULL,
        motif TEXT NOT NULL,
        statut_remboursement TEXT DEFAULT 'non_rembourse',
        solde_restant REAL NOT NULL,
        echeance_remboursement TEXT,
        observation TEXT,
        created_at TEXT NOT NULL,
        created_by INTEGER,
        
        FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id),
        
        CHECK (type_credit IN ('credit_produit', 'credit_argent')),
        CHECK (type_aide IN ('credit', 'don', 'soutien', 'aide_sante', 'aide_education', 'autre')),
        CHECK (montant > 0),
        CHECK (solde_restant >= 0),
        CHECK (solde_restant <= montant),
        CHECK (statut_remboursement IN ('non_rembourse', 'partiellement_rembourse', 'rembourse', 'annule'))
      )
    ''');
    
    // Ajouter les colonnes si elles n'existent pas (pour bases existantes)
    await ensureSocialCreditsColumns(db);
  }
  
  /// S'assurer que toutes les colonnes nécessaires existent dans social_credits
  /// Méthode publique pour être appelée depuis db_initializer
  static Future<void> ensureSocialCreditsColumns(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(social_credits)');
      final columnNames = tableInfo.map((col) => col['name'] as String).toList();
      
      if (!columnNames.contains('type_credit')) {
        await db.execute('ALTER TABLE social_credits ADD COLUMN type_credit TEXT DEFAULT \'credit_argent\'');
      }
      
      if (!columnNames.contains('quantite_produit')) {
        await db.execute('ALTER TABLE social_credits ADD COLUMN quantite_produit REAL');
      }
      
      if (!columnNames.contains('type_produit')) {
        await db.execute('ALTER TABLE social_credits ADD COLUMN type_produit TEXT');
      }
    } catch (e) {
      print('Erreur lors de l\'ajout des colonnes à social_credits: $e');
    }
  }
  
  /// Créer les index pour optimiser les requêtes
  static Future<void> _createIndexes(Database db) async {
    // Index sur adherents_expert
    await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_code ON adherents_expert(code_adherent)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_statut ON adherents_expert(statut)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_type ON adherents_expert(type_personne)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_adherents_village ON adherents_expert(village)');
    
    // Index sur ayants_droit
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ayants_droit_adherent ON ayants_droit(adherent_id)');
    
    // Index sur champs_parcelles
    await db.execute('CREATE INDEX IF NOT EXISTS idx_champs_adherent ON champs_parcelles(adherent_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_champs_etat ON champs_parcelles(etat_champ)');
    
    // Index sur productions
    await db.execute('CREATE INDEX IF NOT EXISTS idx_productions_adherent ON productions(adherent_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_productions_campagne ON productions(campagne)');
    
    // Index sur ventes_expert
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ventes_adherent ON ventes_expert(adherent_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ventes_campagne ON ventes_expert(campagne)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ventes_date ON ventes_expert(date_vente)');
    
    // Index sur journal_paie
    await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_paie_adherent ON journal_paie(adherent_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_paie_vente ON journal_paie(vente_id)');
  }
}

