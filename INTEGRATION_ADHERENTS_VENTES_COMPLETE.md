# Intégration Module Adhérents ↔ Ventes - Documentation Complète

## 🎯 Vue d'ensemble

Cette intégration complète permet une interaction sécurisée et traçable entre le Module Adhérents et le Module Ventes, garantissant :

- ✅ Une répartition juste des recettes
- ✅ Une cohérence stock ↔ finance
- ✅ Une transparence totale pour la coopérative et les adhérents
- ✅ Une traçabilité complète de toutes les opérations

## 🗄️ Structure de la base de données

### Table `vente_adherents` (Table pivot)

Cette table lie chaque vente aux adhérents impactés avec tous les détails de calcul :

```sql
CREATE TABLE vente_adherents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  vente_id INTEGER NOT NULL,
  adherent_id INTEGER NOT NULL,
  poids_utilise REAL NOT NULL,
  prix_kg REAL NOT NULL,
  montant_brut REAL NOT NULL,
  commission_rate REAL NOT NULL,
  commission_amount REAL NOT NULL,
  montant_net REAL NOT NULL,
  campagne_id INTEGER,
  qualite TEXT,
  created_at TEXT NOT NULL,
  created_by INTEGER,
  FOREIGN KEY (vente_id) REFERENCES ventes(id) ON DELETE CASCADE,
  FOREIGN KEY (adherent_id) REFERENCES adherents(id),
  FOREIGN KEY (campagne_id) REFERENCES campagnes(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
)
```

**Index créés :**
- `idx_vente_adherents_vente_id` sur `vente_id`
- `idx_vente_adherents_adherent_id` sur `adherent_id`
- `idx_vente_adherents_campagne_id` sur `campagne_id`
- `idx_vente_adherents_created_at` sur `created_at`

### Colonnes ajoutées à `coop_settings`

- `commission_rate_actionnaire` : Taux de commission spécifique pour les actionnaires
- `commission_rate_producteur` : Taux de commission spécifique pour les producteurs

## 📦 Modèles de données

### `VenteAdherentModel`

Modèle représentant la répartition d'une vente sur un adhérent spécifique.

**Champs principaux :**
- `venteId` : ID de la vente
- `adherentId` : ID de l'adhérent
- `poidsUtilise` : Poids utilisé pour cet adhérent (en kg)
- `prixKg` : Prix unitaire par kg
- `montantBrut` : Montant brut (poids × prix)
- `commissionRate` : Taux de commission appliqué
- `commissionAmount` : Montant de la commission
- `montantNet` : Montant net après commission
- `campagneId` : Campagne agricole
- `qualite` : Qualité du cacao

**Méthodes statiques :**
- `calculateMontantBrut()` : Calculer le montant brut
- `calculateCommissionAmount()` : Calculer le montant de la commission
- `calculateMontantNet()` : Calculer le montant net

## 🔧 Services

### `AdherentService` - Nouvelles méthodes

#### `getStockByCampagne()`
Récupère le stock disponible d'un adhérent pour une campagne donnée.

```dart
Future<double> getStockByCampagne({
  required int adherentId,
  int? campagneId,
})
```

#### `getCommissionRateForAdherent()`
Récupère le taux de commission applicable selon la catégorie de l'adhérent.

**Logique :**
- **Actionnaire** : `commission_rate_actionnaire` ou `commission_rate` par défaut
- **Producteur** : `commission_rate_producteur` ou `commission_rate` par défaut
- **Adhérent simple** : `commission_rate` standard

```dart
Future<double> getCommissionRateForAdherent(int adherentId)
```

#### `canAdherentSell()`
Vérifie si un adhérent est actif et peut vendre.

```dart
Future<bool> canAdherentSell(int adherentId)
```

#### `getCampagnesActives()`
Récupère les campagnes actives d'un adhérent (basé sur les dépôts).

```dart
Future<List<int>> getCampagnesActives(int adherentId)
```

