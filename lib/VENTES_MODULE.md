# Module Ventes - Documentation Technique

## Vue d'ensemble

Le module Ventes permet de gérer les ventes de cacao des adhérents de la coopérative. Il gère automatiquement la mise à jour des stocks lors de la création d'une vente et permet de créer des ventes individuelles ou groupées.

## Architecture

Le module suit l'architecture Clean Architecture + MVVM :

```
lib/
├── data/
│   └── models/
│       ├── vente_model.dart              # Modèle de données Vente
│       └── vente_detail_model.dart       # Modèle pour les détails de ventes groupées
├── services/
│   └── vente/
│       ├── vente_service.dart            # Service CRUD et gestion stock
│       └── export_service.dart          # Service d'export PDF
└── presentation/
    ├── providers/
    │   └── vente_provider.dart           # Provider pour l'état
    ├── viewmodels/
    │   └── vente_viewmodel.dart          # ViewModel avec logique métier
    └── screens/
        └── ventes/
            ├── ventes_list_screen.dart   # Liste avec filtres
            ├── vente_form_screen.dart     # Formulaire création
            └── vente_detail_screen.dart   # Détails de la vente
```

## Structure de la base de données

### Table `ventes`

```sql
CREATE TABLE ventes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  adherent_id INTEGER,
  quantite_total REAL NOT NULL,
  prix_unitaire REAL NOT NULL,
  montant_total REAL NOT NULL,
  acheteur TEXT,
  mode_paiement TEXT,
  date_vente TEXT NOT NULL,
  notes TEXT,
  statut TEXT DEFAULT 'valide',
  created_by INTEGER,
  created_at TEXT NOT NULL,
  FOREIGN KEY (adherent_id) REFERENCES adherents(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
)
```

### Table `vente_details`

```sql
CREATE TABLE vente_details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  vente_id INTEGER NOT NULL,
  adherent_id INTEGER NOT NULL,
  quantite REAL NOT NULL,
  prix_unitaire REAL NOT NULL,
  montant REAL NOT NULL,
  FOREIGN KEY (vente_id) REFERENCES ventes(id),
  FOREIGN KEY (adherent_id) REFERENCES adherents(id)
)
```

## Modèles de données

### VenteModel

Représente une vente avec toutes ses propriétés :

- `id` : Identifiant unique (auto-incrément)
- `type` : Type de vente ('individuelle' ou 'groupee')
- `adherentId` : ID de l'adhérent (null pour ventes groupées)
- `quantiteTotal` : Quantité totale vendue en kg
- `prixUnitaire` : Prix unitaire par kg en FCFA
- `montantTotal` : Montant total de la vente
- `acheteur` : Nom de l'acheteur (optionnel)
- `modePaiement` : Mode de paiement ('especes', 'mobile_money', 'virement')
- `dateVente` : Date de la vente
- `notes` : Observations (optionnel)
- `statut` : Statut ('valide' ou 'annulee')
- `createdBy` : ID de l'utilisateur ayant créé la vente
- `createdAt` : Date de création

### VenteDetailModel

Représente un détail d'une vente groupée :

- `venteId` : ID de la vente
- `adherentId` : ID de l'adhérent
- `quantite` : Quantité vendue pour cet adhérent
- `prixUnitaire` : Prix unitaire
- `montant` : Montant pour cet adhérent

## Services

### VenteService

Service principal pour toutes les opérations CRUD et la gestion automatique du stock.

#### Méthodes principales :

- `createVenteIndividuelle()` : Créer une vente individuelle
  - Vérifie le stock disponible
  - Crée la vente
  - Déduit automatiquement du stock via StockService
  - Enregistre dans l'historique de l'adhérent

- `createVenteGroupee()` : Créer une vente groupée
  - Vérifie les stocks pour tous les adhérents
  - Crée la vente et les détails
  - Déduit automatiquement du stock pour chaque adhérent
  - Enregistre dans l'historique de chaque adhérent

- `annulerVente()` : Annuler une vente
  - Marque la vente comme annulée
  - Restaure automatiquement le stock
  - Enregistre dans l'historique

- `getAllVentes()` : Récupérer toutes les ventes (avec filtres)
- `getVenteById()` : Récupérer une vente par ID
- `getVenteDetails()` : Récupérer les détails d'une vente groupée
- `searchVentes()` : Rechercher des ventes
- `getStatistiques()` : Obtenir des statistiques sur les ventes

### ExportService

Service pour l'export PDF des ventes.

- `exportVente()` : Génère un PDF avec toutes les informations de la vente

## ViewModel

### VenteViewModel

Gère l'état de l'application pour les ventes :

- **État** :
  - Liste des ventes
  - Vente sélectionnée
  - Détails de la vente (pour ventes groupées)
  - Liste des adhérents
  - Filtres (adhérent, type, statut, dates)
  - Requête de recherche
  - États de chargement et erreurs

- **Méthodes principales** :
  - `loadVentes()` : Charger toutes les ventes
  - `searchVentes()` : Rechercher
  - `setFilterAdherent()`, `setFilterType()`, `setFilterStatut()`, `setFilterDates()` : Appliquer des filtres
  - `createVenteIndividuelle()`, `createVenteGroupee()` : Créer des ventes
  - `annulerVente()` : Annuler une vente
  - `loadVenteDetails()` : Charger les détails
  - `getStockDisponible()` : Obtenir le stock disponible d'un adhérent
  - `getStatistiques()` : Obtenir des statistiques

## Écrans

### VentesListScreen

Écran principal listant toutes les ventes avec :
- Barre de recherche (par acheteur, notes)
- Filtres par adhérent, type, statut
- Liste des ventes avec informations principales
- Affichage du statut (valide/annulée)
- Navigation vers les détails

