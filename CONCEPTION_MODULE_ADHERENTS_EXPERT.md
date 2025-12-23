# CONCEPTION EXHAUSTIVE - MODULE ADHÉRENTS EXPERT
## CoopManager - Version Experte

---

## 📋 TABLE DES MATIÈRES

1. [Vue d'ensemble](#vue-densemble)
2. [Schéma de Base de Données](#schéma-de-base-de-données)
3. [Entités & Champs Détaillés](#entités--champs-détaillés)
4. [Règles Métier](#règles-métier)
5. [APIs REST](#apis-rest)
6. [Interface Utilisateur](#interface-utilisateur)
7. [Services Backend](#services-backend)

---

## 🎯 VUE D'ENSEMBLE

Le module **ADHÉRENTS EXPERT** est le cœur du système CoopManager. Il gère l'ensemble du cycle de vie d'un adhérent/producteur depuis son adhésion jusqu'à la vente de sa production et le paiement.

### Architecture Générale

```
┌─────────────────────────────────────────────────────────────┐
│                    MODULE ADHÉRENTS EXPERT                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  ADHÉRENT    │───▶│   CHAMPS     │───▶│ PRODUCTION   │  │
│  │              │    │              │    │              │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                    │                    │          │
│         │                    ▼                    │          │
│         │            ┌──────────────┐            │          │
│         │            │ TRAITEMENTS  │            │          │
│         │            │  AGRICOLES   │            │          │
│         │            └──────────────┘            │          │
│         │                                         │          │
│         ▼                    ▼                    ▼          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ AYANTS DROIT │    │    STOCK     │    │    VENTE     │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                                                              │
│         │                    │                    │          │
│         ▼                    ▼                    ▼          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   CAPITAL    │    │ JOURNAL PAIE │    │ SOCIAL/CREDIT│  │
│  │   SOCIAL     │    │              │    │              │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ SCHÉMA DE BASE DE DONNÉES

### Diagramme Entité-Relation Simplifié

```
ADHERENTS_EXPERT (1) ──┐
                        │
                        ├── (1,N) ── AYANTS_DROIT
                        ├── (1,N) ── CHAMPS_PARCELLES
                        ├── (1,N) ── PRODUCTIONS
                        ├── (1,N) ── VENTES_EXPERT
                        ├── (1,N) ── CAPITAL_SOCIAL_EXPERT
                        └── (1,N) ── SOCIAL_CREDITS

CHAMPS_PARCELLES (1) ── (1,N) ── TRAITEMENTS_AGRICOLES
PRODUCTIONS (1) ─────── (1,N) ── STOCKS_DEPOTS
VENTES_EXPERT (1) ───── (1,1) ── JOURNAL_PAIE
```

---

## 📊 ENTITÉS & CHAMPS DÉTAILLÉS

### 1️⃣ ENTITÉ : ADHERENTS_EXPERT

**Description** : Entité principale représentant un adhérent/producteur de la coopérative.

#### SECTION 1 : IDENTIFICATION

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY, AUTOINCREMENT | Identifiant unique |
| `code_adherent` | TEXT | UNIQUE, NOT NULL | Code unique format: ADH-YYYY-NNNN |
| `type_personne` | TEXT | NOT NULL, DEFAULT 'producteur' | Valeurs: 'producteur', 'adherent', 'adherent_actionnaire' |
| `statut` | TEXT | NOT NULL, DEFAULT 'actif' | Valeurs: 'actif', 'suspendu', 'radie' |
| `date_adhesion` | TEXT | NOT NULL | Date d'adhésion (ISO8601) |
| `site_cooperative` | TEXT | NULL | Site/Unité coopérative |
| `section` | TEXT | NULL | Section administrative |
| `village` | TEXT | NULL | Village/Localité |

#### SECTION 2 : IDENTITÉ PERSONNELLE

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `nom` | TEXT | NOT NULL, min 2 caractères | Nom de famille |
| `prenom` | TEXT | NOT NULL, min 2 caractères | Prénom(s) |
| `sexe` | TEXT | NULL | Valeurs: 'M', 'F', 'Autre' |
| `date_naissance` | TEXT | NULL | Date de naissance (ISO8601) |
| `lieu_naissance` | TEXT | NULL | Lieu de naissance |
| `nationalite` | TEXT | DEFAULT 'Camerounais' | Nationalité |
| `type_piece` | TEXT | NULL | Valeurs: 'CNI', 'Passeport', 'Acte_naissance', 'Autre' |
| `numero_piece` | TEXT | UNIQUE si fourni | Numéro pièce d'identité |
| `telephone` | TEXT | NULL | Format: +237 6XX XXX XXX |
| `telephone_secondaire` | TEXT | NULL | Téléphone secondaire |
| `email` | TEXT | NULL | Format email valide |
| `adresse` | TEXT | NULL | Adresse complète |
| `code_postal` | TEXT | NULL | Code postal |

#### SECTION 3 : SITUATION FAMILIALE

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `nom_pere` | TEXT | NULL | Nom complet du père |
| `nom_mere` | TEXT | NULL | Nom complet de la mère |
| `conjoint` | TEXT | NULL | Nom complet du conjoint |
| `nombre_enfants` | INTEGER | DEFAULT 0 | Nombre d'enfants à charge |
| `situation_matrimoniale` | TEXT | NULL | Valeurs: 'celibataire', 'marie', 'divorce', 'veuf', 'concubinage' |

#### SECTION 4 : INDICATEURS AGRICOLES (CALCULÉS)

| Champ | Type | Contraintes | Description | Règle de Calcul |
|-------|------|-------------|-------------|-----------------|
| `superficie_totale_cultivee` | REAL | DEFAULT 0.0, >= 0 | Superficie totale en ha | SUM(champs.superficie WHERE etat='actif') |
| `nombre_champs` | INTEGER | DEFAULT 0, >= 0 | Nombre de champs | COUNT(champs WHERE adherent_id=id) |
| `rendement_moyen_ha` | REAL | DEFAULT 0.0 | Rendement moyen t/ha | tonnage_total_produit / superficie_totale_cultivee |
| `tonnage_total_produit` | REAL | DEFAULT 0.0, >= 0 | Tonnage total produit | SUM(productions.tonnage_net) |
| `tonnage_total_vendu` | REAL | DEFAULT 0.0, >= 0 | Tonnage total vendu | SUM(ventes.quantite_vendue) |
| `tonnage_disponible_stock` | REAL | DEFAULT 0.0 | Tonnage disponible | tonnage_total_produit - tonnage_total_vendu - pertes |

#### SECTION 5 : INDICATEURS FINANCIERS (CALCULÉS)

| Champ | Type | Contraintes | Description | Règle de Calcul |
|-------|------|-------------|-------------|-----------------|
| `capital_social_souscrit` | REAL | DEFAULT 0.0 | Capital souscrit | SUM(capital_social.nombre_parts × valeur_part) |
| `capital_social_libere` | REAL | DEFAULT 0.0 | Capital libéré | SUM(capital_social.nombre_parts_liberees × valeur_part) |
| `capital_social_restant` | REAL | DEFAULT 0.0 | Capital restant | capital_social_souscrit - capital_social_libere |
| `montant_total_ventes` | REAL | DEFAULT 0.0 | Montant total ventes | SUM(ventes.montant_brut) |
| `montant_total_paye` | REAL | DEFAULT 0.0 | Montant total payé | SUM(journal_paie.montant_net_paye) |
| `solde_crediteur` | REAL | DEFAULT 0.0 | Montant dû à l'adhérent | montant_total_ventes - montant_total_paye - retenues |
| `solde_debiteur` | REAL | DEFAULT 0.0 | Montant dû par l'adhérent | SUM(social_credits.solde_restant) |

#### SECTION 6 : MÉTADONNÉES

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `created_at` | TEXT | NOT NULL | Date création (ISO8601) |
| `updated_at` | TEXT | NULL | Date modification |
| `created_by` | INTEGER | NULL | FK -> users(id) |
| `updated_by` | INTEGER | NULL | FK -> users(id) |
| `photo_path` | TEXT | NULL | Chemin photo profil |
| `notes` | TEXT | NULL | Notes générales |
| `is_deleted` | INTEGER | DEFAULT 0 | Suppression logique |
| `deleted_at` | TEXT | NULL | Date suppression |

**Relations** :
- `(1,N)` → `AYANTS_DROIT` (adherent_id)
- `(1,N)` → `CHAMPS_PARCELLES` (adherent_id)
- `(1,N)` → `PRODUCTIONS` (adherent_id)
- `(1,N)` → `VENTES_EXPERT` (adherent_id)
- `(1,N)` → `CAPITAL_SOCIAL_EXPERT` (adherent_id)
- `(1,N)` → `SOCIAL_CREDITS` (adherent_id)

---

### 2️⃣ ENTITÉ : AYANTS_DROIT

**Description** : Représente les ayants droit (enfants, conjoint, etc.) d'un adhérent.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY | Identifiant unique |
| `adherent_id` | INTEGER | NOT NULL, FK | Référence adhérent |
| `nom_complet` | TEXT | NOT NULL, min 3 caractères | Nom complet |
| `lien_familial` | TEXT | NOT NULL | Valeurs: 'enfant', 'conjoint', 'parent', 'frere_soeur', 'autre' |
| `date_naissance` | TEXT | NULL | Date naissance |
| `contact` | TEXT | NULL | Téléphone |
| `email` | TEXT | NULL | Email |
| `beneficiaire_social` | INTEGER | DEFAULT 0 | Booléen bénéficiaire |
| `priorite_succession` | INTEGER | DEFAULT 999, >= 1 | Priorité succession (1 = première) |
| `numero_piece` | TEXT | NULL | Numéro pièce identité |
| `type_piece` | TEXT | NULL | Type pièce |
| `notes` | TEXT | NULL | Notes |
| `created_at` | TEXT | NOT NULL | Date création |
| `updated_at` | TEXT | NULL | Date modification |
| `is_deleted` | INTEGER | DEFAULT 0 | Suppression logique |

**Relations** :
- `(N,1)` → `ADHERENTS_EXPERT` (adherent_id)

---

### 3️⃣ ENTITÉ : CHAMPS_PARCELLES

**Description** : Représente un champ ou parcelle agricole.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY | Identifiant unique |
| `adherent_id` | INTEGER | NOT NULL, FK | Référence adhérent |
| `code_champ` | TEXT | UNIQUE, NOT NULL | Code unique (ex: CH-ADH001-001) |
| `nom_champ` | TEXT | NULL | Nom/designation |
| `localisation` | TEXT | NULL | Description géographique |
| `latitude` | REAL | NULL | Coordonnée GPS latitude |
| `longitude` | REAL | NULL | Coordonnée GPS longitude |
| `superficie` | REAL | NOT NULL, > 0 | Superficie en hectares |
| `type_sol` | TEXT | NULL | Valeurs: 'argileux', 'sableux', 'limoneux', 'volcanique', 'autre' |
| `annee_mise_en_culture` | INTEGER | NULL | Année mise en culture |
| `etat_champ` | TEXT | DEFAULT 'actif' | Valeurs: 'actif', 'repos', 'abandonne', 'en_preparation' |
| `rendement_estime` | REAL | DEFAULT 0.0, >= 0 | Rendement estimé t/ha |
| `campagne_agricole` | TEXT | NULL | Format: YYYY-YYYY |
| `variete_cacao` | TEXT | NULL | Valeurs: 'forastero', 'criollo', 'trinitario', 'hybride' |
| `nombre_arbres` | INTEGER | NULL | Nombre d'arbres plantés |
| `age_moyen_arbres` | INTEGER | NULL | Âge moyen en années |
| `systeme_irrigation` | TEXT | NULL | Valeurs: 'pluvial', 'irrigue', 'mixte' |
| `notes` | TEXT | NULL | Notes |
| `created_at` | TEXT | NOT NULL | Date création |
| `updated_at` | TEXT | NULL | Date modification |
| `is_deleted` | INTEGER | DEFAULT 0 | Suppression logique |

**Relations** :
- `(N,1)` → `ADHERENTS_EXPERT` (adherent_id)
- `(1,N)` → `TRAITEMENTS_AGRICOLES` (champ_id)

**Règles de Calcul** :
- `production_potentielle = superficie × rendement_estime`

---

### 4️⃣ ENTITÉ : TRAITEMENTS_AGRICOLES

**Description** : Enregistre les traitements appliqués sur un champ.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY | Identifiant unique |
| `champ_id` | INTEGER | NOT NULL, FK | Référence champ |
| `type_traitement` | TEXT | NOT NULL | Valeurs: 'engrais', 'pesticide', 'entretien', 'autre' |
| `produit_utilise` | TEXT | NOT NULL | Nom du produit |
| `quantite` | REAL | NOT NULL, > 0 | Quantité utilisée |
| `unite_quantite` | TEXT | DEFAULT 'kg' | Unité: 'kg', 'L', 'unite' |
| `date_traitement` | TEXT | NOT NULL | Date traitement (ISO8601) |
| `cout_traitement` | REAL | DEFAULT 0.0, >= 0 | Coût en FCFA |
| `operateur` | TEXT | NULL | Nom opérateur |
| `observation` | TEXT | NULL | Observations |
| `created_at` | TEXT | NOT NULL | Date création |
| `created_by` | INTEGER | NULL | FK -> users(id) |

**Relations** :
- `(N,1)` → `CHAMPS_PARCELLES` (champ_id)

---

### 5️⃣ ENTITÉ : PRODUCTIONS

**Description** : Enregistre la production/récolte d'un adhérent.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY | Identifiant unique |
| `adherent_id` | INTEGER | NOT NULL, FK | Référence adhérent |
| `champ_id` | INTEGER | NULL, FK | Référence champ (optionnel) |
| `campagne` | TEXT | NOT NULL | Format: YYYY-YYYY |
| `tonnage_brut` | REAL | NOT NULL, > 0 | Tonnage brut récolté |
| `tonnage_net` | REAL | NOT NULL, > 0 | Tonnage net après séchage |
| `taux_humidite` | REAL | DEFAULT 0.0 | Taux humidité (0-100%) |
| `date_recolte` | TEXT | NOT NULL | Date récolte (ISO8601) |
| `qualite` | TEXT | DEFAULT 'standard' | Valeurs: 'standard', 'premium', 'bio' |
| `observation` | TEXT | NULL | Observations |
| `created_at` | TEXT | NOT NULL | Date création |
| `created_by` | INTEGER | NULL | FK -> users(id) |

**Relations** :
- `(N,1)` → `ADHERENTS_EXPERT` (adherent_id)
- `(N,1)` → `CHAMPS_PARCELLES` (champ_id) - optionnel
- `(1,N)` → `STOCKS_DEPOTS` (production_id)

**Règles de Calcul** :
- `tonnage_net = tonnage_brut × (1 - taux_humidite/100)`
- Contrainte: `tonnage_net <= tonnage_brut`

---

### 6️⃣ ENTITÉ : STOCKS_DEPOTS

**Description** : Enregistre le dépôt de production en magasin.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY | Identifiant unique |
| `production_id` | INTEGER | NOT NULL, FK | Référence production |
| `magasin` | TEXT | NOT NULL | Nom du magasin |
| `date_depot` | TEXT | NOT NULL | Date dépôt (ISO8601) |
| `quantite_deposee` | REAL | NOT NULL, > 0 | Quantité déposée en tonnes |
| `qualite` | TEXT | DEFAULT 'standard' | Valeurs: 'standard', 'premium', 'bio' |
| `reference_document` | TEXT | NULL | Référence bon de dépôt |
| `qr_code` | TEXT | NULL | QR Code document |
| `qr_code_hash` | TEXT | NULL | Hash QR Code |
| `created_at` | TEXT | NOT NULL | Date création |
| `created_by` | INTEGER | NULL | FK -> users(id) |

**Relations** :
- `(N,1)` → `PRODUCTIONS` (production_id)

---

### 7️⃣ ENTITÉ : VENTES_EXPERT

**Description** : Enregistre une vente de production.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY | Identifiant unique |
| `adherent_id` | INTEGER | NOT NULL, FK | Référence adhérent |
| `client_id` | INTEGER | NULL, FK | Référence client (optionnel) |
| `campagne` | TEXT | NOT NULL | Campagne agricole |
| `quantite_vendue` | REAL | NOT NULL, > 0 | Quantité vendue en tonnes |
| `prix_marche` | REAL | NULL | Prix marché du jour |
| `prix_plancher` | REAL | NULL | Prix plancher garanti |
| `prix_jour` | REAL | NOT NULL, > 0 | Prix effectif appliqué |
| `montant_brut` | REAL | NOT NULL, > 0 | Montant brut = quantite × prix_jour |
| `date_vente` | TEXT | NOT NULL | Date vente (ISO8601) |
| `reference_vente` | TEXT | UNIQUE | Référence unique vente |
| `notes` | TEXT | NULL | Notes |
| `created_at` | TEXT | NOT NULL | Date création |
| `created_by` | INTEGER | NULL | FK -> users(id) |

**Relations** :
- `(N,1)` → `ADHERENTS_EXPERT` (adherent_id)
- `(N,1)` → `CLIENTS` (client_id) - optionnel
- `(1,1)` → `JOURNAL_PAIE` (vente_id)

**Règles de Calcul** :
- `montant_brut = quantite_vendue × prix_jour`
- Contrainte: `prix_jour >= prix_plancher` (si prix_plancher défini)
- Contrainte: `prix_jour <= prix_marche` (si prix_marche défini)
- Contrainte: `prix_jour >= prix_min` ET `prix_jour <= prix_max` (selon paramétrage)

---

### 8️⃣ ENTITÉ : PARAMETRAGE_PRIX_RETENUES

**Description** : Paramétrage des prix et taux de retenues par campagne.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY | Identifiant unique |
| `campagne` | TEXT | NOT NULL | Campagne agricole |
| `date_application` | TEXT | NOT NULL | Date application (ISO8601) |
| `prix_min` | REAL | NOT NULL, > 0 | Prix minimum garanti |
| `prix_max` | REAL | NOT NULL, >= prix_min | Prix maximum |
| `prix_jour` | REAL | NOT NULL | Prix du jour |
| `taux_commission` | REAL | DEFAULT 0.05 | Taux commission (0-1) |
| `taux_frais_gestion` | REAL | DEFAULT 0.02 | Taux frais gestion (0-1) |
| `taux_social` | REAL | DEFAULT 0.01 | Taux social (0-1) |
| `taux_credit` | REAL | DEFAULT 0.0 | Taux crédit (0-1) |
| `is_actif` | INTEGER | DEFAULT 1 | Paramétrage actif |
| `created_at` | TEXT | NOT NULL | Date création |
| `created_by` | INTEGER | NULL | FK -> users(id) |

**Contraintes** :
- `prix_jour >= prix_min` ET `prix_jour <= prix_max`
- Tous les taux entre 0 et 1

---

### 9️⃣ ENTITÉ : JOURNAL_PAIE

**Description** : Journal de paiement/règlement après vente.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY | Identifiant unique |
| `vente_id` | INTEGER | NOT NULL, FK | Référence vente |
| `adherent_id` | INTEGER | NOT NULL, FK | Référence adhérent |
| `montant_brut` | REAL | NOT NULL, > 0 | Montant brut vente |
| `commission` | REAL | DEFAULT 0.0 | Commission retenue |
| `frais_gestion` | REAL | DEFAULT 0.0 | Frais gestion retenus |
| `retenue_social` | REAL | DEFAULT 0.0 | Retenue sociale |
| `retenue_credit` | REAL | DEFAULT 0.0 | Retenue crédit |
| `total_retenues` | REAL | NOT NULL, >= 0 | Total retenues |
| `montant_net_paye` | REAL | NOT NULL, >= 0 | Montant net payé |
| `mode_paiement` | TEXT | NOT NULL | Valeurs: 'especes', 'cheque', 'virement', 'mobile_money', 'autre' |
| `date_paiement` | TEXT | NOT NULL | Date paiement (ISO8601) |
| `reference_paiement` | TEXT | UNIQUE | Référence paiement |
| `qr_code` | TEXT | NULL | QR Code reçu |
| `qr_code_hash` | TEXT | NULL | Hash QR Code |
| `notes` | TEXT | NULL | Notes |
| `created_at` | TEXT | NOT NULL | Date création |
| `created_by` | INTEGER | NULL | FK -> users(id) |

**Relations** :
- `(N,1)` → `VENTES_EXPERT` (vente_id)
- `(N,1)` → `ADHERENTS_EXPERT` (adherent_id)

**Règles de Calcul** :
- `commission = montant_brut × taux_commission`
- `frais_gestion = montant_brut × taux_frais_gestion`
- `retenue_social = montant_brut × taux_social`
- `retenue_credit = montant_brut × taux_credit`
- `total_retenues = commission + frais_gestion + retenue_social + retenue_credit`
- `montant_net_paye = montant_brut - total_retenues`
- Contrainte: `montant_net_paye >= 0`

---

### 🔟 ENTITÉ : CAPITAL_SOCIAL_EXPERT

**Description** : Gestion du capital social et des parts souscrites.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY | Identifiant unique |
| `adherent_id` | INTEGER | NOT NULL, FK | Référence adhérent |
| `nombre_parts_souscrites` | INTEGER | NOT NULL, > 0 | Nombre parts souscrites |
| `nombre_parts_liberees` | INTEGER | DEFAULT 0, >= 0 | Nombre parts libérées |
| `nombre_parts_restantes` | INTEGER | NOT NULL, >= 0 | Nombre parts restantes |
| `valeur_part` | REAL | NOT NULL, > 0 | Valeur unitaire part (FCFA) |
| `capital_total` | REAL | NOT NULL | Capital total = nombre_parts × valeur_part |
| `date_souscription` | TEXT | NOT NULL | Date souscription (ISO8601) |
| `date_liberation` | TEXT | NULL | Date libération |
| `statut` | TEXT | DEFAULT 'souscrit' | Valeurs: 'souscrit', 'partiellement_libere', 'libere', 'annule' |
| `notes` | TEXT | NULL | Notes |
| `created_at` | TEXT | NOT NULL | Date création |
| `created_by` | INTEGER | NULL | FK -> users(id) |

**Relations** :
- `(N,1)` → `ADHERENTS_EXPERT` (adherent_id)

**Règles de Calcul** :
- `nombre_parts_restantes = nombre_parts_souscrites - nombre_parts_liberees`
- `capital_total = nombre_parts_souscrites × valeur_part`
- Contrainte: `nombre_parts_liberees <= nombre_parts_souscrites`
- Contrainte: `capital_libere <= capital_souscrit` (au niveau adhérent)

---

### 1️⃣1️⃣ ENTITÉ : SOCIAL_CREDITS

**Description** : Gestion des aides sociales et crédits octroyés.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY | Identifiant unique |
| `adherent_id` | INTEGER | NOT NULL, FK | Référence adhérent |
| `type_aide` | TEXT | NOT NULL | Valeurs: 'credit', 'don', 'soutien', 'aide_sante', 'aide_education', 'autre' |
| `montant` | REAL | NOT NULL, > 0 | Montant octroyé (FCFA) |
| `date_octroi` | TEXT | NOT NULL | Date octroi (ISO8601) |
| `motif` | TEXT | NOT NULL | Motif de l'aide |
| `statut_remboursement` | TEXT | DEFAULT 'non_rembourse' | Valeurs: 'non_rembourse', 'partiellement_rembourse', 'rembourse', 'annule' |
| `solde_restant` | REAL | NOT NULL, >= 0 | Solde restant à rembourser |
| `echeance_remboursement` | TEXT | NULL | Date échéance |
| `observation` | TEXT | NULL | Observations |
| `created_at` | TEXT | NOT NULL | Date création |
| `created_by` | INTEGER | NULL | FK -> users(id) |

**Relations** :
- `(N,1)` → `ADHERENTS_EXPERT` (adherent_id)

**Règles de Calcul** :
- `solde_restant <= montant`
- Si `type_aide = 'don'` → `statut_remboursement = 'annule'` et `solde_restant = 0`

---

## 🔐 RÈGLES MÉTIER OBLIGATOIRES

### Règle 1 : Vente impossible sans stock disponible

**Description** : Une vente ne peut être enregistrée que si l'adhérent a du stock disponible.

**Contrainte** :
```sql
CHECK (quantite_vendue <= tonnage_disponible_stock)
```

**Validation** :
- Avant création d'une vente, vérifier: `tonnage_disponible_stock >= quantite_vendue`
- Si non respecté → Erreur: "Stock insuffisant. Disponible: X tonnes"

---

### Règle 2 : Capital libéré ≤ capital souscrit

**Description** : Le capital libéré ne peut jamais dépasser le capital souscrit.

**Contrainte** :
```sql
CHECK (capital_social_libere <= capital_social_souscrit)
```

**Validation** :
- Lors de la libération de parts, vérifier: `nouveau_capital_libere <= capital_social_souscrit`
- Si non respecté → Erreur: "Impossible de libérer plus que le capital souscrit"

---

### Règle 3 : Prix du jour dans [prix_min, prix_max]

**Description** : Le prix appliqué lors d'une vente doit être dans la fourchette définie.

**Contrainte** :
```sql
CHECK (prix_jour >= prix_min AND prix_jour <= prix_max)
```

**Validation** :
- Avant création d'une vente, récupérer le paramétrage actif
- Vérifier: `prix_min <= prix_jour <= prix_max`
- Si non respecté → Erreur: "Prix hors fourchette autorisée"

---

### Règle 4 : Retenues calculées automatiquement

**Description** : Les retenues sont calculées automatiquement selon les taux du paramétrage.

**Calcul** :
```dart
final parametrage = await getParametrageActif(campagne);
final commission = montantBrut * parametrage.tauxCommission;
final fraisGestion = montantBrut * parametrage.tauxFraisGestion;
final retenueSocial = montantBrut * parametrage.tauxSocial;
final retenueCredit = montantBrut * parametrage.tauxCredit;
final totalRetenues = commission + fraisGestion + retenueSocial + retenueCredit;
final montantNetPaye = montantBrut - totalRetenues;
```

---

### Règle 5 : Journal de paie généré automatiquement après vente

**Description** : Après chaque vente, un journal de paie est automatiquement créé.

**Workflow** :
1. Créer la vente
2. Calculer les retenues selon paramétrage
3. Créer automatiquement le journal de paie
4. Mettre à jour les indicateurs financiers de l'adhérent

**Transaction** : Toute l'opération doit être atomique (rollback en cas d'erreur)

---

### Règle 6 : Historique immuable

**Description** : Les enregistrements historiques (ventes, paiements, productions) ne peuvent pas être modifiés, seulement annulés.

**Implémentation** :
- Pas de `UPDATE` sur les tables historiques
- Ajout d'un champ `is_annule` pour annulation
- Création d'une entrée d'annulation avec référence à l'entrée originale

---

## 🌐 APIs REST

### Endpoint : `/api/adherents`

#### GET `/api/adherents`
Liste tous les adhérents avec filtres.

**Query Parameters** :
- `statut` : Filtrer par statut
- `type_personne` : Filtrer par type
- `village` : Filtrer par village
- `search` : Recherche textuelle
- `page` : Numéro de page
- `limit` : Nombre d'éléments par page

**Response** :
```json
{
  "data": [
    {
      "id": 1,
      "code_adherent": "ADH-2024-001",
      "nom": "Doe",
      "prenom": "John",
      ...
    }
  ],
  "total": 150,
  "page": 1,
  "limit": 20
}
```

#### GET `/api/adherents/:id`
Récupère un adhérent avec toutes ses relations.

**Response** :
```json
{
  "id": 1,
  "code_adherent": "ADH-2024-001",
  "nom": "Doe",
  "prenom": "John",
  "champs": [...],
  "productions": [...],
  "ventes": [...],
  "capital_social": [...],
  ...
}
```

#### POST `/api/adherents`
Crée un nouvel adhérent.

**Body** :
```json
{
  "code_adherent": "ADH-2024-001",
  "nom": "Doe",
  "prenom": "John",
  "date_adhesion": "2024-01-15",
  ...
}
```

#### PUT `/api/adherents/:id`
Met à jour un adhérent.

#### DELETE `/api/adherents/:id`
Suppression logique d'un adhérent.

---

### Endpoint : `/api/adherents/:id/champs`

#### GET `/api/adherents/:id/champs`
Liste tous les champs d'un adhérent.

#### POST `/api/adherents/:id/champs`
Crée un nouveau champ.

---

### Endpoint : `/api/adherents/:id/ventes`

#### GET `/api/adherents/:id/ventes`
Liste toutes les ventes d'un adhérent.

#### POST `/api/adherents/:id/ventes`
Crée une nouvelle vente (génère automatiquement le journal de paie).

---

### Endpoint : `/api/adherents/:id/journal-paie`

#### GET `/api/adherents/:id/journal-paie`
Liste tous les paiements d'un adhérent.

---

## 🖥️ INTERFACE UTILISATEUR

### Fiche Adhérent - Layout Principal

#### Header Résumé
- Statut (badge coloré)
- Capital social (souscrit/libéré/restant)
- Tonnage (produit/vendu/disponible)
- Solde (créancier/débiteur)

#### Onglets

1. **Identité & Filiation**
   - Formulaire identité complète
   - Liste ayants droit (CRUD)
   - Photo profil

2. **Champs & Superficies**
   - Liste champs avec carte
   - Formulaire ajout/modification champ
   - Statistiques par champ

3. **Traitements**
   - Historique traitements par champ
   - Formulaire ajout traitement
   - Graphiques coûts

4. **Production & Stock**
   - Liste productions
   - Formulaire ajout production
   - Dépôts en magasin
   - Graphiques production

5. **Ventes & Journal de paie**
   - Liste ventes
   - Formulaire création vente
   - Journal de paie automatique
   - Graphiques ventes

6. **Capital social**
   - Historique souscriptions
   - Formulaire libération parts
   - Graphiques capital

7. **Social & Crédits**
   - Liste aides/credits
   - Formulaire octroi aide
   - Suivi remboursements

---

## 📦 SERVICES BACKEND

### AdherentExpertService

```dart
class AdherentExpertService {
  // CRUD de base
  Future<AdherentExpertModel> createAdherent(...);
  Future<AdherentExpertModel> updateAdherent(...);
  Future<bool> deleteAdherent(int id);
  Future<AdherentExpertModel?> getAdherentById(int id);
  Future<List<AdherentExpertModel>> getAllAdherents({...});
  
  // Calculs automatiques
  Future<void> updateIndicateursAgricoles(int adherentId);
  Future<void> updateIndicateursFinanciers(int adherentId);
  
  // Recherche et filtres
  Future<List<AdherentExpertModel>> searchAdherents(String query);
  Future<List<AdherentExpertModel>> filterByVillage(String village);
  Future<List<AdherentExpertModel>> filterByStatut(String statut);
}
```

### VenteExpertService

```dart
class VenteExpertService {
  Future<VenteExpertModel> createVente({
    required int adherentId,
    required double quantite,
    required double prixJour,
    ...
  }) async {
    // 1. Vérifier stock disponible
    // 2. Vérifier prix dans fourchette
    // 3. Créer vente
    // 4. Générer journal de paie automatiquement
    // 5. Mettre à jour indicateurs
  }
}
```

---

## ✅ VALIDATION & TESTS

### Tests Unitaires Requis

1. **Test création adhérent** : Vérifier tous les champs
2. **Test calcul indicateurs** : Vérifier calculs automatiques
3. **Test vente** : Vérifier règles métier
4. **Test journal de paie** : Vérifier calcul retenues
5. **Test capital social** : Vérifier contraintes libération

---

## 📝 NOTES IMPORTANTES

1. **Performance** : Les indicateurs calculés doivent être mis en cache et mis à jour de manière incrémentale
2. **Sécurité** : Tous les champs sensibles doivent être validés côté serveur
3. **Audit** : Toutes les modifications doivent être tracées (audit log)
4. **Backup** : Sauvegarde quotidienne de la base de données
5. **Migration** : Migration progressive depuis l'ancien modèle

---

**Version** : 1.0.0  
**Date** : 2024  
**Auteur** : Architecture CoopManager Expert

