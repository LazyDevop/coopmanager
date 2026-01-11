import '../models/vente_model.dart';
import '../models/vente_detail_model.dart';
import 'base_repository.dart';
import '../../services/api/api_client.dart';
import '../../services/api/api_exception.dart';
import '../../data/dto/api_response.dart';
import '../../services/integration/error_handler.dart';

/// Repository pour les ventes avec intégration backend
class VenteRepository extends BaseRepository<VenteModel> {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<VenteModel?> getById(int id, String endpoint) async {
    return getByIdWithErrorHandling(id, '/api/v1/ventes');
  }

  @override
  Future<List<VenteModel>> getAll(String endpoint, {Map<String, dynamic>? queryParams}) async {
    return getAllWithErrorHandling('/api/v1/ventes', queryParams: queryParams);
  }

  @override
  Future<VenteModel> create(Map<String, dynamic> data, String endpoint) async {
    try {
      final response = await _apiClient.post('/api/v1/ventes', data);
      final apiResponse = ApiResponse.fromJson(
        response,
        (json) => VenteModel.fromMap(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.error?.message ?? 'Erreur lors de la création de la vente');
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
  Future<VenteModel> update(int id, Map<String, dynamic> data, String endpoint) async {
    try {
      final response = await _apiClient.put('/api/v1/ventes/$id', data);
      final apiResponse = ApiResponse.fromJson(
        response,
        (json) => VenteModel.fromMap(json as Map<String, dynamic>),
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
      await _apiClient.delete('/api/v1/ventes/$id');
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      throw ApiException(
        ErrorHandler.getUserFriendlyMessage(error.code, defaultMessage: error.message),
        statusCode: error.statusCode,
      );
    }
  }

  @override
  VenteModel fromMap(Map<String, dynamic> map) {
    return VenteModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(VenteModel model) {
    return model.toMap();
  }

  // ========== MÉTHODES SPÉCIFIQUES AUX VENTES ==========

  /// Créer une vente individuelle avec transaction backend
  Future<VenteModel> createVenteIndividuelle({
    required int clientId,
    required int campagneId,
    required int adherentId,
    required double quantiteTotal,
    required double prixUnitaire,
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
    bool overridePrixValidation = false,
  }) async {
    final data = {
      'client_id': clientId,
      'campagne_id': campagneId,
      'adherent_id': adherentId,
      'quantite_total': quantiteTotal,
      'prix_unitaire': prixUnitaire,
      'mode_paiement': modePaiement,
      'date_vente': dateVente.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'override_prix_validation': overridePrixValidation,
    };

    return await createWithOfflineSupport(
      data: data,
      endpoint: '/api/v1/ventes/individuelle',
      module: 'vente',
      localId: {'id': null, 'adherent_id': adherentId},
    );
  }

  /// Créer une vente groupée avec transaction backend
  Future<VenteModel> createVenteGroupee({
    required List<VenteDetailModel> details,
    required int clientId,
    required int campagneId,
    required double prixUnitaire,
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
    bool overridePrixValidation = false,
  }) async {
    final data = {
      'client_id': clientId,
      'campagne_id': campagneId,
      'details': details.map((d) => d.toMap()).toList(),
      'prix_unitaire': prixUnitaire,
      'mode_paiement': modePaiement,
      'date_vente': dateVente.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'override_prix_validation': overridePrixValidation,
    };

    return await createWithOfflineSupport(
      data: data,
      endpoint: '/api/v1/ventes/groupee',
      module: 'vente',
    );
  }

  /// Annuler une vente (transaction backend avec rollback si nécessaire)
  Future<bool> annulerVente({
    required int venteId,
    required int annulePar,
    String? raison,
  }) async {
    try {
      final data = {
        'annule_par': annulePar,
        'raison': raison,
      };

      await _apiClient.post('/api/v1/ventes/$venteId/annuler', data);
      return true;
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      throw ApiException(
        ErrorHandler.getUserFriendlyMessage(error.code, defaultMessage: error.message),
        statusCode: error.statusCode,
      );
    }
  }

  /// Obtenir les détails d'une vente groupée
  Future<List<VenteDetailModel>> getVenteDetails(int venteId) async {
    try {
      final response = await _apiClient.getList('/api/v1/ventes/$venteId/details');
      return response
          .map((json) => VenteDetailModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      throw ApiException(
        ErrorHandler.getUserFriendlyMessage(error.code, defaultMessage: error.message),
        statusCode: error.statusCode,
      );
    }
  }

  /// Simuler une vente (calcul côté backend)
  Future<Map<String, dynamic>> simulateVente({
    required int clientId,
    required int campagneId,
    int? adherentId,
    required double quantiteTotal,
    required double prixUnitaire,
  }) async {
    try {
      final data = {
        'client_id': clientId,
        'campagne_id': campagneId,
        if (adherentId != null) 'adherent_id': adherentId,
        'quantite_total': quantiteTotal,
        'prix_unitaire': prixUnitaire,
      };

      final response = await _apiClient.post('/api/v1/ventes/simulation', data);
      final apiResponse = ApiResponse.fromJson(response, null);

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data as Map<String, dynamic>;
      } else {
        throw ApiException(apiResponse.error?.message ?? 'Erreur lors de la simulation');
      }
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      throw ApiException(
        ErrorHandler.getUserFriendlyMessage(error.code, defaultMessage: error.message),
        statusCode: error.statusCode,
      );
    }
  }

  /// Obtenir les statistiques des ventes
  Future<Map<String, dynamic>> getStatistiques({
    DateTime? startDate,
    DateTime? endDate,
    int? adherentId,
    int? clientId,
    int? campagneId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (adherentId != null) queryParams['adherent_id'] = adherentId;
      if (clientId != null) queryParams['client_id'] = clientId;
      if (campagneId != null) queryParams['campagne_id'] = campagneId;

      final response = await _apiClient.get(
        '/api/v1/ventes/statistiques',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      final apiResponse = ApiResponse.fromJson(response, null);
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  /// Rechercher des ventes
  Future<List<VenteModel>> searchVentes(String query) async {
    try {
      final response = await _apiClient.getList(
        '/api/v1/ventes/search',
        queryParams: {'q': query},
      );
      return response
          .map((json) => VenteModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

