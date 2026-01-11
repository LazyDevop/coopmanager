# Module de Paramétrage Centralisé - Guide d'Intégration

## Vue d'ensemble

Le module de paramétrage centralisé permet de gérer tous les paramètres de l'application de manière unifiée. Tous les modules doivent consommer ces paramètres au lieu d'utiliser des valeurs en dur.

## Architecture

```
lib/
├── data/models/settings/          # Modèles de données pour chaque catégorie
├── services/parametres/
│   └── central_settings_service.dart  # Service centralisé
├── presentation/
│   ├── providers/
│   │   └── settings_provider.dart    # Provider pour l'état
│   ├── widgets/settings/             # Composants UI réutilisables
│   └── screens/settings/             # 10 écrans de paramétrage
```

## Utilisation dans les modules

### 1. Accéder aux paramètres depuis un module

```dart
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

// Dans votre widget
final settingsProvider = context.watch<SettingsProvider>();

// Accéder aux paramètres de ventes
final salesSettings = settingsProvider.salesSettings;
if (salesSettings != null) {
  final prixMin = salesSettings.prixMinimumCacao;
  final prixMax = salesSettings.prixMaximumCacao;
  
  // Valider un prix
  if (salesSettings.isPrixValide(prixSaisi)) {
    // Prix valide
  } else {
    // Afficher une alerte si activée
    if (salesSettings.alertePrixHorsPlage) {
      // Afficher l'alerte
    }
  }
}
```

### 2. Exemple d'intégration dans le module Ventes

```dart
// lib/presentation/screens/ventes/vente_form_screen.dart

import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class VenteFormScreen extends StatefulWidget {
  // ...
}

class _VenteFormScreenState extends State<VenteFormScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final salesSettings = settingsProvider.salesSettings;
    
    return Scaffold(
      body: Column(
        children: [
          // Champ prix avec validation automatique
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Prix (FCFA/kg)',
              helperText: salesSettings != null
                  ? 'Plage: ${salesSettings.prixMinimumCacao} - ${salesSettings.prixMaximumCacao} FCFA/kg'
                  : null,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Prix requis';
              final prix = double.tryParse(value);
              if (prix == null) return 'Prix invalide';
              
              // Utiliser la validation des paramètres
              if (salesSettings != null && !salesSettings.isPrixValide(prix)) {
                return 'Prix hors de la plage autorisée';
              }
              return null;
            },
          ),
          
          // Calcul automatique de la commission
          if (salesSettings != null)
            Text(
              'Commission: ${(montant * salesSettings.commissionCooperative).toStringAsFixed(2)} FCFA',
            ),
        ],
      ),
    );
  }
}
```

### 3. Exemple d'intégration dans le module Adhérents

```dart
// lib/presentation/screens/adherents/adherent_form_screen.dart

import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class AdherentFormScreen extends StatefulWidget {
  // ...
}

class _AdherentFormScreenState extends State<AdherentFormScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final capitalSettings = settingsProvider.capitalSettings;
    
    return Scaffold(
      body: Column(
        children: [
          // Nombre de parts avec validation
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Nombre de parts',
              helperText: capitalSettings != null
                  ? 'Minimum: ${capitalSettings.nombreMinParts}'
                      + (capitalSettings.nombreMaxParts != null
                          ? ', Maximum: ${capitalSettings.nombreMaxParts}'
                          : '')
                  : null,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nombre de parts requis';
              final nombre = int.tryParse(value);
              if (nombre == null) return 'Nombre invalide';
              
              if (capitalSettings != null) {
                if (nombre < capitalSettings.nombreMinParts) {
                  return 'Minimum ${capitalSettings.nombreMinParts} parts requis';
                }
                if (capitalSettings.nombreMaxParts != null &&
                    nombre > capitalSettings.nombreMaxParts!) {
                  return 'Maximum ${capitalSettings.nombreMaxParts} parts autorisé';
                }
              }
              return null;
            },
          ),
          
          // Calcul automatique du capital
          if (capitalSettings != null)
            Text(
              'Capital: ${(nombreParts * capitalSettings.valeurPart).toStringAsFixed(2)} FCFA',
            ),
        ],
      ),
    );
  }
}
```

