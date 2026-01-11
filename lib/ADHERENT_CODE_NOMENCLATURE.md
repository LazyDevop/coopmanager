# Nomenclature de Code Adhérent - ERP Coopérative

## Vue d'ensemble

Ce document décrit la nomenclature unique de code adhérent implémentée dans CoopManager, conforme aux standards ERP coopératifs.

## Format du Code

### Structure

Le code adhérent suit un format fixe de **8 caractères** :

```
[2 lettres coop/site][2 chiffres année][4 alphanumériques séquentiel]
```

### Exemples valides

- `CE25A9F2` - Coopérative CE, année 2025, séquentiel A9F2
- `CO24B103` - Coopérative CO, année 2024, séquentiel B103
- `ES26Z7Q8` - Site ES, année 2026, séquentiel Z7Q8

### Contraintes

- ✅ **Longueur fixe** : 8 caractères exactement
- ✅ **Format alphanumérique** : A-Z, 0-9 uniquement
- ✅ **Lisible par un humain** : Structure claire et logique
- ✅ **Unique** : Garantie d'unicité au sein de la coopérative
- ✅ **Généré automatiquement** : Par le système lors de la création
- ✅ **Non modifiable** : Après création, le code est verrouillé

## Composition du Code

### 1. Préfixe Coopérative/Site (2 lettres)

**Priorité de détermination :**

1. **Code site coopérative** : Si l'adhérent appartient à un site spécifique
2. **Code coopérative** : Depuis les paramètres (`code_cooperative`)
3. **Code par défaut** : "CO" si aucun code n'est configuré

**Configuration :**

Le code coopérative peut être configuré dans les paramètres de la coopérative :
- Accès : Paramètres → Informations coopérative
- Format : 2 lettres majuscules (ex: CO, CE, ES)

### 2. Année d'adhésion (2 chiffres)

Extrait automatiquement depuis la date d'adhésion :
- `2025` → `25`
- `2024` → `24`
- `2026` → `26`

### 3. Partie séquentielle (4 caractères alphanumériques)

Générée automatiquement avec :
- Caractères utilisables : A-Z, 0-9
- Algorithme sécurisé pour éviter les collisions
- Régénération automatique en cas de collision détectée

## Implémentation Technique

### Service de Génération

Le service `AdherentCodeGenerator` gère toute la logique de génération :

```dart
import 'package:coop_manager/services/adherent/adherent_code_generator.dart';

final generator = AdherentCodeGenerator();

// Générer un code unique
final code = await generator.generateUniqueCode(
  dateAdhesion: DateTime.now(),
  siteCooperative: 'CE', // Optionnel
);
```

### Validation

```dart
// Valider le format d'un code
bool isValid = AdherentCodeGenerator.isValidFormat('CE25A9F2');

// Valider et normaliser
String? normalized = AdherentCodeGenerator.validateAndNormalize('ce25a9f2');
// Retourne: 'CE25A9F2' ou null si invalide

// Parser un code
Map<String, String>? parsed = AdherentCodeGenerator.parseCode('CE25A9F2');
// Retourne: {'prefix': 'CE', 'year': '25', 'sequential': 'A9F2'}
```

### Base de Données

#### Contrainte UNIQUE

Un index UNIQUE garantit l'unicité du code :

```sql
CREATE UNIQUE INDEX idx_adherents_code_unique ON adherents(code);
```

#### Migration

La colonne `code_cooperative` est ajoutée automatiquement à la table `coop_settings` :

```sql
ALTER TABLE coop_settings ADD COLUMN code_cooperative TEXT;
```

## Utilisation dans l'Application

### Création d'un Adhérent

Lors de la création d'un adhérent, le code est généré automatiquement :

1. Le système récupère le code coopérative depuis les paramètres
2. Extrait l'année depuis la date d'adhésion
3. Génère une partie séquentielle unique
4. Vérifie l'unicité avant insertion
5. En cas de collision, régénère automatiquement

### Modification d'un Adhérent

**Le code ne peut pas être modifié après création.**

Toute tentative de modification du code génère une erreur :
```
Le code adhérent ne peut pas être modifié après création
```

### Affichage

