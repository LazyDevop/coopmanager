import '../models/recette_model.dart';
import 'base_repository.dart';
import '../../services/api/api_client.dart';
import '../../data/dto/api_response.dart';
import '../../services/integration/error_handler.dart';

/// Repository pour les recettes avec intégration backend
class RecetteRepository extends BaseRepository<RecetteModel> {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<RecetteModel?> getById(int id, String endpoint) async {
    return getByIdWithErrorHandling(id, '/api/v1/recettes');
  }

  @override
  Future<List<RecetteModel>> getAll(String endpoint, {Map<String, dynamic>? queryParams}) async {
    return getAllWithErrorHandling('/api/v1/recettes', queryParams: queryParams);
  }

  @override
  Future<RecetteModel> create(Map<String, dynamic> data, String endpoint) async {
    // Les recettes sont créées automatiquement par le backend lors de la création d'une vente
    throw UnimplementedError('Les recettes sont créées automatiquement par le backend');
  }

  @override
  Future<RecetteModel> update(int id, Map<String, dynamic> data, String endpoint) async {
    // Les recettes ne sont généralement pas modifiables après création
    throw UnimplementedError('Les recettes ne sont pas modifiables');
  }

  @override
  Future<void> delete(int id, String endpoint) async {
    // Les recettes ne sont généralement pas supprimables
    throw UnimplementedError('Les recettes ne sont pas supprimables');
  }

  @override
  RecetteModel fromMap(Map<String, dynamic> map) {
    return RecetteModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(RecetteModel model) {
    return model.toMap();
  }

  // ========== MÉTHODES SPÉCIFIQUES AUX RECETTES ==========

  /// Obtenir les recettes d'un adhérent
  Future<List<RecetteModel>> getRecettesByAdherent({
    required int adherentId,
    int? campagneId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'adherent_id': adherentId,
    };
    if (campagneId != null) queryParams['campagne_id'] = campagneId;
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

    return getAllWithErrorHandling('/api/v1/recettes', queryParams: queryParams);
  }

  /// Obtenir les recettes d'une vente
  Future<List<RecetteModel>> getRecettesByVente(int venteId) async {
    return getAllWithErrorHandling(
      '/api/v1/recettes',
      queryParams: {'vente_id': venteId},
    );
  }

  /// Générer le bordereau PDF
  Future<String> generateBordereauPdf(int recetteId) async {
    try {
      final response = await _apiClient.get('/api/v1/recettes/$recetteId/bordereau');
      final apiResponse = ApiResponse.fromJson(response, null);
      
      if (apiResponse.success && apiResponse.data != null) {
        return (apiResponse.data as Map<String, dynamic>)['pdf_path'] as String;
      } else {
        throw ApiException('Erreur lors de la génération du bordereau');
      }
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      throw ApiException(
        ErrorHandler.getUserFriendlyMessage(error.code, defaultMessage: error.message),
        statusCode: error.statusCode,
      );
    }
  }

  /// Obtenir les statistiques des recettes
  Future<Map<String, dynamic>> getStatistiques({
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

      final response = await _apiClient.get(
        '/api/v1/recettes/statistiques',
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
}

