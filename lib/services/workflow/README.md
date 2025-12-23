# WorkflowService - Service de Gestion Transactionnelle

## Vue d'ensemble

Le `WorkflowService` est le service central qui orchestre toutes les opérations critiques de CoopManager via des transactions SQLite atomiques. Il garantit l'intégrité des données en s'assurant que toutes les opérations d'un workflow sont exécutées avec succès, ou qu'elles sont toutes annulées en cas d'erreur (principe ACID).

## Architecture

### Principe de fonctionnement

Toutes les opérations critiques sont encapsulées dans des transactions SQLite :
- **BEGIN TRANSACTION** : Démarre la transaction
- **Opérations multiples** : Exécution de toutes les étapes du workflow
- **COMMIT** : Si toutes les opérations réussissent
- **ROLLBACK** : Si une opération échoue (annulation automatique)

### Intégration avec les autres services

Le `WorkflowService` utilise les services existants :
- `StockService` : Gestion du stock
- `VenteService` : Gestion des ventes
- `RecetteService` : Calcul des recettes
- `FactureService` : Génération des factures
- `AdherentService` : Historique des adhérents
- `AuditService` : Journalisation des actions
- `NotificationService` : Notifications utilisateur

## Workflows disponibles

### 1. Création de vente individuelle

**Méthode** : `workflowCreateVenteIndividuelle`

**Séquence transactionnelle** :
1. Vérification du stock disponible
2. Création de la vente
3. Déduction du stock (mouvement de stock)
4. Enregistrement dans l'historique de l'adhérent
5. Calcul et création de la recette
6. Génération de la facture (optionnel)
7. Audit log
8. Notifications

**Exemple d'utilisation** :

```dart
final workflowService = WorkflowService();

try {
  final result = await workflowService.workflowCreateVenteIndividuelle(
    adherentId: 1,
    quantite: 50.0, // kg
    prixUnitaire: 1500.0, // FCFA/kg
    acheteur: 'Client ABC',
    modePaiement: 'especes',
    dateVente: DateTime.now(),
    notes: 'Vente de cacao premium',
    createdBy: currentUserId,
    generateFacture: true,
    generateBordereau: false,
  );

  print('Vente créée : ${result['vente']}');
  print('Recette créée : ${result['recette']}');
  print('Stock restant : ${result['stockRestant']} kg');
  
  // Afficher un message de succès
  NotificationService().showToast(
    message: 'Vente enregistrée avec succès',
  );
} catch (e) {
  // L'erreur est automatiquement gérée par le service
  // La transaction a été annulée (rollback)
  print('Erreur : $e');
}
```

### 2. Création de vente groupée

**Méthode** : `workflowCreateVenteGroupee`

**Séquence transactionnelle** :
1. Vérification des stocks pour tous les adhérents
2. Création de la vente groupée
3. Création des détails de vente
4. Déduction du stock pour chaque adhérent
5. Enregistrement dans l'historique de chaque adhérent
6. Calcul et création des recettes pour chaque adhérent
7. Génération de la facture (optionnel)
8. Audit log
9. Notifications

**Exemple d'utilisation** :

```dart
final workflowService = WorkflowService();

final details = [
  VenteDetailModel(
    adherentId: 1,
    quantite: 30.0,
    prixUnitaire: 1500.0,
    montant: 45000.0,
  ),
  VenteDetailModel(
    adherentId: 2,
    quantite: 25.0,
    prixUnitaire: 1500.0,
    montant: 37500.0,
  ),
];

try {
  final result = await workflowService.workflowCreateVenteGroupee(
    details: details,
    prixUnitaire: 1500.0,
    acheteur: 'Client XYZ',
    modePaiement: 'mobile_money',
    dateVente: DateTime.now(),
    createdBy: currentUserId,
    generateFacture: true,
  );

  print('Vente groupée créée : ${result['vente']}');
  print('Recettes créées : ${result['recettes']}');
} catch (e) {
  print('Erreur : $e');
}
```

### 3. Création de dépôt de stock

**Méthode** : `workflowCreateDepot`

**Séquence transactionnelle** :
1. Création du dépôt
2. Création du mouvement de stock
3. Enregistrement dans l'historique de l'adhérent
4. Calcul du nouveau stock
5. Audit log
6. Notifications (si stock faible/critique)

