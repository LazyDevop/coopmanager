# 📄 Topo sur le Paramétrage des Documents - CoopManager

## 🎯 Vue d'ensemble

Le module de paramétrage des documents permet de configurer la génération, la numérotation et la sécurisation de tous les documents officiels générés par l'application (factures, bordereaux de recettes, etc.).

**Accès** : Paramétrage → Documents & QR Code

---

## 📋 Structure des données

### Modèle principal : `DocumentSettingsModel`

```dart
DocumentSettingsModel {
  typesDocuments: Map<String, DocumentTypeConfig>  // Types de documents configurés
  mentionsLegales: String?                         // Texte légal à afficher
  signatureAutomatique: bool                       // Signature auto sur documents
  qrCodeActif: bool                                // Activation QR Code
  qrCodeFormat: String                             // Format QR ('url', 'json', 'custom')
  qrCodeUrlBase: String?                           // URL de base pour vérification
}
```

### Configuration par type : `DocumentTypeConfig`

Pour chaque type de document (facture, bordereau, etc.) :

```dart
DocumentTypeConfig {
  prefixe: String              // Ex: "FAC", "BOR", "REC"
  formatNumero: String         // Format: "YYYY-NNNN", "NNNN", etc.
  actif: bool                  // Type activé/désactivé
  template: String?            // Template personnalisé (optionnel)
}
```

---

## ⚙️ Fonctionnalités principales

### 1. **Configuration des types de documents**

Permet de définir pour chaque type de document :

- **Préfixe** : Identifiant textuel (ex: "FAC" pour facture)
- **Format de numérotation** : 
  - `YYYY-NNNN` : Année + numéro séquentiel (ex: 2024-0001)
  - `NNNN` : Numéro séquentiel simple (ex: 0001)
  - `{PREFIX}-{YEAR}-{NUM}` : Format personnalisé
- **Activation** : Activer/désactiver un type de document
- **Template** : Template personnalisé pour la génération PDF (optionnel)

**Types de documents par défaut** :
- `facture` : Factures de vente
- `bordereau` : Bordereaux de recettes
- `recette` : Bordereaux individuels de recette

### 2. **Mentions légales**

Champ texte libre pour ajouter des mentions légales qui apparaîtront automatiquement sur tous les documents générés.

**Exemple** :
```
"Conformément à la réglementation en vigueur, cette facture est établie selon les normes comptables..."
```

### 3. **Signature automatique**

- **Activée** : Les documents sont automatiquement signés lors de la génération
- **Désactivée** : Signature manuelle requise

### 4. **QR Code de vérification**

#### Activation du QR Code
Permet d'ajouter un QR Code sur chaque document pour :
- Vérification d'authenticité
- Accès rapide aux détails du document
- Traçabilité

#### Configuration du format

**Format `url`** (recommandé) :
- Génère un QR Code pointant vers une URL de vérification
- Format : `{qrCodeUrlBase}/verify/{documentId}`

**Format `json`** :
- Encode les données du document en JSON dans le QR Code
- Permet lecture directe sans connexion internet

**Format `custom`** :
- Format personnalisé défini par la coopérative

#### URL de base
Exemple : `https://coopmanager.example.com/verify/`

Le QR Code généré pointera vers : `https://coopmanager.example.com/verify/FAC-2024-0001`

---

## 🔧 Utilisation dans l'application

### Génération de numéros

Le système utilise automatiquement la configuration pour générer les numéros :

```dart
// Exemple pour une facture
Format configuré : "YYYY-NNNN"
Préfixe : "FAC"
Résultat : "FAC-2024-0001"
```

### Intégration dans les PDF

Les paramètres sont automatiquement appliqués lors de la génération :

1. **Mentions légales** : Ajoutées en bas de chaque page
2. **QR Code** : Intégré si activé (généralement en bas à droite)
3. **Signature** : Appliquée automatiquement si activée
4. **Numérotation** : Selon le format configuré

### Services concernés

- `FacturePdfService` : Génération des factures PDF
- `FactureService` : Génération des numéros de facture
- `DocumentSecurityService` : Gestion des QR Codes et sécurité
- `RecetteService` : Génération des bordereaux de recettes

