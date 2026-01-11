# 📄 Système de Génération de Documents PDF - CoopManager

## 🎯 Vue d'ensemble

Le système de génération de documents PDF de CoopManager garantit :
- ✅ **Cohérence visuelle** : Tous les documents utilisent le même template
- ✅ **Conformité administrative** : Informations légales complètes
- ✅ **Traçabilité** : Historisation de tous les documents générés
- ✅ **Sécurité documentaire** : QR codes et hash SHA-256 pour vérification

## 🏗️ Architecture

```
lib/
├── data/models/document/
│   ├── document_model.dart          # Modèle principal
│   └── document_metadata.dart        # Métadonnées spécifiques
├── services/document/
│   ├── document_generator_service.dart  # Service principal
│   ├── qrcode_service.dart              # Génération QR codes
│   ├── repositories/
│   │   └── document_repository.dart     # Accès base de données
│   └── examples/
│       └── facture_example.dart          # Exemples d'utilisation
└── presentation/providers/
    └── document_provider.dart           # Provider Flutter
```

## 📋 Types de Documents Supportés

1. **Facture de vente** (`FACTURE_VENTE`)
2. **Facture de recette** (`FACTURE_RECETTE`)
3. **Reçu de dépôt cacao** (`RECU_DEPOT`)
4. **Reçu de paiement adhérent** (`RECU_PAIEMENT_ADHERENT`)
5. **Reçu de paiement client** (`RECU_PAIEMENT_CLIENT`)
6. **Bordereau de recette** (`BORDEREAU_RECETTE`)
7. **Journal de caisse** (`JOURNAL_CAISSE`)
8. **État de compte adhérent** (`ETAT_COMPTE_ADHERENT`)
9. **État du capital social** (`ETAT_CAPITAL_SOCIAL`)
10. **Fiche actionnaire** (`FICHE_ACTIONNAIRE`)
11. **Rapport social** (`RAPPORT_SOCIAL`)

## 🔧 Utilisation

### 1. Génération d'un document

```dart
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../providers/document_provider.dart';
import '../../data/models/document/document_model.dart';

// Dans votre widget
final documentProvider = context.read<DocumentProvider>();

final document = await documentProvider.generateDocument(
  documentType: DocumentType.factureVente,
  documentReference: 'FAC-2025-0012',
  cooperativeId: 1,
  generatedBy: currentUserId,
  documentTitle: 'FACTURE DE VENTE',
  buildContent: (pw.Context context) {
    return pw.Column(
      children: [
        // Votre contenu spécifique ici
        pw.Text('Détails de la facture'),
        // ...
      ],
    );
  },
  contentData: {
    'montant_total': 150000.0,
    'client_nom': 'Client XYZ',
    // ...
  },
  additionalMetadata: {
    'facture_id': 123,
    'vente_id': 456,
  },
);
```

### 2. Prévisualisation d'un document

```dart
import 'package:printing/printing.dart';
import 'dart:io';

// Charger le PDF
final file = File(document.filePath!);
final bytes = await file.readAsBytes();

// Afficher l'aperçu
await Printing.layoutPdf(
  onLayout: (format) async => bytes,
);
```

### 3. Téléchargement

```dart
import 'package:file_picker/file_picker.dart';

// Permettre à l'utilisateur de choisir l'emplacement
final file = File(document.filePath!);
final bytes = await file.readAsBytes();

// Utiliser file_picker ou share_plus pour partager
```

### 4. Vérification d'un document

```dart
final isValid = await documentProvider.verifyDocument(
  documentId: document.id!,
  verifiedBy: currentUserId,
);
```

## 📐 Structure du Template

### Header (En-tête)
- Logo de la coopérative
- Raison sociale et sigle
- Adresse complète
- Téléphone et email
- Région / Département
- Devise
- Titre du document

### Footer (Pied de page)
- Numéro d'agrément
- QR Code unique
- Code de vérification (hash)
- Date et heure de génération
- Mention légale

## 🔒 Sécurité

### QR Code
Le QR code contient :
```json
{
  "document_type": "FACTURE_VENTE",
  "document_id": "FAC-2025-0012",
  "cooperative_id": "COOP-1",
  "hash": "SHA256(...)",
  "generated_at": "2026-01-15T10:32:00Z"
}
```

### Hash SHA-256
Le hash est calculé à partir de :
- Type de document
- Référence du document
- ID de la coopérative
- Date de génération
- Contenu du document

## 📊 Traçabilité

Tous les documents générés sont enregistrés dans la table `documents` avec :
- Type et référence
- Hash de vérification
- Métadonnées (JSON)
- Chemin du fichier PDF
- Utilisateur générateur
- Date de génération
- Historique des vérifications

## 🚀 Exemple Complet

Voir `lib/services/document/examples/facture_example.dart` pour un exemple complet de génération de facture.

## 📝 Notes Importantes

1. **Coopérative active requise** : Aucun document ne peut être généré sans une coopérative active configurée
2. **Numéro unique** : Chaque document doit avoir une référence unique
3. **QR Code obligatoire** : Tous les documents incluent un QR code
4. **Immutabilité** : Les documents générés ne peuvent pas être modifiés
5. **Historisation** : Tous les documents sont tracés dans la base de données

## 🔄 Intégration avec les Paramètres

Le système charge automatiquement les paramètres de la coopérative depuis :
- `CooperativeSettingsModel` (via `CentralSettingsService`)
- Logo, raison sociale, adresse, etc.
- Numéro d'agrément pour le footer

## 📱 Interface Flutter

Le `DocumentProvider` expose :
- `generateDocument()` : Générer un nouveau document
- `loadRecentDocuments()` : Charger les documents récents
- `getDocumentByReference()` : Récupérer un document
- `verifyDocument()` : Vérifier l'authenticité

## 🐛 Dépannage

### Erreur : "Aucune coopérative active configurée"
- Vérifier que les paramètres de la coopérative sont configurés
- S'assurer que `CentralSettingsService` est initialisé

### Erreur : "Erreur lors de la génération du QR code"
- Implémenter la génération réelle du QR code (voir TODO dans le code)
- Utiliser une bibliothèque comme `qr_flutter` ou `qr.dart`

### Erreur : "Image non trouvée"
- Vérifier que le chemin du logo est correct
- S'assurer que le fichier existe sur le système de fichiers

