/// Service centralisé pour la gestion de tous les paramètres
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
import '../../data/models/backend/cooperative_model.dart';
import 'backend/settings_service.dart';
import 'repositories/cooperative_repository.dart';
import '../api/api_client.dart';
import '../../config/app_config.dart';
import 'parametres_service.dart';
import 'dart:convert';

class CentralSettingsService {
  final SettingsService _settingsService;
  final ApiClient _apiClient;

  CentralSettingsService({
    SettingsService? settingsService,
    ApiClient? apiClient,
  })  : _settingsService = settingsService ?? SettingsService(),
        _apiClient = apiClient ?? ApiClient();

  String? _currentCooperativeId;
  
  // Cache pour tous les paramètres chargés
  Map<String, Map<String, dynamic>>? _allSettingsCache;
  DateTime? _cacheTimestamp;
  static const _cacheValidityDuration = Duration(minutes: 5);

  /// Initialiser avec l'ID de la coopérative active
  Future<void> initialize(String? cooperativeId) async {
    if (cooperativeId != null) {
      _currentCooperativeId = cooperativeId;
    } else {
      // Essayer de récupérer la coopérative active depuis le repository
      try {
        final coopRepo = CooperativeRepository();
        final currentCoop = await coopRepo.getCurrent();
        _currentCooperativeId = currentCoop?.id;
      } catch (e) {
        print('Erreur lors de la récupération de la coopérative active: $e');
        _currentCooperativeId = null;
      }
    }
    // Invalider le cache lors de l'initialisation
    _allSettingsCache = null;
    _cacheTimestamp = null;
  }
  
  /// Charger TOUS les paramètres en une seule requête depuis la table settings
  /// Cette méthode centralise le chargement pour améliorer les performances
  Future<Map<String, Map<String, dynamic>>> loadAllSettingsUnified() async {
    try {
      // Vérifier le cache
      if (_allSettingsCache != null && 
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheValidityDuration) {
        print('📦 Utilisation du cache des paramètres');
        return _allSettingsCache!;
      }
      
      // S'assurer qu'on a un cooperativeId
      if (_currentCooperativeId == null) {
        final coopRepo = CooperativeRepository();
        final currentCoop = await coopRepo.getCurrent();
        _currentCooperativeId = currentCoop?.id;
      }
      
      print('🔄 Chargement unifié de tous les paramètres (cooperativeId: $_currentCooperativeId)');
      
      // Charger tous les paramètres en une seule requête
      final allSettings = await _settingsService.getAllSettings(
        cooperativeId: _currentCooperativeId,
      );
      
      // Organiser par catégorie
      final Map<String, Map<String, dynamic>> settingsByCategory = {};
      
      for (final setting in allSettings) {
        if (!settingsByCategory.containsKey(setting.category)) {
          settingsByCategory[setting.category] = {};
        }
        settingsByCategory[setting.category]![setting.key] = setting.getTypedValue();
      }
      
      // Mettre en cache
      _allSettingsCache = settingsByCategory;
      _cacheTimestamp = DateTime.now();
      
      print('✅ ${allSettings.length} paramètres chargés pour ${settingsByCategory.length} catégories');
      
      return settingsByCategory;
    } catch (e, stackTrace) {
      print('❌ Erreur lors du chargement unifié des paramètres: $e');
      print('Stack trace: $stackTrace');
      return {};
    }
  }
  
  /// Invalider le cache des paramètres
  void invalidateCache() {
    _allSettingsCache = null;
    _cacheTimestamp = null;
    print('🗑️ Cache des paramètres invalidé');
  }

  // ========== COOPÉRATIVE ==========

  Future<CooperativeSettingsModel> getCooperativeSettings() async {
    if (AppConfig.useApi) {
      try {
        final response = await _apiClient.get('/settings/cooperative');
        return CooperativeSettingsModel.fromMap(response);
      } catch (e) {
        // Fallback sur cache local
        return await _getCooperativeSettingsFromCache();
      }
    }
    return await _getCooperativeSettingsFromCache();
  }

