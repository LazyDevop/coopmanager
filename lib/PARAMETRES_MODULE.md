# Module de Paramétrage Coopérative - CoopManager

## Vue d'ensemble

Ce module permet de gérer les paramètres globaux de la coopérative de cacaoculteurs. Il permet de personnaliser et configurer certains aspects clés du fonctionnement du logiciel, notamment les informations de la coopérative, les paramètres financiers et la gestion des campagnes.

## Architecture

```
lib/
├── data/
│   └── models/
│       └── parametres_cooperative_model.dart  # Modèles ParametresCooperativeModel, CampagneModel, BaremeQualiteModel
├── services/
│   └── parametres/
│       └── parametres_service.dart            # Service de gestion des paramètres
└── presentation/
    ├── viewmodels/
    │   └── parametres_viewmodel.dart          # ViewModel de gestion des paramètres (MVVM)
    └── screens/
        └── parametres/
            ├── parametres_main_screen.dart     # Écran principal avec onglets
            ├── parametres_info_screen.dart      # Gestion des informations coopérative
            ├── parametres_finances_screen.dart  # Gestion des paramètres financiers
            ├── parametres_campagnes_screen.dart # Gestion des campagnes
            └── campagne_form_screen.dart        # Formulaire de création/modification campagne
```

## Fonctionnalités

### 1. Informations de la coopérative

- **Nom de la coopérative** : Nom officiel (obligatoire)
- **Logo** : Upload et affichage du logo
- **Adresse** : Adresse complète de la coopérative
- **Contacts** : Téléphone et email

Ces informations apparaissent automatiquement sur :
- Les factures PDF
- Les bordereaux de recette PDF
- Les documents exportés

### 2. Paramètres financiers

- **Taux de commission** : Pourcentage appliqué pour le calcul des recettes (ex: 5%)
- **Période de campagne** : Durée par défaut d'une campagne en jours
- **Barèmes par qualité** : Prix et commissions spécifiques pour chaque qualité de cacao :
  - Standard
  - Premium
  - Bio

Chaque barème peut définir :
- Prix minimum (FCFA/kg)
- Prix maximum (FCFA/kg)
- Taux de commission spécifique (optionnel, sinon utilise le taux général)

### 3. Gestion des campagnes

- **Création de campagnes** : Nom, dates début/fin, description
- **Activation/Désactivation** : Contrôle de l'état des campagnes
- **Vérification des chevauchements** : Empêche les campagnes actives qui se chevauchent
- **Association aux opérations** : Les ventes et dépôts peuvent être associés à une campagne active

## Utilisation

### Obtenir les paramètres

```dart
final parametresService = ParametresService();
final parametres = await parametresService.getParametres();

print('Nom: ${parametres.nomCooperative}');
print('Commission: ${parametres.commissionRate * 100}%');
```

### Mettre à jour les paramètres

```dart
final viewModel = context.read<ParametresViewModel>();

await viewModel.saveParametres(
  nomCooperative: 'Nouveau nom',
  adresse: 'Nouvelle adresse',
  telephone: '+1234567890',
  email: 'contact@cooperative.local',
  commissionRate: 0.06, // 6%
  updatedBy: currentUser.id!,
);
```

### Créer une campagne

```dart
final viewModel = context.read<ParametresViewModel>();

await viewModel.createCampagne(
  nom: 'Campagne 2024-2025',
  dateDebut: DateTime(2024, 1, 1),
  dateFin: DateTime(2024, 12, 31),
  description: 'Campagne principale de récolte',
  createdBy: currentUser.id!,
);
```

### Obtenir la campagne active

```dart
final parametresService = ParametresService();
final campagneActive = await parametresService.getCampagneActive();

if (campagneActive != null) {
  print('Campagne active: ${campagneActive.nom}');
}
```

### Gérer les barèmes

```dart
final viewModel = context.read<ParametresViewModel>();

await viewModel.saveBareme(
  qualite: 'premium',
  prixMin: 1500.0,
  prixMax: 2000.0,
  commissionRate: 0.03, // 3% pour le premium
);
```

## Base de données

### Table `coop_settings`

- `id` : Identifiant unique
- `nom_cooperative` : Nom de la coopérative
- `logo_path` : Chemin vers le fichier logo
- `adresse` : Adresse de la coopérative
- `telephone` : Numéro de téléphone
- `email` : Adresse email
- `commission_rate` : Taux de commission (ex: 0.05 pour 5%)
- `periode_campagne_days` : Durée par défaut d'une campagne en jours
- `date_debut_campagne` : Date de début de campagne (optionnel)
- `date_fin_campagne` : Date de fin de campagne (optionnel)
- `updated_at` : Date de dernière mise à jour

### Table `campagnes`

