# Module Recettes & Commissions

## 📋 Vue d'ensemble

Module flexible et paramétrable pour la gestion des commissions dans une coopérative de cacaoculteurs. Le système permet d'ajouter dynamiquement des commissions sans modifier le code.

## 🎯 Objectifs métier

- ✅ Ajouter dynamiquement une nouvelle commission
- ✅ Définir le montant fixe de chaque commission
- ✅ Définir la durée d'application (permanente, temporaire, reconductible)
- ✅ Appliquer automatiquement les commissions au calcul des recettes
- ✅ Garder l'historique même si une commission change ou expire
- ✅ Aucune commission codée en dur
- ✅ Pas de pourcentage, uniquement des montants fixes

## 🏗️ Architecture

### Tables de base de données

#### `commissions`
Stocke toutes les règles de commission.

```sql
commissions (
  id INTEGER PRIMARY KEY,
  code TEXT UNIQUE,              -- Code unique (ex: "TRANSPORT")
  libelle TEXT,                  -- Libellé descriptif
  montant_fixe REAL,             -- Montant fixe en FCFA
  type_application TEXT,         -- PAR_KG | PAR_VENTE
  date_debut DATE,
  date_fin DATE,                 -- NULL = permanente
  reconductible INTEGER,         -- 1 = oui, 0 = non
  periode_reconduction_days INTEGER,
  statut TEXT,                   -- active | inactive
  description TEXT,
  created_by INTEGER,
  created_at TEXT,
  updated_at TEXT,
  updated_by INTEGER
)
```

#### `recette_commissions`
Snapshot des commissions appliquées à chaque recette. **Garantit que les recettes passées ne changent jamais.**

```sql
recette_commissions (
  id INTEGER PRIMARY KEY,
  recette_id INTEGER,
  commission_code TEXT,
  commission_libelle TEXT,
  montant_applique REAL,
  type_application TEXT,
  poids_vendu REAL,
  montant_fixe_utilise REAL,
  date_application TEXT,
  created_at TEXT
)
```

#### `commission_history`
Historique de toutes les modifications de commissions.

```sql
commission_history (
  id INTEGER PRIMARY KEY,
  commission_id INTEGER,
  commission_code TEXT,
  action TEXT,                   -- CREATE | UPDATE | ACTIVATE | DEACTIVATE | RECONDUCTION
  old_montant_fixe REAL,
  new_montant_fixe REAL,
  old_date_debut TEXT,
  new_date_debut TEXT,
  old_date_fin TEXT,
  new_date_fin TEXT,
  changed_by INTEGER,
  change_reason TEXT,
  created_at TEXT
)
```

## 🔧 Règles métier

### 1. Sélection des commissions applicables

Une commission est appliquée si :
- `statut = 'active'`
- `date_vente >= date_debut`
- `date_fin IS NULL OR date_vente <= date_fin`

### 2. Calcul du montant de la commission

**Si `type_application = 'PAR_KG'` :**
```
montant = poids_vendu × montant_fixe
```

**Si `type_application = 'PAR_VENTE'` :**
```
montant = montant_fixe
```

### 3. Reconduction automatique

Si `reconductible = 1` et `date_fin < date_du_jour` :
- Une nouvelle période est générée automatiquement
- La nouvelle période commence à `date_fin + 1 jour`
- La nouvelle période dure `periode_reconduction_days` jours

### 4. Calcul d'une recette

```
Recette brute = poids × prix_du_marche
Total commissions = somme de toutes les commissions actives
Recette nette = Recette brute – Total commissions
```

## 💻 Utilisation

### Créer une commission

```dart
final commissionService = CommissionService();

final commission = CommissionModel(
  code: 'TRANSPORT',
  libelle: 'Commission Transport',
  montantFixe: 25.0, // 25 FCFA/kg
  typeApplication: CommissionTypeApplication.parKg,
  dateDebut: DateTime(2024, 1, 1),
  dateFin: null, // Permanente
  reconductible: false,
  statut: CommissionStatut.active,
  createdAt: DateTime.now(),
);

await commissionService.createCommission(
  commission: commission,
  userId: currentUser.id!,
  reason: 'Création commission transport',
);
```

### Calculer une recette

```dart
final recetteService = RecetteCommissionService();

final result = await recetteService.calculerRecette(
  adherentId: 1,
  venteId: 123,
  poidsVendu: 1000.0, // kg
  prixUnitaire: 1500.0, // FCFA/kg
  dateVente: DateTime.now(),
  userId: currentUser.id!,
);

print('Montant brut: ${result.montantBrut} FCFA');
print('Total commissions: ${result.totalCommissions} FCFA');
print('Montant net: ${result.montantNet} FCFA');
print('Commissions appliquées: ${result.commissionsAppliquees.length}');
```

### Reconduire les commissions expirées

```dart
final commissionsReconduites = await commissionService.reconduireCommissionsExpirees(
  userId: currentUser.id!,
  reason: 'Reconduction automatique mensuelle',
);
```

## 📊 Exemple concret

### Commissions actives
- **Transport** : 25 FCFA/kg (permanente)
- **Sociale** : 10 FCFA/kg (janvier-juin, reconductible)

### Vente
- 1 000 kg à 1 500 FCFA/kg

### Calcul
```
Brute = 1 000 × 1 500 = 1 500 000 FCFA
Transport = 1 000 × 25 = 25 000 FCFA
Sociale = 1 000 × 10 = 10 000 FCFA
Total commissions = 35 000 FCFA
Nette = 1 500 000 - 35 000 = 1 465 000 FCFA
```

## 🔗 Intégration avec les autres modules

### Ventes
- Déclenche automatiquement le calcul de recette
- Utilise `RecetteCommissionService.calculerRecette()`

### Paiements
- Se base sur la `montantNet` de la recette
- Les commissions sont déjà déduites

### Comptabilité
- Chaque commission est enregistrée comme charge
- Utilise les données de `recette_commissions`

### Paramétrage
- Interface pour créer/modifier les commissions
- Utilise `CommissionService`

## ✅ Garanties

1. **Traçabilité** : Toutes les modifications sont historisées
2. **Auditabilité** : Chaque action est loggée avec utilisateur et raison
3. **Immutabilité** : Les recettes passées ne changent jamais (snapshot)
4. **Flexibilité** : Ajout de commissions sans modification du code
5. **Évolutivité** : Support de nouveaux types de commissions

## 🧪 Tests

Voir `lib/services/commissions/commission_seed_data.dart` pour des exemples de données et de calculs.

## 📝 Notes importantes

- ⚠️ Les recettes sont calculées avec les commissions actives **au moment de la vente**
- ⚠️ Les modifications de commissions n'affectent **jamais** les recettes passées
- ⚠️ La reconduction automatique doit être exécutée périodiquement (cron job recommandé)
- ⚠️ Le code de commission doit être unique et descriptif (ex: "TRANSPORT", "SOCIALE")

