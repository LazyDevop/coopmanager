# Architecture Admin Dashboard - CoopManager

## Vue d'ensemble

Cette architecture implémente un système de layout professionnel de type Admin Dashboard pour l'application Flutter Desktop CoopManager.

## Structure

```
lib/presentation/layout/
├── main_layout.dart          # Layout principal global
├── header/
│   └── app_header.dart       # Header fixe avec recherche, notifications, profil
└── sidebar/
    └── app_sidebar.dart      # Sidebar fixe avec navigation dynamique
```

## Principes fondamentaux

### 1. Un seul layout global

Le `MainLayout` est le **seul** layout global de l'application. Il contient :
- Un Header fixe en haut
- Un Sidebar fixe à gauche
- Une zone de contenu dynamique au centre

### 2. Pages sans Scaffold

**IMPORTANT** : Toutes les pages métiers doivent être des widgets simples **sans Scaffold**.

❌ **Mauvais exemple** :
```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(  // ❌ NE PAS utiliser Scaffold
      appBar: AppBar(...),  // ❌ NE PAS utiliser AppBar
      body: ...
    );
  }
}
```

✅ **Bon exemple** :
```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(  // ✅ Utiliser Container ou Column/Row
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Titre de la page'),
          // Contenu de la page
        ],
      ),
    );
  }
}
```

### 3. Navigation centralisée

La navigation est gérée par le `MainAppShell` qui utilise le `MainLayout`. Les pages sont injectées dans le layout via le Navigator interne.

## Utilisation

### Créer une nouvelle page

1. **Créer le widget de contenu** (sans Scaffold) :
```dart
// lib/presentation/screens/mon_module/ma_page_content.dart
class MaPageContent extends StatelessWidget {
  const MaPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text('Titre de ma page'),
          // Contenu de la page
        ],
      ),
    );
  }
}
```

2. **Ajouter la route dans `main_app_shell.dart`** :
```dart
case AppRoutes.maPage:
  screen = const MaPageContent();
  break;
```

3. **Ajouter l'item de menu dans `navigation_service.dart`** (si nécessaire) :
```dart
NavigationItem(
  title: 'Ma Page',
  icon: Icons.my_icon,
  route: AppRoutes.maPage,
  module: 'mon_module',
),
```

### Gestion des états

#### État de chargement local
```dart
if (isLoading) {
  return const LocalLoader(message: 'Chargement...');
}
```

#### État vide
```dart
if (items.isEmpty) {
  return const EmptyState(
    icon: Icons.inbox,
    title: 'Aucun élément',
    message: 'Ajoutez votre premier élément',
  );
}
```

#### État d'erreur
```dart
if (error != null) {
  return ErrorState(
    message: error,
    onRetry: () => loadData(),
  );
}
```

### Gestion des rôles

Le Sidebar affiche automatiquement uniquement les modules accessibles selon le rôle de l'utilisateur.

Les permissions sont gérées par :
- `PermissionService` : Vérifie les permissions
- `NavigationService` : Filtre les modules selon le rôle

### Exemple complet

```dart
// lib/presentation/screens/adherents/adherents_list_content.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/local_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../viewmodels/adherent_viewmodel.dart';

class AdherentsListContent extends StatelessWidget {
  const AdherentsListContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdherentViewModel>(
      builder: (context, viewModel, _) {
        // État de chargement
        if (viewModel.isLoading && viewModel.adherents.isEmpty) {
          return const LocalLoader(message: 'Chargement des adhérents...');
        }

        // État d'erreur
        if (viewModel.errorMessage != null) {
          return ErrorState(
            message: viewModel.errorMessage!,
            onRetry: () => viewModel.loadAdherents(),
          );
        }

        // État vide
        if (viewModel.filteredAdherents.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline,
            title: 'Aucun adhérent trouvé',
            message: 'Ajoutez votre premier adhérent',
          );
        }

        // Contenu normal
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Titre
              Text(
                'Liste des adhérents',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              // Liste
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.filteredAdherents.length,
                  itemBuilder: (context, index) {
                    final adherent = viewModel.filteredAdherents[index];
                    return ListTile(
                      title: Text(adherent.fullName),
                      // ...
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

## Composants disponibles

### Layout
- `MainLayout` : Layout principal global
- `AppHeader` : Header fixe
- `AppSidebar` : Sidebar fixe

### Widgets communs
- `LocalLoader` : Loader local pour une section
- `EmptyState` : État vide
- `ErrorState` : État d'erreur
- `LoadingOverlay` : Overlay de chargement global

## Bonnes pratiques

1. **Ne jamais utiliser Scaffold dans les pages métiers**
2. **Utiliser les widgets d'état** (LocalLoader, EmptyState, ErrorState)
3. **Gérer les permissions** via PermissionService
4. **Navigation via Navigator interne** (pas rootNavigator)
5. **Padding cohérent** : Utiliser `EdgeInsets.all(24.0)` pour les pages

## Migration depuis l'ancien système

Pour migrer une page existante :

1. Retirer le `Scaffold` et l'`AppBar`
2. Envelopper le contenu dans un `Container` avec padding
3. Utiliser les widgets d'état (LocalLoader, EmptyState, ErrorState)
4. Mettre à jour la route dans `main_app_shell.dart`

## Support

Pour toute question ou problème, consulter les exemples dans :
- `lib/presentation/screens/dashboard/dashboard_content.dart`
- `lib/presentation/screens/adherents/adherents_list_screen.dart` (à migrer)

