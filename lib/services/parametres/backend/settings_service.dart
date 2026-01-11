/// Service backend pour la gestion des settings avec règles métier
import '../../../data/models/backend/setting_model.dart';
import '../repositories/setting_repository.dart';
import '../repositories/cooperative_repository.dart';
import '../../auth/audit_service.dart';

class SettingsService {
  final ISettingRepository _repository;
  final ICooperativeRepository _cooperativeRepository;
  final AuditService _auditService;

  SettingsService({
    ISettingRepository? repository,
    ICooperativeRepository? cooperativeRepository,
    AuditService? auditService,
  })  : _repository = repository ?? SettingRepository(),
        _cooperativeRepository = cooperativeRepository ?? CooperativeRepository(),
        _auditService = auditService ?? AuditService();

  /// Obtenir un setting par catégorie et clé
  Future<SettingModel?> getSetting({
    String? cooperativeId,
    required String category,
    required String key,
  }) async {
    // Si cooperativeId n'est pas fourni, utiliser la coopérative active
    final coopId = cooperativeId ?? (await _cooperativeRepository.getCurrent())?.id;
    
    // Chercher d'abord dans les settings de la coopérative, puis dans les globaux
    SettingModel? setting = await _repository.getByKey(coopId, category, key);
    if (setting == null && coopId != null) {
      setting = await _repository.getByKey(null, category, key);
    }
    
    return setting;
  }

  /// Obtenir TOUS les settings en une seule requête (pour chargement centralisé)
  Future<List<SettingModel>> getAllSettings({
    String? cooperativeId,
  }) async {
    try {
      final coopId = cooperativeId ?? (await _cooperativeRepository.getCurrent())?.id;
      
      // Récupérer tous les settings de la coopérative et les globaux
      final coopSettings = coopId != null 
          ? await _repository.getAll(coopId)
          : <SettingModel>[];
      final globalSettings = await _repository.getAll(null);
      
      // Fusionner en donnant priorité aux settings de la coopérative
      final Map<String, SettingModel> merged = {};
      for (final setting in globalSettings) {
        if (setting.isActive) {
          final key = '${setting.category}.${setting.key}';
          merged[key] = setting;
        }
      }
      for (final setting in coopSettings) {
        if (setting.isActive) {
          final key = '${setting.category}.${setting.key}';
          merged[key] = setting;
        }
      }
      
      return merged.values.toList();
    } catch (e) {
      // Si la table n'existe pas, retourner une liste vide sans faire planter l'application
      if (e.toString().contains('n\'existe pas')) {
        print('⚠️ Table settings n\'existe pas encore');
        return [];
      }
      print('⚠️ Erreur lors de la récupération de tous les settings: $e');
      return [];
    }
  }

  /// Obtenir tous les settings d'une catégorie avec gestion robuste des erreurs
  Future<List<SettingModel>> getSettingsByCategory({
    String? cooperativeId,
    required String category,
  }) async {
    try {
      final coopId = cooperativeId ?? (await _cooperativeRepository.getCurrent())?.id;
      
      // Récupérer les settings de la coopérative et les globaux
      final coopSettings = coopId != null 
          ? await _repository.getByCategory(coopId, category)
          : <SettingModel>[];
      final globalSettings = await _repository.getByCategory(null, category);
      
      // Fusionner en donnant priorité aux settings de la coopérative
      final Map<String, SettingModel> merged = {};
      for (final setting in globalSettings) {
        if (setting.isActive) {
          merged[setting.key] = setting;
        }
      }
      for (final setting in coopSettings) {
        if (setting.isActive) {
          merged[setting.key] = setting;
        }
      }
      
      return merged.values.toList()..sort((a, b) => a.key.compareTo(b.key));
    } catch (e) {
      // Si la table n'existe pas, retourner une liste vide sans faire planter l'application
      if (e.toString().contains('n\'existe pas')) {
        print('⚠️ Table settings n\'existe pas encore');
        return [];
      }
      print('⚠️ Erreur lors de la récupération des settings de la catégorie $category: $e');
      return [];
    }
  }

  /// Obtenir une valeur typée avec valeur par défaut si absente
  Future<T?> getValue<T>({
    String? cooperativeId,
    required String category,
    required String key,
    T? defaultValue,
  }) async {
    try {
      final setting = await getSetting(
        cooperativeId: cooperativeId,
        category: category,
        key: key,
      );
      
      if (setting == null || !setting.isActive) {
        return defaultValue;
      }
      
      final typedValue = setting.getTypedValue();
      if (typedValue is T) return typedValue;
      return defaultValue;
    } catch (e) {
      print('⚠️ Erreur lors de la récupération de la valeur $category.$key: $e');
      return defaultValue;
    }
  }

