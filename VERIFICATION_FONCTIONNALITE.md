# Vérification de Fonctionnalité - CoopManager

## ✅ Vérifications effectuées

### 1. Backend - Services
- ✅ `VenteService.createVenteWithRepartition()` existe et est implémentée
- ✅ `VenteService.getRepartitionVente()` existe et est implémentée
- ✅ `AdherentService.getStockByCampagne()` existe et est implémentée
- ✅ `AdherentService.canAdherentSell()` existe et est implémentée
- ✅ `AdherentService.getCommissionRateForAdherent()` existe et est implémentée

### 2. Backend - Modèles
- ✅ `VenteAdherentModel` créé et importé correctement
- ✅ `ParametresCooperativeModel` mis à jour avec commission différenciée

### 3. Frontend - ViewModels
- ✅ `VenteViewModel` importe `VenteAdherentModel`
- ✅ Méthodes ajoutées dans `VenteViewModel` :
  - `createVenteWithRepartition()` ✅
  - `getRepartitionVente()` ✅
  - `getStockByCampagne()` ✅
  - `canAdherentSell()` ✅

### 4. Frontend - Écrans
- ✅ `ventes_list_screen.dart` utilise `Consumer<VenteViewModel>`
- ✅ `vente_form_v1_screen.dart` utilise `Consumer<VenteViewModel>`
- ✅ Les écrans appellent `viewModel.loadVentes()` dans `initState`

### 5. Base de données
- ✅ Migration V14 créée pour table `vente_adherents`
- ✅ Colonnes de commission différenciée ajoutées à `coop_settings`
- ✅ Index créés pour performance

### 6. Linter
- ✅ Aucune erreur de linter détectée

## ⚠️ Points à vérifier en runtime

### 1. Colonne `stock_depot_id` dans `stock_mouvements`
**Fichier**: `lib/services/vente/vente_service.dart` ligne 1178

**Vérification nécessaire** :
```sql
-- Vérifier si la colonne existe
PRAGMA table_info(stock_mouvements);
```

**Si la colonne n'existe pas**, il faut :
- Ajouter la colonne dans la migration
- Ou modifier la requête pour ne pas l'utiliser

### 2. Colonne `campagne_id` dans `stock_depots`
**Fichier**: `lib/services/adherent/adherent_service.dart` ligne 688

**Vérification nécessaire** :
```sql
-- Vérifier si la colonne existe
PRAGMA table_info(stock_depots);
```

**Si la colonne n'existe pas**, il faut :
- Ajouter la colonne dans une migration
- Ou modifier la requête pour ne pas filtrer par campagne

### 3. Table `journal_ventes`
**Fichier**: `lib/services/vente/vente_service.dart` ligne 1061

**Vérification nécessaire** :
```sql
-- Vérifier si la table existe
SELECT name FROM sqlite_master WHERE type='table' AND name='journal_ventes';
```

**Si la table n'existe pas**, il faut :
- Créer la table dans une migration
- Ou commenter temporairement l'appel à `_logJournalVente`

## 🔧 Corrections potentielles nécessaires

### Correction 1 : Vérifier colonnes manquantes

Si les colonnes `stock_depot_id` ou `campagne_id` n'existent pas, créer une migration :

```dart
// Dans db_initializer.dart ou nouvelle migration
await db.execute('''
  ALTER TABLE stock_mouvements 
  ADD COLUMN stock_depot_id INTEGER
''');

await db.execute('''
  ALTER TABLE stock_depots 
  ADD COLUMN campagne_id INTEGER
''');
```

### Correction 2 : Gérer l'absence de journal_ventes

Si la table `journal_ventes` n'existe pas :

```dart
// Créer la table dans une migration
await db.execute('''
  CREATE TABLE IF NOT EXISTS journal_ventes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vente_id INTEGER NOT NULL,
    action TEXT NOT NULL,
    ancien_statut TEXT,
    nouveau_statut TEXT,
    ancien_montant REAL,
    nouveau_montant REAL,
    details TEXT,
    created_by INTEGER,
    created_at TEXT NOT NULL,
    FOREIGN KEY (vente_id) REFERENCES ventes(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
  )
''');
```

## 🧪 Tests à effectuer

### Test 1 : Créer une vente V1
```dart
// Dans l'application
1. Ouvrir l'écran de création de vente V1
2. Remplir le formulaire
3. Cliquer sur "Créer la vente V1"
4. Vérifier que la vente est créée
5. Vérifier que le stock est débité
6. Vérifier que la recette est créée
```

### Test 2 : Créer une vente avec répartition
```dart
// Dans l'application
1. Appeler createVenteWithRepartition()
2. Vérifier que les lignes vente_adherents sont créées
3. Vérifier que les recettes sont créées pour chaque adhérent
4. Vérifier que le stock est débité pour chaque adhérent
```

### Test 3 : Récupérer la répartition
```dart
// Dans l'application
1. Créer une vente avec répartition
2. Appeler getRepartitionVente(venteId)
3. Vérifier que la liste retournée contient les bonnes données
```

## 📝 Checklist de vérification finale

### Avant de dire que tout est fonctionnel :

- [ ] Vérifier que toutes les colonnes de base de données existent
- [ ] Tester la création d'une vente V1 dans l'application
- [ ] Tester la création d'une vente avec répartition
- [ ] Vérifier que les recettes sont créées automatiquement
- [ ] Vérifier que le stock est débité correctement
- [ ] Tester la récupération de la répartition
- [ ] Vérifier que les erreurs sont gérées correctement
- [ ] Tester avec des données réelles (adhérents, stocks, campagnes)

## 🚨 Problèmes potentiels identifiés

### Problème 1 : Colonnes manquantes
**Probabilité**: Moyenne
**Impact**: Erreurs SQL au runtime
**Solution**: Créer les migrations nécessaires

### Problème 2 : Table journal_ventes manquante
**Probabilité**: Faible (si migration V12/V13 existe)
**Impact**: Erreur lors de l'enregistrement dans le journal
**Solution**: Créer la table ou gérer l'erreur gracieusement

### Problème 3 : Requête SQL complexe dans _selectStocksDisponibles
**Probabilité**: Faible
**Impact**: Performance ou erreurs SQL
**Solution**: Tester avec des données réelles

## ✅ Conclusion

**Code compilé** : ✅ Oui (pas d'erreurs de linter)
**Architecture** : ✅ Correcte
**Connexions** : ✅ Correctes
**Fonctionnalité runtime** : ⚠️ À tester

**Recommandation** : 
1. Vérifier les colonnes de base de données en runtime
2. Tester avec des données réelles
3. Corriger les migrations si nécessaire
4. Ajouter la gestion d'erreurs pour les cas limites

