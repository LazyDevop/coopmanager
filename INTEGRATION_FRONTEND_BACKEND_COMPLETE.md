# 🚀 INTÉGRATION FRONTEND ↔ BACKEND COMPLÈTE
## COOPMANAGER – ERP COOPÉRATIF

---

## 📋 TABLE DES MATIÈRES

1. [Architecture Globale](#architecture-globale)
2. [Contrats API Standardisés](#contrats-api-standardisés)
3. [Repositories avec Gestion Offline](#repositories-avec-gestion-offline)
4. [Synchronisation Offline](#synchronisation-offline)
5. [Gestion des Erreurs](#gestion-des-erreurs)
6. [Endpoints API Documentés](#endpoints-api-documentés)
7. [Workflows Critiques](#workflows-critiques)
8. [Guide d'Utilisation](#guide-dutilisation)

---

## 🏗️ ARCHITECTURE GLOBALE

### Structure des Couches

```
UI (Flutter Screens)
    ↓
ViewModel (State Management - Provider)
    ↓
Repository (Data Layer)
    ↓
API Service / Sync Service
    ↓
Backend API (REST)
    ↓
Database (PostgreSQL/MySQL avec Transactions)
```

### Flux de Données

1. **Mode Connecté** : UI → ViewModel → Repository → API Service → Backend → Database
2. **Mode Offline** : UI → ViewModel → Repository → SQLite Cache → Sync Queue → Backend (quand reconnecté)

---

## 📦 CONTRATS API STANDARDISÉS

### Format de Réponse Standard

Toutes les réponses API suivent le format suivant :

```dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final ApiMeta? meta;
  final ApiError? error;
}
```

**Exemple de Réponse Succès :**
```json
{
  "success": true,
  "message": "Vente créée avec succès",
  "data": {
    "id": 1,
    "type": "individuelle",
    "montant_total": 150000.0,
    ...
  },
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "user_id": 1,
    "module": "vente"
  }
}
```

**Exemple de Réponse Erreur :**
```json
{
  "success": false,
  "message": "Stock insuffisant",
  "error": {
    "code": "INSUFFICIENT_STOCK",
    "message": "Le stock disponible est de 50 kg, mais vous avez demandé 100 kg",
    "status_code": 400
  }
}
```

### Codes d'Erreur Normalisés

- `NETWORK_ERROR` : Erreur de connexion réseau
- `TIMEOUT_ERROR` : Timeout de la requête
- `UNAUTHORIZED` : Non authentifié
- `FORBIDDEN` : Permissions insuffisantes
- `NOT_FOUND` : Ressource introuvable
- `VALIDATION_ERROR` : Erreur de validation
- `INSUFFICIENT_STOCK` : Stock insuffisant
- `INVALID_PRICE` : Prix invalide
- `TRANSACTION_FAILED` : Échec de transaction
- `SYNC_CONFLICT` : Conflit de synchronisation

---

## 🔄 REPOSITORIES AVEC GESTION OFFLINE

### Architecture des Repositories

Chaque repository hérite de `BaseRepository` qui fournit :

1. **Méthodes CRUD standardisées**
2. **Gestion automatique offline**
3. **Gestion d'erreurs normalisée**
4. **Support de la synchronisation**

### Exemple : VenteRepository

```dart
class VenteRepository extends BaseRepository<VenteModel> {
  // Créer avec support offline automatique
  Future<VenteModel> createVenteIndividuelle({...}) async {
    return await createWithOfflineSupport(
      data: data,
      endpoint: '/api/v1/ventes/individuelle',
      module: 'vente',
      localId: {'id': null, 'adherent_id': adherentId},
    );
  }
}
```

### Repositories Disponibles

- ✅ `VenteRepository` : Gestion des ventes
- ✅ `AdherentRepository` : Gestion des adhérents
- ✅ `StockRepository` : Gestion du stock
- ✅ `RecetteRepository` : Gestion des recettes
- 🔄 `FactureRepository` : À créer
- 🔄 `ComptabiliteRepository` : À créer
- 🔄 `CapitalRepository` : À créer

---

## 📱 SYNCHRONISATION OFFLINE

### Principe de Fonctionnement

1. **Enregistrement Local** : Les actions sont d'abord enregistrées en SQLite
2. **Queue de Synchronisation** : Les actions sont ajoutées à une queue
3. **Synchronisation Automatique** : Le service sync tente de synchroniser toutes les 5 minutes
4. **Gestion des Conflits** : Détection et résolution des conflits

### Service de Synchronisation

```dart
final syncService = SyncService();

// Initialiser au démarrage de l'app
await syncService.initialize();

// Ajouter manuellement à la queue (géré automatiquement par les repositories)
await syncService.addToQueue(
  action: 'create',
  module: 'vente',
  endpoint: '/api/v1/ventes',
  data: {...},
);

// Synchroniser manuellement
await syncService.syncQueue();

// Obtenir les statistiques
final stats = await syncService.getSyncStats();
```

### Table SQLite de Synchronisation

```sql
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  action TEXT NOT NULL,           -- 'create', 'update', 'delete'
  module TEXT NOT NULL,            -- 'vente', 'adherent', etc.
  endpoint TEXT NOT NULL,          -- '/api/v1/ventes'
  data TEXT NOT NULL,              -- JSON des données
  created_at TEXT NOT NULL,
  synced_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0,
  local_id TEXT                    -- Mapping ID local → ID serveur
);
```

---

## ⚠️ GESTION DES ERREURS

### ErrorHandler Centralisé

```dart
final error = ErrorHandler.handleException(exception);

// Obtenir un message utilisateur-friendly
final message = ErrorHandler.getUserFriendlyMessage(error.code);

// Vérifier si l'erreur est récupérable
if (ErrorHandler.isRetryable(error.code)) {
  // Réessayer automatiquement
}

// Vérifier si reconnexion nécessaire
if (ErrorHandler.requiresReauth(error.code)) {
  // Rediriger vers login
}
```

### Affichage dans l'UI

```dart
try {
  await viewModel.createVente(...);
} catch (e) {
  if (e is ApiException) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ErrorHandler.getUserFriendlyMessage(
          ErrorHandler.handleException(e).code,
        )),
      ),
    );
  }
}
```

---

## 🌐 ENDPOINTS API DOCUMENTÉS

Voir le fichier `lib/services/api/endpoints_documentation.md` pour la documentation complète.

### Endpoints Principaux

#### Ventes
- `POST /api/v1/ventes/individuelle` : Créer une vente individuelle
- `POST /api/v1/ventes/groupee` : Créer une vente groupée
- `POST /api/v1/ventes/{id}/annuler` : Annuler une vente
- `POST /api/v1/ventes/simulation` : Simuler une vente
- `GET /api/v1/ventes/statistiques` : Statistiques

#### Adhérents
- `GET /api/v1/adherents` : Liste des adhérents
- `POST /api/v1/adherents` : Créer un adhérent
- `PUT /api/v1/adherents/{id}/statut` : Mettre à jour le statut
- `GET /api/v1/adherents/{id}/stock` : Stock disponible

#### Stock
- `POST /api/v1/stock/depot` : Créer un dépôt
- `GET /api/v1/stock/{adherent_id}/actuel` : Stock actuel

#### Synchronisation
- `POST /api/v1/sync` : Synchroniser les données offline
- `GET /api/v1/sync/status` : Statut de synchronisation
- `GET /api/v1/health` : Health check

---

## 🔁 WORKFLOWS CRITIQUES

### Workflow : Vente Complète

```
1. Utilisateur saisit les données de vente
   ↓
2. ViewModel appelle Repository.createVenteIndividuelle()
   ↓
3. Repository tente l'appel API
   ↓
4a. Si succès :
    - Backend exécute transaction atomique :
      * Débite le stock
      * Crée la vente
      * Calcule et crée la recette
      * Crée l'écriture comptable
      * Met à jour le capital
    - Retourne la vente créée
   ↓
4b. Si erreur réseau :
    - Ajoute à la queue offline
    - Retourne un modèle temporaire avec is_synced=false
   ↓
5. UI affiche le résultat
   ↓
6. SyncService synchronise automatiquement plus tard
```

### Workflow : Adhésion Actionnaire

```
1. Création de l'adhérent
   ↓
2. Backend valide le statut
   ↓
3. Création automatique de l'historique
   ↓
4. Calcul initial du capital
   ↓
5. Enregistrement comptable
```

---

## 📖 GUIDE D'UTILISATION

### 1. Utiliser un Repository dans un ViewModel

```dart
class VenteViewModel extends ChangeNotifier {
  final VenteRepository _repository = VenteRepository();
  
  Future<bool> createVente({...}) async {
    try {
      final vente = await _repository.createVenteIndividuelle(...);
      // Succès
      return true;
    } catch (e) {
      if (e is ApiException) {
        _errorMessage = ErrorHandler.getUserFriendlyMessage(
          ErrorHandler.handleException(e).code,
        );
      }
      return false;
    }
  }
}
```

### 2. Gérer le Mode Offline

```dart
// Vérifier si en ligne
final isOnline = await SyncService()._isOnline();

// Forcer la synchronisation
await SyncService().syncQueue();

// Obtenir les stats
final stats = await SyncService().getSyncStats();
print('En attente: ${stats['pending']}');
```

### 3. Afficher les Erreurs

```dart
try {
  await viewModel.createVente(...);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Vente créée avec succès')),
  );
} catch (e) {
  final error = ErrorHandler.handleException(e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ErrorHandler.getUserFriendlyMessage(error.code)),
      backgroundColor: Colors.red,
    ),
  );
}
```

### 4. Mettre à Jour un ViewModel Existant

**Avant :**
```dart
final venteService = VenteService();
final ventes = await venteService.getAllVentes();
```

**Après :**
```dart
final venteRepository = VenteRepository();
final ventes = await venteRepository.getAll('/api/v1/ventes');
```

---

## ✅ RÈGLES D'OR

1. ✅ **Aucune donnée affichée dans le frontend ne doit être calculée côté UI sans validation backend**
2. ✅ **Toutes les transactions critiques doivent être atomiques côté backend**
3. ✅ **Toutes les actions doivent être traçables (audit log)**
4. ✅ **Le mode offline doit être transparent pour l'utilisateur**
5. ✅ **Les erreurs doivent être gérées de manière cohérente**

---

## 🔧 PROCHAINES ÉTAPES

### À Implémenter

1. ✅ Contrats API standardisés
2. ✅ Repositories de base
3. ✅ Synchronisation offline
4. ✅ Gestion d'erreurs
5. 🔄 Mettre à jour tous les ViewModels pour utiliser les repositories
6. 🔄 Créer les repositories manquants (Facture, Comptabilité, Capital)
7. 🔄 Implémenter le système d'audit complet
8. 🔄 Tests d'intégration

### Backend à Développer

1. Implémenter les endpoints selon la documentation
2. Gérer les transactions SQL atomiques
3. Implémenter l'audit log automatique
4. Gérer les conflits de synchronisation
5. Valider toutes les règles métier côté backend

---

## 📚 FICHIERS CRÉÉS

### DTOs et Contrats
- `lib/data/dto/api_response.dart` : Format de réponse standardisé
- `lib/data/dto/sync_queue_item.dart` : Modèle pour la queue de sync

### Repositories
- `lib/data/repositories/base_repository.dart` : Repository de base
- `lib/data/repositories/vente_repository.dart` : Repository des ventes
- `lib/data/repositories/adherent_repository.dart` : Repository des adhérents
- `lib/data/repositories/stock_repository.dart` : Repository du stock
- `lib/data/repositories/recette_repository.dart` : Repository des recettes

### Services
- `lib/services/integration/error_handler.dart` : Gestionnaire d'erreurs
- `lib/services/integration/sync_service.dart` : Service de synchronisation

### Documentation
- `lib/services/api/endpoints_documentation.md` : Documentation complète des endpoints
- `INTEGRATION_FRONTEND_BACKEND_COMPLETE.md` : Ce document

---

## 🎯 CONCLUSION

L'architecture d'intégration Frontend ↔ Backend est maintenant en place avec :

- ✅ Contrats API standardisés
- ✅ Repositories avec gestion offline
- ✅ Synchronisation automatique
- ✅ Gestion d'erreurs normalisée
- ✅ Documentation complète

**Prochaine étape** : Mettre à jour les ViewModels existants pour utiliser les nouveaux repositories et implémenter le backend selon la documentation fournie.

