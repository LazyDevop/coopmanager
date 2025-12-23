# Guide d'utilisation des composants UI/UX CoopManager

Ce guide explique comment utiliser les nouveaux composants UI/UX créés pour CoopManager.

## Structure des composants

```
lib/presentation/widgets/
├── common/              # Composants réutilisables
│   ├── loading_indicator.dart
│   ├── status_badge.dart
│   ├── stat_card.dart
│   ├── data_table_widget.dart
│   ├── toast_helper.dart
│   ├── form_field_widget.dart
│   └── confirmation_dialog.dart
├── layout/              # Layouts principaux
│   └── main_layout.dart
└── dashboard/            # Composants spécifiques au dashboard
    ├── dashboard_stats.dart
    └── dashboard_charts.dart
```

## Thème et couleurs

Le thème personnalisé est défini dans `lib/config/theme/app_theme.dart`.

### Utilisation du thème

```dart
import 'package:coop_manager/config/theme/app_theme.dart';

// Dans MaterialApp
theme: AppTheme.lightTheme,
```

### Couleurs disponibles

- `AppTheme.primaryColor` - Marron cacao (#8B4513)
- `AppTheme.secondaryColor` - Vert cacao (#6B8E23)
- `AppTheme.accentColor` - Beige (#D2B48C)
- `AppTheme.successColor` - Vert succès (#4CAF50)
- `AppTheme.errorColor` - Rouge erreur (#E53935)
- `AppTheme.warningColor` - Orange avertissement (#FF9800)
- `AppTheme.infoColor` - Bleu information (#2196F3)

## Layout principal

### MainLayout

Le `MainLayout` fournit le menu latéral et la barre supérieure pour tous les écrans.

```dart
import 'package:coop_manager/presentation/widgets/layout/main_layout.dart';
import 'package:coop_manager/config/routes/routes.dart';

MainLayout(
  currentRoute: AppRoutes.adherents,
  title: 'Gestion des Adhérents',
  child: YourContentWidget(),
)
```

**Fonctionnalités :**
- Menu latéral avec navigation
- Barre supérieure avec recherche globale
- Badge de notifications
- Profil utilisateur avec menu déroulant
- Menu collapsible

## Composants communs

### LoadingIndicator

Indicateur de chargement personnalisé.

```dart
import 'package:coop_manager/presentation/widgets/common/loading_indicator.dart';

LoadingIndicator(
  message: 'Chargement...',
  size: 50.0,
  color: AppTheme.primaryColor,
)
```

### LoadingOverlay

Overlay de chargement pour les opérations.

```dart
LoadingOverlay(
  isLoading: viewModel.isLoading,
  message: 'Enregistrement...',
  child: YourContentWidget(),
)
```

### LoadingButton

Bouton avec indicateur de chargement intégré.

```dart
import 'package:coop_manager/presentation/widgets/common/loading_button.dart';

LoadingButton(
  text: 'Enregistrer',
  icon: Icons.save,
  isLoading: viewModel.isSaving,
  onPressed: () => viewModel.save(),
)
```

### StatusBadge

Badge de statut avec icône et couleur.

```dart
import 'package:coop_manager/presentation/widgets/common/status_badge.dart';

// Badge personnalisé
StatusBadge(
  label: 'Actif',
  color: AppTheme.successColor,
  icon: Icons.check_circle,
)

// Badges prédéfinis
StatusBadges.success('Validé')
StatusBadges.error('Erreur')
StatusBadges.warning('Attention')
StatusBadges.stockLow()
StatusBadges.validated()
```

### StatCard

Carte de statistique pour le tableau de bord.

```dart
import 'package:coop_manager/presentation/widgets/common/stat_card.dart';

StatCard(
  title: 'Adhérents',
  value: '150',
  icon: Icons.people,
  color: AppTheme.adherentColor,
  subtitle: '120 actifs',
  onTap: () => Navigator.pushNamed(context, AppRoutes.adherents),
)
```

### DataTableWidget

Tableau de données avec recherche et filtres.

```dart
import 'package:coop_manager/presentation/widgets/common/data_table_widget.dart';

DataTableWidget<AdherentModel>(
  data: adherents,
  isLoading: isLoading,
  searchHint: 'Rechercher un adhérent...',
  searchFilter: (adherent) => '${adherent.nom} ${adherent.prenom}',
  actions: [
    LoadingButton(
      text: 'Ajouter',
      icon: Icons.add,
      onPressed: () => Navigator.pushNamed(context, AppRoutes.adherentAdd),
    ),
  ],
  columns: const [
    DataColumn(label: Text('Nom')),
    DataColumn(label: Text('Téléphone')),
    DataColumn(label: Text('Statut')),
  ],
  buildRow: (adherent, index) {
    return DataRow(
      cells: [
        DataCell(Text(adherent.nom)),
        DataCell(Text(adherent.telephone ?? '-')),
        DataCell(StatusBadges.success('Actif')),
      ],
    );
  },
)
```

### ToastHelper

Helper pour afficher des toasts.

```dart
import 'package:coop_manager/presentation/widgets/common/toast_helper.dart';

// Toasts simples
ToastHelper.showSuccess('Opération réussie');
ToastHelper.showError('Une erreur est survenue');
ToastHelper.showWarning('Attention');
ToastHelper.showInfo('Information');

// Snackbar avec actions
CustomSnackbar.showSuccess(context, 'Données sauvegardées');
CustomSnackbar.showError(context, 'Erreur de sauvegarde');
CustomSnackbar.showWithUndo(
  context,
  message: 'Élément supprimé',
  onUndo: () => viewModel.undoDelete(),
);
```

### FormFieldWidget

Champ de formulaire amélioré.

```dart
import 'package:coop_manager/presentation/widgets/common/form_field_widget.dart';

FormFieldWidget(
  label: 'Nom',
  hint: 'Entrez le nom',
  controller: _nomController,
  prefixIcon: Icons.person,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Le nom est requis';
    }
    return null;
  },
)
```

### FormFieldWithStatus

Champ avec indicateur de statut.

```dart
FormFieldWithStatus(
  label: 'Code adhérent',
  controller: _codeController,
  status: FormFieldStatus.success,
  statusMessage: 'Code disponible',
  prefixIcon: Icons.badge,
)
```

### ConfirmationDialog

Dialog de confirmation personnalisé.

```dart
import 'package:coop_manager/presentation/widgets/common/confirmation_dialog.dart';

final confirmed = await ConfirmationDialog.show(
  context,
  title: 'Confirmer la suppression',
  message: 'Êtes-vous sûr de vouloir supprimer cet élément ?',
  confirmText: 'Supprimer',
  confirmColor: AppTheme.errorColor,
);

if (confirmed == true) {
  // Effectuer la suppression
}
```

## Composants Dashboard

### DashboardStats

Widget pour afficher les statistiques du tableau de bord.

```dart
import 'package:coop_manager/presentation/widgets/dashboard/dashboard_stats.dart';

DashboardStats()
```

### Graphiques

#### SalesBarChart

Graphique en barres pour les ventes.

```dart
import 'package:coop_manager/presentation/widgets/dashboard/dashboard_charts.dart';

SalesBarChart(
  data: {
    'Lun': 150000.0,
    'Mar': 180000.0,
    'Mer': 200000.0,
  },
  title: 'Ventes de la semaine',
)
```

#### PieChartWidget

Graphique en camembert.

```dart
PieChartWidget(
  data: {
    'Premium': 45.0,
    'Standard': 35.0,
    'Bio': 20.0,
  },
  title: 'Répartition du stock',
)
```

#### TrendLineChart

Graphique en ligne pour les tendances.

```dart
TrendLineChart(
  data: [
    {'value': 100},
    {'value': 150},
    {'value': 120},
  ],
  title: 'Évolution des recettes',
)
```

## Exemple d'intégration complète

Voir les fichiers suivants pour des exemples complets :

- `lib/presentation/screens/dashboard_screen_improved.dart` - Tableau de bord amélioré
- `lib/presentation/screens/adherents/adherents_list_screen_improved.dart` - Liste des adhérents améliorée

## Migration depuis les écrans existants

Pour migrer un écran existant vers le nouveau design :

1. **Remplacer le Scaffold par MainLayout**
   ```dart
   // Avant
   Scaffold(
     appBar: AppBar(...),
     body: ...,
   )
   
   // Après
   MainLayout(
     currentRoute: AppRoutes.yourRoute,
     title: 'Titre de la page',
     child: ...,
   )
   ```

2. **Utiliser les nouveaux composants**
   - Remplacer `CircularProgressIndicator` par `LoadingIndicator`
   - Remplacer les toasts par `ToastHelper`
   - Utiliser `DataTableWidget` pour les tableaux
   - Utiliser `StatusBadge` pour les statuts

3. **Appliquer le thème**
   - Utiliser les couleurs de `AppTheme`
   - Utiliser les styles du thème Material 3

4. **Ajouter les indicateurs de chargement**
   - Utiliser `LoadingOverlay` pour les opérations longues
   - Utiliser `LoadingButton` pour les boutons d'action

## Bonnes pratiques

1. **Cohérence visuelle** : Utiliser toujours les composants du thème plutôt que des couleurs hardcodées
2. **Feedback utilisateur** : Toujours afficher un feedback (toast/snackbar) après une action
3. **Indicateurs de chargement** : Toujours afficher un indicateur pour les opérations asynchrones
4. **Gestion d'erreurs** : Utiliser `ToastHelper.showError()` pour les erreurs
5. **Confirmations** : Utiliser `ConfirmationDialog` pour les actions critiques

## Dépendances requises

Assurez-vous d'avoir les dépendances suivantes dans `pubspec.yaml` :

```yaml
dependencies:
  flutter_spinkit: ^5.2.0
  fl_chart: ^0.66.0
  fluttertoast: ^8.2.4
```

## Support

Pour toute question ou problème, consultez les fichiers d'exemple ou contactez l'équipe de développement.
