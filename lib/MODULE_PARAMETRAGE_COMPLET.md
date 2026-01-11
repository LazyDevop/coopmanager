# Module de Paramétrage Complet - CoopManager

## 🎯 Vue d'ensemble

Ce module centralise tous les paramètres transversaux de la plateforme pour :
- Éviter le codage en dur
- Faciliter l'évolution métier
- Adapter le logiciel à plusieurs coopératives
- Garantir la conformité légale, financière et opérationnelle

## 📁 Structure du Module

```
lib/
├── data/
│   └── models/
│       └── parametrage_models.dart          # Tous les modèles de paramétrage
├── services/
│   └── parametres/
│       ├── parametres_service.dart           # Service existant (compatibilité)
│       └── parametrage_complet_service.dart  # Service complet avec toutes les méthodes CRUD
└── services/database/migrations/
    └── parametrage_complet_migrations.dart    # Migration vers version 19
```

## 🗄️ Tables de Base de Données

### 1. Paramétrage de l'Entité (Coopérative)
- **cooperative_entity** : Informations complètes de la coopérative
  - Informations générales (raison sociale, sigle, type, forme juridique, etc.)
  - Localisation (région, département, arrondissement, village, adresse)
  - Contact (téléphone, email, site web)
  - Champs innovants (devise, langue, fuseau horaire, slogan, QR code, niveau de maturité)

### 2. Paramétrage Organisationnel
- **sections** : Sections de la coopérative
- **sites** : Sites liés aux sections
- **magasins** : Magasins liés aux sites (type, capacité)
- **comites** : Comités internes (nom, rôle, description)

