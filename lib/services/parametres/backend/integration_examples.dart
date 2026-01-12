/// Exemples d'intégration du module de paramétrage avec les autres modules

import '../../../data/models/backend/setting_model.dart';
import '../../../data/models/backend/specialized_settings_models.dart';
import 'settings_service.dart';
import '../repositories/specialized_settings_repository.dart';
import '../repositories/cooperative_repository.dart';

// ============================================
// EXEMPLE 1 : INTÉGRATION AVEC LE MODULE VENTES
// ============================================

class VentesIntegrationExample {
  final SettingsService _settingsService;
  final ICooperativeRepository _coopRepo;

  VentesIntegrationExample({
    SettingsService? settingsService,
    ICooperativeRepository? coopRepo,
  })  : _settingsService = settingsService ?? SettingsService(),
        _coopRepo = coopRepo ?? CooperativeRepository();

  /// Valider le prix d'une vente selon les paramètres
  Future<bool> validatePrixVente({
    required String cooperativeId,
    required double prixUnitaire,
    required String produitId,
  }) async {
    // 1. Récupérer la devise
    final devise = await _settingsService.getValue<String>(
      cooperativeId: cooperativeId,
      category: 'coop',
      key: 'devise',
      defaultValue: 'XAF',
    );

    // 2. Récupérer les seuils de prix
    final prixMin = await _settingsService.getValue<double>(
      cooperativeId: cooperativeId,
      category: 'vente',
      key: 'prix_min_$produitId',
    );
    
    final prixMax = await _settingsService.getValue<double>(
      cooperativeId: cooperativeId,
      category: 'vente',
      key: 'prix_max_$produitId',
    );

    // 3. Valider
    if (prixMin != null && prixUnitaire < prixMin) {
      throw Exception('Le prix est inférieur au minimum autorisé: $prixMin $devise');
    }
    
    if (prixMax != null && prixUnitaire > prixMax) {
      throw Exception('Le prix est supérieur au maximum autorisé: $prixMax $devise');
    }

    // 4. Vérifier la variation autorisée
    final variationAutorisee = await _settingsService.getValue<double>(
      cooperativeId: cooperativeId,
      category: 'vente',
      key: 'variation_autorisee',
      defaultValue: 10.0,
    );

    final prixJour = await _settingsService.getValue<double>(
      cooperativeId: cooperativeId,
      category: 'vente',
      key: 'prix_jour_$produitId',
    );

    if (prixJour != null) {
      final variation = ((prixUnitaire - prixJour) / prixJour * 100).abs();
      if (variation > variationAutorisee) {
        throw Exception('La variation de prix dépasse le seuil autorisé: $variationAutorisee%');
      }
    }

    return true;
  }

  /// Générer le numéro de vente automatiquement
  Future<String> generateNumeroVente({
    required String cooperativeId,
    required int sequence,
  }) async {
    final docRepo = DocumentSettingsRepository();
    final settings = await docRepo.getByType(cooperativeId, DocumentType.vente);
    
    if (settings == null) {
      // Format par défaut
      return 'VNT-${DateTime.now().year}-${sequence.toString().padLeft(4, '0')}';
    }
    
    return settings.generateNumero(sequence);
  }

  /// Récupérer les taxes applicables
  Future<Map<String, double>> getTaxes({
    required String cooperativeId,
  }) async {
    final tva = await _settingsService.getValue<double>(
      cooperativeId: cooperativeId,
      category: 'vente',
      key: 'taux_tva',
      defaultValue: 0.0,
    );

    final fraisTransport = await _settingsService.getValue<double>(
      cooperativeId: cooperativeId,
      category: 'vente',
      key: 'frais_transport',
      defaultValue: 0.0,
    );

    return {
      'tva': tva ?? 0.0,
      'frais_transport': fraisTransport ?? 0.0,
    };
  }
}

// ============================================
// EXEMPLE 2 : INTÉGRATION AVEC LE MODULE CAPITAL SOCIAL
// ============================================

class CapitalSocialIntegrationExample {
  final CapitalSettingsRepository _capitalRepo;
  final SettingsService _settingsService;

