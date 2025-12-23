# Module Facturation - Documentation Technique

## Vue d'ensemble

Le module Facturation permet de générer, gérer et suivre les factures PDF liées aux ventes de cacao et aux recettes des adhérents. Il assure un suivi officiel et formel des transactions avec génération automatique de factures professionnelles.

## Architecture

Le module suit l'architecture Clean Architecture + MVVM :

```
lib/
├── data/
│   └── models/
│       └── facture_model.dart              # Modèle de données Facture
├── services/
│   └── facture/
│       ├── facture_service.dart            # Service CRUD factures
│       └── facture_pdf_service.dart        # Service génération PDF
└── presentation/
    ├── providers/
    │   └── facture_provider.dart           # Provider pour l'état
    ├── viewmodels/
    │   └── facture_viewmodel.dart          # ViewModel avec logique métier
    └── screens/
        └── factures/
            ├── factures_list_screen.dart   # Liste avec filtres
            └── facture_detail_screen.dart  # Détails de la facture
```

## Structure de la base de données

### Table `factures`

```sql
CREATE TABLE factures (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  numero TEXT UNIQUE NOT NULL,
  adherent_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  montant_total REAL NOT NULL,
  date_facture TEXT NOT NULL,
  date_echeance TEXT,
  statut TEXT NOT NULL,
  notes TEXT,
  pdf_path TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  FOREIGN KEY (adherent_id) REFERENCES adherents(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
)
```

## Modèles de données

### FactureModel

Représente une facture avec toutes ses propriétés :

- `id` : Identifiant unique (auto-incrément)
- `numero` : Numéro de facture unique (format: FAC-V-YYYYMM-XXXX)
- `adherentId` : ID de l'adhérent
- `type` : Type de facture ('vente', 'recette', 'bordereau')
- `montantTotal` : Montant total de la facture
- `dateFacture` : Date d'émission
- `dateEcheance` : Date d'échéance (optionnel)
- `statut` : Statut ('brouillon', 'validee', 'payee', 'annulee')
- `notes` : Notes (contient les références aux ventes/recettes)
- `pdfPath` : Chemin du fichier PDF généré
- `createdBy` : ID de l'utilisateur ayant créé la facture
- `createdAt`, `updatedAt` : Dates de création/modification

### Génération du numéro de facture

Le numéro est généré automatiquement selon le format :
- Vente : `FAC-V-YYYYMM-XXXX` (ex: FAC-V-202401-0001)
- Recette : `FAC-R-YYYYMM-XXXX` (ex: FAC-R-202401-0001)
- Bordereau : `FAC-B-YYYYMM-XXXX` (ex: FAC-B-202401-0001)

## Services

### FactureService

Service principal pour toutes les opérations CRUD.

#### Méthodes principales :

- `generateNumero()` : Générer un numéro de facture unique
- `createFacture()` : Créer une facture
- `createFactureFromVente()` : Créer une facture depuis une vente
- `createFactureFromRecette()` : Créer une facture depuis une recette
- `updateFacture()` : Mettre à jour une facture
- `marquerPayee()` : Marquer une facture comme payée
- `annulerFacture()` : Annuler une facture
- `getAllFactures()` : Récupérer toutes les factures (avec filtres)
- `getFactureById()` : Récupérer une facture par ID
- `getFactureByNumero()` : Récupérer une facture par numéro
- `searchFactures()` : Rechercher des factures
- `getStatistiques()` : Obtenir des statistiques

### FacturePdfService

Service pour la génération de PDF professionnels.

#### Méthodes principales :

- `generateFactureVente()` : Générer une facture PDF pour une vente
- `generateFactureRecette()` : Générer une facture PDF pour une recette
- `generateBordereauRecettes()` : Générer un bordereau PDF pour plusieurs recettes
- `printFacture()` : Imprimer une facture

#### Contenu des factures PDF :

1. **En-tête** :
   - Nom de la coopérative
   - Adresse, téléphone, email
   - Titre "FACTURE"

2. **Informations client** :
   - Nom et prénom de l'adhérent
   - Code adhérent
   - Village, téléphone, email

3. **Informations facture** :
   - Numéro de facture
   - Date d'émission
   - Date d'échéance (si applicable)
   - Statut

4. **Détails** :
   - Pour ventes : quantité, prix unitaire, montant, acheteur, mode de paiement
   - Pour recettes : montant brut, commission, montant net
   - Pour bordereaux : tableau détaillé de toutes les recettes

5. **Totaux** :
   - Montant total en évidence

6. **Pied de page** :
   - Date de génération
   - Nom de la coopérative

## ViewModel

### FactureViewModel

Gère l'état de l'application pour les factures :

- **État** :
  - Liste des factures
  - Facture sélectionnée
  - Adhérent, vente, recette associés
  - Filtres (adhérent, type, statut, dates)
  - Requête de recherche
  - États de chargement et erreurs

