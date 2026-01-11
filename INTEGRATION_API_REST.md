# Intégration API REST - CoopManager

## 📋 Vue d'ensemble

Ce document explique comment les interfaces Ventes et Adhérents ont été connectées aux APIs REST pour rendre l'application entièrement fonctionnelle.

## 🏗️ Architecture

### Structure des services API

```
lib/services/api/
├── api_client.dart              # Client HTTP générique avec gestion d'erreurs
├── api_exception.dart           # Exception personnalisée pour les erreurs API
├── adherent_api_service.dart    # Service API pour les adhérents
├── vente_api_service.dart       # Service API pour les ventes
├── stock_api_service.dart       # Service API pour les stocks
├── parametres_api_service.dart  # Service API pour les paramètres
├── client_api_service.dart      # Service API pour les clients
└── paiement_api_service.dart    # Service API pour les paiements
```

### Configuration

La configuration se trouve dans `lib/config/app_config.dart` :

```dart
// URL de base de l'API REST
static const String apiBaseUrl = 'http://localhost:8000/api';

// Mode de fonctionnement: 'api' pour APIs REST, 'local' pour SQLite
static const String dataSourceMode = 'api';
```

## 🔌 Endpoints API implémentés

### Adhérents

- `GET /adherents` - Liste des adhérents (avec pagination, filtres)
- `GET /adherents/{id}` - Détails d'un adhérent
- `GET /adherents/code/{code}` - Adhérent par code
- `POST /adherents` - Créer un adhérent
- `PUT /adherents/{id}` - Mettre à jour un adhérent
- `PATCH /adherents/{id}/status` - Activer/Désactiver
- `GET /adherents/search?q={query}` - Recherche
- `GET /adherents/villages` - Liste des villages
- `GET /adherents/check-code` - Vérifier l'existence d'un code
- `GET /adherents/next-code` - Générer le prochain code
- `GET /adherents/{id}/historique` - Historique d'un adhérent
- `GET /adherents/{id}/depots` - Dépôts d'un adhérent
- `GET /adherents/{id}/ventes` - Ventes d'un adhérent
- `GET /adherents/{id}/recettes` - Recettes d'un adhérent

### Ventes

- `GET /ventes` - Liste des ventes (avec filtres, pagination)
- `GET /ventes/{id}` - Détails d'une vente
- `POST /ventes` - Créer une vente V1
- `POST /ventes/individuelle` - Créer une vente individuelle
- `POST /ventes/groupee` - Créer une vente groupée
- `POST /ventes/{id}/annuler` - Annuler une vente
- `GET /ventes/{id}/details` - Détails d'une vente groupée
- `GET /ventes/search?q={query}` - Recherche
- `GET /ventes/statistiques` - Statistiques des ventes
- `POST /ventes/simulation` - Simuler une vente
- `POST /ventes/{id}/valider` - Valider une vente (workflow)

### Stocks

- `GET /stocks/disponibles/{adherentId}` - Stock disponible d'un adhérent
- `GET /stocks/disponibles` - Liste des stocks disponibles

### Paramètres

- `GET /parametres` - Paramètres de la coopérative
- `GET /parametres/prix` - Barèmes de prix
- `GET /parametres/commissions` - Configuration des commissions
- `GET /parametres/campagnes` - Liste des campagnes
- `GET /parametres/campagnes/active` - Campagne active
- `GET /parametres/baremes-qualite` - Barèmes de qualité

### Clients

- `GET /clients` - Liste des clients
- `GET /clients/{id}` - Détails d'un client

### Paiements

- `POST /paiements` - Enregistrer un paiement
- `GET /paiements/vente/{venteId}` - Paiements d'une vente

## 🔄 Utilisation dans les ViewModels

### Exemple avec AdherentViewModel

Le ViewModel utilise maintenant le wrapper hybride qui bascule automatiquement entre API et SQLite :