  Future<CooperativeSettingsModel> _getCooperativeSettingsFromCache() async {
    try {
      // Utiliser le chargement unifié pour obtenir tous les paramètres
      final allSettings = await loadAllSettingsUnified();
      final cooperativeSettings = allSettings['cooperative'] ?? {};
      
      // Si aucun paramètre trouvé, essayer l'ancienne table coop_settings
      if (cooperativeSettings.isEmpty) {
        print('⚠️ Aucun paramètre trouvé dans la table settings, recherche dans coop_settings...');
        try {
          final parametresService = ParametresService();
          final oldParametres = await parametresService.getParametres();
          
          // Convertir l'ancien modèle vers le nouveau format
          final map = <String, dynamic>{
            'raison_sociale': oldParametres.nomCooperative,
            'logo_path': oldParametres.logoPath,
            'adresse': oldParametres.adresse,
            'telephone': oldParametres.telephone,
            'email': oldParametres.email,
          };
          
          print('✅ Paramètres trouvés dans coop_settings, conversion effectuée');
          return CooperativeSettingsModel.fromMap(map);
        } catch (e) {
          print('⚠️ Erreur lors de la récupération depuis coop_settings: $e');
        }
      }

      final map = <String, dynamic>{};
      for (final entry in cooperativeSettings.entries) {
        map[entry.key] = entry.value;
      }
      
      // Debug: afficher les clés trouvées
      if (map.isNotEmpty) {
        print('📋 Paramètres coopérative chargés: ${map.keys.join(", ")}');
      } else {
        print('⚠️ Aucun paramètre coopérative trouvé dans la base de données');
      }

      // Si la map est vide, retourner des valeurs par défaut
      if (map.isEmpty) {
        print('📝 Retour des valeurs par défaut');
        return CooperativeSettingsModel(
          raisonSociale: 'Coopérative de Cacaoculteurs',
          devise: 'XAF',
          langue: 'FR',
        );
      }

      return CooperativeSettingsModel.fromMap(map);
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la récupération des paramètres coopérative: $e');
      print('Stack trace: $stackTrace');
      // Retourner un modèle avec des valeurs par défaut
      return CooperativeSettingsModel(
        raisonSociale: 'Coopérative de Cacaoculteurs',
        devise: 'XAF',
        langue: 'FR',
      );
    }
  }

  Future<void> saveCooperativeSettings(
    CooperativeSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();
    map.remove('id');
    map.remove('updated_at');
    map.remove('updated_by');

    if (AppConfig.useApi) {
      try {
        await _apiClient.put('/settings/cooperative', {
          ...map,
          'updated_by': userId,
          'reason': reason,
        });
      } catch (e) {
        // Fallback sur cache local
        await _saveCooperativeSettingsToCache(settings, userId, reason: reason);
      }
    } else {
      await _saveCooperativeSettingsToCache(settings, userId, reason: reason);
    }
  }

