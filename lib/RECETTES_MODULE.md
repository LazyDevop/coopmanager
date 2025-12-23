# Module de Gestion des Recettes - CoopManager

## Vue d'ensemble

Ce module gère les recettes des adhérents après les ventes de cacao dans l'application CoopManager. Il calcule automatiquement les recettes nettes après commission et permet de générer des bordereaux PDF pour les paiements.

## Architecture

```
lib/
├── data/
│   └── models/
│       └── recette_model.dart           # Modèle RecetteModel et RecetteSummaryModel
├── services/
│   └── recette/
│       └── recette_service.dart         # Service de gestion des recettes
└── presentation/
    ├── viewmodels/
    │   └── recette_viewmodel.dart       # ViewModel de gestion des recettes (MVVM)
    └── screens/
        ├── recettes_list_screen.dart     # Liste des recettes par adhérent
        ├── recette_detail_screen.dart    # Détail des recettes d'un adhérent
        ├── recette_bordereau_screen.dart # Génération de bordereau PDF
        └── recette_export_screen.dart    # Export PDF/CSV
```

## Fonctionnalités

### 1. Calcul automatique des recettes

Chaque vente enregistrée génère automatiquement une recette correspondante pour l'adhérent.

**Formule de calcul :**
```
Recette nette = Montant brut - (Montant brut × Commission / 100)
```

- La commission est récupérée depuis les paramètres de la coopérative
- Taux par défaut : 5% (configurable dans le module Paramétrage)
- Historique des calculs conservé dans la base de données

### 2. Bordereau PDF

Génération automatique d'un bordereau de recette pour chaque adhérent avec :

- **Informations adhérent** : Nom, code, téléphone
- **Détails des ventes** : Date, quantité, prix unitaire, montant brut
- **Commission appliquée** : Taux et montant
- **Recette nette** : Montant à payer à l'adhérent
- **Total général** : Résumé des montants

Le bordereau peut être :
- Généré immédiatement après une vente
- Généré sur demande pour une période donnée
- Imprimé directement depuis l'application
- Exporté en PDF pour remise au caissier ou à l'adhérent

### 3. Historique des recettes

- Liste complète des recettes par adhérent et par période
- Consultation par adhérent, date ou campagne
- Export PDF / Excel possible
- Historique mis à jour automatiquement après chaque vente

### 4. Interface utilisateur

- **Écran principal** : Tableau listant tous les adhérents avec leurs recettes nettes
- **Filtres** : Par période, adhérent, ou campagne
- **Boutons** :
  - Consulter bordereau PDF
  - Historique complet
  - Export PDF/Excel
- **Vue détaillée** : Par adhérent avec ventes, montant brut, commission, recette nette

## Utilisation

### Créer une recette automatiquement après une vente

```dart
final recetteService = RecetteService();

await recetteService.createRecetteFromVente(
  adherentId: adherentId,
  venteId: venteId,
  montantBrut: montantBrut,
  createdBy: currentUser.id!,
);
```

### Créer une recette manuelle

```dart
final recetteService = RecetteService();

await recetteService.createRecetteManuelle(
  adherentId: adherentId,
  montantBrut: 100000.0,
  dateRecette: DateTime.now(),
  notes: 'Paiement exceptionnel',
  createdBy: currentUser.id!,
);
```

### Obtenir les recettes d'un adhérent

```dart
final recetteService = RecetteService();
final recettes = await recetteService.getRecettesByAdherent(adherentId);
```

### Obtenir le résumé des recettes

```dart
final recetteService = RecetteService();
final summary = await recetteService.getRecettesSummary(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
);
```

### Générer un bordereau PDF

```dart
final recetteService = RecetteService();
final ventes = await recetteService.getVentesForBordereau(
  adherentId,
  startDate: startDate,
  endDate: endDate,
);
// Utiliser ces données pour générer le PDF
```

## Intégration avec les autres modules

### Module Ventes

