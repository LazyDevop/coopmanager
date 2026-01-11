import '../api/api_client.dart';
import '../../data/models/client_model.dart';

/// Service API pour les clients
class ClientApiService {
  final ApiClient _apiClient = ApiClient();

  /// Récupérer tous les clients
  /// GET /clients
  Future<List<ClientModel>> getAllClients({bool? activeOnly}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (activeOnly != null) queryParams['active_only'] = activeOnly;

      final response = await _apiClient.getList(
        '/clients',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      return response
          .map((json) => ClientModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des clients: $e');
    }
  }

  /// Récupérer un client par ID
  /// GET /clients/{id}
  Future<ClientModel?> getClientById(int id) async {
    try {
      final response = await _apiClient.get('/clients/$id');
      if (response.isEmpty) return null;
      return ClientModel.fromMap(response);
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      throw Exception('Erreur lors de la récupération du client: $e');
    }
  }
}

