  Future<void> _saveCooperativeSettingsToCache(
    CooperativeSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    // S'assurer qu'on a un cooperativeId avant de sauvegarder
    if (_currentCooperativeId == null) {
      final coopRepo = CooperativeRepository();
      final currentCoop = await coopRepo.getCurrent();
      _currentCooperativeId = currentCoop?.id;
      
      if (_currentCooperativeId == null) {
        print('⚠️ Aucune coopérative active, création d\'une coopérative par défaut...');
        // Créer une coopérative par défaut si aucune n'existe
        try {
          final defaultCoop = CooperativeModel(
            id: 'coop-default-${DateTime.now().millisecondsSinceEpoch}',
            raisonSociale: settings.raisonSociale,
            sigle: settings.sigle,
            formeJuridique: settings.formeJuridique,
            numeroAgrement: settings.numeroAgrement,
            rccm: settings.rccm,
            dateCreation: settings.dateCreation,
            adresse: settings.adresse,
            region: settings.region,
            departement: settings.departement,
            telephone: settings.telephone,
            email: settings.email,
            devise: settings.devise,
            langue: settings.langue,
            logo: settings.logoPath,
            statut: CooperativeStatut.active,
          );
          await coopRepo.create(defaultCoop);
          _currentCooperativeId = defaultCoop.id;
          print('✅ Coopérative par défaut créée: $_currentCooperativeId');
        } catch (e) {
          print('❌ Erreur lors de la création de la coopérative par défaut: $e');
          throw Exception('Impossible de sauvegarder: aucune coopérative active et impossible d\'en créer une');
        }
      }
    }
    
    final map = settings.toMap();
    print('💾 Sauvegarde des paramètres coopérative (cooperativeId: $_currentCooperativeId): ${map.keys.join(", ")}');
    
    for (final entry in map.entries) {
      if (entry.value != null) {
        try {
          await _settingsService.saveSetting(
            cooperativeId: _currentCooperativeId,
            category: 'cooperative',
            key: entry.key,
            value: entry.value,
            userId: userId,
            reason: reason,
          );
          print('✅ Paramètre sauvegardé: ${entry.key} = ${entry.value}');
        } catch (e) {
          print('❌ Erreur lors de la sauvegarde de ${entry.key}: $e');
          rethrow; // Relancer l'erreur pour que l'utilisateur soit informé
        }
      }
    }
    print('✅ Tous les paramètres coopérative ont été sauvegardés');
  }

  // ========== GÉNÉRAL ==========

  Future<GeneralSettingsModel> getGeneralSettings() async {
    if (AppConfig.useApi) {
      try {
        final response = await _apiClient.get('/settings/general');
        return GeneralSettingsModel.fromMap(response);
      } catch (e) {
        return await _getGeneralSettingsFromCache();
      }
    }
    return await _getGeneralSettingsFromCache();
  }

  Future<GeneralSettingsModel> _getGeneralSettingsFromCache() async {
    final settings = await _settingsService.getSettingsByCategory(
      cooperativeId: _currentCooperativeId,
      category: 'general',
    );

    final map = <String, dynamic>{};
    for (final setting in settings) {
      map[setting.key] = setting.getTypedValue();
    }

    return GeneralSettingsModel.fromMap(map);
  }

  Future<void> saveGeneralSettings(
    GeneralSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();

    if (AppConfig.useApi) {
      try {
        await _apiClient.put('/settings/general', {
          ...map,
          'updated_by': userId,
          'reason': reason,
        });
      } catch (e) {
        await _saveGeneralSettingsToCache(settings, userId, reason: reason);
      }
    } else {
      await _saveGeneralSettingsToCache(settings, userId, reason: reason);
    }
  }

  Future<void> _saveGeneralSettingsToCache(
    GeneralSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();
    for (final entry in map.entries) {
      await _settingsService.saveSetting(
        cooperativeId: _currentCooperativeId,
        category: 'general',
        key: entry.key,
        value: entry.value,
        userId: userId,
        reason: reason,
      );
    }
  }

  // ========== CAPITAL ==========

  Future<CapitalSettingsModel> getCapitalSettings() async {
    if (AppConfig.useApi) {
      try {
        final response = await _apiClient.get('/settings/capital');
        return CapitalSettingsModel.fromMap(response);
      } catch (e) {
        return await _getCapitalSettingsFromCache();
      }
    }
    return await _getCapitalSettingsFromCache();
  }

  Future<CapitalSettingsModel> _getCapitalSettingsFromCache() async {
    final settings = await _settingsService.getSettingsByCategory(
      cooperativeId: _currentCooperativeId,
      category: 'capital',
    );

    final map = <String, dynamic>{};
    for (final setting in settings) {
      map[setting.key] = setting.getTypedValue();
    }

    return CapitalSettingsModel.fromMap(map);
  }

  Future<void> saveCapitalSettings(
    CapitalSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();

    if (AppConfig.useApi) {
      try {
        await _apiClient.put('/settings/capital', {
          ...map,
          'updated_by': userId,
          'reason': reason,
        });
      } catch (e) {
        await _saveCapitalSettingsToCache(settings, userId, reason: reason);
      }
    } else {
      await _saveCapitalSettingsToCache(settings, userId, reason: reason);
    }
  }

