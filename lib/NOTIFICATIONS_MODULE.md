# Module Notifications - Documentation Technique

## Vue d'ensemble

Le module Notifications centralise toutes les alertes et notifications de l'application CoopManager. Il gère les notifications locales (toast in-app), les notifications système Windows, et l'historique complet dans SQLite pour audit et suivi.

## Architecture

Le module suit l'architecture Clean Architecture + MVVM :

```
lib/
├── data/
│   └── models/
│       └── notification_model.dart          # Modèle de données Notification
├── services/
│   └── notification/
│       ├── notification_service.dart        # Service centralisé
│       └── export_notification_service.dart # Service d'export PDF
└── presentation/
    ├── providers/
    │   └── notification_provider.dart       # Provider pour l'état
    ├── viewmodels/
    │   └── notification_viewmodel.dart     # ViewModel avec logique métier
    └── screens/
        └── notifications/
            └── notifications_history_screen.dart # Historique avec filtres
```

## Structure de la base de données

### Table `notifications`

```sql
CREATE TABLE notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  titre TEXT NOT NULL,
  message TEXT NOT NULL,
  module TEXT,
  entity_type TEXT,
  entity_id INTEGER,
  user_id INTEGER,
  is_read INTEGER DEFAULT 0,
  priority TEXT DEFAULT 'normal',
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
)
```

## Modèles de données

### NotificationModel

Représente une notification avec toutes ses propriétés :

- `id` : Identifiant unique (auto-incrément)
- `type` : Type de notification ('info', 'success', 'warning', 'error', 'critical', etc.)
- `titre` : Titre de la notification
- `message` : Message détaillé
- `module` : Module source ('stock', 'ventes', 'recettes', 'factures', 'auth', 'settings')
- `entityType` : Type d'entité liée ('adherent', 'vente', 'recette', etc.)
- `entityId` : ID de l'entité liée
- `userId` : ID de l'utilisateur concerné (null pour notifications globales)
- `isRead` : Statut de lecture
- `priority` : Priorité ('low', 'normal', 'high', 'critical')
- `createdAt` : Date de création

## Services

### NotificationService

Service centralisé pour toutes les notifications. Singleton pour garantir une seule instance.

#### Initialisation

```dart
// Dans main.dart
await NotificationService().initialize();
```

#### Méthodes principales :

- `showToast()` : Afficher un toast in-app
- `showSystemNotification()` : Afficher une notification système Windows
- `logNotification()` : Logger une notification dans SQLite
- `notify()` : Méthode complète (toast + système + log)
- `getAllNotifications()` : Récupérer toutes les notifications (avec filtres)
- `markAsRead()` : Marquer comme lue
- `markAllAsRead()` : Marquer toutes comme lues
- `deleteNotification()` : Supprimer une notification
- `getUnreadCount()` : Obtenir le nombre de non lues

#### Méthodes spécialisées par module :

- `notifyDepotAdded()` : Dépôt ajouté
- `notifyStockLow()` : Stock faible
- `notifyStockCritical()` : Stock critique
- `notifyVenteCreated()` : Vente créée
- `notifyVenteAnnulee()` : Vente annulée
- `notifyRecetteCalculated()` : Recette calculée
- `notifyFactureGenerated()` : Facture générée
- `notifyUserLogin()` : Connexion utilisateur
- `notifyUserLogout()` : Déconnexion utilisateur
- `notifySettingsChanged()` : Paramètres modifiés

### ExportNotificationService

Service pour l'export PDF de l'historique des notifications.

- `exportNotifications()` : Génère un PDF avec toutes les notifications

## ViewModel

### NotificationViewModel

Gère l'état de l'application pour les notifications :

- **État** :
  - Liste des notifications
  - Compteur de non lues
  - Filtres (utilisateur, type, module, statut de lecture, dates)
  - Requête de recherche
  - États de chargement et erreurs

- **Méthodes principales** :
  - `initialize()` : Initialiser le service
  - `loadNotifications()` : Charger toutes les notifications
  - `searchNotifications()` : Rechercher
  - `setFilterUser()`, `setFilterType()`, `setFilterModule()`, etc. : Appliquer des filtres
  - `markAsRead()`, `markAllAsRead()` : Marquer comme lues
  - `deleteNotification()`, `deleteReadNotifications()` : Supprimer
  - `refreshUnreadCount()` : Rafraîchir le compteur

## Écrans

### NotificationsHistoryScreen

Écran d'historique des notifications avec :
- Badge avec compteur de non lues dans l'AppBar
- Barre de recherche
- Filtres par type, module, statut de lecture
- Liste des notifications avec :
  - Icône selon le type
  - Indicateur visuel pour les non lues
  - Informations complètes (titre, message, date, module)