### VenteFormScreen

Formulaire pour créer une vente :
- **Vente individuelle** :
  - Sélection de l'adhérent
  - Affichage du stock disponible
  - Saisie de la quantité et du prix unitaire
  - Informations sur l'acheteur et le mode de paiement
  - Validation des champs et vérification du stock

- **Vente groupée** :
  - Prix unitaire commun
  - Ajout de plusieurs adhérents avec leurs quantités
  - Affichage du stock disponible pour chaque adhérent
  - Calcul automatique des montants

### VenteDetailScreen

Écran de détails d'une vente :
- Informations complètes de la vente
- Pour les ventes groupées : liste des adhérents avec leurs quantités et montants
- Actions : Exporter en PDF, Annuler la vente

## Gestion automatique du stock

### Lors de la création d'une vente

1. **Vérification du stock** :
   - Le service vérifie que le stock disponible est suffisant
   - Lance une exception si le stock est insuffisant

2. **Création de la vente** :
   - La vente est enregistrée dans la base de données
   - Pour les ventes groupées, les détails sont également enregistrés

3. **Déduction du stock** :
   - Appel à `StockService.deductStockForVente()`
   - Création d'un mouvement de stock de type 'vente'
   - La quantité est déduite (négative) du stock

4. **Enregistrement dans l'historique** :
   - Appel à `AdherentService.logVente()`
   - L'opération est enregistrée dans l'historique de l'adhérent

### Lors de l'annulation d'une vente

1. **Marquage comme annulée** :
   - Le statut de la vente est changé en 'annulee'

2. **Restauration du stock** :
   - Création d'un ajustement de stock positif
   - Le stock est restauré pour chaque adhérent concerné

3. **Enregistrement dans l'historique** :
   - L'annulation est enregistrée dans l'historique avec des valeurs négatives

## Intégration avec les autres modules

### Module Stock

Le module Ventes utilise `StockService` pour :
- Vérifier le stock disponible avant une vente
- Déduire le stock lors de la création d'une vente
- Restaurer le stock lors de l'annulation

### Module Adhérents

Le module Ventes utilise `AdherentService` pour :
- Enregistrer les ventes dans l'historique des adhérents
- Récupérer la liste des adhérents actifs

### Module Recettes

Les ventes peuvent être liées aux recettes pour :
- Générer automatiquement les recettes lors du paiement
- Calculer les commissions

## Routes

Les routes sont définies dans `config/routes/routes.dart` :

- `/ventes` : Liste des ventes
- `/ventes/individuelle` : Formulaire de création vente individuelle
- `/ventes/groupee` : Formulaire de création vente groupée
- `/ventes/detail` : Détails d'une vente (avec argument int venteId)

## Validation

### Règles de validation

1. **Quantité** :
   - Obligatoire
   - Doit être supérieure à 0
   - Ne doit pas dépasser le stock disponible

2. **Prix unitaire** :
   - Obligatoire
   - Doit être supérieur à 0

3. **Date de vente** :
   - Obligatoire
   - Ne peut pas être dans le futur

4. **Adhérent** :
   - Obligatoire pour les ventes individuelles
   - Au moins un adhérent pour les ventes groupées

## Gestion des erreurs

Toutes les méthodes du service lancent des exceptions en cas d'erreur. Le ViewModel capture ces erreurs et les expose via `errorMessage`. Les écrans affichent les erreurs à l'utilisateur via `Fluttertoast`.

## Export PDF

Le service d'export génère un PDF complet contenant :
- Informations de la vente (type, date, montant, etc.)
- Pour les ventes groupées : détails par adhérent
- Informations sur l'acheteur et le mode de paiement

Le PDF est sauvegardé dans le dossier `exports` et peut être imprimé ou partagé.

## Scénarios d'utilisation

### Vente individuelle

1. L'utilisateur sélectionne un adhérent
2. Le système affiche le stock disponible
3. L'utilisateur saisit la quantité et le prix
4. Le système vérifie le stock et crée la vente
5. Le stock est automatiquement déduit
6. L'opération est enregistrée dans l'historique

### Vente groupée

1. L'utilisateur définit le prix unitaire commun
2. L'utilisateur ajoute plusieurs adhérents avec leurs quantités
3. Le système vérifie les stocks pour tous les adhérents
4. La vente est créée avec les détails
5. Le stock est déduit pour chaque adhérent
6. Les opérations sont enregistrées dans l'historique de chaque adhérent

### Annulation d'une vente

1. L'utilisateur sélectionne une vente valide
2. L'utilisateur confirme l'annulation (avec raison optionnelle)
3. La vente est marquée comme annulée
4. Le stock est restauré pour tous les adhérents concernés
5. L'annulation est enregistrée dans l'historique

## Bonnes pratiques

1. **Toujours vérifier le stock** avant de créer une vente
2. **Valider les données** avant de les sauvegarder
3. **Gérer les erreurs** de manière appropriée
4. **Utiliser le ViewModel** pour toute interaction avec les données
5. **Ne pas accéder directement au Service** depuis les écrans
6. **Enregistrer dans l'historique** toutes les opérations importantes

## Tests recommandés

- Test de création de vente individuelle avec stock suffisant
- Test de création de vente individuelle avec stock insuffisant
- Test de création de vente groupée
- Test d'annulation de vente
- Test de restauration du stock lors de l'annulation
- Test de filtres et recherche
- Test d'export PDF

## Évolutions futures possibles

- Export Excel en plus du PDF
- Génération automatique de factures
- Calcul automatique des commissions
- Intégration avec le module Recettes pour paiements automatiques
- Statistiques avancées et graphiques
- Notifications pour ventes importantes