**Exemple d'utilisation** :

```dart
final workflowService = WorkflowService();

try {
  final result = await workflowService.workflowCreateDepot(
    adherentId: 1,
    quantite: 100.0, // kg
    prixUnitaire: 1200.0, // FCFA/kg
    dateDepot: DateTime.now(),
    qualite: 'premium',
    observations: 'Cacao de première qualité',
    createdBy: currentUserId,
  );

  print('Dépôt créé : ${result['depot']}');
  print('Stock actuel : ${result['stockActuel']} kg');
} catch (e) {
  print('Erreur : $e');
}
```

### 4. Annulation de vente

**Méthode** : `workflowAnnulerVente`

**Séquence transactionnelle** :
1. Vérification de l'existence de la vente
2. Marquage de la vente comme annulée
3. Restauration du stock (ajustement positif)
4. Suppression de la recette associée
5. Mise à jour de l'historique de l'adhérent
6. Audit log
7. Notifications

**Exemple d'utilisation** :

```dart
final workflowService = WorkflowService();

try {
  final result = await workflowService.workflowAnnulerVente(
    venteId: 123,
    annulePar: currentUserId,
    raison: 'Erreur de saisie',
  );

  print('Vente annulée : ${result['vente']}');
  print('Message : ${result['message']}');
} catch (e) {
  print('Erreur : $e');
}
```

### 5. Modification de vente

**Méthode** : `workflowModifierVente`

**Séquence transactionnelle** :
1. Récupération de l'ancienne vente
2. Vérification du stock disponible pour la nouvelle quantité
3. Restauration du stock de l'ancienne quantité
4. Suppression de l'ancienne recette
5. Mise à jour de la vente avec les nouvelles données
6. Déduction du stock pour la nouvelle quantité
7. Création de la nouvelle recette
8. Mise à jour de l'historique
9. Audit log
10. Notifications

**Exemple d'utilisation** :

```dart
final workflowService = WorkflowService();

try {
  final result = await workflowService.workflowModifierVente(
    venteId: 123,
    adherentId: 1,
    nouvelleQuantite: 60.0, // Ancienne : 50.0 kg
    nouveauPrixUnitaire: 1600.0, // Ancien : 1500.0 FCFA/kg
    nouveauAcheteur: 'Nouveau Client',
    nouveauModePaiement: 'virement',
    nouvellesNotes: 'Quantité modifiée',
    modifiePar: currentUserId,
  );

  print('Vente modifiée : ${result['vente']}');
  print('Nouvelle recette : ${result['recette']}');
  print('Stock restant : ${result['stockRestant']} kg');
} catch (e) {
  print('Erreur : $e');
}
```

### 6. Ajustement de stock

**Méthode** : `workflowCreateAjustement`

**Séquence transactionnelle** :
1. Création du mouvement d'ajustement
2. Calcul du nouveau stock
3. Audit log
4. Notifications (si stock faible/critique)

**Exemple d'utilisation** :

```dart
final workflowService = WorkflowService();

try {
  // Ajout de stock
  final result = await workflowService.workflowCreateAjustement(
    adherentId: 1,
    quantite: 10.0, // Positif pour ajout
    raison: 'Correction d\'erreur de saisie',
    createdBy: currentUserId,
  );

  print('Ajustement créé : ${result['ajustement']}');
  print('Stock actuel : ${result['stockActuel']} kg');
} catch (e) {
  print('Erreur : $e');
}
```

## Gestion des erreurs

### Comportement automatique

Le `WorkflowService` gère automatiquement les erreurs :

1. **Rollback automatique** : Si une étape échoue, toutes les opérations précédentes sont annulées
2. **Audit log** : Toutes les transactions (succès et échecs) sont enregistrées
3. **Notifications** : Les erreurs sont notifiées à l'utilisateur via toast et notifications système
4. **Propagation** : L'erreur est relancée pour permettre à l'appelant de la gérer

### Types d'erreurs courantes

- **Stock insuffisant** : Vérifié avant toute création de vente
- **Vente déjà annulée** : Vérifié avant annulation
- **Vente non trouvée** : Vérifié avant modification/annulation
- **Erreurs de base de données** : Gérées automatiquement avec rollback

## Intégrité des données

### Contraintes garanties