  Future<void> _saveCapitalSettingsToCache(
    CapitalSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();
    for (final entry in map.entries) {
      if (entry.value != null) {
        await _settingsService.saveSetting(
          cooperativeId: _currentCooperativeId,
          category: 'capital',
          key: entry.key,
          value: entry.value,
          userId: userId,
          reason: reason,
        );
      }
    }
  }

  // ========== COMPTABILITÉ ==========

  Future<AccountingSettingsModel> getAccountingSettings() async {
    if (AppConfig.useApi) {
      try {
        final response = await _apiClient.get('/settings/accounting');
        return AccountingSettingsModel.fromMap(response);
      } catch (e) {
        return await _getAccountingSettingsFromCache();
      }
    }
    return await _getAccountingSettingsFromCache();
  }

  Future<AccountingSettingsModel> _getAccountingSettingsFromCache() async {
    final settings = await _settingsService.getSettingsByCategory(
      cooperativeId: _currentCooperativeId,
      category: 'accounting',
    );

    final map = <String, dynamic>{};
    for (final setting in settings) {
      map[setting.key] = setting.getTypedValue();
    }

    return AccountingSettingsModel.fromMap(map);
  }

  Future<void> saveAccountingSettings(
    AccountingSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();

    if (AppConfig.useApi) {
      try {
        await _apiClient.put('/settings/accounting', {
          ...map,
          'updated_by': userId,
          'reason': reason,
        });
      } catch (e) {
        await _saveAccountingSettingsToCache(settings, userId, reason: reason);
      }
    } else {
      await _saveAccountingSettingsToCache(settings, userId, reason: reason);
    }
  }

  Future<void> _saveAccountingSettingsToCache(
    AccountingSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();
    for (final entry in map.entries) {
      if (entry.value != null) {
        await _settingsService.saveSetting(
          cooperativeId: _currentCooperativeId,
          category: 'accounting',
          key: entry.key,
          value: entry.value,
          userId: userId,
          reason: reason,
        );
      }
    }
  }

  // ========== VENTES ==========

  Future<SalesSettingsModel> getSalesSettings() async {
    if (AppConfig.useApi) {
      try {
        final response = await _apiClient.get('/settings/sales');
        return SalesSettingsModel.fromMap(response);
      } catch (e) {
        return await _getSalesSettingsFromCache();
      }
    }
    return await _getSalesSettingsFromCache();
  }

  Future<SalesSettingsModel> _getSalesSettingsFromCache() async {
    final settings = await _settingsService.getSettingsByCategory(
      cooperativeId: _currentCooperativeId,
      category: 'sales',
    );

    final map = <String, dynamic>{};
    for (final setting in settings) {
      if (setting.key == 'retenues_automatiques') {
        if (setting.value != null) {
          map[setting.key] = json.decode(setting.value!);
        }
      } else {
        map[setting.key] = setting.getTypedValue();
      }
    }

    return SalesSettingsModel.fromMap(map);
  }

  Future<void> saveSalesSettings(
    SalesSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();
    map['retenues_automatiques'] = json.encode(settings.retenuesAutomatiques);

    if (AppConfig.useApi) {
      try {
        await _apiClient.put('/settings/sales', {
          ...map,
          'updated_by': userId,
          'reason': reason,
        });
      } catch (e) {
        await _saveSalesSettingsToCache(settings, userId, reason: reason);
      }
    } else {
      await _saveSalesSettingsToCache(settings, userId, reason: reason);
    }
  }

  Future<void> _saveSalesSettingsToCache(
    SalesSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();
    for (final entry in map.entries) {
      dynamic value = entry.value;
      if (entry.key == 'retenues_automatiques') {
        value = json.encode(value);
      }
      await _settingsService.saveSetting(
        cooperativeId: _currentCooperativeId,
        category: 'sales',
        key: entry.key,
        value: value,
        userId: userId,
        reason: reason,
      );
    }
  }

  // ========== RECETTES ==========