- Actions : Marquer comme lu, Supprimer
- Menu : Tout marquer comme lu, Supprimer les lues, Exporter

## Types de notifications

### Par type

- **info** : Informations générales (bleu)
- **success** : Opérations réussies (vert)
- **warning** : Avertissements (orange)
- **error** : Erreurs (rouge)
- **critical** : Alertes critiques (rouge foncé)

### Par module

- **stock** : Dépôts, stock faible/critique
- **ventes** : Ventes créées, annulées
- **recettes** : Recettes calculées
- **factures** : Factures générées
- **auth** : Connexions/déconnexions
- **settings** : Modifications de paramètres

### Par priorité

- **low** : Faible priorité (pas de notification système)
- **normal** : Priorité normale
- **high** : Priorité élevée (notification système)
- **critical** : Priorité critique (notification système + toast rouge)

## Intégration avec les modules existants

### Module Stock

```dart
// Dans StockService.createDepot()
await _notificationService.notifyDepotAdded(
  adherentId: adherentId,
  quantite: quantite,
  userId: createdBy,
);

// Vérification automatique du stock dans getStockActuel()
await _checkStockAndNotify(adherentId, stockActuel);
```

### Module Ventes

```dart
// Dans VenteService.createVenteIndividuelle() ou createVenteGroupee()
await _notificationService.notifyVenteCreated(
  venteId: venteId,
  montant: montantTotal,
  userId: createdBy,
);

// Dans VenteService.annulerVente()
await _notificationService.notifyVenteAnnulee(
  venteId: venteId,
  raison: raison ?? '',
  userId: annulePar,
);
```

### Module Recettes

```dart
// Dans RecetteService.createRecetteFromVente() ou createRecetteManuelle()
await _notificationService.notifyRecetteCalculated(
  recetteId: id,
  montantNet: montantNet,
  userId: createdBy,
);
```

### Module Facturation

```dart
// Dans FactureService.createFacture()
await _notificationService.notifyFactureGenerated(
  numeroFacture: numero,
  montant: montantTotal,
  userId: createdBy,
);
```

### Module Authentification

```dart
// Dans AuthService.login()
await _notificationService.notifyUserLogin(
  username: username,
  userId: user.id!,
);

// Dans AuthService.logout()
await _notificationService.notifyUserLogout(
  username: username,
  userId: userId,
);
```

## Routes

Les routes sont définies dans `config/routes/routes.dart` :

- `/notifications` : Historique des notifications

## Gestion des permissions

Certaines notifications peuvent être filtrées selon les rôles :

- **Admin** : Voit toutes les notifications
- **Gestionnaire Stock** : Voit les notifications stock et ventes
- **Caissier** : Voit les notifications ventes, recettes et factures
- **Consultation** : Voit toutes les notifications en lecture seule

Le filtrage se fait dans `NotificationViewModel.loadNotifications()` en passant le `userId` de l'utilisateur connecté.

## Notifications système Windows

Les notifications système sont affichées :
- Automatiquement pour les priorités 'high' et 'critical'
- Sur demande avec `showSystem: true` dans `notify()`

Configuration Windows :
- Channel ID : `coop_manager_notifications`
- Channel Name : `Notifications CoopManager`
- Channel Description : `Notifications pour les événements de CoopManager`

## Toast in-app

Les toasts sont affichés avec des couleurs selon le type :
- **success** : Vert
- **error/critical** : Rouge
- **warning** : Orange
- **info** : Bleu

## Historique et audit

Toutes les notifications sont enregistrées dans SQLite pour :
- Audit et traçabilité
- Consultation ultérieure
- Export PDF/Excel
- Analyse des événements

## Export PDF

Le service d'export génère un PDF complet contenant :
- En-tête avec date d'édition
- Résumé (total, non lues, par type, par module)
- Tableau détaillé de toutes les notifications
- Pied de page

## Bonnes pratiques

1. **Toujours logger** les notifications importantes dans SQLite
2. **Utiliser les méthodes spécialisées** pour chaque type d'événement
3. **Respecter les priorités** pour éviter la surcharge de notifications
4. **Filtrer selon les rôles** pour la confidentialité
5. **Marquer comme lues** après consultation
6. **Nettoyer régulièrement** les anciennes notifications lues

## Tests recommandés

- Test de toast in-app
- Test de notification système Windows
- Test de logging dans SQLite
- Test de filtres et recherche
- Test de marquage comme lu
- Test d'export PDF
- Test d'intégration avec les modules

## Évolutions futures possibles

- Notifications push (si serveur ajouté)
- Sons personnalisés par type
- Notifications programmées
- Groupement de notifications similaires
- Préférences utilisateur pour les notifications
- Notifications email
- Intégration avec calendrier pour rappels
