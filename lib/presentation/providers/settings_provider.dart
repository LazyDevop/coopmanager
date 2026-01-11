import 'package:flutter/foundation.dart';
import '../../data/models/settings/cooperative_settings_model.dart';
import '../../data/models/settings/general_settings_model.dart';
import '../../data/models/settings/capital_settings_model.dart';
import '../../data/models/settings/accounting_settings_model.dart';
import '../../data/models/settings/sales_settings_model.dart';
import '../../data/models/settings/receipt_settings_model.dart';
import '../../data/models/settings/document_settings_model.dart';
import '../../data/models/settings/social_settings_model.dart';
import '../../data/models/settings/module_settings_model.dart';
import '../../data/models/settings/setting_history_model.dart';
import '../../services/parametres/central_settings_service.dart';

/// Provider centralisé pour la gestion de tous les paramètres
class SettingsProvider extends ChangeNotifier {
  final CentralSettingsService _settingsService = CentralSettingsService();

  // États des paramètres
  CooperativeSettingsModel? _cooperativeSettings;
  GeneralSettingsModel? _generalSettings;
  CapitalSettingsModel? _capitalSettings;
  AccountingSettingsModel? _accountingSettings;
  SalesSettingsModel? _salesSettings;
  ReceiptSettingsModel? _receiptSettings;
  DocumentSettingsModel? _documentSettings;
  SocialSettingsModel? _socialSettings;
  ModuleSettingsModel? _moduleSettings;

  // États de chargement
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, bool> _loadingCategories = {};

  // Getters
  CooperativeSettingsModel? get cooperativeSettings => _cooperativeSettings;
  GeneralSettingsModel? get generalSettings => _generalSettings;
  CapitalSettingsModel? get capitalSettings => _capitalSettings;
  AccountingSettingsModel? get accountingSettings => _accountingSettings;
  SalesSettingsModel? get salesSettings => _salesSettings;
  ReceiptSettingsModel? get receiptSettings => _receiptSettings;
  DocumentSettingsModel? get documentSettings => _documentSettings;
  SocialSettingsModel? get socialSettings => _socialSettings;
  ModuleSettingsModel? get moduleSettings => _moduleSettings;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool isCategoryLoading(String category) => _loadingCategories[category] ?? false;

