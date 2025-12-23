# Module d'Authentification - CoopManager

## Vue d'ensemble

Ce module gère l'authentification, la gestion des utilisateurs et des rôles pour l'application CoopManager. Il suit une architecture Clean Architecture avec le pattern MVVM et utilise Provider pour la gestion d'état.

## Architecture

```
lib/
├── data/
│   └── models/
│       ├── user_model.dart          # Modèle de données utilisateur
│       └── audit_log_model.dart      # Modèle de logs d'audit
├── services/
│   ├── auth/
│   │   ├── auth_service.dart        # Service d'authentification
│   │   ├── user_service.dart        # Service de gestion des utilisateurs
│   │   ├── audit_service.dart       # Service de journalisation
│   │   └── permission_service.dart  # Service de gestion des permissions
│   └── database/
│       └── db_initializer.dart       # Initialisation de la base de données
└── presentation/
    ├── viewmodels/
    │   └── auth_viewmodel.dart       # ViewModel d'authentification (MVVM)
    ├── screens/
    │   ├── login_screen.dart         # Écran de connexion
    │   └── dashboard_screen.dart    # Tableaux de bord selon les rôles
    └── widgets/
        └── auth_wrapper.dart         # Wrapper pour la gestion de session
```

## Utilisateur par défaut

Lors de la première initialisation de la base de données, un utilisateur administrateur est créé automatiquement :

- **Username**: `admin`
- **Mot de passe**: `Admin@123`
- **Rôle**: `admin` (Administrateur)
- **Statut**: Actif

⚠️ **Important**: Changez le mot de passe par défaut après la première connexion en production.

## Rôles et Permissions

### Administrateur (`admin`)
- Accès complet à tous les modules
- Gestion des utilisateurs
- Configuration de l'application

### Gestionnaire Stock (`gestionnaire_stock`)
- Consultation des adhérents
- Gestion complète du stock (dépôts, mouvements)
- Consultation des ventes

### Caissier / Comptable (`caissier`)
- Consultation des adhérents et du stock
- Gestion des ventes (création, modification)
- Gestion des recettes
- Gestion des factures (création, impression)

### Superviseur (`consultation`)
- Accès en lecture seule à tous les modules
- Consultation des rapports et statistiques

## Utilisation

### Connexion

```dart
final authViewModel = context.read<AuthViewModel>();
final success = await authViewModel.login('username', 'password');

if (success) {
  final user = authViewModel.currentUser;
  // Rediriger vers le tableau de bord approprié
}
```

### Vérification de l'authentification

```dart
final authViewModel = context.watch<AuthViewModel>();

if (authViewModel.isAuthenticated) {
  // Utilisateur connecté
  final user = authViewModel.currentUser;
} else {
  // Rediriger vers le login
}
```

### Déconnexion

```dart
final authViewModel = context.read<AuthViewModel>();
await authViewModel.logout();
```

### Vérification des permissions

```dart
import 'package:coop_manager/services/auth/permission_service.dart';

final user = authViewModel.currentUser!;

// Vérifier une permission spécifique
if (PermissionService.hasPermission(user, 'manage_stock')) {
  // Afficher le bouton de gestion du stock
}

// Vérifier l'accès à un module
if (PermissionService.canAccessModule(user, 'stock')) {
  // Afficher le module stock
}

// Vérifier les actions CRUD
if (PermissionService.canCreate(user, 'adherents')) {
  // Afficher le bouton de création
}
```

## Sécurité

### Hashage des mots de passe

Les mots de passe sont hachés avec SHA-256 et un salt unique. Le format stocké est : `salt:hash`

Pour améliorer la sécurité en production, considérez l'utilisation de :
- **bcrypt** (via le package `bcrypt`)
- **Argon2** (via le package `argon2`)

### Validation

- Les champs username et password sont validés côté client
- Les mots de passe ne sont jamais stockés en clair
- Les sessions sont stockées dans SharedPreferences (local)

## Audit Log

Toutes les actions critiques sont journalisées automatiquement :

- Connexions (réussies et échouées)
- Déconnexions
- Création/modification/suppression d'utilisateurs
- Changements de rôles
- Réinitialisations de mot de passe

### Consultation des logs

```dart
final auditService = AuditService();

// Récupérer tous les logs
final logs = await auditService.getAuditLogs();

// Récupérer les logs d'un utilisateur
final userLogs = await auditService.getAuditLogs(userId: userId);

// Récupérer les connexions récentes
final logins = await auditService.getRecentLogins(limit: 50);
```

## Redirection selon le rôle

Après connexion réussie, l'utilisateur est redirigé automatiquement vers le tableau de bord correspondant à son rôle :

- **Admin** → `/dashboard` (tableau de bord complet)
- **Gestionnaire Stock** → `/stock` (module stock)
- **Caissier** → `/ventes` (module ventes)
- **Superviseur** → `/dashboard` (tableau de bord en lecture seule)

## Gestion de session

La session utilisateur est :
- Sauvegardée automatiquement dans SharedPreferences après connexion
- Chargée automatiquement au démarrage de l'application
- Supprimée lors de la déconnexion

## Tests

### Test de connexion

1. Lancer l'application
2. Utiliser les identifiants par défaut :
   - Username: `admin`
   - Password: `Admin@123`
3. Vérifier la redirection vers le tableau de bord

### Test de gestion d'erreurs

- Tentative de connexion avec un utilisateur inexistant
- Tentative de connexion avec un mot de passe incorrect
- Vérification des messages d'erreur affichés

## Dépendances

- `provider`: ^6.0.5 - Gestion d'état
- `sqflite_common_ffi`: ^2.3.1 - Base de données SQLite pour Desktop
- `shared_preferences`: ^2.2.2 - Stockage local des préférences
- `crypto`: ^3.0.3 - Hashage des mots de passe
- `path_provider`: ^2.1.1 - Chemins de fichiers

## Notes pour les développeurs

### Ajouter un nouveau rôle

1. Ajouter la constante dans `lib/config/app_config.dart`
2. Ajouter les permissions dans `lib/services/auth/permission_service.dart`
3. Ajouter le cas dans `_getDashboardRoute()` de `login_screen.dart`
4. Créer le tableau de bord spécifique si nécessaire

### Modifier le hashage des mots de passe

Pour utiliser bcrypt ou Argon2 :

1. Ajouter la dépendance dans `pubspec.yaml`
2. Modifier `hashPassword()` et `verifyPassword()` dans `auth_service.dart`
3. Migrer les mots de passe existants si nécessaire

### Ajouter une nouvelle permission

1. Ajouter la permission dans les listes de `permission_service.dart`
2. Utiliser `PermissionService.hasPermission()` dans les widgets concernés

## Support

Pour toute question ou problème, consultez la documentation Flutter ou contactez l'équipe de développement.