---

## 📊 Écran de paramétrage

**Chemin** : Paramétrage → Documents & QR Code

### Sections disponibles

1. **Configuration documents**
   - Mentions légales (champ texte multiligne)
   - Signature automatique (toggle)

2. **QR Code**
   - QR Code actif (toggle)
   - URL de base pour QR Code (si activé)

### Sauvegarde

- Les modifications sont sauvegardées dans la table `settings` (catégorie `document`)
- Historique des modifications conservé
- Audit trail pour traçabilité

---

## 🔐 Sécurité et traçabilité

### QR Code de vérification

Chaque document généré avec QR Code contient :
- Identifiant unique du document
- Hash de sécurité pour vérification
- Timestamp de génération

### Audit

Toutes les modifications de paramètres sont :
- Enregistrées avec l'utilisateur responsable
- Horodatées
- Traçables dans l'historique

---

## 📝 Exemples de configuration

### Configuration standard

```json
{
  "types_documents": {
    "facture": {
      "prefixe": "FAC",
      "format_numero": "YYYY-NNNN",
      "actif": true
    },
    "bordereau": {
      "prefixe": "BOR",
      "format_numero": "YYYY-NNNN",
      "actif": true
    }
  },
  "qr_code_actif": true,
  "qr_code_format": "url",
  "qr_code_url_base": "https://coop.example.com/verify/",
  "signature_automatique": true,
  "mentions_legales": "Document établi conformément..."
}
```

### Format de numérotation personnalisé

Pour un format `FAC-2024-001` :
- Préfixe : `FAC`
- Format : `YYYY-NNN` (3 chiffres au lieu de 4)

---

## 🎨 Personnalisation avancée

### Templates personnalisés

Chaque type de document peut avoir son propre template :
- Structure du document
- Mise en page
- Éléments visuels
- Positionnement des informations

### Intégration avec les autres modules

Les paramètres de documents sont utilisés par :
- **Module Facturation** : Génération des factures
- **Module Recettes** : Bordereaux de paiement
- **Module Ventes** : Documents de vente
- **Module Comptabilité** : Pièces justificatives

---

## ⚠️ Points d'attention

1. **Modification des formats** : 
   - Les changements n'affectent que les nouveaux documents
   - Les documents existants conservent leur numérotation originale

2. **Désactivation d'un type** :
   - Empêche la génération de nouveaux documents de ce type
   - Les documents existants restent accessibles

3. **QR Code** :
   - Nécessite une URL de base valide si format `url`
   - Vérifier que l'URL est accessible publiquement

4. **Mentions légales** :
   - S'appliquent à tous les documents
   - Vérifier la conformité légale avant activation

---

## 🔄 Migration et compatibilité

Les paramètres sont stockés dans :
- Table `settings` (catégorie `document`)
- Compatible avec l'ancien système
- Migration automatique lors de la mise à jour

---

## 📚 Documentation technique

### Fichiers clés

- `lib/data/models/settings/document_settings_model.dart` : Modèles de données
- `lib/presentation/screens/settings/document_settings_screen.dart` : Interface utilisateur
- `lib/services/parametres/central_settings_service.dart` : Service de gestion
- `lib/services/facture/facture_pdf_service.dart` : Génération PDF
- `lib/services/qrcode/document_security_service.dart` : Sécurité QR Code

### API Backend (si mode API)

- `GET /settings/document` : Récupérer les paramètres
- `PUT /settings/document` : Sauvegarder les paramètres

---

## ✅ Checklist de configuration

- [ ] Définir les préfixes pour chaque type de document
- [ ] Configurer le format de numérotation souhaité
- [ ] Activer/désactiver les types de documents nécessaires
- [ ] Ajouter les mentions légales si requises
- [ ] Configurer la signature automatique
- [ ] Activer le QR Code si nécessaire
- [ ] Définir l'URL de base pour la vérification QR Code
- [ ] Tester la génération d'un document de chaque type
- [ ] Vérifier l'affichage des mentions légales
- [ ] Valider le fonctionnement du QR Code

---

**Dernière mise à jour** : Module intégré dans CoopManager v2.0.0