Lorsqu'une vente est enregistrée, une recette est automatiquement créée via `createRecetteFromVente()`.

**Exemple d'intégration dans le service de ventes :**

```dart
// Après création d'une vente
final venteId = await db.insert('ventes', venteData);

// Créer automatiquement la recette
final recetteService = RecetteService();
await recetteService.createRecetteFromVente(
  adherentId: adherentId,
  venteId: venteId,
  montantBrut: montantTotal,
  createdBy: currentUser.id!,
);
```

### Module Adhérents

Les recettes sont affichées dans le détail d'un adhérent.

### Module Facturation

Les recettes peuvent être utilisées pour générer des factures de paiement.

## Base de données

### Table `recettes`

- `id` : Identifiant unique
- `adherent_id` : Référence à l'adhérent
- `vente_id` : Référence à la vente (peut être null pour recettes manuelles)
- `montant_brut` : Montant brut de la vente
- `commission_rate` : Taux de commission (ex: 0.05 pour 5%)
- `commission_amount` : Montant de la commission
- `montant_net` : Montant net à payer (brut - commission)
- `date_recette` : Date de la recette
- `notes` : Notes optionnelles
- `created_by` : Utilisateur qui a créé la recette
- `created_at` : Date de création

## Permissions

- **Administrateur** : Accès complet (consultation, génération bordereaux, export)
- **Caissier** : Consultation, génération bordereaux, export
- **Gestionnaire Stock** : Consultation uniquement
- **Superviseur** : Consultation uniquement

## Scénarios d'utilisation

### Scénario 1 : Vente enregistrée → Calcul automatique

1. Un caissier enregistre une vente
2. Le système calcule automatiquement la recette nette
3. La recette est enregistrée dans la base de données
4. L'historique est mis à jour

### Scénario 2 : Génération de bordereau

1. L'utilisateur sélectionne un adhérent
2. Clique sur "Générer bordereau PDF"
3. Le système génère un PDF avec toutes les ventes et recettes
4. Le PDF peut être imprimé ou sauvegardé

### Scénario 3 : Consultation historique

1. L'utilisateur accède au module Recettes
2. Filtre par période ou adhérent
3. Consulte le résumé des recettes
4. Exporte en PDF ou Excel si nécessaire

### Scénario 4 : Modification/Annulation de vente

1. Une vente est modifiée ou annulée
2. La recette associée est mise à jour ou supprimée
3. L'historique est automatiquement corrigé

## Tests

### Scénarios de test

1. **Création automatique après vente**
   - Enregistrer une vente
   - Vérifier que la recette est créée automatiquement
   - Vérifier les calculs (montant brut, commission, montant net)

2. **Génération de bordereau**
   - Générer un bordereau pour un adhérent
   - Vérifier le contenu du PDF
   - Vérifier les totaux

3. **Export PDF/Excel**
   - Exporter toutes les recettes
   - Vérifier le format et le contenu

4. **Filtres**
   - Filtrer par période
   - Filtrer par adhérent
   - Vérifier les résultats

## Notes pour les développeurs

### Modifier le taux de commission

Le taux de commission est récupéré depuis la table `coop_settings`. Pour le modifier :

1. Accéder au module Paramétrage Coopérative
2. Modifier le taux de commission
3. Les nouvelles recettes utiliseront le nouveau taux

### Ajouter des champs personnalisés

Pour ajouter des champs personnalisés aux recettes :

1. Ajouter la colonne dans la table `recettes` via une migration
2. Mettre à jour `RecetteModel`
3. Mettre à jour `RecetteService`
4. Mettre à jour les écrans si nécessaire

### Améliorer les performances

Pour de grandes quantités de données :

- Pagination dans les listes
- Index supplémentaires sur les colonnes fréquemment utilisées
- Cache des résumés calculés

## Support

Pour toute question ou problème, consultez la documentation Flutter ou contactez l'équipe de développement.

