# Module de Paramétrage Centralisé - CoopManager

## 🎯 Vue d'ensemble

Module complet de paramétrage centralisé permettant aux administrateurs de configurer tous les aspects de l'application sans modification de code. Tous les modules consomment dynamiquement ces paramètres.

## 📋 Fonctionnalités

### 10 Écrans de Paramétrage

1. **Informations de la Coopérative**
   - Raison sociale, sigle, forme juridique
   - Numéro d'agrément, RCCM
   - Date de création
   - Adresse complète (région, département)
   - Contacts (téléphone, email)
   - Devise, langue
   - Logo (upload)

2. **Paramètres Généraux**
   - Devise
   - Format de date
   - Mode hors ligne
   - Durée de session
   - Notifications
   - Thème UI
   - Sauvegarde automatique

3. **Capital Social**
   - Valeur d'une part
   - Nombre minimum/maximum de parts
   - Libération obligatoire
   - Délai de libération
   - Dividendes activés
   - Taux de dividende

4. **Comptabilité Simplifiée**
   - Exercice actif
   - Soldes initiaux (caisse, banque)
   - Taux frais de gestion
   - Taux réserve
   - Comptes par défaut

5. **Ventes & Prix du Marché**
   - Prix minimum/maximum cacao
   - Prix du jour
   - Mode validation prix
   - Commission coopérative
   - Retenues automatiques
   - Alerte prix hors plage
   - Historique des prix

6. **Recettes & Commissions**
   - Types de commissions
   - Taux par catégorie
   - Retenues sociales
   - Retenues capital
   - Ordre de calcul

7. **Documents & QR Code**
   - Type document
   - Préfixe
   - Format numéro
   - Mentions légales
   - Signature automatique
   - QR Code actif
   - Aperçu PDF

8. **Social**
   - Types d'aides
   - Plafonds
   - Conditions d'éligibilité
   - Validation requise

9. **Utilisateurs & Rôles**
   - Gestion des rôles
   - Permissions
   - Accès modules
   - Restrictions

10. **Modules & Sécurité**
    - Activer/désactiver modules
    - Verrouillage paramétrage
    - Audit & logs
    - Authentification double facteur

## 🏗️ Architecture

### Structure des fichiers

```
lib/
├── data/models/settings/
│   ├── cooperative_settings_model.dart
│   ├── general_settings_model.dart
│   ├── capital_settings_model.dart
│   ├── accounting_settings_model.dart
│   ├── sales_settings_model.dart
│   ├── receipt_settings_model.dart
│   ├── document_settings_model.dart
│   ├── social_settings_model.dart
│   ├── module_settings_model.dart
│   └── setting_history_model.dart
│
├── services/parametres/
│   └── central_settings_service.dart
│
├── presentation/
│   ├── providers/
│   │   └── settings_provider.dart
│   ├── widgets/settings/
│   │   ├── setting_section_card.dart
│   │   ├── setting_toggle.dart
│   │   ├── setting_input.dart
│   │   ├── setting_select.dart
│   │   ├── setting_number_input.dart
│   │   ├── save_bar.dart
│   │   └── setting_history_dialog.dart
│   └── screens/settings/
│       ├── settings_main_screen.dart
│       ├── cooperative_settings_screen.dart
│       ├── general_settings_screen.dart
│       ├── capital_settings_screen.dart
│       ├── accounting_settings_screen.dart
│       ├── sales_settings_screen.dart
│       ├── receipt_settings_screen.dart
│       ├── document_settings_screen.dart
│       ├── social_settings_screen.dart
│       ├── users_roles_settings_screen.dart
│       └── module_settings_screen.dart
```

### Flux de données

```
UI → SettingsProvider → CentralSettingsService → API/SQLite
                          ↓
                      Cache SQLite
```

## 🚀 Utilisation

### 1. Initialisation

Le `SettingsProvider` doit être ajouté dans `main.dart` :

```dart
MultiProvider(
  providers: [
    // ... autres providers
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
  ],
  // ...
)
```

### 2. Accéder aux paramètres dans un module

```dart
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

// Dans votre widget
final settingsProvider = context.watch<SettingsProvider>();
final salesSettings = settingsProvider.salesSettings;

if (salesSettings != null) {
  // Utiliser les paramètres
  final prixMin = salesSettings.prixMinimumCacao;
  final prixMax = salesSettings.prixMaximumCacao;
  
  // Valider un prix
  if (salesSettings.isPrixValide(prixSaisi)) {
    // Prix valide
  }
}
```

### 3. Navigation vers le module

```dart
Navigator.pushNamed(context, AppRoutes.settingsMain);
```

## 🔧 Composants UI Réutilisables

### SettingSectionCard
Carte de section avec titre, icône et contenu.

### SettingToggle
Switch pour les paramètres booléens.

### SettingInput
Champ de texte avec validation.

### SettingSelect
Menu déroulant pour les choix multiples.

### SettingNumberInput
Champ numérique avec validation min/max.

### SaveBar
Barre de sauvegarde flottante avec gestion des changements.

### SettingHistoryDialog
Dialog pour afficher l'historique des modifications.

## 📊 Intégration avec les modules existants

### Module Ventes
- Utilise `salesSettings` pour valider les prix
- Applique automatiquement les commissions configurées
- Affiche des alertes si prix hors plage

### Module Adhérents
- Utilise `capitalSettings` pour valider le nombre de parts
- Calcule automatiquement le capital selon la valeur de part

### Module Facturation
- Utilise `cooperativeSettings` pour les informations de la coopérative
- Utilise `documentSettings` pour les mentions légales et QR Code

### Module Recettes
- Utilise `receiptSettings` pour calculer les retenues
- Applique l'ordre de calcul configuré

## 🔐 Sécurité

- Vérification des permissions avant accès
- Audit des modifications (historique)
- Validation des données avant sauvegarde
- Support multi-coopérative

## 📱 Responsive

- Interface adaptative pour desktop/web/mobile
- Menu latéral sur écrans larges
- Navigation par onglets sur petits écrans

## 🔄 Synchronisation

- Cache SQLite local pour fonctionnement hors ligne
- Synchronisation automatique avec le backend si disponible
- Fallback automatique en cas d'erreur réseau

## 📝 Historique

Toutes les modifications sont enregistrées avec :
- Ancienne valeur
- Nouvelle valeur
- Utilisateur
- Date/heure
- Raison (optionnelle)

## 🎨 Material 3

Interface moderne utilisant Material Design 3 avec :
- Thèmes clair/sombre
- Animations fluides
- Composants réutilisables
- Accessibilité

## ⚠️ Règles métier

1. **Aucune valeur en dur** : Tous les modules doivent consommer les paramètres
2. **Validation automatique** : Les paramètres incluent la logique de validation
3. **Cohérence** : Les modifications sont validées avant sauvegarde
4. **Traçabilité** : Toutes les modifications sont tracées

## 🔮 Fonctionnalités futures

- Mode "Assistant de configuration"
- Recommandations IA
- Import/Export de configuration
- Templates de configuration
- Validation avancée avec règles métier complexes

## 📚 Documentation

Voir `SETTINGS_MODULE_INTEGRATION.md` pour des exemples d'intégration détaillés.