  /// Initialiser le provider
  Future<void> initialize(String? cooperativeId) async {
    try {
      await _settingsService.initialize(cooperativeId);
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'initialisation: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Charger tous les paramètres
  Future<void> loadAllSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        loadCooperativeSettings(),
        loadGeneralSettings(),
        loadCapitalSettings(),
        loadAccountingSettings(),
        loadSalesSettings(),
        loadReceiptSettings(),
        loadDocumentSettings(),
        loadSocialSettings(),
        loadModuleSettings(),
      ]);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des paramètres: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les paramètres de la coopérative
  Future<void> loadCooperativeSettings() async {
    _loadingCategories['cooperative'] = true;
    notifyListeners();

    try {
      _cooperativeSettings = await _settingsService.getCooperativeSettings();
      _loadingCategories['cooperative'] = false;
      notifyListeners();
    } catch (e) {
      _loadingCategories['cooperative'] = false;
      _errorMessage = 'Erreur lors du chargement des paramètres coopérative: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Sauvegarder les paramètres de la coopérative
  Future<bool> saveCooperativeSettings(
    CooperativeSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _settingsService.saveCooperativeSettings(settings, userId, reason: reason);
      // Recharger les paramètres depuis la base de données pour s'assurer qu'ils sont bien sauvegardés
      await loadCooperativeSettings();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les paramètres généraux
  Future<void> loadGeneralSettings() async {
    _loadingCategories['general'] = true;
    notifyListeners();

    try {
      _generalSettings = await _settingsService.getGeneralSettings();
      _loadingCategories['general'] = false;
      notifyListeners();
    } catch (e) {
      _loadingCategories['general'] = false;
      _errorMessage = 'Erreur lors du chargement des paramètres généraux: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Sauvegarder les paramètres généraux
  Future<bool> saveGeneralSettings(
    GeneralSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _settingsService.saveGeneralSettings(settings, userId, reason: reason);
      _generalSettings = settings;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les paramètres du capital
  Future<void> loadCapitalSettings() async {
    _loadingCategories['capital'] = true;
    notifyListeners();

    try {
      _capitalSettings = await _settingsService.getCapitalSettings();
      _loadingCategories['capital'] = false;
      notifyListeners();
    } catch (e) {
      _loadingCategories['capital'] = false;
      _errorMessage = 'Erreur lors du chargement des paramètres capital: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Sauvegarder les paramètres du capital
  Future<bool> saveCapitalSettings(
    CapitalSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _settingsService.saveCapitalSettings(settings, userId, reason: reason);
      _capitalSettings = settings;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les paramètres de comptabilité
  Future<void> loadAccountingSettings() async {
    _loadingCategories['accounting'] = true;
    notifyListeners();

    try {
      _accountingSettings = await _settingsService.getAccountingSettings();
      _loadingCategories['accounting'] = false;
      notifyListeners();
    } catch (e) {
      _loadingCategories['accounting'] = false;
      _errorMessage = 'Erreur lors du chargement des paramètres comptabilité: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Sauvegarder les paramètres de comptabilité
  Future<bool> saveAccountingSettings(
    AccountingSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _settingsService.saveAccountingSettings(settings, userId, reason: reason);
      _accountingSettings = settings;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les paramètres de ventes
  Future<void> loadSalesSettings() async {
    _loadingCategories['sales'] = true;
    notifyListeners();

    try {
      _salesSettings = await _settingsService.getSalesSettings();
      _loadingCategories['sales'] = false;
      notifyListeners();
    } catch (e) {
      _loadingCategories['sales'] = false;
      _errorMessage = 'Erreur lors du chargement des paramètres ventes: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Sauvegarder les paramètres de ventes
  Future<bool> saveSalesSettings(
    SalesSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _settingsService.saveSalesSettings(settings, userId, reason: reason);
      _salesSettings = settings;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les paramètres de recettes
  Future<void> loadReceiptSettings() async {
    _loadingCategories['receipt'] = true;
    notifyListeners();

    try {
      _receiptSettings = await _settingsService.getReceiptSettings();
      _loadingCategories['receipt'] = false;
      notifyListeners();
    } catch (e) {
      _loadingCategories['receipt'] = false;
      _errorMessage = 'Erreur lors du chargement des paramètres recettes: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Sauvegarder les paramètres de recettes
  Future<bool> saveReceiptSettings(
    ReceiptSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _settingsService.saveReceiptSettings(settings, userId, reason: reason);
      _receiptSettings = settings;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les paramètres de documents
  Future<void> loadDocumentSettings() async {
    _loadingCategories['document'] = true;
    notifyListeners();

    try {
      _documentSettings = await _settingsService.getDocumentSettings();
      _loadingCategories['document'] = false;
      notifyListeners();
    } catch (e) {
      _loadingCategories['document'] = false;
      _errorMessage = 'Erreur lors du chargement des paramètres documents: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Sauvegarder les paramètres de documents
  Future<bool> saveDocumentSettings(
    DocumentSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _settingsService.saveDocumentSettings(settings, userId, reason: reason);
      _documentSettings = settings;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les paramètres sociaux
  Future<void> loadSocialSettings() async {
    _loadingCategories['social'] = true;
    notifyListeners();

    try {
      _socialSettings = await _settingsService.getSocialSettings();
      _loadingCategories['social'] = false;
      notifyListeners();
    } catch (e) {
      _loadingCategories['social'] = false;
      _errorMessage = 'Erreur lors du chargement des paramètres sociaux: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Sauvegarder les paramètres sociaux
  Future<bool> saveSocialSettings(
    SocialSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _settingsService.saveSocialSettings(settings, userId, reason: reason);
      _socialSettings = settings;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les paramètres de modules
  Future<void> loadModuleSettings() async {
    _loadingCategories['module'] = true;
    notifyListeners();

    try {
      _moduleSettings = await _settingsService.getModuleSettings();
      _loadingCategories['module'] = false;
      notifyListeners();
    } catch (e) {
      _loadingCategories['module'] = false;
      _errorMessage = 'Erreur lors du chargement des paramètres modules: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Sauvegarder les paramètres de modules
  Future<bool> saveModuleSettings(
    ModuleSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _settingsService.saveModuleSettings(settings, userId, reason: reason);
      _moduleSettings = settings;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtenir l'historique des modifications
  Future<List<SettingHistoryModel>> getSettingHistory({
    String? category,
    String? key,
    int? limit,
  }) async {
    try {
      return await _settingsService.getSettingHistory(
        category: category,
        key: key,
        limit: limit,
      );
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement de l\'historique: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  /// Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtenir une valeur de paramètre rapidement (helper)
  T? getValue<T>(String category, String key, T? defaultValue) {
    switch (category) {
      case 'cooperative':
        // Implémenter selon les besoins
        break;
      case 'general':
        // Implémenter selon les besoins
        break;
      // ... autres catégories
    }
    return defaultValue;
  }
}

