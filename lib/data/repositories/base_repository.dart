import '../../services/api/api_client.dart';
import '../../services/integration/sync_service.dart';
import '../../services/integration/error_handler.dart';
import '../../data/dto/api_response.dart';
import '../../config/app_config.dart';

/// Repository de base avec gestion offline et synchronisation
abstract class BaseRepository<T> {
  final ApiClient _apiClient = ApiClient();
  final SyncService _syncService = SyncService();

  /// Obtenir un élément par ID depuis l'API
  Future<T?> getById(int id, String endpoint);

  /// Obtenir tous les éléments depuis l'API
  Future<List<T>> getAll(String endpoint, {Map<String, dynamic>? queryParams});

  /// Créer un élément via l'API
  Future<T> create(Map<String, dynamic> data, String endpoint);

  /// Mettre à jour un élément via l'API
  Future<T> update(int id, Map<String, dynamic> data, String endpoint);

  /// Supprimer un élément via l'API
  Future<void> delete(int id, String endpoint);

  /// Convertir un Map en modèle T
  T fromMap(Map<String, dynamic> map);

  /// Convertir un modèle T en Map
  Map<String, dynamic> toMap(T model);

  /// Créer avec gestion offline
  Future<T> createWithOfflineSupport({
    required Map<String, dynamic> data,
    required String endpoint,
    required String module,
    Map<String, dynamic>? localId,
  }) async {
    if (AppConfig.useApi) {
      try {
        final response = await _apiClient.post(endpoint, data);
        final apiResponse = ApiResponse.fromJson(response, (json) => fromMap(json as Map<String, dynamic>));
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw ApiException(apiResponse.error?.message ?? 'Erreur lors de la création');
        }
      } catch (e) {
        // En cas d'erreur réseau, ajouter à la queue offline
        if (ErrorHandler.isRetryable(ErrorHandler.handleException(e).code)) {
          await _syncService.addToQueue(
            action: 'create',
            module: module,
            endpoint: endpoint,
            data: data,
            localId: localId,
          );
          // Retourner un modèle temporaire avec ID local
          return fromMap({...data, 'id': localId?['id'] ?? -1, 'is_synced': false});
        }
        rethrow;
      }
    } else {
      // Mode local uniquement
      return fromMap({...data, 'id': localId?['id'] ?? -1, 'is_synced': false});
    }
  }

  /// Mettre à jour avec gestion offline
  Future<T> updateWithOfflineSupport({
    required int id,
    required Map<String, dynamic> data,
    required String endpoint,
    required String module,
  }) async {
    if (AppConfig.useApi) {
      try {
        final response = await _apiClient.put(endpoint, data);
        final apiResponse = ApiResponse.fromJson(response, (json) => fromMap(json as Map<String, dynamic>));
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
          throw ApiException(apiResponse.error?.message ?? 'Erreur lors de la mise à jour');
        }
      } catch (e) {
        // En cas d'erreur réseau, ajouter à la queue offline
        if (ErrorHandler.isRetryable(ErrorHandler.handleException(e).code)) {
          await _syncService.addToQueue(
            action: 'update',
            module: module,
            endpoint: endpoint,
            data: {...data, 'id': id},
          );
          // Retourner le modèle mis à jour localement
          return fromMap({...data, 'id': id, 'is_synced': false});
        }
        rethrow;
      }
    } else {
      // Mode local uniquement
      return fromMap({...data, 'id': id, 'is_synced': false});
    }
  }

  /// Supprimer avec gestion offline
  Future<void> deleteWithOfflineSupport({
    required int id,
    required String endpoint,
    required String module,
  }) async {
    if (AppConfig.useApi) {
      try {
        await _apiClient.delete(endpoint);
      } catch (e) {
        // En cas d'erreur réseau, ajouter à la queue offline
        if (ErrorHandler.isRetryable(ErrorHandler.handleException(e).code)) {
          await _syncService.addToQueue(
            action: 'delete',
            module: module,
            endpoint: endpoint,
            data: {'id': id},
          );
        }
        rethrow;
      }
    }
    // En mode local, la suppression est gérée par le service local
  }

  /// Obtenir avec gestion d'erreurs normalisée
  Future<List<T>> getAllWithErrorHandling(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _apiClient.getList(endpoint, queryParams: queryParams);
      return response.map((json) => fromMap(json as Map<String, dynamic>)).toList();
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      throw ApiException(
        ErrorHandler.getUserFriendlyMessage(error.code),
        statusCode: error.statusCode,
      );
    }
  }

  /// Obtenir par ID avec gestion d'erreurs normalisée
  Future<T?> getByIdWithErrorHandling(int id, String endpoint) async {
    try {
      final response = await _apiClient.get('$endpoint/$id');
      if (response.isEmpty) return null;
      return fromMap(response);
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      final error = ErrorHandler.handleException(e);
      throw ApiException(
        ErrorHandler.getUserFriendlyMessage(error.code),
        statusCode: error.statusCode,
      );
    }
  }
}

