# DashboardLayout - Guide d'utilisation

## Vue d'ensemble

Le `DashboardLayout` est un widget Flutter qui fournit une structure de layout de type dashboard/admin panel avec :

- ✅ **Header fixe** en haut avec recherche, notifications et profil utilisateur
- ✅ **Sidebar fixe** à gauche avec menu de navigation
- ✅ **Zone de contenu dynamique** à droite où chaque page charge son propre contenu
- ✅ **Compatible desktop et web** Flutter
- ✅ **Navigation sans recréer le layout** complet (seul le `child` change)
- ✅ **Mise en évidence automatique** de l'élément de menu actif
- ✅ **Respect des patterns Flutter** (pas de GlobalKey partagées)

## Structure

```
┌─────────────────────────────────────────────────┐
│  Sidebar (fixe)  │  Header (fixe)               │
│                  ├───────────────────────────────┤
│  Menu            │  Recherche | Notif | Profil │
│  Navigation      ├───────────────────────────────┤
│                  │                               │
│  [Dashboard]     │  Contenu dynamique (child)   │
│  [Adhérents]     │                               │
│  [Stock]         │  ← Cette zone change selon    │
│  [Ventes]        │     la navigation            │
│  ...             │                               │
│                  │                               │
└──────────────────┴───────────────────────────────┘
```

## Utilisation de base

### 1. Dans une page simple

```dart
import 'package:flutter/material.dart';
import '../../config/routes/routes.dart';
import '../widgets/dashboard_layout.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: AppRoutes.adherents,
      child: Column(
        children: [
          // Votre contenu ici
          Text('Ma page'),
        ],
      ),
    );
  }
}
```

### 2. Avec callback sur changement de route

```dart
DashboardLayout(
  currentRoute: AppRoutes.dashboard,
  onRouteChanged: (route) {
    debugPrint('Route changée vers: $route');
    // Faire quelque chose lors du changement de route
  },
  child: MyContent(),
)
```

### 3. Intégration avec MainAppShell

Le `DashboardLayout` peut remplacer le `MainLayout` actuel dans `MainAppShell` :

```dart
// Dans main_app_shell.dart
return DashboardLayout(
  currentRoute: _currentRoute,
  onRouteChanged: (route) {
    _onRouteChanged(route);
  },
  child: Navigator(
    key: _navigatorKey,
    initialRoute: _currentRoute,
    onGenerateRoute: (settings) {
      // ... votre logique de routing
    },
  ),
);
```

## Caractéristiques

### Sidebar

- **Largeur** : 260px (expanded) ou 70px (collapsed)
- **Animation** : Transition fluide de 200ms
- **Couleur** : `Colors.brown.shade800` (personnalisable)
- **Menu items** : Générés automatiquement selon le rôle utilisateur via `NavigationService`
- **Mise en évidence** : L'élément actif est automatiquement mis en évidence

### Header

- **Hauteur** : 70px (fixe)
- **Contenu** :
  - Barre de recherche globale
  - Bouton notifications avec badge (nombre de non lues)
  - Profil utilisateur avec menu déroulant (déconnexion, profil)

### Zone de contenu

- **Flexible** : Utilise `Expanded` pour s'adapter à la taille disponible
- **Scrollable** : Les pages peuvent utiliser `SingleChildScrollView` si nécessaire
- **Responsive** : S'adapte automatiquement à différentes tailles d'écran

## Migration depuis MainLayout

Si vous utilisez actuellement `MainLayout`, la migration vers `DashboardLayout` est simple :

### Avant (MainLayout)

```dart
MainLayout(
  currentRoute: AppRoutes.dashboard,
  child: MyContent(),
)
```

### Après (DashboardLayout)

```dart
DashboardLayout(
  currentRoute: AppRoutes.dashboard,
  child: MyContent(),
)
```

Les deux widgets ont la même interface, donc la migration est transparente.

## Personnalisation

### Changer les couleurs

Modifiez directement dans `dashboard_layout.dart` :

```dart
// Sidebar
color: Colors.brown.shade800,  // Ligne ~102

// Header
color: Colors.white,  // Ligne ~223
```

### Ajouter des éléments au header

Modifiez la méthode `_buildHeader` dans `dashboard_layout.dart` :

```dart
Widget _buildHeader(...) {
  return Container(
    // ... votre code
    child: Row(
      children: [
        // Vos éléments personnalisés
        YourCustomWidget(),
        // ... éléments existants
      ],
    ),
  );
}
```

### Personnaliser les items de menu

Les items de menu sont générés par `NavigationService.getSidebarModules(user)`. 
Pour ajouter/modifier des items, modifiez `navigation_service.dart`.

## Exemples

Voir `dashboard_layout_example.dart` pour des exemples complets d'utilisation.

## Bonnes pratiques

1. **Ne pas créer de Scaffold dans les pages** : Le `DashboardLayout` fournit déjà le `Scaffold`
2. **Utiliser `rootNavigator: false`** : Pour la navigation interne qui garde la sidebar visible
3. **Retourner uniquement le contenu** : Les pages doivent retourner leur contenu, pas un `Scaffold`
4. **Utiliser `currentRoute` correctement** : Assurez-vous que la route correspond à la page actuelle

## Compatibilité

- ✅ Flutter 3.x+
- ✅ Desktop (Windows, macOS, Linux)
- ✅ Web
- ✅ Mobile (avec adaptations possibles)

## Support

Pour toute question ou problème, consultez le code source dans `dashboard_layout.dart` ou les exemples dans `dashboard_layout_example.dart`.