  Future<ReceiptSettingsModel> getReceiptSettings() async {
    if (AppConfig.useApi) {
      try {
        final response = await _apiClient.get('/settings/receipt');
        return ReceiptSettingsModel.fromMap(response);
      } catch (e) {
        return await _getReceiptSettingsFromCache();
      }
    }
    return await _getReceiptSettingsFromCache();
  }

  Future<ReceiptSettingsModel> _getReceiptSettingsFromCache() async {
    final settings = await _settingsService.getSettingsByCategory(
      cooperativeId: _currentCooperativeId,
      category: 'receipt',
    );

    final map = <String, dynamic>{};
    for (final setting in settings) {
      if (setting.key == 'types_commissions' || setting.key == 'ordre_calcul') {
        if (setting.value != null) {
          map[setting.key] = json.decode(setting.value!);
        }
      } else {
        map[setting.key] = setting.getTypedValue();
      }
    }

    return ReceiptSettingsModel.fromMap(map);
  }

  Future<void> saveReceiptSettings(
    ReceiptSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();

    if (AppConfig.useApi) {
      try {
        await _apiClient.put('/settings/receipt', {
          ...map,
          'updated_by': userId,
          'reason': reason,
        });
      } catch (e) {
        await _saveReceiptSettingsToCache(settings, userId, reason: reason);
      }
    } else {
      await _saveReceiptSettingsToCache(settings, userId, reason: reason);
    }
  }

  Future<void> _saveReceiptSettingsToCache(
    ReceiptSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();
    for (final entry in map.entries) {
      dynamic value = entry.value;
      if (entry.key == 'types_commissions' || entry.key == 'ordre_calcul') {
        value = json.encode(value);
      }
      await _settingsService.saveSetting(
        cooperativeId: _currentCooperativeId,
        category: 'receipt',
        key: entry.key,
        value: value,
        userId: userId,
        reason: reason,
      );
    }
  }

  // ========== DOCUMENTS ==========

  Future<DocumentSettingsModel> getDocumentSettings() async {
    if (AppConfig.useApi) {
      try {
        final response = await _apiClient.get('/settings/document');
        return DocumentSettingsModel.fromMap(response);
      } catch (e) {
        return await _getDocumentSettingsFromCache();
      }
    }
    return await _getDocumentSettingsFromCache();
  }

  Future<DocumentSettingsModel> _getDocumentSettingsFromCache() async {
    final settings = await _settingsService.getSettingsByCategory(
      cooperativeId: _currentCooperativeId,
      category: 'document',
    );

    final map = <String, dynamic>{};
    for (final setting in settings) {
      if (setting.key == 'types_documents') {
        if (setting.value != null) {
          map[setting.key] = json.decode(setting.value!);
        }
      } else {
        map[setting.key] = setting.getTypedValue();
      }
    }

    return DocumentSettingsModel.fromMap(map);
  }

  Future<void> saveDocumentSettings(
    DocumentSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();

    if (AppConfig.useApi) {
      try {
        await _apiClient.put('/settings/document', {
          ...map,
          'updated_by': userId,
          'reason': reason,
        });
      } catch (e) {
        await _saveDocumentSettingsToCache(settings, userId, reason: reason);
      }
    } else {
      await _saveDocumentSettingsToCache(settings, userId, reason: reason);
    }
  }

  Future<void> _saveDocumentSettingsToCache(
    DocumentSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();
    for (final entry in map.entries) {
      dynamic value = entry.value;
      if (entry.key == 'types_documents') {
        value = json.encode(value);
      }
      await _settingsService.saveSetting(
        cooperativeId: _currentCooperativeId,
        category: 'document',
        key: entry.key,
        value: value,
        userId: userId,
        reason: reason,
      );
    }
  }

  // ========== SOCIAL ==========

  Future<SocialSettingsModel> getSocialSettings() async {
    if (AppConfig.useApi) {
      try {
        final response = await _apiClient.get('/settings/social');
        return SocialSettingsModel.fromMap(response);
      } catch (e) {
        return await _getSocialSettingsFromCache();
      }
    }
    return await _getSocialSettingsFromCache();
  }

