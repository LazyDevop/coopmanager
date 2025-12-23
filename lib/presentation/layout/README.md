# Architecture Admin Dashboard - CoopManager

## 📋 Vue d'ensemble

Cette architecture implémente un système de layout professionnel de type **Admin Dashboard** pour l'application Flutter Desktop CoopManager, similaire aux dashboards ERP/CRM modernes (AdminLTE, Metronic, etc.).

## 🏗️ Structure

```
lib/presentation/layout/
├── main_layout.dart          # Layout principal global (UNIQUE)
├── header/
│   └── app_header.dart       # Header fixe avec recherche, notifications, profil
└── sidebar/
    └── app_sidebar.dart      # Sidebar fixe avec navigation dynamique selon rôles
```

## ✨ Caractéristiques

### ✅ Layout unique global
- Un seul `MainLayout` dans toute l'application
- Header fixe en haut
- Sidebar fixe à gauche
- Zone de contenu dynamique au centre

### ✅ Pages sans Scaffold
- Toutes les pages métiers sont de simples widgets
- Aucun Scaffold, AppBar ou menu dans les pages
- Contenu injecté dynamiquement dans le layout

### ✅ Navigation centralisée
- Navigation fluide sans rechargement du layout
- Gestion des routes via Navigator interne
- Sidebar et Header restent visibles lors de la navigation

### ✅ Gestion des rôles
- Sidebar dynamique selon le profil utilisateur
- Masquage automatique des menus non autorisés
- Permissions gérées via `PermissionService`

### ✅ UX professionnelle
- Indicateur de chargement global (overlay)
- Loaders locaux pour tableaux et formulaires
- Gestion des états vides et erreurs
- Icônes cohérentes (Material Icons)

## 🚀 Utilisation rapide

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
          Text('Titre de ma page', 
            style: Theme.of(context).textTheme.headlineMedium),
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

3. **Ajouter l'item de menu dans `navigation_service.dart`** :
```dart
NavigationItem(
  title: 'Ma Page',
  icon: Icons.my_icon,
  route: AppRoutes.maPage,
  module: 'mon_module',
),
```

## 📖 Documentation complète

Voir [ARCHITECTURE.md](./ARCHITECTURE.md) pour la documentation complète.

## 🎯 Exemples

- **Dashboard** : `lib/presentation/screens/dashboard_screen.dart`
- **Adhérents** : `lib/presentation/screens/adherents/adherents_list_screen.dart`
- **Exemple simple** : `lib/presentation/screens/dashboard/dashboard_content.dart`

## 🔧 Migration

Pour migrer une page existante :

1. ✅ Retirer le `Scaffold` et l'`AppBar`
2. ✅ Envelopper le contenu dans un `Container` avec padding
3. ✅ Utiliser les widgets d'état (LocalLoader, EmptyState, ErrorState)
4. ✅ Mettre à jour la route dans `main_app_shell.dart`

## 📦 Composants disponibles

### Layout
- `MainLayout` : Layout principal global
- `AppHeader` : Header fixe
- `AppSidebar` : Sidebar fixe

### Widgets communs
- `LocalLoader` : Loader local pour une section
- `EmptyState` : État vide
- `ErrorState` : État d'erreur
- `LoadingOverlay` : Overlay de chargement global

## ⚠️ Règles importantes

1. ❌ **NE JAMAIS** utiliser `Scaffold` dans les pages métiers
2. ❌ **NE JAMAIS** utiliser `AppBar` dans les pages métiers
3. ✅ **TOUJOURS** utiliser les widgets d'état (LocalLoader, EmptyState, ErrorState)
4. ✅ **TOUJOURS** utiliser `Navigator.of(context, rootNavigator: false)` pour la navigation interne
5. ✅ **TOUJOURS** utiliser `EdgeInsets.all(24.0)` pour le padding des pages

## 🎨 Rôles et permissions

Le système gère automatiquement les rôles suivants :
- **Administrateur** : Accès à tous les modules
- **Gestionnaire Stock** : Accès aux modules Stock et Adhérents
- **Caissier / Comptable** : Accès aux modules Ventes, Recettes, Factures
- **Superviseur / Consultation** : Accès en lecture seule

Les permissions sont gérées par :
- `PermissionService` : Vérifie les permissions
- `NavigationService` : Filtre les modules selon le rôle

## 📝 Notes

- Le layout est optimisé pour Desktop Windows (.exe)
- Compatible avec Flutter stable
- Architecture modulaire et maintenable
- Code propre et commenté