- **Méthodes principales** :
  - `loadFactures()` : Charger toutes les factures
  - `searchFactures()` : Rechercher
  - `setFilterAdherent()`, `setFilterType()`, `setFilterStatut()`, `setFilterDates()` : Appliquer des filtres
  - `generateFactureFromVente()` : Générer une facture depuis une vente
  - `generateFactureFromRecette()` : Générer une facture depuis une recette
  - `generateBordereauRecettes()` : Générer un bordereau
  - `loadFactureDetails()` : Charger les détails
  - `marquerPayee()` : Marquer comme payée
  - `annulerFacture()` : Annuler une facture
  - `getStatistiques()` : Obtenir des statistiques

## Écrans

### FacturesListScreen

Écran principal listant toutes les factures avec :
- Barre de recherche (par numéro, notes)
- Filtres par adhérent, type, statut
- Liste des factures avec informations principales
- Affichage du statut avec code couleur
- Navigation vers les détails

### FactureDetailScreen

Écran de détails d'une facture :
- Informations complètes de la facture
- Informations de l'adhérent
- Détails de la vente ou recette associée
- Actions : Voir PDF, Imprimer, Exporter, Marquer comme payée, Annuler

## Génération automatique

### Depuis les ventes

Lorsqu'une vente est créée, une facture peut être générée automatiquement :

```dart
// Dans VenteService après création d'une vente
final factureViewModel = FactureViewModel();
await factureViewModel.generateFactureFromVente(
  adherentId: adherentId,
  venteId: venteId,
  createdBy: currentUser.id!,
);
```

### Depuis les recettes

Lorsqu'une recette est créée, une facture peut être générée automatiquement :

```dart
// Dans RecetteService après création d'une recette
final factureViewModel = FactureViewModel();
await factureViewModel.generateFactureFromRecette(
  adherentId: adherentId,
  recetteId: recetteId,
  createdBy: currentUser.id!,
);
```

### Bordereaux de recettes

Pour générer un bordereau regroupant plusieurs recettes :

```dart
await factureViewModel.generateBordereauRecettes(
  adherentId: adherentId,
  recetteIds: [recetteId1, recetteId2, ...],
  startDate: startDate,
  endDate: endDate,
  createdBy: currentUser.id!,
);
```

## Intégration avec les autres modules

### Module Ventes

Le module Facturation peut générer des factures depuis les ventes :
- Facture individuelle : une facture par vente
- Facture groupée : une facture avec détails par adhérent

### Module Recettes

Le module Facturation peut générer :
- Factures de recette : une facture par recette
- Bordereaux : une facture regroupant plusieurs recettes

### Module Adhérents

Le module Facturation utilise les informations des adhérents pour :
- Afficher les informations client sur les factures
- Filtrer les factures par adhérent

## Routes

Les routes sont définies dans `config/routes/routes.dart` :

- `/factures` : Liste des factures
- `/factures/detail` : Détails d'une facture (avec argument int factureId)

## Gestion des statuts

### Statuts disponibles

1. **brouillon** : Facture en cours de création
2. **validee** : Facture validée et émise
3. **payee** : Facture payée
4. **annulee** : Facture annulée

### Transitions de statut

- `brouillon` → `validee` : Lors de la génération du PDF
- `validee` → `payee` : Lors du paiement
- `validee` → `annulee` : Lors de l'annulation
- `payee` → `annulee` : Annulation après paiement (avec raison)

## Export et impression

### Export PDF

Les factures sont sauvegardées dans le dossier `factures` du répertoire de documents :
- Format : `facture_FAC-V-YYYYMM-XXXX_timestamp.pdf`
- Chemin stocké dans `pdfPath` de la facture

### Impression

L'impression utilise le package `printing` :
- Aperçu avant impression
- Sélection de l'imprimante
- Options d'impression (copies, orientation, etc.)

### Export batch

Pour exporter plusieurs factures simultanément :
- Sélection multiple dans la liste
- Génération d'un PDF combiné ou export individuel
- Export Excel pour suivi interne

## Validation

### Règles de validation

1. **Numéro de facture** :
   - Généré automatiquement
   - Unique dans la base de données

2. **Montant total** :
   - Obligatoire
   - Doit être supérieur à 0

3. **Date de facture** :
   - Obligatoire
   - Ne peut pas être dans le futur

## Gestion des erreurs

Toutes les méthodes du service lancent des exceptions en cas d'erreur. Le ViewModel capture ces erreurs et les expose via `errorMessage`. Les écrans affichent les erreurs à l'utilisateur via `Fluttertoast`.

## Bonnes pratiques

1. **Générer automatiquement** les factures lors de la création de ventes/recettes
2. **Sauvegarder le chemin PDF** dans la base de données
3. **Valider les données** avant de générer le PDF
4. **Gérer les erreurs** de manière appropriée
5. **Utiliser le ViewModel** pour toute interaction avec les données
6. **Ne pas accéder directement au Service** depuis les écrans
7. **Régénérer le PDF** si le fichier est manquant

## Tests recommandés

- Test de génération de numéro unique
- Test de création de facture depuis une vente
- Test de création de facture depuis une recette
- Test de génération de bordereau
- Test de génération PDF
- Test d'impression
- Test de filtres et recherche
- Test de changement de statut

## Évolutions futures possibles

- Export Excel avec formules de calcul
- Envoi par email automatique
- Signature électronique
- Intégration avec systèmes comptables
- Templates personnalisables
- Multi-langue (français, anglais)
- QR codes pour vérification
- Archivage automatique
