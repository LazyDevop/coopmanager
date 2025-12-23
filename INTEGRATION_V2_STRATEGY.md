# 🎯 Stratégie d'Intégration CoopManager V2

## 📋 Vue d'ensemble

Ce document décrit la stratégie d'intégration des fonctionnalités V2 dans l'application CoopManager existante, en garantissant la rétrocompatibilité et une évolution progressive.

**Version actuelle** : 1.0.0  
**Version cible** : 2.0.0  
**Date** : $(date)

---

## 🎯 Objectifs de la V2

### Nouvelles fonctionnalités

1. **Gestion des clients (acheteurs)**
   - CRUD clients
   - Historique des transactions
   - Statistiques par client

2. **Catégorisation des producteurs**
   - Producteur / Adhérent / Actionnaire
   - Évolution de statut
   - Gestion des droits selon catégorie

3. **Capital social et parts**
   - Gestion des parts sociales
   - Suivi du capital social
   - Distribution des dividendes

4. **Module social**
   - Aides et actions sociales
   - Suivi des bénéficiaires
   - Budget social

5. **Comptabilité simplifiée**
   - Écritures comptables automatiques
   - Grand livre
   - États financiers

6. **Sécurité documentaire**
   - QR Code sur tous les documents
   - Hash de vérification
   - Vérification hors ligne

---

## 📊 Analyse d'impact

### Modules à étendre

| Module | Impact | Actions requises |
|--------|--------|------------------|
| **Adhérents** | 🔴 Élevé | Ajouter catégorie, statut, parts sociales |
| **Ventes** | 🔴 Élevé | Lien obligatoire avec client, écritures comptables |
| **Recettes** | 🟡 Moyen | Traçabilité comptable et sociale |
| **Factures** | 🟡 Moyen | Ajouter QR Code et hash |
| **Stock** | 🟢 Faible | Lien avec catégorie producteur (optionnel) |

### Modules à créer

1. **Clients** (nouveau)
2. **Capital Social** (nouveau)
3. **Comptabilité** (nouveau)
4. **Social** (nouveau)
5. **QR Code Service** (nouveau)

### Modules inchangés

- ✅ Authentification
- ✅ Paramétrage (base)
- ✅ Notifications
- ✅ Audit logs

---

## 🏗️ Architecture proposée

### Structure de dossiers mise à jour

```
lib/
├── data/
│   └── models/
│       ├── adherent_model.dart              # ✅ Étendu (catégorie, statut)
│       ├── client_model.dart                # 🆕 Nouveau
│       ├── part_sociale_model.dart          # 🆕 Nouveau
│       ├── ecriture_comptable_model.dart    # 🆕 Nouveau
│       ├── aide_sociale_model.dart          # 🆕 Nouveau
│       ├── document_securise_model.dart    # 🆕 Nouveau
│       └── ... (modèles existants)
│
├── services/
│   ├── client/                              # 🆕 Nouveau module
│   │   ├── client_service.dart
│   │   └── client_export_service.dart
│   ├── capital/                             # 🆕 Nouveau module
│   │   ├── capital_service.dart
│   │   └── part_sociale_service.dart
│   ├── comptabilite/                        # 🆕 Nouveau module
│   │   ├── comptabilite_service.dart
│   │   ├── grand_livre_service.dart
│   │   └── etat_financier_service.dart
│   ├── social/                               # 🆕 Nouveau module
│   │   ├── social_service.dart
│   │   └── aide_sociale_service.dart
│   ├── qrcode/                               # 🆕 Nouveau module
│   │   ├── qrcode_service.dart
│   │   ├── document_security_service.dart
│   │   └── verification_service.dart
│   └── ... (services existants)
│
└── presentation/
    ├── screens/
    │   ├── clients/                          # 🆕 Nouveau module
    │   ├── capital/                          # 🆕 Nouveau module
    │   ├── comptabilite/                     # 🆕 Nouveau module
    │   ├── social/                           # 🆕 Nouveau module
    │   └── ... (écrans existants)
    └── viewmodels/
        ├── client_viewmodel.dart             # 🆕 Nouveau
        ├── capital_viewmodel.dart            # 🆕 Nouveau
        ├── comptabilite_viewmodel.dart       # 🆕 Nouveau
        ├── social_viewmodel.dart             # 🆕 Nouveau
        └── ... (viewmodels existants)
```

