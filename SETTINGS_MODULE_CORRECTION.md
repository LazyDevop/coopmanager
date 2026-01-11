# ✅ CORRECTION MODULE PARAMÉTRAGE (SETTINGS)

## 📋 Résumé des corrections

Le module de paramétrage a été entièrement corrigé et amélioré pour résoudre l'erreur `SqliteException: no such table: settings` et garantir une gestion robuste des paramètres.

---

## 🗄️ 1. Base de données (SQLite)

### Table `settings` créée avec tous les champs requis

```sql
CREATE TABLE settings (
  id TEXT PRIMARY KEY,
  cooperative_id TEXT,
  category TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT,
  value_type TEXT DEFAULT 'string',
  description TEXT,
  is_active INTEGER DEFAULT 1,
  editable INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id) ON DELETE CASCADE,
  UNIQUE (cooperative_id, category, key)
)
```

### Index créés pour optimiser les performances

- `idx_settings_cooperative` : Sur `cooperative_id`
- `idx_settings_category` : Sur `category`
- `idx_settings_key` : Sur `key`
- `idx_settings_active` : Sur `is_active`
- `idx_settings_category_active` : Sur `(category, is_active)`

### Contrainte d'unicité

- `UNIQUE (cooperative_id, category, key)` : Garantit qu'un paramètre est unique par coopérative, catégorie et clé

---

## 🔄 2. Migrations SQLite

### Migration Version 21

**Fichier** : `lib/services/database/migrations/settings_table_migration.dart`

- ✅ Création automatique de la table `settings` si elle n'existe pas
- ✅ Vérification et ajout des colonnes manquantes (`description`, `is_active`)
- ✅ Création automatique des index
- ✅ Création de la table `setting_history` pour l'historique

### Intégration dans `db_initializer.dart`

- ✅ Migration automatique lors de `onUpgrade` (version 21)
- ✅ Création dans `onCreate` pour les nouvelles bases
- ✅ Vérification lors de l'initialisation pour les bases existantes

**Version de la base de données** : `21` (mise à jour dans `app_config.dart`)

---

## 📦 3. Backend Flutter (Data Layer)

### SettingModel (`lib/data/models/backend/setting_model.dart`)

**Champs complets** :
- `id` : Identifiant unique (UUID)
- `cooperativeId` : ID de la coopérative (null = global)
- `category` : Catégorie du paramètre
- `key` : Clé du paramètre
- `value` : Valeur (string)
- `valueType` : Type de valeur (string, int, double, bool, json)
- `description` : Description du paramètre ✨ **NOUVEAU**
- `isActive` : Actif/Inactif ✨ **NOUVEAU**
- `editable` : Modifiable ou non
- `createdAt` : Date de création
- `updatedAt` : Date de mise à jour

**Méthodes** :
- `getTypedValue()` : Convertit la valeur selon son type
- `valueToString()` : Convertit une valeur en string pour stockage
- `fromMap()` / `toMap()` : Sérialisation
- `copyWith()` : Création de copies modifiées

### SettingRepository (`lib/services/parametres/repositories/setting_repository.dart`)

**Méthodes principales** :
- `getById()` : Récupérer un setting par ID
- `getByKey()` : Récupérer par cooperative_id, category et key
- `getByCategory()` : Récupérer tous les settings d'une catégorie
- `getAll()` : Récupérer tous les settings d'une coopérative
- `create()` : Créer un nouveau setting
- `update()` : Mettre à jour un setting
- `delete()` : Supprimer un setting
- `logHistory()` : Enregistrer l'historique des modifications

**Sécurité** :
- ✅ Vérification de l'existence de la table avant chaque requête
- ✅ Gestion des erreurs sans crash
- ✅ Filtrage automatique des settings inactifs (`is_active = 1`)

### SettingsService (`lib/services/parametres/backend/settings_service.dart`)

**Fonctionnalités** :
- ✅ Récupération avec fallback sur settings globaux
- ✅ Gestion robuste des erreurs (retourne `null` ou valeurs par défaut)
- ✅ Support multi-coopérative
- ✅ Audit logging automatique
- ✅ Validation des paramètres non modifiables

**Méthodes principales** :
- `getSetting()` : Récupérer un setting avec gestion d'erreurs
- `getSettingsByCategory()` : Récupérer tous les settings d'une catégorie
- `getValue<T>()` : Récupérer une valeur typée avec valeur par défaut
- `saveSetting()` : Créer ou mettre à jour un setting

---

## 🔗 4. Intégration avec les autres modules

### Fichier d'exemple : `lib/services/parametres/settings_integration_example.dart`

**Classes d'intégration créées** :

1. **SettingsVentesIntegration** :
   - `getPrixMinimumCacao()` / `getPrixMaximumCacao()`
   - `getPrixDuJour()`
   - `getTauxCommission()`
   - `validerPrix()` : Valide un prix selon les limites configurées

2. **SettingsRecettesIntegration** :
   - `getTauxCommission()`
   - `getRetenuesSocialesActives()`
   - `getRetenuesCapitalActives()`