  /// Créer ou mettre à jour un setting
  Future<SettingModel> saveSetting({
    String? cooperativeId,
    required String category,
    required String key,
    required dynamic value,
    SettingValueType valueType = SettingValueType.string,
    bool editable = true,
    required int userId,
    String? reason,
  }) async {
    final coopId = cooperativeId ?? (await _cooperativeRepository.getCurrent())?.id;
    
    if (coopId == null) {
      throw Exception('Aucune coopérative active. Activez d\'abord une coopérative.');
    }
    
    final valueString = SettingModel.valueToString(value, valueType);
    final existing = await _repository.getByKey(coopId, category, key);
    
    SettingModel setting;
    if (existing != null) {
      // Mise à jour
      setting = await _repository.update(
        existing.copyWith(
          value: valueString,
          valueType: valueType,
          updatedAt: DateTime.now(),
        ),
      );
      
      await _auditService.logAction(
        userId: userId,
        action: 'UPDATE_SETTING',
        entityType: 'settings',
        entityId: null, // setting.id est String, pas int
        details: 'Mise à jour: $category.$key = $valueString (ID: ${setting.id})',
      );
    } else {
      // Création
      setting = SettingModel(
        cooperativeId: coopId,
        category: category,
        key: key,
        value: valueString,
        valueType: valueType,
        editable: editable,
      );
      
      setting = await _repository.create(setting);
      
      await _auditService.logAction(
        userId: userId,
        action: 'CREATE_SETTING',
        entityType: 'settings',
        entityId: null, // setting.id est String, pas int
        details: 'Création: $category.$key = $valueString (ID: ${setting.id})',
      );
    }
    
    // Logger l'historique
    if (existing != null) {
      await _repository.logHistory(
        setting.id,
        coopId,
        existing.value,
        valueString,
        userId.toString(),
        reason,
      );
    }
    
    return setting;
  }

  /// Supprimer un setting
  Future<bool> deleteSetting({
    String? cooperativeId,
    required String category,
    required String key,
    required int userId,
  }) async {
    final coopId = cooperativeId ?? (await _cooperativeRepository.getCurrent())?.id;
    
    if (coopId == null) {
      throw Exception('Aucune coopérative active');
    }
    
    final setting = await _repository.getByKey(coopId, category, key);
    if (setting == null) return false;
    
    // Vérifier que le setting n'est pas utilisé (règle métier)
    if (!await _canDeleteSetting(setting)) {
      throw Exception('Ce paramètre est utilisé et ne peut pas être supprimé');
    }
    
    final deleted = await _repository.delete(setting.id);
    
    if (deleted) {
      await _auditService.logAction(
        userId: userId,
        action: 'DELETE_SETTING',
        entityType: 'settings',
        entityId: null, // setting.id est String, pas int
        details: 'Suppression: $category.$key (ID: ${setting.id})',
      );
    }
    
    return deleted;
  }

  /// Vérifier si un setting peut être supprimé (règle métier)
  Future<bool> _canDeleteSetting(SettingModel setting) async {
    // Liste des settings critiques qui ne peuvent pas être supprimés
    const criticalSettings = [
      'finance.commission_rate',
      'accounting.exercice_actif',
      'accounting.plan_comptable',
      'document.prefix_facture',
      'document.prefix_recu',
    ];
    
    final fullKey = '${setting.category}.${setting.key}';
    if (criticalSettings.contains(fullKey)) {
      return false;
    }
    
    // Vérifier si le setting est utilisé dans d'autres modules
    // (à implémenter selon les besoins)
    
    return true;
  }

  /// Obtenir tous les settings d'une coopérative
  Future<Map<String, dynamic>> getAllSettingsAsMap({
    String? cooperativeId,
  }) async {
    final coopId = cooperativeId ?? (await _cooperativeRepository.getCurrent())?.id;
    if (coopId == null) return {};
    
    final settings = await _repository.getAll(coopId);
    final Map<String, dynamic> result = {};
    
    for (final setting in settings) {
      if (!result.containsKey(setting.category)) {
        result[setting.category] = {};
      }
      result[setting.category][setting.key] = setting.getTypedValue();
    }
    
    return result;
  }
}

