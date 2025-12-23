# Système de Navigation Dynamique et Gestion des Rôles - CoopManager

## Vue d'ensemble

Ce document décrit le système de navigation dynamique basé sur les rôles utilisateur implémenté pour CoopManager. Le système permet d'afficher différents modules, actions et données selon le rôle de l'utilisateur connecté.

## Architecture

### Composants principaux

1. **NavigationService** (`lib/services/navigation/navigation_service.dart`)
   - Gère la liste des modules accessibles selon le rôle
   - Filtre les modules pour chaque rôle

2. **MainLayout** (`lib/presentation/widgets/main_layout.dart`)
   - Layout principal avec menu latéral et barre supérieure
   - Menu latéral dynamique selon le rôle
   - Barre supérieure avec recherche, notifications et profil

3. **ScreenWrapper** (`lib/presentation/widgets/screen_wrapper.dart`)
   - Wrapper pour envelopper les écrans avec le layout principal

4. **EnhancedDashboardScreen** (`lib/presentation/screens/enhanced_dashboard_screen.dart`)
   - Dashboard amélioré avec graphiques et statistiques par rôle

5. **NotificationFilterService** (`lib/services/notification/notification_filter_service.dart`)
   - Filtre les notifications selon le rôle de l'utilisateur

6. **ConditionalActions** (`lib/presentation/widgets/common/conditional_actions.dart`)
   - Widgets pour afficher des actions conditionnelles selon les permissions

## Rôles et Permissions

### Administrateur (`admin`)
- **Modules accessibles** : Tous les modules
- **Actions** : Toutes les actions (créer, modifier, supprimer)
- **Notifications** : Toutes les notifications

### Caissier (`caissier`)
- **Modules accessibles** :
  - Tableau de bord
  - Ventes
  - Recettes
  - Facturation
  - Notifications
- **Actions** :
  - Créer, modifier, supprimer : Ventes, Recettes, Factures
  - Lecture seule : Adhérents, Stock
- **Notifications** :
  - Ventes validées
  - Recettes calculées
  - Bordereaux générés
  - Paiements en attente

### Magasinier (`gestionnaire_stock`)
- **Modules accessibles** :
  - Tableau de bord
  - Adhérents (lecture seule)
  - Stock
  - Notifications
- **Actions** :
  - Créer, modifier, supprimer : Stock, Dépôts
  - Lecture seule : Adhérents
- **Notifications** :
  - Stock faible
  - Stock critique
  - Dépôts récents

## Utilisation

### Envelopper un écran avec le layout principal

```dart
import '../widgets/screen_wrapper.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      currentRoute: AppRoutes.myRoute,
      child: Scaffold(
        body: // Votre contenu
      ),
    );
  }
}
```

### Utiliser les actions conditionnelles

```dart
import '../widgets/common/conditional_actions.dart';

ConditionalActions(
  user: user,
  entity: 'adherents',
  onAdd: () => Navigator.pushNamed(context, AppRoutes.adherentAdd),
  onEdit: () => _handleEdit(),
  onDelete: () => _handleDelete(),
)
```

### Utiliser un bouton conditionnel

```dart
ConditionalFAB(
  user: user,
  entity: 'ventes',
  onPressed: () => Navigator.pushNamed(context, AppRoutes.venteAdd),
  tooltip: 'Nouvelle vente',
)
```

### Filtrer les notifications par rôle

```dart
final notificationViewModel = context.read<NotificationViewModel>();
await notificationViewModel.loadNotifications(user: user);
final filteredNotifications = notificationViewModel.getFilteredNotifications(user);
```

## Widgets réutilisables

### ToastHelper
Affichage de messages toast et snackbar :

```dart
ToastHelper.showSuccess('Opération réussie');
ToastHelper.showError('Une erreur est survenue');
ToastHelper.showWarning('Attention');
ToastHelper.showInfo('Information');
ToastHelper.showSuccessSnackBar(context, 'Succès');
ToastHelper.showErrorSnackBar(context, 'Erreur');
ToastHelper.showSnackBarWithUndo(context, 'Action effectuée', onUndo: () {});
```

### StatusIndicators
Indicateurs de statut visuels :

```dart
StatusIndicators.stockLow()
StatusIndicators.stockOk()
StatusIndicators.venteValidee()
StatusIndicators.recetteCalculee()
StatusIndicators.depotEnAttente()
StatusIndicators.depotValide()
```

### LoadingIndicator
Indicateurs de chargement :

```dart
LoadingIndicator(message: 'Chargement...')
LoadingOverlay(isLoading: true, child: widget)
LoadingButton(
  text: 'Enregistrer',
  isLoading: isSaving,
  onPressed: () => _save(),
)
```

## Dashboard par rôle

### Administrateur
- Cartes : Adhérents, Stock total, Ventes, Recettes, Paiements, Alertes
- Graphiques : Évolution des ventes, Évolution du stock

### Caissier
- Cartes : Ventes, Recettes nettes, Paiements en attente
- Graphiques : Évolution des ventes

### Magasinier
- Cartes : Stock total, Dépôts récents, Stocks faibles
- Graphiques : Évolution du stock

## Notifications filtrées

Les notifications sont automatiquement filtrées selon le rôle :

- **Admin** : Voit toutes les notifications
- **Caissier** : Voit uniquement les notifications liées aux ventes, recettes et factures
- **Magasinier** : Voit uniquement les notifications liées au stock et aux adhérents

## Personnalisation

### Ajouter un nouveau module

1. Ajouter l'item dans `NavigationService._getAllModules()`
2. Ajouter les permissions dans `PermissionService`
3. Ajouter le filtre dans `NavigationService.getSidebarModules()`

### Ajouter un nouveau rôle

1. Ajouter la constante dans `AppConfig`
2. Ajouter les permissions dans `PermissionService`
3. Ajouter le filtre dans `NotificationFilterService`
4. Ajouter le dashboard dans `EnhancedDashboardScreen`

## Notes importantes

- Le système utilise Provider pour la gestion d'état
- Les permissions sont vérifiées côté client (à sécuriser côté serveur en production)
- Les notifications sont filtrées automatiquement selon le rôle
- Le menu latéral peut être réduit/agrandi
- La barre supérieure inclut une recherche globale (à implémenter)

## Prochaines étapes

- [ ] Implémenter la recherche globale
- [ ] Ajouter des animations de transition
- [ ] Implémenter le cache des données du dashboard
- [ ] Ajouter des tests unitaires
- [ ] Sécuriser les permissions côté serveur