1. **Atomicité** : Toutes les opérations d'un workflow sont exécutées ensemble ou pas du tout
2. **Cohérence** : Les données restent cohérentes même en cas d'erreur
3. **Isolation** : Les transactions sont isolées les unes des autres
4. **Durabilité** : Les données validées sont persistées

### Relations entre entités

Le service garantit la cohérence des relations :
- **Adhérent ↔ Stock** : Chaque mouvement de stock est lié à un adhérent
- **Stock ↔ Ventes** : Chaque vente déduit le stock correspondant
- **Ventes ↔ Recettes** : Chaque vente génère une recette
- **Recettes ↔ Factures** : Les factures peuvent être générées depuis les recettes

## Audit et traçabilité

### Journalisation automatique

Toutes les opérations sont enregistrées dans `audit_logs` :
- **Action** : Type d'opération (CREATE_VENTE, ANNULER_VENTE, etc.)
- **User ID** : Utilisateur ayant effectué l'opération
- **Entity Type** : Type d'entité concernée (ventes, stock, etc.)
- **Entity ID** : ID de l'entité concernée
- **Details** : Détails de l'opération
- **Timestamp** : Date et heure de l'opération

### Notifications

Les notifications sont envoyées pour :
- Succès d'opérations critiques
- Erreurs transactionnelles
- Alertes de stock faible/critique
- Annulations de ventes

## Bonnes pratiques

### 1. Toujours utiliser le WorkflowService pour les opérations critiques

❌ **Mauvais** :
```dart
// Opérations séparées sans transaction
await venteService.createVenteIndividuelle(...);
await stockService.deductStockForVente(...);
await recetteService.createRecetteFromVente(...);
```

✅ **Bon** :
```dart
// Opération transactionnelle complète
await workflowService.workflowCreateVenteIndividuelle(...);
```

### 2. Gérer les erreurs proprement

```dart
try {
  final result = await workflowService.workflowCreateVenteIndividuelle(...);
  // Afficher un message de succès
  showSuccessMessage('Vente créée avec succès');
} catch (e) {
  // Afficher un message d'erreur
  showErrorMessage('Erreur lors de la création de la vente: $e');
}
```

### 3. Utiliser les notifications intégrées

Le service envoie automatiquement les notifications appropriées. Vous pouvez également ajouter vos propres notifications après le succès :

```dart
try {
  final result = await workflowService.workflowCreateVenteIndividuelle(...);
  
  // Notification personnalisée supplémentaire
  NotificationService().showToast(
    message: 'Vente #${result['vente'].id} créée avec succès',
  );
} catch (e) {
  // L'erreur est déjà notifiée par le service
}
```

## Tests

### Exemple de test unitaire

```dart
test('Workflow création vente individuelle - Succès', () async {
  final workflowService = WorkflowService();
  
  // Préparer les données de test
  final adherentId = 1;
  final quantite = 50.0;
  final prixUnitaire = 1500.0;
  
  // Créer un dépôt de stock d'abord
  await workflowService.workflowCreateDepot(
    adherentId: adherentId,
    quantite: 100.0,
    dateDepot: DateTime.now(),
    createdBy: 1,
  );
  
  // Créer la vente
  final result = await workflowService.workflowCreateVenteIndividuelle(
    adherentId: adherentId,
    quantite: quantite,
    prixUnitaire: prixUnitaire,
    dateVente: DateTime.now(),
    createdBy: 1,
  );
  
  // Vérifications
  expect(result['vente'], isNotNull);
  expect(result['recette'], isNotNull);
  expect(result['stockRestant'], equals(50.0));
});
```

## Migration depuis les services individuels

Si vous utilisez actuellement les services individuels (`VenteService`, `StockService`, etc.) directement, voici comment migrer vers le `WorkflowService` :

### Avant (sans transaction)

```dart
// Risque d'incohérence si une étape échoue
final vente = await venteService.createVenteIndividuelle(...);
await stockService.deductStockForVente(...);
await recetteService.createRecetteFromVente(...);
```

### Après (avec transaction)

```dart
// Garantie d'intégrité avec rollback automatique
final result = await workflowService.workflowCreateVenteIndividuelle(...);
```

## Support et maintenance

Pour toute question ou problème concernant le `WorkflowService`, consultez :
- La documentation des services individuels
- Les logs d'audit dans la table `audit_logs`
- Les notifications dans la table `notifications`