- `id` : Identifiant unique
- `nom` : Nom de la campagne
- `date_debut` : Date de début
- `date_fin` : Date de fin
- `description` : Description optionnelle
- `is_active` : Statut actif/inactif
- `created_at` : Date de création
- `updated_at` : Date de mise à jour

### Table `baremes_qualite`

- `id` : Identifiant unique
- `qualite` : Qualité du cacao (standard, premium, bio)
- `prix_min` : Prix minimum (FCFA/kg)
- `prix_max` : Prix maximum (FCFA/kg)
- `commission_rate` : Taux de commission spécifique (optionnel)
- `created_at` : Date de création
- `updated_at` : Date de mise à jour

## Permissions

- **Administrateur uniquement** : Accès complet à tous les paramètres
- Les autres rôles n'ont pas accès à ce module

## Intégration avec les autres modules

### Module Recettes

Le taux de commission est récupéré depuis les paramètres pour calculer les recettes nettes.

### Module Ventes

Les barèmes de qualité peuvent être utilisés pour suggérer les prix lors de la création d'une vente.

### Module Facturation

Les informations de la coopérative (nom, logo, adresse) sont utilisées dans les factures PDF.

### Module Stock

Les campagnes peuvent être utilisées pour filtrer les dépôts et mouvements de stock.

## Scénarios d'utilisation

### Scénario 1 : Configuration initiale

1. L'application démarre avec les paramètres par défaut
2. L'administrateur accède au module Paramétrage
3. Configure les informations de la coopérative
4. Définit le taux de commission
5. Crée la première campagne

### Scénario 2 : Modification du taux de commission

1. L'administrateur modifie le taux de commission dans Paramétrage > Finances
2. Les nouvelles recettes utilisent automatiquement le nouveau taux
3. Les recettes existantes ne sont pas modifiées

### Scénario 3 : Gestion de campagne

1. Création d'une nouvelle campagne pour la saison
2. Activation de la campagne
3. Les nouvelles opérations peuvent être associées à cette campagne
4. Désactivation de l'ancienne campagne

### Scénario 4 : Upload de logo

1. L'administrateur sélectionne un fichier image
2. Le logo est copié dans le répertoire de l'application
3. Le chemin est sauvegardé dans la base de données
4. Le logo apparaît sur tous les documents PDF générés

## Tests

### Scénarios de test

1. **Configuration initiale**
   - Vérifier que les paramètres par défaut sont créés
   - Vérifier l'accès au module avec les permissions

2. **Modification des paramètres**
   - Modifier le nom de la coopérative
   - Modifier le taux de commission
   - Vérifier que les modifications sont sauvegardées

3. **Upload de logo**
   - Sélectionner un fichier image
   - Vérifier que le logo est copié et sauvegardé
   - Vérifier l'affichage du logo

4. **Gestion des campagnes**
   - Créer une campagne
   - Vérifier qu'on ne peut pas créer de campagnes qui se chevauchent
   - Activer/Désactiver une campagne
   - Supprimer une campagne

5. **Barèmes de qualité**
   - Définir des barèmes pour chaque qualité
   - Vérifier la sauvegarde
   - Vérifier l'utilisation dans les autres modules

## Notes pour les développeurs

### Ajouter un nouveau paramètre

1. Ajouter la colonne dans la table `coop_settings` via une migration
2. Mettre à jour `ParametresCooperativeModel`
3. Mettre à jour `ParametresService`
4. Mettre à jour l'écran de paramétrage si nécessaire

### Utiliser le logo dans les PDF

```dart
// Dans un service d'export PDF
final parametres = await parametresService.getParametres();

if (parametres.logoPath != null && File(parametres.logoPath!).existsSync()) {
  final logoImage = pw.MemoryImage(
    File(parametres.logoPath!).readAsBytesSync(),
  );
  // Utiliser logoImage dans le PDF
}
```

### Utiliser les informations de la coopérative

```dart
final parametres = await parametresService.getParametres();

// Utiliser dans les en-têtes de documents
final header = '''
${parametres.nomCooperative}
${parametres.adresse ?? ''}
Téléphone: ${parametres.telephone ?? ''}
Email: ${parametres.email ?? ''}
''';
```

### Filtrer par campagne

```dart
final campagneActive = await parametresService.getCampagneActive();

if (campagneActive != null) {
  // Filtrer les ventes/dépôts par campagne
  final ventes = await db.query(
    'ventes',
    where: 'date_vente >= ? AND date_vente <= ?',
    whereArgs: [
      campagneActive.dateDebut.toIso8601String(),
      campagneActive.dateFin.toIso8601String(),
    ],
  );
}
```

## Support

Pour toute question ou problème, consultez la documentation Flutter ou contactez l'équipe de développement.

