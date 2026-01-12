/// Exemples d'intégration des settings avec les autres modules
/// 
/// Ce fichier montre comment utiliser les settings dans les différents modules
/// de l'application (Ventes, Recettes, Facturation, Social, Capital)

import '../parametres/backend/settings_service.dart';
import '../parametres/repositories/cooperative_repository.dart';
import '../../data/models/backend/setting_model.dart';

/// Exemple d'intégration avec le module Ventes
class SettingsVentesIntegration {
  final SettingsService _settingsService;
  
  SettingsVentesIntegration({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();
  
  /// Récupérer le prix minimum du cacao depuis les settings
  Future<double> getPrixMinimumCacao({double defaultValue = 1000.0}) async {
    return await _settingsService.getValue<double>(
      category: 'ventes',
      key: 'prix_minimum_cacao',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
  
  /// Récupérer le prix maximum du cacao depuis les settings
  Future<double> getPrixMaximumCacao({double defaultValue = 2000.0}) async {
    return await _settingsService.getValue<double>(
      category: 'ventes',
      key: 'prix_maximum_cacao',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
  
  /// Récupérer le prix du jour depuis les settings
  Future<double?> getPrixDuJour() async {
    return await _settingsService.getValue<double>(
      category: 'ventes',
      key: 'prix_du_jour',
      defaultValue: null,
    );
  }
  
  /// Récupérer le taux de commission depuis les settings
  Future<double> getTauxCommission({double defaultValue = 0.05}) async {
    return await _settingsService.getValue<double>(
      category: 'ventes',
      key: 'taux_commission',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
  
  /// Valider un prix selon les limites configurées
  Future<bool> validerPrix(double prix) async {
    final prixMin = await getPrixMinimumCacao();
    final prixMax = await getPrixMaximumCacao();
    return prix >= prixMin && prix <= prixMax;
  }
}

/// Exemple d'intégration avec le module Recettes
class SettingsRecettesIntegration {
  final SettingsService _settingsService;
  
  SettingsRecettesIntegration({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();
  
  /// Récupérer le taux de commission pour les recettes
  Future<double> getTauxCommission({double defaultValue = 0.05}) async {
    return await _settingsService.getValue<double>(
      category: 'recettes',
      key: 'taux_commission',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
  
  /// Récupérer les retenues sociales activées
  Future<bool> getRetenuesSocialesActives({bool defaultValue = true}) async {
    return await _settingsService.getValue<bool>(
      category: 'recettes',
      key: 'retenues_sociales_actives',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
  
  /// Récupérer les retenues capital activées
  Future<bool> getRetenuesCapitalActives({bool defaultValue = false}) async {
    return await _settingsService.getValue<bool>(
      category: 'recettes',
      key: 'retenues_capital_actives',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
}

/// Exemple d'intégration avec le module Facturation
class SettingsFacturationIntegration {
  final SettingsService _settingsService;
  
  SettingsFacturationIntegration({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();
  
  /// Récupérer le préfixe des factures
  Future<String> getPrefixeFacture({String defaultValue = 'FAC'}) async {
    return await _settingsService.getValue<String>(
      category: 'documents',
      key: 'prefixe_facture',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
  
  /// Récupérer le format de numéro de facture
  Future<String> getFormatNumero({String defaultValue = '{PREFIX}-{YEAR}-{NUM}'}) async {
    return await _settingsService.getValue<String>(
      category: 'documents',
      key: 'format_numero',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
  
  /// Vérifier si la signature automatique est activée
  Future<bool> getSignatureAutomatique({bool defaultValue = false}) async {
    return await _settingsService.getValue<bool>(
      category: 'documents',
      key: 'signature_automatique',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
  
  /// Vérifier si le QR Code est activé
  Future<bool> getQrCodeActif({bool defaultValue = true}) async {
    return await _settingsService.getValue<bool>(
      category: 'documents',
      key: 'qr_code_actif',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
}

/// Exemple d'intégration avec le module Social
class SettingsSocialIntegration {
  final SettingsService _settingsService;
  
  SettingsSocialIntegration({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();
  
  /// Récupérer le plafond d'aide sociale
  Future<double> getPlafondAideSociale({double defaultValue = 100000.0}) async {
    return await _settingsService.getValue<double>(
      category: 'social',
      key: 'plafond_aide_sociale',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
  
  /// Vérifier si la validation est requise pour les aides
  Future<bool> getValidationRequise({bool defaultValue = true}) async {
    return await _settingsService.getValue<bool>(
      category: 'social',
      key: 'validation_requise',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
}

/// Exemple d'intégration avec le module Capital Social
class SettingsCapitalIntegration {
  final SettingsService _settingsService;
  
  SettingsCapitalIntegration({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();
  
  /// Récupérer la valeur d'une part
  Future<double> getValeurPart({double defaultValue = 1000.0}) async {
    return await _settingsService.getValue<double>(
      category: 'capital',
      key: 'valeur_part',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
  
  /// Récupérer le nombre minimum de parts
  Future<int> getNombreMinParts({int defaultValue = 1}) async {
    return await _settingsService.getValue<int>(
      category: 'capital',
      key: 'nombre_min_parts',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
  
  /// Récupérer le nombre maximum de parts
  Future<int?> getNombreMaxParts() async {
    return await _settingsService.getValue<int>(
      category: 'capital',
      key: 'nombre_max_parts',
      defaultValue: null,
    );
  }
  
  /// Vérifier si la libération est obligatoire
  Future<bool> getLiberationObligatoire({bool defaultValue = false}) async {
    return await _settingsService.getValue<bool>(
      category: 'capital',
      key: 'liberation_obligatoire',
      defaultValue: defaultValue,
    ) ?? defaultValue;
  }
  
  /// Calculer le capital total pour un nombre de parts
  Future<double> calculerCapital(int nombreParts) async {
    final valeurPart = await getValeurPart();
    return nombreParts * valeurPart;
  }
}

/// Classe utilitaire pour accéder facilement à tous les settings
class SettingsHelper {
  static final SettingsVentesIntegration ventes = SettingsVentesIntegration();
  static final SettingsRecettesIntegration recettes = SettingsRecettesIntegration();
  static final SettingsFacturationIntegration facturation = SettingsFacturationIntegration();
  static final SettingsSocialIntegration social = SettingsSocialIntegration();
  static final SettingsCapitalIntegration capital = SettingsCapitalIntegration();
  
  /// Exemple d'utilisation dans un module de vente
  static Future<void> exempleUtilisationVente() async {
    // Récupérer les paramètres de vente
    final prixMin = await ventes.getPrixMinimumCacao();
    final prixMax = await ventes.getPrixMaximumCacao();
    final tauxCommission = await ventes.getTauxCommission();
    
    // Utiliser les paramètres pour une vente
    const prixVente = 1500.0;
    if (await ventes.validerPrix(prixVente)) {
      final commission = prixVente * tauxCommission;
      final montantNet = prixVente - commission;
      print('Prix validé: $prixVente, Commission: $commission, Net: $montantNet');
    } else {
      print('Prix hors limites: $prixVente (min: $prixMin, max: $prixMax)');
    }
  }
  
  /// Exemple d'utilisation dans un module de facturation
  static Future<String> genererNumeroFacture(int numero) async {
    final prefixe = await facturation.getPrefixeFacture();
    final format = await facturation.getFormatNumero();
    final annee = DateTime.now().year;
    
    return format
        .replaceAll('{PREFIX}', prefixe)
        .replaceAll('{YEAR}', annee.toString())
        .replaceAll('{NUM}', numero.toString().padLeft(6, '0'));
  }
}

