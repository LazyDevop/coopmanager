# Module de Paramétrage Backend - Architecture Complète

## 🎯 Vue d'ensemble

Ce module implémente une architecture backend robuste, modulaire et évolutive pour la gestion centralisée de tous les paramètres de l'application CoopManager. Il suit les principes de Clean Architecture avec support multi-coopérative.

## 🏗️ Architecture

```
lib/
├── data/
│   └── models/
│       └── backend/
│           ├── cooperative_model.dart              # Modèle coopérative
│           ├── setting_model.dart                 # Modèle settings générique
│           └── specialized_settings_models.dart   # Modèles spécialisés
├── services/
│   ├── database/
│   │   └── migrations/
│   │       └── parametrage_backend_migrations.dart # Migration V20
│   └── parametres/
│       ├── repositories/                          # Couche Repository (Clean Architecture)
│       │   ├── cooperative_repository.dart
│       │   ├── setting_repository.dart
│       │   └── specialized_settings_repository.dart
│       └── backend/                              # Couche Service (Règles métier)
│           ├── cooperative_service.dart
│           ├── settings_service.dart
│           ├── API_ROUTES.md                     # Documentation API
│           ├── integration_examples.dart         # Exemples d'intégration
│           └── seed_data.dart                     # Données par défaut
```

## 🗄️ Schéma de Base de Données

### Table `cooperatives`
Gestion multi-coopérative avec une seule coopérative active à la fois.

**Champs principaux:**
- `id` (TEXT PRIMARY KEY) : UUID
- `raison_sociale` (TEXT NOT NULL)
- `devise` (TEXT DEFAULT 'XAF')
- `langue` (TEXT DEFAULT 'FR')
- `statut` (TEXT DEFAULT 'ACTIVE') : ACTIVE, INACTIVE, SUSPENDED

### Table `settings`
Système générique de paramètres avec support multi-coopérative.

**Champs principaux:**
- `id` (TEXT PRIMARY KEY) : UUID
- `cooperative_id` (TEXT) : null = setting global
- `category` (TEXT NOT NULL) : finance, vente, stock, etc.
- `key` (TEXT NOT NULL)
- `value` (TEXT)
- `value_type` (TEXT) : string, int, double, bool, json
- `editable` (INTEGER DEFAULT 1)

**Contrainte:** UNIQUE (cooperative_id, category, key)

### Tables Spécialisées

#### `capital_settings`
Paramètres du capital social (valeur part, parts min/max, libération).

#### `accounting_settings`
Paramètres comptables (exercice actif, plan comptable, taux, comptes).

#### `document_settings`
Paramètres de documents (préfixes, formats, signatures).

#### `setting_history`
Historique des changements pour audit et IA.

## 🔧 Services Backend

### SettingsService
Service principal pour la gestion des settings avec règles métier :

- **Priorité des settings** : Settings coopérative > Settings globaux
- **Validation** : Vérification des paramètres critiques avant suppression
- **Historique** : Enregistrement automatique des changements
- **Cache** : Support pour cache local (à implémenter)

**Méthodes principales:**
```dart
getSetting({cooperativeId, category, key})
getSettingsByCategory({cooperativeId, category})
getValue<T>({cooperativeId, category, key, defaultValue})
saveSetting({cooperativeId, category, key, value, userId})
deleteSetting({cooperativeId, category, key, userId})
```

### CooperativeService
Service pour la gestion des coopératives avec règles métier :

- **Une seule active** : Une seule coopérative active à la fois
- **Validation** : Vérification des champs obligatoires
- **Protection** : Impossible de supprimer la coopérative active

## 📡 API REST (Documentation)

Voir `lib/services/parametres/backend/API_ROUTES.md` pour la documentation complète des endpoints.

### Endpoints Principaux

#### Cooperatives
- `GET /cooperatives` - Liste des coopératives
- `GET /cooperatives/current` - Coopérative active
- `POST /cooperatives` - Créer
- `PUT /cooperatives/{id}` - Mettre à jour
- `POST /cooperatives/{id}/set-current` - Définir comme active

#### Settings
- `GET /settings/{category}` - Settings par catégorie
- `GET /settings/{category}/{key}` - Setting spécifique
- `POST /settings` - Créer/Mettre à jour
- `DELETE /settings/{id}` - Supprimer

#### Paramètres Spécialisés
- `GET /capital-settings` - Paramètres capital
- `GET /accounting-settings` - Paramètres comptables
- `GET /document-settings` - Paramètres documents

## 🔗 Intégration avec les Modules

