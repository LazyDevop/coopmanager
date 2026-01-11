import '../models/adherent_model.dart';
import 'base_repository.dart';
import '../../services/api/api_client.dart';
import '../../services/api/api_exception.dart';
import '../../data/dto/api_response.dart';
import '../../services/integration/error_handler.dart';

/// Repository pour les adhérents avec intégration backend
class AdherentRepository extends BaseRepository<AdherentModel> {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<AdherentModel?> getById(int id, String endpoint) async {
    return getByIdWithErrorHandling(id, '/api/v1/adherents');
  }

  @override
  Future<List<AdherentModel>> getAll(String endpoint, {Map<String, dynamic>? queryParams}) async {
    return getAllWithErrorHandling('/api/v1/adherents', queryParams: queryParams);
  }

  @override
  Future<AdherentModel> create(Map<String, dynamic> data, String endpoint) async {
    try {
      final response = await _apiClient.post('/api/v1/adherents', data);
      final apiResponse = ApiResponse.fromJson(
        response,
        (json) => AdherentModel.fromMap(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.error?.message ?? 'Erreur lors de la création de l\'adhérent');
      }
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      throw ApiException(
        ErrorHandler.getUserFriendlyMessage(error.code, defaultMessage: error.message),
        statusCode: error.statusCode,
      );
    }
  }

  @override
  Future<AdherentModel> update(int id, Map<String, dynamic> data, String endpoint) async {
    try {
      final response = await _apiClient.put('/api/v1/adherents/$id', data);
      final apiResponse = ApiResponse.fromJson(
        response,
        (json) => AdherentModel.fromMap(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.error?.message ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      throw ApiException(
        ErrorHandler.getUserFriendlyMessage(error.code, defaultMessage: error.message),
        statusCode: error.statusCode,
      );
    }
  }

  @override
  Future<void> delete(int id, String endpoint) async {
    try {
      await _apiClient.delete('/api/v1/adherents/$id');
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      throw ApiException(
        ErrorHandler.getUserFriendlyMessage(error.code, defaultMessage: error.message),
        statusCode: error.statusCode,
      );
    }
  }

  @override
  AdherentModel fromMap(Map<String, dynamic> map) {
    return AdherentModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(AdherentModel model) {
    return model.toMap();
  }

  // ========== MÉTHODES SPÉCIFIQUES AUX ADHÉRENTS ==========

  /// Obtenir les adhérents actifs
  Future<List<AdherentModel>> getActiveAdherents() async {
    return getAllWithErrorHandling(
      '/api/v1/adherents',
      queryParams: {'is_active': true},
    );
  }

  /// Obtenir les adhérents par catégorie
  Future<List<AdherentModel>> getAdherentsByCategorie(String categorie) async {
    return getAllWithErrorHandling(
      '/api/v1/adherents',
      queryParams: {'categorie': categorie},
    );
  }

  /// Obtenir les adhérents par statut
  Future<List<AdherentModel>> getAdherentsByStatut(String statut) async {
    return getAllWithErrorHandling(
      '/api/v1/adherents',
      queryParams: {'statut': statut},
    );
  }

  /// Rechercher des adhérents
  Future<List<AdherentModel>> searchAdherents(String query) async {
    try {
      final response = await _apiClient.getList(
        '/api/v1/adherents/search',
        queryParams: {'q': query},
      );
      return response
          .map((json) => AdherentModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtenir le stock disponible d'un adhérent
  Future<double> getStockDisponible(int adherentId) async {
    try {
      final response = await _apiClient.get('/api/v1/adherents/$adherentId/stock');
      final apiResponse = ApiResponse.fromJson(response, null);
      if (apiResponse.success && apiResponse.data != null) {
        return (apiResponse.data as Map<String, dynamic>)['stock_disponible'] as double? ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Vérifier si un adhérent peut vendre
  Future<bool> canAdherentSell(int adherentId) async {
    try {
      final response = await _apiClient.get('/api/v1/adherents/$adherentId/can-sell');
      final apiResponse = ApiResponse.fromJson(response, null);
      if (apiResponse.success && apiResponse.data != null) {
        return (apiResponse.data as Map<String, dynamic>)['can_sell'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Mettre à jour le statut d'un adhérent (avec historique automatique backend)
  Future<AdherentModel> updateStatut({
    required int adherentId,
    required String statut,
    String? raison,
    required int updatedBy,
  }) async {
    try {
      final data = {
        'statut': statut,
        'raison': raison,
        'updated_by': updatedBy,
      };

      final response = await _apiClient.put('/api/v1/adherents/$adherentId/statut', data);
      final apiResponse = ApiResponse.fromJson(
        response,
        (json) => AdherentModel.fromMap(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.error?.message ?? 'Erreur lors de la mise à jour du statut');
      }
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      throw ApiException(
        ErrorHandler.getUserFriendlyMessage(error.code, defaultMessage: error.message),
        statusCode: error.statusCode,
      );
    }
  }
}