#### `getSoldeFinancier()`
Calcule le solde financier d'un adhérent (montant dû = ventes - paiements).

```dart
Future<double> getSoldeFinancier(int adherentId)
```

#### `getVentesWithDetails()`
Récupère les ventes d'un adhérent avec tous les détails de répartition.

```dart
Future<List<Map<String, dynamic>>> getVentesWithDetails(int adherentId)
```

### `VenteService` - Nouvelles méthodes

#### `createVenteWithRepartition()`
Crée une vente avec répartition automatique par adhérents.

**Fonctionnalités :**
1. ✅ Validation du prix (seuils min/max)
2. ✅ Sélection des stocks disponibles par campagne/qualité
3. ✅ Répartition automatique selon FIFO et priorité catégorie
4. ✅ Création des lignes `vente_adherents` avec calculs de commission
5. ✅ Création automatique des recettes pour chaque adhérent
6. ✅ Génération du QR Code
7. ✅ Enregistrement dans le journal
8. ✅ Transaction atomique (rollback en cas d'erreur)

**Paramètres :**
```dart
Future<VenteModel> createVenteWithRepartition({
  required double quantiteTotal,
  required double prixUnitaire,
  required int campagneId,
  String? qualite,
  String? acheteur,
  int? clientId,
  String? modePaiement,
  required DateTime dateVente,
  String? notes,
  required int createdBy,
  List<int>? adherentIdsPrioritaires, // Optionnel
  bool overridePrixValidation = false,
})
```

**Logique de répartition :**
1. **Priorité** : Adhérents prioritaires (si spécifiés) → Actionnaires → Adhérents → Producteurs
2. **FIFO** : Date de dépôt (plus ancien en premier)
3. **Vérifications** : Adhérent actif ET statut actif

#### `getRepartitionVente()`
Récupère la répartition complète d'une vente (tous les adhérents impactés).

```dart
Future<List<VenteAdherentModel>> getRepartitionVente(int venteId)
```

#### `getVentesByAdherent()`
Récupère toutes les ventes d'un adhérent avec détails de répartition.

```dart
Future<List<Map<String, dynamic>>> getVentesByAdherent(int adherentId)
```

## 🧮 Gestion différenciée selon catégorie

### Adhérent simple
- Commission standard (`commission_rate`)
- Pas de dividendes
- Droits standards

### Adhérent actionnaire
- Commission paramétrable (`commission_rate_actionnaire` ou `commission_rate`)
- Possibilité de ristourne
- Impact sur dividendes futurs
- Priorité dans la répartition automatique

### Producteur non adhérent
- Commission spéciale (`commission_rate_producteur` ou `commission_rate`)
- Droits limités
- Option conversion en adhérent
- Priorité la plus basse dans la répartition

## 🔐 Sécurité & Audit

### Enregistrement automatique
- ✅ Utilisateur créateur (`created_by`)
- ✅ Rôle de l'utilisateur
- ✅ Date et heure de l'opération

### Journalisation
- ✅ Calculs effectués
- ✅ Modifications manuelles
- ✅ Toutes les opérations dans `journal_ventes`

### Inviolabilité
- ✅ Les ventes validées ne peuvent pas être modifiées
- ✅ Seule l'annulation est possible (avec raison)
- ✅ Rollback automatique en cas d'erreur

## 📊 Flux de données

### Création d'une vente avec répartition

```
1. Validation prix (seuils min/max)
   ↓
2. Sélection stocks disponibles (campagne, qualité, FIFO, priorité)
   ↓
3. Vérification stocks suffisants
   ↓
4. Création vente principale
   ↓
5. Pour chaque adhérent impacté :
   ├─ Création ligne vente_adherents
   ├─ Calcul commission selon catégorie
   ├─ Débit stock (mouvement)
   ├─ Création recette automatique
   └─ Enregistrement historique adhérent
   ↓
6. Génération QR Code
   ↓
7. Enregistrement journal
   ↓
8. Audit & Notification
   ↓
9. COMMIT transaction
```

### Récupération répartition

```
GET /ventes/{id}/repartition
   ↓
Retourne List<VenteAdherentModel>
   ├─ adherent_id
   ├─ poids_utilise
   ├─ montant_brut
   ├─ commission_rate
   ├─ commission_amount
   └─ montant_net
```

## 🖥️ Frontend (À implémenter)

### Écran vente – Vue adhérents impactés

**Composants nécessaires :**
- Tableau dynamique affichant :
  - Code adhérent
  - Nom complet
  - Poids vendu
  - Montant brut
  - Commission
  - Montant net
- Indicateurs visuels :
  - 🏆 Adhérent actionnaire
  - 👤 Producteur simple
  - ⚠️ Adhérent suspendu
  - 📉 Stock insuffisant

### Fiche adhérent – Onglet "Ventes"

**Fonctionnalités :**
- Historique des ventes
- Détail par campagne
- Graphiques de progression
- Téléchargement documents
- Export PDF/Excel

## 🚀 Utilisation

### Exemple : Créer une vente avec répartition automatique

```dart
final venteService = VenteService();

final vente = await venteService.createVenteWithRepartition(
  quantiteTotal: 1000.0, // 1000 kg
  prixUnitaire: 1500.0, // 1500 FCFA/kg
  campagneId: 1,
  qualite: 'premium',
  clientId: 5,
  dateVente: DateTime.now(),
  createdBy: currentUserId,
  adherentIdsPrioritaires: [10, 15], // Prioriser ces adhérents
);

// Récupérer la répartition
final repartition = await venteService.getRepartitionVente(vente.id!);
for (final ligne in repartition) {
  print('Adhérent ${ligne.adherentId}: ${ligne.poidsUtilise} kg → ${ligne.montantNet} FCFA');
}
```

### Exemple : Récupérer les ventes d'un adhérent

```dart
final adherentService = AdherentService();

// Vérifier si peut vendre
final canSell = await adherentService.canAdherentSell(adherentId);
if (!canSell) {
  throw Exception('Adhérent inactif ou suspendu');
}

// Récupérer le stock par campagne
final stock = await adherentService.getStockByCampagne(
  adherentId: adherentId,
  campagneId: campagneId,
);

// Récupérer le taux de commission
final commissionRate = await adherentService.getCommissionRateForAdherent(adherentId);

// Récupérer les ventes avec détails
final ventes = await adherentService.getVentesWithDetails(adherentId);
```

## ✅ Checklist d'intégration

- [x] Modèle `VenteAdherentModel` créé
- [x] Table `vente_adherents` créée avec migration
- [x] Méthodes `AdherentService` pour exposer données
- [x] Logique commission différenciée implémentée
- [x] Répartition automatique avec FIFO et priorité
- [x] Création automatique recettes (transaction atomique)
- [x] Méthodes récupération répartition
- [ ] Écran frontend adhérents impactés
- [ ] Onglet Ventes dans fiche adhérent

## 📝 Notes importantes

1. **Transaction atomique** : Toute erreur lors de la création d'une vente avec répartition entraîne un rollback complet.

2. **Stock FIFO** : Les stocks sont prélevés selon le principe FIFO (First In, First Out) pour garantir la traçabilité.

3. **Priorité catégorie** : Les actionnaires sont prioritaires dans la répartition automatique.

4. **Commission différenciée** : Les taux peuvent être configurés dans les paramètres de la coopérative.

5. **Adhérents inactifs** : Les adhérents inactifs ou suspendus ne peuvent pas vendre (vérification automatique).

## 🔄 Migration

La migration vers la version 14 crée automatiquement :
- La table `vente_adherents`
- Les colonnes de commission différenciée
- Les index nécessaires
- Migration des données existantes depuis `vente_details`

## 📚 Références

- `lib/data/models/vente_adherent_model.dart`
- `lib/services/adherent/adherent_service.dart`
- `lib/services/vente/vente_service.dart`
- `lib/services/database/migrations/adherent_vente_integration_migrations.dart`

