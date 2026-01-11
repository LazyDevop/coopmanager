import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../../data/models/vente_model.dart';
import '../../data/models/vente_detail_model.dart';

/// Service API pour les opérations sur les ventes
class VenteApiService {
  final ApiClient _apiClient = ApiClient();

  /// Récupérer toutes les ventes
  /// GET /ventes
  Future<List<VenteModel>> getAllVentes({
    int? adherentId,
    int? clientId,
    int? campagneId,
    String? type,
    String? statut,
    String? statutPaiement,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (adherentId != null) queryParams['adherent_id'] = adherentId;
      if (clientId != null) queryParams['client_id'] = clientId;
      if (campagneId != null) queryParams['campagne_id'] = campagneId;
      if (type != null) queryParams['type'] = type;
      if (statut != null) queryParams['statut'] = statut;
      if (statutPaiement != null) queryParams['statut_paiement'] = statutPaiement;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.getList(
        '/ventes',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      return response
          .map((json) => VenteModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des ventes: $e');
    }
  }

  /// Récupérer une vente par ID
  /// GET /ventes/{id}
  Future<VenteModel?> getVenteById(int id) async {
    try {
      final response = await _apiClient.get('/ventes/$id');
      if (response.isEmpty) return null;
      return VenteModel.fromMap(response);
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      throw Exception('Erreur lors de la récupération de la vente: $e');
    }
  }

  /// Créer une vente V1
  /// POST /ventes
  Future<VenteModel> createVenteV1(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/ventes', data);
      return VenteModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de la vente: $e');
    }
  }

  /// Créer une vente individuelle
  /// POST /ventes/individuelle
  Future<VenteModel> createVenteIndividuelle(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/ventes/individuelle', data);
      return VenteModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de la vente individuelle: $e');
    }
  }

  /// Créer une vente groupée
  /// POST /ventes/groupee
  Future<VenteModel> createVenteGroupee(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/ventes/groupee', data);
      return VenteModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de la vente groupée: $e');
    }
  }

  /// Annuler une vente
  /// POST /ventes/{id}/annuler
  Future<bool> annulerVente(int venteId, Map<String, dynamic> data) async {
    try {
      await _apiClient.post('/ventes/$venteId/annuler', data);
      return true;
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la vente: $e');
    }
  }

  /// Récupérer les détails d'une vente groupée
  /// GET /ventes/{id}/details
  Future<List<VenteDetailModel>> getVenteDetails(int venteId) async {
    try {
      final response = await _apiClient.getList('/ventes/$venteId/details');
      return response
          .map((json) => VenteDetailModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des détails: $e');
    }
  }

  /// Rechercher des ventes
  /// GET /ventes/search?q={query}
  Future<List<VenteModel>> searchVentes(String query) async {
    try {
      final response = await _apiClient.getList(
        '/ventes/search',
        queryParams: {'q': query},
      );

      return response
          .map((json) => VenteModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Obtenir les statistiques des ventes
  /// GET /ventes/statistiques
  Future<Map<String, dynamic>> getStatistiques({
    DateTime? startDate,
    DateTime? endDate,
    int? adherentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (adherentId != null) queryParams['adherent_id'] = adherentId;

      final response = await _apiClient.get(
        '/ventes/statistiques',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      return response;
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  /// Simuler une vente
  /// POST /ventes/simulation
  Future<Map<String, dynamic>> simulateVente(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/ventes/simulation', data);
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la simulation: $e');
    }
  }

  /// Valider une vente (workflow multi-niveaux)
  /// POST /ventes/{id}/valider
  Future<bool> validateVente(int venteId, Map<String, dynamic> data) async {
    try {
      await _apiClient.post('/ventes/$venteId/valider', data);
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la validation: $e');
    }
  }
}