Le code adhérent apparaît sur :
- ✅ Tous les documents officiels (reçus, factures, bordereaux)
- ✅ Les QR Codes générés
- ✅ Les listes et détails d'adhérents
- ✅ Les exports et rapports

## Migration depuis l'Ancien Format

### Ancien Format (Déprécié)

- Format : `ADH001`, `ADH002`, etc.
- Longueur variable
- Séquentiel numérique uniquement

### Compatibilité

Les anciens codes sont **acceptés** pour la compatibilité ascendante, mais :
- ⚠️ Les nouveaux adhérents utilisent automatiquement le nouveau format
- ⚠️ L'ancienne méthode `generateNextCode()` est marquée comme dépréciée
- ✅ Les deux formats coexistent dans la base de données

## Configuration

### Paramètres Coopérative

Pour configurer le code coopérative :

1. Accéder à **Paramètres** → **Informations coopérative**
2. Saisir le **Code coopérative** (2 lettres majuscules)
3. Exemples : `CO`, `CE`, `ES`, `CA`, `BA`

**Validation :**
- Exactement 2 caractères
- Lettres majuscules uniquement (A-Z)
- Obligatoire pour utiliser la nouvelle nomenclature

## Gestion des Collisions

Le système gère automatiquement les collisions :

1. **Vérification préalable** : Avant insertion, vérifie l'unicité
2. **Régénération** : En cas de collision, génère un nouveau code
3. **Tentatives multiples** : Jusqu'à 10 tentatives par défaut
4. **Fallback sécurisé** : Utilise un timestamp si nécessaire

## Exemples d'Utilisation

### Génération manuelle

```dart
final generator = AdherentCodeGenerator();

// Code pour un adhérent de 2025
final code2025 = await generator.generateUniqueCode(
  dateAdhesion: DateTime(2025, 1, 15),
);

// Code pour un site spécifique
final codeSite = await generator.generateUniqueCode(
  dateAdhesion: DateTime.now(),
  siteCooperative: 'ES',
);
```

### Validation dans le formulaire

```dart
// Dans le formulaire d'adhérent
final code = codeController.text.trim();
if (!AdherentCodeGenerator.isValidFormat(code)) {
  return 'Format de code invalide. Format attendu: CE25A9F2';
}
```

### Extraction d'informations

```dart
final parsed = AdherentCodeGenerator.parseCode('CE25A9F2');
if (parsed != null) {
  print('Coopérative: ${parsed['prefix']}');      // CE
  print('Année: ${parsed['year']}');              // 25
  print('Séquentiel: ${parsed['sequential']}');   // A9F2
  
  final fullYear = AdherentCodeGenerator.extractFullYear('CE25A9F2');
  print('Année complète: $fullYear');              // 2025
}
```

## Sécurité et Intégrité

### Garanties

1. **Unicité** : Contrainte UNIQUE en base de données
2. **Immutabilité** : Code non modifiable après création
3. **Validation** : Format vérifié avant insertion
4. **Traçabilité** : Code utilisé dans tous les documents officiels

### Bonnes Pratiques

- ✅ Toujours utiliser `AdherentCodeGenerator` pour générer les codes
- ✅ Valider le format avant insertion manuelle
- ✅ Ne jamais modifier un code existant
- ✅ Configurer le code coopérative dans les paramètres

## Support et Maintenance

### Dépannage

**Problème : Code déjà existant**
- Solution : Le système régénère automatiquement
- Vérifier la contrainte UNIQUE en base de données

**Problème : Format invalide**
- Solution : Utiliser `validateAndNormalize()` pour corriger
- Vérifier que le code respecte le format [2 lettres][2 chiffres][4 alphanumériques]

**Problème : Code non généré**
- Solution : Vérifier que le code coopérative est configuré
- Vérifier les permissions de la base de données

### Logs

Les erreurs de génération sont loggées avec le préfixe :
```
⚠️ Erreur lors de la génération du code adhérent: ...
```

## Conclusion

La nouvelle nomenclature de code adhérent offre :
- ✅ Un format standardisé et professionnel
- ✅ Une intégrité garantie par la base de données
- ✅ Une traçabilité complète sur tous les documents
- ✅ Une compatibilité avec les systèmes ERP existants

Pour toute question ou problème, consulter la documentation technique ou contacter le support.

