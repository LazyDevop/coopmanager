# Module de Gestion des Stocks - CoopManager

## Vue d'ensemble

Ce module gère les stocks de cacao par adhérent dans l'application CoopManager. Il assure la traçabilité complète du cacao et sert de base pour le calcul des recettes et la gestion des ventes.

## Architecture

```
lib/
├── data/
│   └── models/
│       ├── stock_model.dart              # Modèle StockDepotModel et StockActuelModel
│       └── stock_movement_model.dart      # Modèle StockMovementModel
├── services/
│   └── stock/
│       └── stock_service.dart            # Service de gestion des stocks
└── presentation/
    ├── viewmodels/
    │   └── stock_viewmodel.dart          # ViewModel de gestion des stocks (MVVM)
    └── screens/
        ├── stock_list_screen.dart         # Liste des stocks par adhérent
        ├── stock_depot_form_screen.dart    # Formulaire d'ajout de dépôt
        ├── stock_movements_history_screen.dart  # Historique des mouvements
        ├── stock_adjustment_screen.dart    # Ajustement de stock
        └── stock_export_screen.dart        # Export PDF/CSV
```

## Fonctionnalités

### 1. Enregistrement des dépôts

- Enregistrement d'un dépôt de cacao par adhérent
- Champs : quantité (kg), qualité (standard/premium/bio), prix unitaire (optionnel), date, observations
- Validation des champs obligatoires
- Mise à jour automatique du stock total de l'adhérent
- Création automatique d'un mouvement de stock

### 2. Consultation du stock

- Liste complète des adhérents avec stock actuel
- Consultation détaillée par adhérent :
  - Dépôts effectués
  - Quantité restante
  - Qualité du cacao
- Indicateurs visuels des seuils de stock :
  - **Stock vide** (0 kg) : Rouge
  - **Stock critique** (< 10 kg) : Orange foncé
  - **Stock faible** (10-50 kg) : Orange clair
  - **Stock optimal** (50-200 kg) : Vert
  - **Stock élevé** (> 200 kg) : Bleu

### 3. Historique des mouvements

- Suivi de toutes les opérations affectant le stock :
  - Dépôts (ajout)
  - Ventes (déduction automatique)
  - Ajustements (corrections manuelles)
- Chaque mouvement inclut :
  - Type (dépôt, vente, ajustement)
  - Quantité (positive pour dépôt, négative pour vente/ajustement)
  - Date
  - Utilisateur qui a effectué l'opération
  - Commentaire ou note optionnelle
- Filtres disponibles :
  - Par adhérent
  - Par type de mouvement
  - Par période (date début/fin)

### 4. Ajustement de stock

- Fonctionnalité réservée aux administrateurs et gestionnaires de stock
- Permet d'ajouter ou retirer du stock manuellement
- Raison obligatoire pour chaque ajustement
- Validation : le retrait ne peut pas dépasser le stock actuel

### 5. Export des données