```dart
// Dans adherent_viewmodel.dart
final AdherentServiceApiWrapper _adherentService = AdherentServiceApiWrapper();

Future<void> loadAdherents() async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    _adherents = await _adherentService.getAllAdherents(
      isActive: _filterActive,
      village: _filterVillage,
    );
    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
    _isLoading = false;
    notifyListeners();
  }
}
```

## 🛠️ Modification des services existants

Pour utiliser les APIs au lieu de SQLite, modifier les services comme suit :

### Avant (SQLite)

```dart
class AdherentService {
  Future<List<AdherentModel>> getAllAdherents() async {
    final db = await DatabaseInitializer.database;
    final result = await db.query('adherents');
    return result.map((map) => AdherentModel.fromMap(map)).toList();
  }
}
```

### Après (API)

```dart
class AdherentService {
  final AdherentApiService _apiService = AdherentApiService();
  
  Future<List<AdherentModel>> getAllAdherents() async {
    return await _apiService.getAllAdherents();
  }
}
```

## 🔐 Authentification

Le client API gère automatiquement l'authentification via un token Bearer stocké dans SharedPreferences :

```dart
// Le token est automatiquement ajouté aux headers
headers['Authorization'] = 'Bearer $token';
```

Pour configurer le token après connexion :

```dart
final apiClient = ApiClient();
await apiClient.saveAuthToken('votre_token_jwt');
```

## ⚠️ Gestion des erreurs

Le client API gère automatiquement :

- **Erreurs réseau** : SocketException → Message utilisateur clair
- **Erreurs HTTP** : Codes 4xx/5xx → ApiException avec message métier
- **Timeouts** : 30 secondes par défaut
- **Format JSON invalide** : FormatException → Message d'erreur

Exemple de gestion dans les ViewModels :

```dart
try {
  final ventes = await _venteApiService.getAllVentes();
} on ApiException catch (e) {
  _errorMessage = e.message; // Message métier clair
} catch (e) {
  _errorMessage = 'Erreur inattendue: ${e.toString()}';
}
```

## 📦 Installation

1. Ajouter le package `http` dans `pubspec.yaml` :

```yaml
dependencies:
  http: ^1.1.0
```

2. Installer les dépendances :

```bash
flutter pub get
```

3. Configurer l'URL de l'API dans `lib/config/app_config.dart` :

```dart
static const String apiBaseUrl = 'https://votre-api.com/api';
```

## 🧪 Tests

Pour tester avec les APIs :

1. Définir `dataSourceMode = 'api'` dans `app_config.dart`
2. Configurer l'URL de l'API
3. S'assurer que le backend est accessible
4. Tester les fonctionnalités dans l'application

Pour revenir à SQLite local :

1. Définir `dataSourceMode = 'local'` dans `app_config.dart`

## 📝 Prochaines étapes

1. ✅ Créer le client API HTTP
2. ✅ Créer les services API pour Adhérents et Ventes
3. ⏳ Modifier les ViewModels pour utiliser les APIs
4. ⏳ Ajouter la pagination serveur dans les écrans
5. ⏳ Implémenter la gestion des transactions côté UI
6. ⏳ Ajouter les tests unitaires pour les services API

## 🔍 Dépannage

### Erreur de connexion réseau

Vérifier :
- L'URL de l'API est correcte dans `app_config.dart`
- Le backend est démarré et accessible
- Le firewall/autorisations réseau

### Erreur 401 Unauthorized

Vérifier :
- Le token d'authentification est valide
- Le token est bien sauvegardé dans SharedPreferences
- Le format du token est correct (Bearer token)

### Erreur 404 Not Found

Vérifier :
- Les endpoints API correspondent aux routes du backend
- Les paramètres de requête sont corrects

## 📚 Documentation complémentaire

- [Architecture Clean Architecture](./ARCHITECTURE.md)
- [Module Adhérents](./lib/ADHERENTS_MODULE.md)
- [Module Ventes](./lib/VENTES_MODULE.md)

