---

## 🗄️ Modèle de données V2

### Nouvelles tables

#### 1. Table `clients`
```sql
CREATE TABLE clients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE NOT NULL,
  nom TEXT NOT NULL,
  type TEXT NOT NULL, -- 'entreprise', 'particulier', 'cooperative'
  telephone TEXT,
  email TEXT,
  adresse TEXT,
  ville TEXT,
  pays TEXT DEFAULT 'Cameroun',
  siret TEXT, -- Pour entreprises
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT
)
```

#### 2. Table `adherent_categories`
```sql
CREATE TABLE adherent_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  adherent_id INTEGER NOT NULL,
  categorie TEXT NOT NULL, -- 'producteur', 'adherent', 'actionnaire'
  date_debut TEXT NOT NULL,
  date_fin TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  FOREIGN KEY (adherent_id) REFERENCES adherents(id)
)
```

#### 3. Table `parts_sociales`
```sql
CREATE TABLE parts_sociales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  adherent_id INTEGER NOT NULL,
  nombre_parts INTEGER NOT NULL,
  valeur_unitaire REAL NOT NULL,
  date_acquisition TEXT NOT NULL,
  date_cession TEXT,
  statut TEXT DEFAULT 'actif', -- 'actif', 'cede', 'annule'
  created_by INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  FOREIGN KEY (adherent_id) REFERENCES adherents(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
)
```

#### 4. Table `ecritures_comptables`
```sql
CREATE TABLE ecritures_comptables (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  numero TEXT UNIQUE NOT NULL,
  date_ecriture TEXT NOT NULL,
  type_operation TEXT NOT NULL, -- 'vente', 'recette', 'aide_sociale', 'capital'
  operation_id INTEGER, -- ID de l'opération source (vente_id, recette_id, etc.)
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
```

#### 5. Table `aides_sociales`
```sql
CREATE TABLE aides_sociales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  adherent_id INTEGER NOT NULL,
  type_aide TEXT NOT NULL, -- 'sante', 'education', 'urgence', 'autre'
  montant REAL NOT NULL,
  date_aide TEXT NOT NULL,
  description TEXT NOT NULL,
  statut TEXT DEFAULT 'en_attente', -- 'en_attente', 'approuve', 'verse', 'refuse'
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
```

#### 6. Table `documents_securises`
```sql
CREATE TABLE documents_securises (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  document_type TEXT NOT NULL, -- 'facture', 'recu', 'bordereau', 'etat_compte'
  document_id INTEGER NOT NULL,
  qr_code_data TEXT NOT NULL,
  hash_verification TEXT NOT NULL,
  qr_code_image_path TEXT,
  date_generation TEXT NOT NULL,
  created_by INTEGER,
  FOREIGN KEY (created_by) REFERENCES users(id)
)
```

### Tables modifiées

#### Table `adherents` (extension)
```sql
ALTER TABLE adherents ADD COLUMN categorie TEXT DEFAULT 'producteur';
ALTER TABLE adherents ADD COLUMN statut TEXT DEFAULT 'actif'; -- 'actif', 'suspendu', 'radie'
ALTER TABLE adherents ADD COLUMN date_statut TEXT;
```