- Export PDF avec :
  - Résumé des stocks (total global, nombre d'adhérents, alertes)
  - Tableau détaillé des stocks par adhérent
  - Historique des mouvements
- Export CSV (compatible Excel) avec toutes les données

## Calcul automatique du stock

Le stock actuel d'un adhérent est calculé comme suit :

```
Stock Actuel = Somme des dépôts + Somme des mouvements (ventes/ajustements)
```

Les mouvements de type "vente" et "ajustement" sont négatifs, donc ils réduisent le stock.

## Utilisation

### Créer un dépôt

```dart
final stockViewModel = context.read<StockViewModel>();
final authViewModel = context.read<AuthViewModel>();

await stockViewModel.createDepot(
  adherentId: adherentId,
  quantite: 100.0, // kg
  prixUnitaire: 1500.0, // optionnel
  dateDepot: DateTime.now(),
  qualite: 'premium', // standard, premium, bio
  observations: 'Cacao de qualité supérieure',
  createdBy: authViewModel.currentUser!.id!,
);
```

### Calculer le stock actuel

```dart
final stockService = StockService();
final stockActuel = await stockService.getStockActuel(adherentId);
```

### Déduire du stock lors d'une vente

```dart
final stockService = StockService();
await stockService.deductStockForVente(
  adherentId: adherentId,
  quantite: 50.0, // kg vendus
  venteId: venteId,
  createdBy: currentUser.id!,
);
```

### Créer un ajustement

```dart
final stockViewModel = context.read<StockViewModel>();

await stockViewModel.createAjustement(
  adherentId: adherentId,
  quantite: -10.0, // négatif pour retrait
  raison: 'Perte due à l\'humidité',
  createdBy: currentUser.id!,
);
```

## Permissions

- **Administrateur** : Accès complet (création, consultation, ajustement, export)
- **Gestionnaire Stock** : Création de dépôts, consultation, ajustement
- **Caissier** : Consultation uniquement
- **Superviseur** : Consultation uniquement

## Intégration avec les autres modules

### Module Ventes

Lorsqu'une vente est enregistrée, le stock est automatiquement déduit via `deductStockForVente()`.

### Module Recettes

Le stock sert de base pour calculer les recettes des adhérents.

### Module Adhérents

Les stocks sont affichés dans le détail d'un adhérent.

## Base de données

### Table `stock_depots`

- `id` : Identifiant unique
- `adherent_id` : Référence à l'adhérent
- `quantite` : Quantité déposée (kg)
- `prix_unitaire` : Prix unitaire (optionnel)
- `date_depot` : Date du dépôt
- `qualite` : Qualité du cacao (standard, premium, bio)
- `notes` : Observations
- `created_by` : Utilisateur qui a créé le dépôt
- `created_at` : Date de création

### Table `stock_mouvements`

- `id` : Identifiant unique
- `adherent_id` : Référence à l'adhérent
- `type` : Type de mouvement (depot, vente, ajustement)
- `quantite` : Quantité (positive pour dépôt, négative pour vente/ajustement)
- `stock_depot_id` : Référence au dépôt (si type = depot)
- `vente_id` : Référence à la vente (si type = vente)
- `date_mouvement` : Date du mouvement
- `notes` : Commentaire
- `created_by` : Utilisateur qui a créé le mouvement
- `created_at` : Date de création

## Tests

### Scénarios de test

1. **Création d'un dépôt**
   - Créer un dépôt pour un adhérent
   - Vérifier que le stock actuel est mis à jour
   - Vérifier qu'un mouvement est créé

2. **Vente avec déduction**
   - Enregistrer une vente
   - Vérifier que le stock est déduit automatiquement
   - Vérifier qu'un mouvement de type "vente" est créé

3. **Ajustement de stock**
   - Créer un ajustement (ajout)
   - Créer un ajustement (retrait)
   - Vérifier que le stock est mis à jour correctement
   - Vérifier qu'un mouvement de type "ajustement" est créé

4. **Calcul du stock**
   - Vérifier le calcul du stock actuel après plusieurs opérations
   - Vérifier le stock par qualité

5. **Export**
   - Exporter en PDF
   - Exporter en CSV
   - Vérifier le contenu des fichiers exportés

## Notes pour les développeurs

### Ajouter une nouvelle qualité

1. Ajouter la qualité dans `AppConfig.qualitesCacao`
2. Le système prendra en charge automatiquement la nouvelle qualité

### Modifier les seuils de stock

Modifier les valeurs dans `StockActuelModel.status` getter dans `stock_model.dart` :

```dart
StockStatus get status {
  if (stockTotal <= 0) return StockStatus.vide;
  if (stockTotal < 10) return StockStatus.critique;  // Modifier ici
  if (stockTotal < 50) return StockStatus.faible;     // Modifier ici
  if (stockTotal < 200) return StockStatus.optimal;   // Modifier ici
  return StockStatus.eleve;
}
```

### Améliorer les performances

Pour de grandes quantités de données, considérer :
- Pagination dans les listes
- Index supplémentaires sur les colonnes fréquemment utilisées
- Cache des stocks calculés

## Support

Pour toute question ou problème, consultez la documentation Flutter ou contactez l'équipe de développement.