3. **SettingsFacturationIntegration** :
   - `getPrefixeFacture()`
   - `getFormatNumero()`
   - `getSignatureAutomatique()`
   - `getQrCodeActif()`

4. **SettingsSocialIntegration** :
   - `getPlafondAideSociale()`
   - `getValidationRequise()`

5. **SettingsCapitalIntegration** :
   - `getValeurPart()`
   - `getNombreMinParts()` / `getNombreMaxParts()`
   - `getLiberationObligatoire()`
   - `calculerCapital()` : Calcule le capital total

**Classe utilitaire** : `SettingsHelper`
- Accès centralisé à tous les helpers d'intégration
- Exemples d'utilisation dans les modules

---

## 🛡️ 5. Sécurité et robustesse

### Vérifications avant chaque requête

✅ **Dans SettingRepository** :
- Vérification de l'existence de la table avant chaque opération
- Gestion des erreurs avec messages explicites
- Filtrage automatique des settings inactifs

✅ **Dans SettingsService** :
- Gestion des erreurs sans crash de l'application
- Retour de valeurs par défaut si un paramètre est absent
- Fallback sur settings globaux si settings coopérative absents

✅ **Dans CentralSettingsService** :
- Try-catch autour de toutes les opérations
- Retour de modèles par défaut en cas d'erreur
- Messages d'erreur informatifs dans les logs

### Valeurs par défaut

Tous les modules retournent des valeurs par défaut si un paramètre est absent :
- **Ventes** : Prix min/max par défaut, taux commission 5%
- **Facturation** : Préfixe "FAC", format standard
- **Capital** : Valeur part 1000, min 1 part
- **Social** : Plafond 100000, validation requise
- **Recettes** : Taux commission 5%, retenues activées

---

## 📝 6. Utilisation

### Exemple : Récupérer un paramètre de vente

```dart
final settingsService = SettingsService();
final prixMin = await settingsService.getValue<double>(
  category: 'ventes',
  key: 'prix_minimum_cacao',
  defaultValue: 1000.0,
) ?? 1000.0;
```

### Exemple : Utiliser les helpers d'intégration

```dart
// Dans un module de vente
final prixMin = await SettingsHelper.ventes.getPrixMinimumCacao();
final prixMax = await SettingsHelper.ventes.getPrixMaximumCacao();
final isValid = await SettingsHelper.ventes.validerPrix(prixVente);
```

### Exemple : Générer un numéro de facture

```dart
final numero = await SettingsHelper.facturation.genererNumeroFacture(123);
// Résultat : "FAC-2024-000123"
```

---

## ✅ 7. Tests et validation

### Vérifications effectuées

- ✅ Table `settings` créée automatiquement lors de l'initialisation
- ✅ Migration vers version 21 fonctionnelle
- ✅ Gestion des erreurs sans crash
- ✅ Valeurs par défaut retournées si paramètres absents
- ✅ Support multi-coopérative fonctionnel
- ✅ Index créés pour optimiser les performances
- ✅ Contrainte d'unicité respectée

### Commandes de test

```bash
# Analyser le code
flutter analyze lib/services/parametres/

# Vérifier les migrations
flutter run --verbose
```

---

## 🚀 8. Prochaines étapes

1. **Tests unitaires** : Créer des tests pour chaque méthode du repository et service
2. **Documentation API** : Documenter les catégories et clés de paramètres disponibles
3. **Interface admin** : Créer une interface pour gérer les paramètres depuis l'UI
4. **Validation** : Ajouter des règles de validation pour les valeurs de paramètres
5. **Cache** : Implémenter un cache en mémoire pour améliorer les performances

---

## 📚 Fichiers créés/modifiés

### Nouveaux fichiers
- ✅ `lib/services/database/migrations/settings_table_migration.dart`
- ✅ `lib/services/parametres/repositories/settings_repository.dart` (alternative)
- ✅ `lib/services/parametres/settings_integration_example.dart`

### Fichiers modifiés
- ✅ `lib/data/models/backend/setting_model.dart` (ajout `description` et `isActive`)
- ✅ `lib/services/parametres/repositories/setting_repository.dart` (vérifications de sécurité)
- ✅ `lib/services/parametres/backend/settings_service.dart` (gestion robuste des erreurs)
- ✅ `lib/services/parametres/central_settings_service.dart` (gestion d'erreurs améliorée)
- ✅ `lib/services/database/db_initializer.dart` (migration version 21)
- ✅ `lib/config/app_config.dart` (version DB mise à jour à 21)

---

## ✨ Résultat

Le module de paramétrage est maintenant :
- ✅ **Stable** : Gestion robuste des erreurs
- ✅ **Évolutif** : Structure extensible pour nouveaux paramètres
- ✅ **Sécurisé** : Vérifications avant chaque opération
- ✅ **Performant** : Index optimisés pour les requêtes
- ✅ **Intégré** : Exemples d'utilisation dans tous les modules

**L'erreur `no such table: settings` est résolue !** 🎉