### 3. Paramétrage Métier
- **produits** : Produits et cultures (code, nom, unité de mesure, rendement, seuil d'alerte)
- **prix_marche** : Prix et marché (prix min/max/jour, marché de référence, variation autorisée)

### 4. Paramétrage Financier & Comptable
- **capital_social** : Capital social (valeur part, parts min/max, libération obligatoire)
- **parametres_comptables** : Comptabilité (plan comptable, exercice actif, comptes, taux)
- **retenues** : Taxes et retenues (type, mode calcul, valeur, plafond, automatique)

### 5. Paramétrage Commercial
- **parametres_documents** : Documents et numérotation (préfixes, format, signature, impression, export)

### 6. Paramétrage Sécurité & Utilisateurs
- **parametres_securite** : Sécurité avancée (validation double, journal audit, verrouillage exercice, sauvegarde auto)

### 7. Paramétrage IA & Analytique (V2+)
- **parametres_ia** : Paramètres intelligents (seuil anomalie, prédiction prix, scoring adhérent, alerte performance)

### 8. Table Générique
- **settings** : Paramètres dynamiques (category, key, value, type, editable)

## 📦 Modèles de Données

Tous les modèles sont définis dans `lib/data/models/parametrage_models.dart` :

- `CooperativeEntityModel` : Entité coopérative complète
- `SectionModel` : Section organisationnelle
- `SiteModel` : Site lié à une section
- `MagasinModel` : Magasin lié à un site
- `ComiteModel` : Comité interne
- `ProduitModel` : Produit/culture
- `PrixMarcheModel` : Prix de marché
- `CapitalSocialModel` : Capital social
- `ParametresComptablesModel` : Paramètres comptables
- `RetenueModel` : Retenue/taxe
- `ParametresDocumentsModel` : Paramètres documents
- `ParametresSecuriteModel` : Paramètres sécurité
- `ParametresIAModel` : Paramètres IA
- `SettingModel` : Paramètre générique

## 🔧 Service de Paramétrage

Le service `ParametrageCompletService` dans `lib/services/parametres/parametrage_complet_service.dart` fournit toutes les méthodes CRUD pour :

### Entité Coopérative
- `getCooperativeEntity()` : Récupérer l'entité
- `saveCooperativeEntity()` : Créer/mettre à jour

### Organisation
- `getAllSections()` / `createSection()` / `updateSection()` / `deleteSection()`
- `getAllSites()` / `createSite()` / `updateSite()` / `deleteSite()`
- `getAllMagasins()` / `createMagasin()` / `updateMagasin()` / `deleteMagasin()`
- `getAllComites()` / `createComite()` / `updateComite()` / `deleteComite()`

### Métier
- `getAllProduits()` / `createProduit()` / `updateProduit()` / `deleteProduit()`
- `getAllPrixMarche()` / `createPrixMarche()` / `updatePrixMarche()` / `deletePrixMarche()`

### Financier & Comptable
- `getCapitalSocial()` / `saveCapitalSocial()`
- `getParametresComptables()` / `saveParametresComptables()`
- `getAllRetenues()` / `createRetenue()` / `updateRetenue()` / `deleteRetenue()`

### Commercial
- `getParametresDocuments()` / `saveParametresDocuments()`

### Sécurité
- `getParametresSecurite()` / `saveParametresSecurite()`

### IA & Analytique
- `getParametresIA()` / `saveParametresIA()`

### Settings Génériques
- `getSetting()` / `getSettingsByCategory()` / `saveSetting()` / `deleteSetting()`

## 🚀 Migration

La migration vers la version 19 est définie dans `lib/services/database/migrations/parametrage_complet_migrations.dart` :

- Crée toutes les nouvelles tables
- Crée les index pour optimiser les performances
- Insère les paramètres par défaut
- Migre les données existantes de `coop_settings` vers `cooperative_entity`

## 📝 Utilisation

### Exemple : Récupérer l'entité coopérative

```dart
final service = ParametrageCompletService();
final entity = await service.getCooperativeEntity();
if (entity != null) {
  print('Raison sociale: ${entity.raisonSociale}');
  print('Devise: ${entity.devisePrincipale.name}');
}
```

### Exemple : Créer une section

```dart
final service = ParametrageCompletService();
final section = SectionModel(
  code: 'SEC-001',
  nom: 'Section Nord',
  localisation: 'Douala',
  isActive: true,
  createdAt: DateTime.now(),
);

final created = await service.createSection(
  section: section,
  userId: currentUser.id!,
);
```

### Exemple : Gérer les produits

```dart
final service = ParametrageCompletService();

// Créer un produit
final produit = ProduitModel(
  codeProduit: 'PROD-001',
  nomProduit: 'Cacao',
  uniteMesure: UniteMesure.kg,
  rendementMoyen: 500.0,
  seuilAlerte: 100.0,
  isActive: true,
  createdAt: DateTime.now(),
);

await service.createProduit(
  produit: produit,
  userId: currentUser.id!,
);

// Créer un prix marché
final prix = PrixMarcheModel(
  produitId: produit.id!,
  prixMin: 1500.0,
  prixMax: 2000.0,
  prixJour: 1750.0,
  marcheReference: MarcheReference.local,
  variationAutorisee: 10.0,
  isActive: true,
  createdAt: DateTime.now(),
);

await service.createPrixMarche(
  prix: prix,
  userId: currentUser.id!,
);
```

### Exemple : Utiliser les settings génériques

```dart
final service = ParametrageCompletService();

// Créer un setting
final setting = SettingModel(
  category: 'finance',
  key: 'taux_tva',
  value: '19.25',
  type: SettingType.string,
  editable: true,
  createdAt: DateTime.now(),
);

await service.saveSetting(
  setting: setting,
  userId: currentUser.id!,
);

// Récupérer tous les settings d'une catégorie
final financeSettings = await service.getSettingsByCategory('finance');
```

## ✅ État d'Implémentation

### ✅ Complété
- [x] Modèles de données complets
- [x] Migration de base de données (version 19)
- [x] Service complet avec toutes les méthodes CRUD
- [x] Audit trail pour toutes les opérations
- [x] Méthodes copyWith pour tous les modèles

### 🔄 À Faire
- [ ] ViewModel pour gérer la logique métier et l'état
- [ ] Écrans UI pour chaque section de paramétrage :
  - [ ] Écran principal avec onglets
  - [ ] Onglet Entité (Coopérative)
  - [ ] Onglet Organisation (Sections, Sites, Magasins, Comités)
  - [ ] Onglet Métier (Produits, Prix)
  - [ ] Onglet Financier (Capital, Comptabilité, Retenues)
  - [ ] Onglet Commercial (Documents)
  - [ ] Onglet Sécurité
  - [ ] Onglet IA & Analytique
  - [ ] Onglet Settings Génériques
- [ ] Provider pour la gestion d'état
- [ ] Validation des données
- [ ] Tests unitaires

## 🔐 Permissions

Ce module est réservé aux **administrateurs** uniquement. Toutes les opérations sont tracées dans le journal d'audit.

## 📚 Intégration avec les Autres Modules

### Module Ventes
- Utilise les prix marché pour valider les prix de vente
- Utilise les produits pour les références
- Utilise les sections/sites/magasins pour filtrer

### Module Stock
- Utilise les produits pour les références
- Utilise les magasins pour la localisation
- Utilise les seuils d'alerte pour les notifications

### Module Facturation
- Utilise les paramètres documents pour la numérotation
- Utilise l'entité coopérative pour les en-têtes
- Utilise les paramètres commerciaux pour l'impression

### Module Comptabilité
- Utilise les paramètres comptables pour la configuration
- Utilise les retenues pour les calculs automatiques
- Utilise le capital social pour les parts

## 🎨 Prochaines Étapes

1. Créer le ViewModel `ParametrageCompletViewModel`
2. Créer les écrans UI avec navigation par onglets
3. Ajouter la validation des formulaires
4. Intégrer avec les autres modules
5. Ajouter les tests

## 📖 Notes Techniques

- Toutes les dates sont stockées en ISO8601
- Les booléens sont stockés comme INTEGER (0/1)
- Les enums sont stockés comme TEXT (nom de l'enum)
- Toutes les opérations sont auditées
- Les paramètres par défaut sont créés automatiquement lors de la migration