  Future<SocialSettingsModel> _getSocialSettingsFromCache() async {
    final settings = await _settingsService.getSettingsByCategory(
      cooperativeId: _currentCooperativeId,
      category: 'social',
    );

    final map = <String, dynamic>{};
    for (final setting in settings) {
      if (setting.key == 'types_aides') {
        if (setting.value != null) {
          map[setting.key] = json.decode(setting.value!);
        }
      } else {
        map[setting.key] = setting.getTypedValue();
      }
    }

    return SocialSettingsModel.fromMap(map);
  }

  Future<void> saveSocialSettings(
    SocialSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();

    if (AppConfig.useApi) {
      try {
        await _apiClient.put('/settings/social', {
          ...map,
          'updated_by': userId,
          'reason': reason,
        });
      } catch (e) {
        await _saveSocialSettingsToCache(settings, userId, reason: reason);
      }
    } else {
      await _saveSocialSettingsToCache(settings, userId, reason: reason);
    }
  }

  Future<void> _saveSocialSettingsToCache(
    SocialSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();
    for (final entry in map.entries) {
      dynamic value = entry.value;
      if (entry.key == 'types_aides') {
        value = json.encode(value);
      }
      await _settingsService.saveSetting(
        cooperativeId: _currentCooperativeId,
        category: 'social',
        key: entry.key,
        value: value,
        userId: userId,
        reason: reason,
      );
    }
  }

  // ========== MODULES ==========

  Future<ModuleSettingsModel> getModuleSettings() async {
    if (AppConfig.useApi) {
      try {
        final response = await _apiClient.get('/settings/module');
        return ModuleSettingsModel.fromMap(response);
      } catch (e) {
        return await _getModuleSettingsFromCache();
      }
    }
    return await _getModuleSettingsFromCache();
  }

  Future<ModuleSettingsModel> _getModuleSettingsFromCache() async {
    final settings = await _settingsService.getSettingsByCategory(
      cooperativeId: _currentCooperativeId,
      category: 'module',
    );

    final map = <String, dynamic>{};
    for (final setting in settings) {
      if (setting.key == 'modules_actives' || setting.key == 'ip_autorisees') {
        if (setting.value != null) {
          map[setting.key] = json.decode(setting.value!);
        }
      } else {
        map[setting.key] = setting.getTypedValue();
      }
    }

    return ModuleSettingsModel.fromMap(map);
  }

  Future<void> saveModuleSettings(
    ModuleSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();

    if (AppConfig.useApi) {
      try {
        await _apiClient.put('/settings/module', {
          ...map,
          'updated_by': userId,
          'reason': reason,
        });
      } catch (e) {
        await _saveModuleSettingsToCache(settings, userId, reason: reason);
      }
    } else {
      await _saveModuleSettingsToCache(settings, userId, reason: reason);
    }
  }

  Future<void> _saveModuleSettingsToCache(
    ModuleSettingsModel settings,
    int userId, {
    String? reason,
  }) async {
    final map = settings.toMap();
    for (final entry in map.entries) {
      dynamic value = entry.value;
      if (entry.key == 'modules_actives' || entry.key == 'ip_autorisees') {
        value = json.encode(value);
      }
      await _settingsService.saveSetting(
        cooperativeId: _currentCooperativeId,
        category: 'module',
        key: entry.key,
        value: value,
        userId: userId,
        reason: reason,
      );
    }
  }

  // ========== HISTORIQUE ==========

  Future<List<SettingHistoryModel>> getSettingHistory({
    String? category,
    String? key,
    int? limit,
  }) async {
    if (AppConfig.useApi) {
      try {
        final queryParams = <String, dynamic>{};
        if (category != null) queryParams['category'] = category;
        if (key != null) queryParams['key'] = key;
        if (limit != null) queryParams['limit'] = limit;

        final response = await _apiClient.getList('/settings/history', queryParams: queryParams);
        return response.map((e) => SettingHistoryModel.fromMap(e as Map<String, dynamic>)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }
}

