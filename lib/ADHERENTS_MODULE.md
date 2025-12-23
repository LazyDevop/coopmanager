# Module Adhérents - Documentation Technique

## Vue d'ensemble

Le module Adhérents est le cœur du système CoopManager. Il permet de gérer tous les adhérents de la coopérative de cacaoculteurs, leurs informations personnelles, et l'historique complet de leurs opérations (dépôts, ventes, recettes).

## Architecture

Le module suit l'architecture Clean Architecture + MVVM :

```
lib/
├── data/
│   └── models/
│       ├── adherent_model.dart              # Modèle de données Adhérent
│       └── adherent_historique_model.dart   # Modèle pour l'historique
├── services/
│   └── adherent/
│       ├── adherent_service.dart            # Service CRUD et historique
│       └── export_service.dart              # Service d'export PDF
└── presentation/
    ├── providers/
    │   └── adherent_provider.dart           # Provider pour l'état
    ├── viewmodels/
    │   └── adherent_viewmodel.dart          # ViewModel avec logique métier
    └── screens/
        └── adherents/
            ├── adherents_list_screen.dart    # Liste avec filtres
            ├── adherent_form_screen.dart     # Formulaire création/modification
            └── adherent_detail_screen.dart   # Détails avec onglets
```

## Structure de la base de données

### Table `adherents`

```sql
CREATE TABLE adherents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE NOT NULL,
  nom TEXT NOT NULL,
  prenom TEXT NOT NULL,
  telephone TEXT,
  email TEXT,
  village TEXT,
  adresse TEXT,
  cnib TEXT,
  date_naissance TEXT,
  date_adhesion TEXT NOT NULL,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT
)
```

### Table `adherent_historique`

```sql
CREATE TABLE adherent_historique (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  adherent_id INTEGER NOT NULL,
  type_operation TEXT NOT NULL,
  operation_id INTEGER,
  description TEXT NOT NULL,
  montant REAL,
  quantite REAL,
  date_operation TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL,
  FOREIGN KEY (adherent_id) REFERENCES adherents(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
)
```

## Modèles de données

### AdherentModel

Représente un adhérent avec toutes ses propriétés :

- `id` : Identifiant unique (auto-incrément)
- `code` : Code adhérent unique (obligatoire)
- `nom`, `prenom` : Nom et prénom (obligatoires)
- `telephone`, `email` : Coordonnées (optionnels)
- `village` : Localisation (optionnel)
- `adresse` : Adresse complète (optionnel)
- `cnib` : Numéro CNIB (optionnel)
- `dateNaissance` : Date de naissance (optionnel)
- `dateAdhesion` : Date d'adhésion (obligatoire)
- `isActive` : Statut actif/inactif
- `createdAt`, `updatedAt` : Dates de création/modification

### AdherentHistoriqueModel

Représente une entrée dans l'historique :

- `adherentId` : ID de l'adhérent
- `typeOperation` : Type ('depot', 'vente', 'recette', 'modification', etc.)
- `operationId` : ID de l'opération liée
- `description` : Description textuelle
- `montant`, `quantite` : Montants et quantités (optionnels)
- `dateOperation` : Date de l'opération
- `createdBy` : ID de l'utilisateur ayant créé l'entrée

## Services

### AdherentService

Service principal pour toutes les opérations CRUD et la gestion de l'historique.

#### Méthodes principales :

- `createAdherent()` : Créer un nouvel adhérent
- `updateAdherent()` : Mettre à jour un adhérent
- `toggleAdherentStatus()` : Activer/Désactiver un adhérent
- `getAllAdherents()` : Récupérer tous les adhérents (avec filtres)
- `getAdherentById()` : Récupérer par ID
- `getAdherentByCode()` : Récupérer par code
- `searchAdherents()` : Rechercher des adhérents
- `codeExists()` : Vérifier l'unicité du code
- `getAllVillages()` : Obtenir la liste des villages

#### Méthodes d'historique :

- `logDepot()` : Enregistrer un dépôt
- `logVente()` : Enregistrer une vente
- `logRecette()` : Enregistrer une recette
- `getHistorique()` : Récupérer l'historique avec filtres
- `getDepots()`, `getVentes()`, `getRecettes()` : Récupérer les opérations spécifiques

### ExportService

Service pour l'export PDF de l'historique.

- `exportAdherentHistorique()` : Génère un PDF complet avec toutes les informations

## ViewModel

### AdherentViewModel

Gère l'état de l'application pour les adhérents :

- **État** :
  - Liste des adhérents
  - Adhérent sélectionné
  - Historique, dépôts, ventes, recettes
  - Villages disponibles
  - Filtres (statut, village)
  - Requête de recherche
  - États de chargement et erreurs