### Module Ventes
```dart
final integration = VentesIntegrationExample();

// Valider le prix
await integration.validatePrixVente(
  cooperativeId: coopId,
  prixUnitaire: 1500,
  produitId: 'prod-1',
);

// Générer numéro
final numero = await integration.generateNumeroVente(
  cooperativeId: coopId,
  sequence: 1,
);
```

### Module Capital Social
```dart
final integration = CapitalSocialIntegrationExample();

// Valider souscription
await integration.validateSouscription(
  cooperativeId: coopId,
  nombreParts: 5,
);

// Calculer montant
final montant = await integration.calculerMontantSouscription(
  cooperativeId: coopId,
  nombreParts: 5,
);
```

### Module Facturation
```dart
final integration = FacturationIntegrationExample();

// Générer numéro facture
final numero = await integration.generateNumeroFacture(
  cooperativeId: coopId,
  sequence: 1,
);

// Récupérer mentions légales
final mentions = await integration.getMentionsLegales(
  cooperativeId: coopId,
);
```

### Module Comptabilité
```dart
final integration = ComptabiliteIntegrationExample();

// Vérifier exercice
await integration.canOpenExercise(
  cooperativeId: coopId,
  exercice: 2025,
);

// Calculer réserves
final calculs = await integration.calculateReservesAndFees(
  cooperativeId: coopId,
  montantBrut: 1000000,
);
```

## 🚀 Initialisation

### Migration
La migration vers la version 20 crée automatiquement :
- Toutes les tables nécessaires
- Les index pour optimiser les performances
- La coopérative par défaut
- La migration des données existantes

### Seed Data
```dart
final seed = ParametrageSeedData();

// Créer coopérative par défaut avec tous ses paramètres
final coopId = await seed.seedDefaultCooperative(userId: 1);

// Créer paramètres globaux
await seed.seedGlobalSettings(userId: 1);
```

## ✅ Règles Métier Implémentées

1. **Une seule coopérative active** : Impossible d'avoir plusieurs coopératives actives simultanément
2. **Paramètres critiques** : Certains paramètres ne peuvent pas être supprimés
3. **Validation des prix** : Blocage des ventes si prix hors plage autorisée
4. **Exercice comptable unique** : Un seul exercice actif à la fois
5. **Historique obligatoire** : Tous les changements sont tracés
6. **Paramètres obligatoires** : Vérification avant activation d'un module

## 🔐 Sécurité

- **Audit trail** : Toutes les opérations sont tracées
- **Permissions** : Réservé aux administrateurs
- **Validation** : Vérification des données avant sauvegarde
- **Protection** : Impossible de supprimer les paramètres critiques

## 📊 Utilisation Pratique

### Exemple 1 : Récupérer un paramètre
```dart
final service = SettingsService();
final commissionRate = await service.getValue<double>(
  category: 'finance',
  key: 'commission_rate',
  defaultValue: 0.05,
);
```

### Exemple 2 : Configurer un paramètre
```dart
await service.saveSetting(
  category: 'vente',
  key: 'seuil_validation_double',
  value: 100000,
  valueType: SettingValueType.double,
  userId: currentUser.id!,
);
```

### Exemple 3 : Utiliser les paramètres spécialisés
```dart
final docRepo = DocumentSettingsRepository();
final settings = await docRepo.getByType(coopId, DocumentType.facture);
final numero = settings?.generateNumero(sequenceNumber);
```

## 🎯 Prochaines Étapes

1. **Cache local** : Implémenter un cache pour améliorer les performances
2. **Listener de changement** : Notifier les modules lors des changements
3. **Export/Import** : Permettre l'export et l'import des paramètres
4. **API REST complète** : Implémenter les endpoints HTTP si nécessaire
5. **Tests unitaires** : Ajouter des tests pour les règles métier critiques

## 📝 Notes Techniques

- **UUID** : Tous les IDs utilisent UUID v4
- **Dates** : Stockées en ISO8601
- **Types** : Support string, int, double, bool, json
- **Transactions** : Utilisation de transactions SQL pour l'intégrité
- **Migration** : Version 20 de la base de données

## 🔄 Compatibilité

Ce module est compatible avec :
- ✅ SQLite (local)
- ✅ PostgreSQL (cloud - à adapter)
- ✅ Mode API REST (à implémenter)
- ✅ Mode local (déjà fonctionnel)

## 📚 Documentation Complémentaire

- `API_ROUTES.md` : Documentation complète des endpoints
- `integration_examples.dart` : Exemples d'intégration détaillés
- `seed_data.dart` : Scripts d'initialisation