  CapitalSocialIntegrationExample({
    CapitalSettingsRepository? capitalRepo,
    SettingsService? settingsService,
  })  : _capitalRepo = capitalRepo ?? CapitalSettingsRepository(),
        _settingsService = settingsService ?? SettingsService();

  /// Valider une souscription de parts
  Future<bool> validateSouscription({
    required String cooperativeId,
    required int nombreParts,
  }) async {
    final settings = await _capitalRepo.getByCooperative(cooperativeId);
    if (settings == null) {
      throw Exception('Les paramètres du capital social ne sont pas configurés');
    }

    // Vérifier le minimum
    if (nombreParts < settings.partsMin) {
      throw Exception('Le nombre minimum de parts est ${settings.partsMin}');
    }

    // Vérifier le maximum
    if (settings.partsMax != null && nombreParts > settings.partsMax!) {
      throw Exception('Le nombre maximum de parts est ${settings.partsMax}');
    }

    return true;
  }

  /// Calculer le montant total d'une souscription
  Future<double> calculerMontantSouscription({
    required String cooperativeId,
    required int nombreParts,
  }) async {
    final settings = await _capitalRepo.getByCooperative(cooperativeId);
    if (settings == null) {
      throw Exception('Les paramètres du capital social ne sont pas configurés');
    }

    return settings.valeurPart * nombreParts;
  }

  /// Vérifier si la libération est obligatoire
  Future<bool> isLiberationObligatoire({
    required String cooperativeId,
  }) async {
    final settings = await _capitalRepo.getByCooperative(cooperativeId);
    return settings?.liberationObligatoire ?? false;
  }
}

// ============================================
// EXEMPLE 3 : INTÉGRATION AVEC LE MODULE FACTURATION
// ============================================

class FacturationIntegrationExample {
  final DocumentSettingsRepository _docRepo;
  final SettingsService _settingsService;
  final ICooperativeRepository _coopRepo;

  FacturationIntegrationExample({
    DocumentSettingsRepository? docRepo,
    SettingsService? settingsService,
    ICooperativeRepository? coopRepo,
  })  : _docRepo = docRepo ?? DocumentSettingsRepository(),
        _settingsService = settingsService ?? SettingsService(),
        _coopRepo = coopRepo ?? CooperativeRepository();

  /// Générer un numéro de facture
  Future<String> generateNumeroFacture({
    required String cooperativeId,
    required int sequence,
  }) async {
    final settings = await _docRepo.getByType(cooperativeId, DocumentType.facture);
    
    if (settings == null) {
      throw Exception('Les paramètres de facturation ne sont pas configurés');
    }
    
    return settings.generateNumero(sequence);
  }

  /// Récupérer les mentions légales pour le pied de page
  Future<String?> getMentionsLegales({
    required String cooperativeId,
  }) async {
    final settings = await _docRepo.getByType(cooperativeId, DocumentType.facture);
    return settings?.piedPage;
  }

  /// Vérifier si la signature automatique est activée
  Future<bool> isSignatureAuto({
    required String cooperativeId,
  }) async {
    final settings = await _docRepo.getByType(cooperativeId, DocumentType.facture);
    return settings?.signatureAuto ?? false;
  }

  /// Récupérer les informations de la coopérative pour l'en-tête
  Future<Map<String, String?>> getCooperativeInfo({
    required String cooperativeId,
  }) async {
    final coop = await _coopRepo.getById(cooperativeId);
    if (coop == null) {
      throw Exception('Coopérative introuvable');
    }

    return {
      'raison_sociale': coop.raisonSociale,
      'sigle': coop.sigle,
      'adresse': coop.adresse,
      'telephone': coop.telephone,
      'email': coop.email,
      'rccm': coop.rccm,
      'numero_agrement': coop.numeroAgrement,
    };
  }
}

// ============================================
// EXEMPLE 4 : INTÉGRATION AVEC LE MODULE COMPTABILITÉ
// ============================================

class ComptabiliteIntegrationExample {
  final AccountingSettingsRepository _accountingRepo;
  final SettingsService _settingsService;

  ComptabiliteIntegrationExample({
    AccountingSettingsRepository? accountingRepo,
    SettingsService? settingsService,
  })  : _accountingRepo = accountingRepo ?? AccountingSettingsRepository(),
        _settingsService = settingsService ?? SettingsService();