- **Méthodes principales** :
  - `loadAdherents()` : Charger tous les adhérents
  - `searchAdherents()` : Rechercher
  - `setFilterActive()`, `setFilterVillage()` : Appliquer des filtres
  - `createAdherent()`, `updateAdherent()` : CRUD
  - `toggleAdherentStatus()` : Changer le statut
  - `loadAdherentDetails()` : Charger les détails complets

## Écrans

### AdherentsListScreen

Écran principal listant tous les adhérents avec :
- Barre de recherche
- Filtres par statut et village
- Liste des adhérents avec informations principales
- Actions : Consulter, Modifier, Activer/Désactiver

### AdherentFormScreen

Formulaire pour créer ou modifier un adhérent :
- Validation des champs obligatoires
- Vérification de l'unicité du code
- Sélection de dates avec DatePicker
- Gestion des erreurs

### AdherentDetailScreen

Écran de détails avec onglets :
1. **Informations** : Toutes les données personnelles
2. **Dépôts** : Historique des dépôts de cacao
3. **Ventes** : Historique des ventes
4. **Recettes** : Historique des paiements reçus

Actions disponibles :
- Modifier l'adhérent
- Activer/Désactiver
- Exporter l'historique en PDF

## Intégration avec les autres modules

Le module Adhérents est utilisé par :

1. **Module Stock** : Pour enregistrer les dépôts liés à un adhérent
2. **Module Ventes** : Pour associer les ventes à un adhérent
3. **Module Recettes** : Pour enregistrer les paiements reçus par un adhérent

### Enregistrement automatique dans l'historique

Lorsqu'un dépôt, une vente ou une recette est créé dans les autres modules, ils doivent appeler les méthodes correspondantes du `AdherentService` :

```dart
// Dans le module Stock après création d'un dépôt
await adherentService.logDepot(
  adherentId: adherentId,
  depotId: depotId,
  quantite: quantite,
  montant: montant,
  dateDepot: dateDepot,
  createdBy: currentUser.id,
);

// Dans le module Ventes après création d'une vente
await adherentService.logVente(
  adherentId: adherentId,
  venteId: venteId,
  quantite: quantite,
  montant: montant,
  dateVente: dateVente,
  createdBy: currentUser.id,
);

// Dans le module Recettes après création d'une recette
await adherentService.logRecette(
  adherentId: adherentId,
  recetteId: recetteId,
  montantNet: montantNet,
  dateRecette: dateRecette,
  createdBy: currentUser.id,
);
```

## Routes

Les routes sont définies dans `config/routes/routes.dart` :

- `/adherents` : Liste des adhérents
- `/adherents/add` : Formulaire de création
- `/adherents/edit` : Formulaire de modification (avec argument AdherentModel)
- `/adherents/detail` : Détails (avec argument int adherentId)

## Validation

### Règles de validation

1. **Code adhérent** :
   - Obligatoire
   - Minimum 3 caractères
   - Unique dans la base de données

2. **Nom et Prénom** :
   - Obligatoires
   - Non vides

3. **Email** :
   - Optionnel
   - Si renseigné, doit contenir '@' et '.'

4. **Date d'adhésion** :
   - Obligatoire
   - Ne peut pas être dans le futur

## Gestion des erreurs

Toutes les méthodes du service lancent des exceptions en cas d'erreur. Le ViewModel capture ces erreurs et les expose via `errorMessage`. Les écrans affichent les erreurs à l'utilisateur via `Fluttertoast`.

## Export PDF

Le service d'export génère un PDF complet contenant :
- Informations personnelles de l'adhérent
- Historique des opérations
- Détails des dépôts
- Détails des ventes
- Détails des recettes

Le PDF est sauvegardé dans le dossier `exports` du répertoire de documents de l'application et peut être imprimé ou partagé.

## Bonnes pratiques

1. **Toujours vérifier l'unicité du code** avant la création
2. **Enregistrer dans l'historique** toutes les opérations importantes
3. **Valider les données** avant de les sauvegarder
4. **Gérer les erreurs** de manière appropriée
5. **Utiliser le ViewModel** pour toute interaction avec les données
6. **Ne pas accéder directement au Service** depuis les écrans

## Tests recommandés

- Test de création d'adhérent avec code unique
- Test de validation des champs obligatoires
- Test de recherche et filtres
- Test d'activation/désactivation
- Test d'enregistrement dans l'historique
- Test d'export PDF

## Évolutions futures possibles

- Export Excel en plus du PDF
- Import en masse depuis un fichier CSV/Excel
- Statistiques et graphiques par adhérent
- Notifications pour événements importants
- Photos des adhérents
- Géolocalisation des villages
