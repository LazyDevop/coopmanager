import '../models/stock_model.dart';
import '../models/stock_movement_model.dart';
import 'base_repository.dart';
import '../../services/api/api_client.dart';
import '../../data/dto/api_response.dart';
import '../../services/integration/error_handler.dart';

/// Repository pour le stock avec intégration backend
class StockRepository extends BaseRepository<StockDepotModel> {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<StockDepotModel?> getById(int id, String endpoint) async {
    return getByIdWithErrorHandling(id, '/api/v1/stock');
  }

  @override
  Future<List<StockDepotModel>> getAll(String endpoint, {Map<String, dynamic>? queryParams}) async {
    return getAllWithErrorHandling('/api/v1/stock', queryParams: queryParams);
  }

  @override
  Future<StockDepotModel> create(Map<String, dynamic> data, String endpoint) async {
    try {
      final response = await _apiClient.post('/api/v1/stock/depot', data);
      final apiResponse = ApiResponse.fromJson(
        response,
        (json) => StockDepotModel.fromMap(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.error?.message ?? 'Erreur lors de la création du dépôt');
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
  Future<StockDepotModel> update(int id, Map<String, dynamic> data, String endpoint) async {
    try {
      final response = await _apiClient.put('/api/v1/stock/$id', data);
      final apiResponse = ApiResponse.fromJson(
        response,
        (json) => StockDepotModel.fromMap(json as Map<String, dynamic>),
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
      await _apiClient.delete('/api/v1/stock/$id');
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      throw ApiException(
        ErrorHandler.getUserFriendlyMessage(error.code, defaultMessage: error.message),
        statusCode: error.statusCode,
      );
    }
  }

  @override
  StockDepotModel fromMap(Map<String, dynamic> map) {
    return StockDepotModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(StockDepotModel model) {
    return model.toMap();
  }

  // ========== MÉTHODES SPÉCIFIQUES AU STOCK ==========

  /// Créer un dépôt de stock (transaction backend atomique)
  Future<StockDepotModel> createDepot({
    required int adherentId,
    required int campagneId,
    required double quantite,
    String? qualite,
    double? prixUnitaire,
    required DateTime dateDepot,
    String? observations,
    required int createdBy,
  }) async {
    final data = {
      'adherent_id': adherentId,
      'campagne_id': campagneId,
      'quantite': quantite,
      'qualite': qualite,
      'prix_unitaire': prixUnitaire,
      'date_depot': dateDepot.toIso8601String(),
      'observations': observations,
      'created_by': createdBy,
    };

    return await createWithOfflineSupport(
      data: data,
      endpoint: '/api/v1/stock/depot',
      module: 'stock',
      localId: {'id': null, 'adherent_id': adherentId},
    );
  }

  /// Obtenir le stock actuel d'un adhérent
  Future<StockActuelModel> getStockActuel(int adherentId) async {
    try {
      final response = await _apiClient.get('/api/v1/stock/$adherentId/actuel');
      final apiResponse = ApiResponse.fromJson(response, null);
      
      if (apiResponse.success && apiResponse.data != null) {
        final data = apiResponse.data as Map<String, dynamic>;
        return StockActuelModel(
          adherentId: adherentId,
          adherentCode: data['adherent_code'] as String? ?? '',
          adherentNom: data['adherent_nom'] as String? ?? '',
          adherentPrenom: data['adherent_prenom'] as String? ?? '',
          stockTotal: (data['stock_total'] as num?)?.toDouble() ?? 0.0,
          stockStandard: (data['stock_standard'] as num?)?.toDouble() ?? 0.0,
          stockPremium: (data['stock_premium'] as num?)?.toDouble() ?? 0.0,
          stockBio: (data['stock_bio'] as num?)?.toDouble() ?? 0.0,
          dernierDepot: data['dernier_depot'] != null 
              ? DateTime.parse(data['dernier_depot'] as String)
              : null,
          dernierMouvement: data['dernier_mouvement'] != null
              ? DateTime.parse(data['dernier_mouvement'] as String)
              : null,
        );
      } else {
        return StockActuelModel(
          adherentId: adherentId,
          adherentCode: '',
          adherentNom: '',
          adherentPrenom: '',
          stockTotal: 0.0,
        );
      }
    } catch (e) {
      return StockActuelModel(
        adherentId: adherentId,
        adherentCode: '',
        adherentNom: '',
        adherentPrenom: '',
        stockTotal: 0.0,
      );
    }
  }

  /// Obtenir l'historique des mouvements
  Future<List<StockMovementModel>> getMouvements({
    int? adherentId,
    int? campagneId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (adherentId != null) queryParams['adherent_id'] = adherentId;
      if (campagneId != null) queryParams['campagne_id'] = campagneId;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _apiClient.getList(
        '/api/v1/stock/mouvements',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      return response
          .map((json) => StockMovementModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Ajuster le stock (correction)
  Future<StockDepotModel> ajusterStock({
    required int depotId,
    required double nouvelleQuantite,
    required String raison,
    required int updatedBy,
  }) async {
    try {
      final data = {
        'nouvelle_quantite': nouvelleQuantite,
        'raison': raison,
        'updated_by': updatedBy,
      };

      final response = await _apiClient.post('/api/v1/stock/$depotId/ajuster', data);
      final apiResponse = ApiResponse.fromJson(
        response,
        (json) => StockDepotModel.fromMap(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.error?.message ?? 'Erreur lors de l\'ajustement');
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