### 4. Exemple d'intégration dans le module Facturation

```dart
// lib/presentation/screens/factures/facture_detail_screen.dart

import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class FactureDetailScreen extends StatelessWidget {
  // ...
  
  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final cooperativeSettings = settingsProvider.cooperativeSettings;
    final documentSettings = settingsProvider.documentSettings;
    
    return Scaffold(
      body: Column(
        children: [
          // Afficher les informations de la coopérative
          if (cooperativeSettings != null) ...[
            Text(cooperativeSettings.raisonSociale),
            if (cooperativeSettings.logoPath != null)
              Image.file(File(cooperativeSettings.logoPath!)),
            Text(cooperativeSettings.adresse ?? ''),
          ],
          
          // Afficher les mentions légales si configurées
          if (documentSettings?.mentionsLegales != null)
            Text(documentSettings!.mentionsLegales!),
          
          // QR Code si activé
          if (documentSettings?.qrCodeActif == true)
            // Générer le QR Code
            QRCodeWidget(data: factureId),
        ],
      ),
    );
  }
}
```

### 5. Exemple d'intégration dans le module Recettes

```dart
// lib/presentation/screens/recettes/recette_detail_screen.dart

import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class RecetteDetailScreen extends StatelessWidget {
  // ...
  
  Widget _buildCalculRecette(BuildContext context, double montantBrut) {
    final settingsProvider = context.watch<SettingsProvider>();
    final receiptSettings = settingsProvider.receiptSettings;
    
    if (receiptSettings == null) return SizedBox();
    
    double montantNet = montantBrut;
    
    // Appliquer les retenues selon l'ordre configuré
    for (final retenue in receiptSettings.ordreCalcul) {
      switch (retenue) {
        case 'social':
          montantNet -= montantBrut * receiptSettings.tauxRetenueSociale;
          break;
        case 'capital':
          montantNet -= montantBrut * receiptSettings.tauxRetenueCapital;
          break;
      }
    }
    
    return Column(
      children: [
        Text('Montant brut: ${montantBrut.toStringAsFixed(2)} FCFA'),
        Text('Retenues: ${(montantBrut - montantNet).toStringAsFixed(2)} FCFA'),
        Text('Montant net: ${montantNet.toStringAsFixed(2)} FCFA'),
      ],
    );
  }
}
```

## Chargement initial des paramètres

Dans votre écran principal ou au démarrage de l'application :

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser != null) {
      final settingsProvider = context.read<SettingsProvider>();
      settingsProvider.initialize(currentUser.id.toString());
      settingsProvider.loadAllSettings();
    }
  });
}
```

## Règles métier importantes

1. **Aucune valeur en dur** : Tous les modules doivent utiliser les paramètres configurés
2. **Validation automatique** : Les paramètres incluent la logique de validation
3. **Cache local** : Les paramètres sont mis en cache pour fonctionner hors ligne
4. **Synchronisation** : Les modifications sont synchronisées avec le backend si disponible

## Catégories de paramètres disponibles

1. **Coopérative** : Informations de la coopérative (nom, logo, adresse, etc.)
2. **Général** : Paramètres généraux (devise, format date, thème, etc.)
3. **Capital** : Configuration du capital social
4. **Comptabilité** : Paramètres comptables
5. **Ventes** : Prix et commissions pour les ventes
6. **Recettes** : Configuration des recettes et commissions
7. **Documents** : Configuration des documents et QR Code
8. **Social** : Paramètres des aides sociales
9. **Utilisateurs** : Gestion des utilisateurs et rôles
10. **Modules** : Activation/désactivation des modules et sécurité

## Navigation vers le module de paramétrage

```dart
Navigator.pushNamed(context, AppRoutes.settingsMain);
```

Ou depuis le menu principal, ajouter un élément :

```dart
ListTile(
  leading: Icon(Icons.settings),
  title: Text('Paramétrage'),
  onTap: () => Navigator.pushNamed(context, AppRoutes.settingsMain),
)
```