  /// Vérifier qu'un exercice peut être ouvert
  Future<bool> canOpenExercise({
    required String cooperativeId,
    required int exercice,
  }) async {
    final settings = await _accountingRepo.getByCooperative(cooperativeId);
    if (settings == null) {
      throw Exception('Les paramètres comptables ne sont pas configurés');
    }

    // Règle métier : Un seul exercice actif à la fois
    if (settings.exerciceActif != exercice) {
      // Vérifier que l'exercice actif est clôturé
      final isClosed = await _settingsService.getValue<bool>(
        cooperativeId: cooperativeId,
        category: 'accounting',
        key: 'exercice_${settings.exerciceActif}_closed',
        defaultValue: false,
      );

      if (!isClosed) {
        throw Exception('L\'exercice ${settings.exerciceActif} doit être clôturé avant d\'ouvrir $exercice');
      }
    }

    return true;
  }

  /// Récupérer les comptes par défaut
  Future<Map<String, String?>> getDefaultAccounts({
    required String cooperativeId,
  }) async {
    final settings = await _accountingRepo.getByCooperative(cooperativeId);
    if (settings == null) {
      throw Exception('Les paramètres comptables ne sont pas configurés');
    }

    return {
      'caisse': settings.compteCaisse,
      'banque': settings.compteBanque,
    };
  }

  /// Calculer les réserves et frais de gestion
  Future<Map<String, double>> calculateReservesAndFees({
    required String cooperativeId,
    required double montantBrut,
  }) async {
    final settings = await _accountingRepo.getByCooperative(cooperativeId);
    if (settings == null) {
      throw Exception('Les paramètres comptables ne sont pas configurés');
    }

    final reserve = montantBrut * settings.tauxReserve;
    final fraisGestion = montantBrut * settings.tauxFraisGestion;

    return {
      'reserve': reserve,
      'frais_gestion': fraisGestion,
      'net': montantBrut - reserve - fraisGestion,
    };
  }
}

// ============================================
// EXEMPLE 5 : UTILISATION GÉNÉRALE
// ============================================

class ParametrageUsageExample {
  final SettingsService _settingsService;
  final ICooperativeRepository _coopRepo;

  ParametrageUsageExample({
    SettingsService? settingsService,
    ICooperativeRepository? coopRepo,
  })  : _settingsService = settingsService ?? SettingsService(),
        _coopRepo = coopRepo ?? CooperativeRepository();

  /// Initialiser les paramètres par défaut pour une nouvelle coopérative
  Future<void> initializeDefaultSettings({
    required String cooperativeId,
    required int userId,
  }) async {
    // Paramètres financiers
    await _settingsService.saveSetting(
      cooperativeId: cooperativeId,
      category: 'finance',
      key: 'commission_rate',
      value: 0.05,
      valueType: SettingValueType.double,
      userId: userId,
    );

    // Paramètres de vente
    await _settingsService.saveSetting(
      cooperativeId: cooperativeId,
      category: 'vente',
      key: 'validation_double',
      value: true,
      valueType: SettingValueType.bool,
      userId: userId,
    );

    await _settingsService.saveSetting(
      cooperativeId: cooperativeId,
      category: 'vente',
      key: 'seuil_validation_double',
      value: 100000,
      valueType: SettingValueType.double,
      userId: userId,
    );

    // Paramètres de stock
    await _settingsService.saveSetting(
      cooperativeId: cooperativeId,
      category: 'stock',
      key: 'seuil_alerte',
      value: 100,
      valueType: SettingValueType.double,
      userId: userId,
    );
  }

  /// Vérifier que tous les paramètres obligatoires sont configurés
  Future<bool> validateRequiredSettings({
    required String cooperativeId,
  }) async {
    final requiredSettings = [
      {'category': 'finance', 'key': 'commission_rate'},
      {'category': 'accounting', 'key': 'exercice_actif'},
      {'category': 'accounting', 'key': 'plan_comptable'},
    ];

    for (final req in requiredSettings) {
      final setting = await _settingsService.getSetting(
        cooperativeId: cooperativeId,
        category: req['category']!,
        key: req['key']!,
      );

      if (setting == null) {
        return false;
      }
    }

    return true;
  }
}

