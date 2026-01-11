# Module Facturation & Documents Officiels - CoopManager

## 📋 Vue d'ensemble

Module complet de gestion des documents officiels de la coopérative avec :
- Génération automatique de tous les documents métier
- Numérotation séquentielle unique
- Sécurisation par QR Code et hash SHA-256
- Traçabilité complète et immutabilité
- Intégration avec tous les modules existants

## 🏗️ Architecture

### Modèles de données

1. **DocumentModel** : Document officiel avec tous les métadonnées
2. **DocumentNumerotationModel** : Gestion de la numérotation séquentielle
3. **DocumentVerificationModel** : Historique des vérifications QR Code

### Services

1. **DocumentService** : Orchestration principale
   - Génération de documents
   - Numérotation automatique
   - Vérification QR Code
   - Annulation de documents

2. **PdfGeneratorService** : Génération PDF
   - Templates pour chaque type de document
   - Intégration QR Code dans PDF
   - Formatage professionnel

3. **QRCodeService** : Génération et vérification QR Code
   - Hash SHA-256
   - Génération d'images QR Code
   - Vérification hors ligne/en ligne

### Base de données (Migration V16)

Tables créées :
- `documents` : Tous les documents officiels
- `document_types` : Types de documents configurables
- `document_numerotation` : Numérotation séquentielle
- `document_verifications` : Historique vérifications

## 📄 Types de documents supportés

1. **Reçu de dépôt cacao** (`recu_depot`)
2. **Bordereau de pesée** (`bordereau_pesee`)
3. **Facture client** (`facture_client`)
4. **Bon de livraison** (`bon_livraison`)
5. **Bordereau de paiement** (`bordereau_paiement`)
6. **Reçu de paiement** (`recu_paiement`)
7. **État de compte adhérent** (`etat_compte`)
8. **État de participation actionnaire** (`etat_participation`)
9. **Journal des ventes** (`journal_ventes`)
10. **Journal de caisse** (`journal_caisse`)
11. **Journal des paiements** (`journal_paiements`)
12. **Rapport social** (`rapport_social`)

## 🔐 Sécurité

### Hash SHA-256
- Chaque document génère un hash unique basé sur son contenu
- Hash stocké dans `qr_code_hash`
- Vérification possible hors ligne

### QR Code
- Contient : numéro document, hash, date, type
- Image QR Code générée et intégrée dans PDF
- Vérification via écran dédié

### Immutabilité
- Documents marqués `est_immuable = true` après génération
- Aucune modification possible après génération
- Annulation via document d'annulation séparé

## 🔗 Intégration avec modules existants

### Module Stock
- Génération automatique de **Reçu de dépôt** lors d'un dépôt
- Génération de **Bordereau de pesée** lors de la pesée

### Module Ventes
- Génération automatique de **Facture client** lors d'une vente
- Génération de **Bon de livraison** si applicable

### Module Recettes
- Génération automatique de **Bordereau de paiement** lors du calcul de recette
- Génération de **Reçu de paiement** lors d'un paiement

### Module Adhérents
- Génération de **État de compte** sur demande
- Génération de **État de participation** pour actionnaires

## 🖥️ Frontend

### Écrans créés

1. **DocumentsListScreen** : Liste de tous les documents
   - Filtres par type, statut
   - Recherche par numéro
   - Affichage avec codes couleur par type
   - Badges de statut

2. **DocumentDetailScreen** (TODO) : Détail d'un document
   - Aperçu PDF intégré
   - Informations complètes
   - Vérification QR Code

3. **DocumentVerificationScreen** (TODO) : Vérification QR Code
   - Scanner QR Code
   - Vérification hash
   - Affichage résultat

### Navigation

- Route `/documents` : Liste des documents
- Route `/documents/detail` : Détail document
- Route `/documents/verification` : Vérification QR Code

## 📊 Numérotation

Format par défaut : `{PREFIXE}-{YYYY}-{NUM}`

Exemples :
- `DEP-2024-00001` : Reçu de dépôt
- `FAC-2024-00001` : Facture client
- `REC-2024-00001` : Reçu de paiement

Numérotation peut être :
- Globale (toutes campagnes)
- Par campagne (si `campagne_id` spécifié)

## 🚀 Utilisation

### Générer un document manuellement

```dart
final documentService = DocumentService();

final document = await documentService.genererDocument(
  type: DocumentModel.typeFactureClient,
  operationType: 'vente',
  contenu: {
    'client_nom': 'Client ABC',
    'montant': 50000.0,
    'date_vente': DateTime.now().toIso8601String(),
    // ... autres données
  },
  clientId: 1,
  operationId: venteId,
  createdBy: currentUser.id!,
);
```

### Vérifier un document

```dart
final estValide = await documentService.verifierDocument(
  documentId: documentId,
  hashVerifie: hashFromQRCode,
);
```

## ✅ Fonctionnalités implémentées

- [x] Modèles de données complets
- [x] Migration base de données V16
- [x] DocumentService avec orchestration
- [x] PdfGeneratorService (structure, placeholders)
- [x] QRCodeService amélioré avec hash SHA-256
- [x] DocumentViewModel pour état frontend
- [x] DocumentsListScreen avec filtres et recherche
- [x] Intégration dans navigation principale
- [x] Routes configurées

## 🔄 À compléter

- [ ] Implémenter génération PDF réelle (package pdf)
- [ ] Implémenter génération QR Code image (package qr_flutter)
- [ ] Créer DocumentDetailScreen avec aperçu PDF
- [ ] Créer DocumentVerificationScreen avec scanner
- [ ] Intégrer génération automatique dans StockService
- [ ] Intégrer génération automatique dans VenteService
- [ ] Intégrer génération automatique dans RecetteService
- [ ] Créer ArchiveService pour stockage immuable

## 📝 Notes techniques

- Les PDF sont générés dans `documents/` du répertoire application
- Les QR Codes sont générés dans `documents/qrcodes/`
- Hash SHA-256 garantit l'intégrité des documents
- Transactions DB garantissent la cohérence
- Audit complet de toutes les opérations