#### Table `ventes` (extension)
```sql
ALTER TABLE ventes ADD COLUMN client_id INTEGER;
ALTER TABLE ventes ADD COLUMN ecriture_comptable_id INTEGER;
ALTER TABLE ventes ADD COLUMN qr_code_hash TEXT;
FOREIGN KEY (client_id) REFERENCES clients(id)
FOREIGN KEY (ecriture_comptable_id) REFERENCES ecritures_comptables(id)
```

#### Table `recettes` (extension)
```sql
ALTER TABLE recettes ADD COLUMN ecriture_comptable_id INTEGER;
ALTER TABLE recettes ADD COLUMN qr_code_hash TEXT;
FOREIGN KEY (ecriture_comptable_id) REFERENCES ecritures_comptables(id)
```

#### Table `factures` (extension)
```sql
ALTER TABLE factures ADD COLUMN qr_code_hash TEXT;
ALTER TABLE factures ADD COLUMN document_securise_id INTEGER;
FOREIGN KEY (document_securise_id) REFERENCES documents_securises(id)
```

---

## 🔄 Plan de migration

### Phase 1 : Préparation (Semaine 1)

- [ ] Créer les migrations de base de données
- [ ] Créer les nouveaux modèles de données
- [ ] Créer les services de base (QR Code, sécurité)
- [ ] Tests unitaires des nouveaux modèles

### Phase 2 : Extension modules existants (Semaine 2)

- [ ] Étendre `AdherentModel` avec catégorisation
- [ ] Étendre `VenteModel` avec lien client
- [ ] Ajouter génération QR Code aux factures existantes
- [ ] Migrer les données existantes (catégorie par défaut)

### Phase 3 : Nouveaux modules (Semaine 3-4)

- [ ] Module Clients (CRUD complet)
- [ ] Module Capital Social (parts sociales)
- [ ] Module Comptabilité (écritures automatiques)
- [ ] Module Social (aides sociales)

### Phase 4 : Intégration UI (Semaine 5)

- [ ] Ajouter les nouveaux menus dans MainLayout
- [ ] Créer les écrans pour nouveaux modules
- [ ] Intégrer QR Code dans les PDF existants
- [ ] Tableaux de bord enrichis

### Phase 5 : Tests et validation (Semaine 6)

- [ ] Tests d'intégration
- [ ] Tests de régression
- [ ] Validation avec utilisateurs
- [ ] Documentation utilisateur

---

## 🔐 Sécurité et QR Code

### Format QR Code

```json
{
  "type": "facture|recu|bordereau|etat_compte",
  "id": "12345",
  "hash": "sha256_hash_du_document",
  "date": "2024-01-15T10:30:00Z",
  "cooperative": "code_cooperative"
}
```

### Vérification hors ligne

1. Scanner QR Code
2. Extraire hash et ID
3. Comparer avec hash stocké en base
4. Afficher résultat de vérification

---

## ✅ Garanties de rétrocompatibilité

### Données existantes

- ✅ Tous les adhérents existants auront `categorie = 'producteur'` par défaut
- ✅ Toutes les ventes existantes auront `client_id = NULL` (optionnel)
- ✅ Les écritures comptables seront générées uniquement pour nouvelles opérations
- ✅ Les QR Codes seront générés à la demande pour documents existants

### Code existant

- ✅ Aucun changement breaking dans les modèles existants
- ✅ Méthodes existantes restent fonctionnelles
- ✅ Nouveaux champs optionnels par défaut
- ✅ Services existants non modifiés

---

## 📈 Indicateurs de succès

- ✅ Tous les tests existants passent
- ✅ Aucune perte de données
- ✅ Performance maintenue
- ✅ Nouveaux modules fonctionnels
- ✅ QR Code généré sur tous nouveaux documents

---

## 🚀 Prochaines étapes

1. Valider cette stratégie
2. Créer les migrations de base de données
3. Implémenter les nouveaux modèles
4. Développer les nouveaux services
5. Intégrer dans l'UI

---

**Document créé le** : $(date)  
**Version** : 1.0  
**Auteur** : Architecture Team

