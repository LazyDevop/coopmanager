import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../../data/models/adherent_model.dart';

/// Service API pour les opérations sur les adhérents
class AdherentApiService {
  final ApiClient _apiClient = ApiClient();

  /// Récupérer tous les adhérents
  /// GET /adherents
  Future<List<AdherentModel>> getAllAdherents({
    bool? isActive,
    String? village,
    int? page,
    int? limit,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isActive != null) queryParams['is_active'] = isActive;
      if (village != null && village.isNotEmpty) queryParams['village'] = village;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.getList(
        '/adherents',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      return response
          .map((json) => AdherentModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des adhérents: $e');
    }
  }

  /// Récupérer un adhérent par ID
  /// GET /adherents/{id}
  Future<AdherentModel?> getAdherentById(int id) async {
    try {
      final response = await _apiClient.get('/adherents/$id');
      if (response.isEmpty) return null;
      return AdherentModel.fromMap(response);
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      throw Exception('Erreur lors de la récupération de l\'adhérent: $e');
    }
  }

  /// Récupérer un adhérent par code
  /// GET /adherents/code/{code}
  Future<AdherentModel?> getAdherentByCode(String code) async {
    try {
      final response = await _apiClient.get('/adherents/code/$code');
      if (response.isEmpty) return null;
      return AdherentModel.fromMap(response);
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      throw Exception('Erreur lors de la récupération de l\'adhérent: $e');
    }
  }

  /// Créer un nouvel adhérent
  /// POST /adherents
  Future<AdherentModel> createAdherent(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/adherents', data);
      return AdherentModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'adhérent: $e');
    }
  }

  /// Mettre à jour un adhérent
  /// PUT /adherents/{id}
  Future<AdherentModel> updateAdherent(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/adherents/$id', data);
      return AdherentModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'adhérent: $e');
    }
  }

  /// Activer/Désactiver un adhérent
  /// PATCH /adherents/{id}/status
  Future<bool> toggleAdherentStatus(int id, bool isActive) async {
    try {
      await _apiClient.post('/adherents/$id/status', {'is_active': isActive});
      return true;
    } catch (e) {
      throw Exception('Erreur lors du changement de statut: $e');
    }
  }

  /// Rechercher des adhérents
  /// GET /adherents/search?q={query}
  Future<List<AdherentModel>> searchAdherents(String query) async {
    try {
      final response = await _apiClient.getList(
        '/adherents/search',
        queryParams: {'q': query},
      );

      return response
          .map((json) => AdherentModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Obtenir tous les villages distincts
  /// GET /adherents/villages
  Future<List<String>> getAllVillages() async {
    try {
      final response = await _apiClient.getList('/adherents/villages');
      return response.map((v) => v.toString()).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des villages: $e');
    }
  }

  /// Vérifier si un code existe
  /// GET /adherents/check-code/{code}
  Future<bool> codeExists(String code, {int? excludeId}) async {
    try {
      final queryParams = <String, dynamic>{'code': code};
      if (excludeId != null) queryParams['exclude_id'] = excludeId;
      
      final response = await _apiClient.get(
        '/adherents/check-code',
        queryParams: queryParams,
      );
      
      return response['exists'] as bool? ?? false;
    } catch (e) {
      throw Exception('Erreur lors de la vérification du code: $e');
    }
  }

  /// Générer le prochain code disponible
  /// GET /adherents/next-code
  Future<String> generateNextCode() async {
    try {
      final response = await _apiClient.get('/adherents/next-code');
      return response['code'] as String? ?? 'ADH001';
    } catch (e) {
      throw Exception('Erreur lors de la génération du code: $e');
    }
  }

  /// Récupérer l'historique d'un adhérent
  /// GET /adherents/{id}/historique
  Future<List<Map<String, dynamic>>> getHistorique(int adherentId) async {
    try {
      final response = await _apiClient.getList('/adherents/$adherentId/historique');
      return response.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'historique: $e');
    }
  }

  /// Récupérer les dépôts d'un adhérent
  /// GET /adherents/{id}/depots
  Future<List<Map<String, dynamic>>> getDepots(int adherentId) async {
    try {
      final response = await _apiClient.getList('/adherents/$adherentId/depots');
      return response.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des dépôts: $e');
    }
  }

  /// Récupérer les ventes d'un adhérent
  /// GET /adherents/{id}/ventes
  Future<List<Map<String, dynamic>>> getVentes(int adherentId) async {
    try {
      final response = await _apiClient.getList('/adherents/$adherentId/ventes');
      return response.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des ventes: $e');
    }
  }

  /// Récupérer les recettes d'un adhérent
  /// GET /adherents/{id}/recettes
  Future<List<Map<String, dynamic>>> getRecettes(int adherentId) async {
    try {
      final response = await _apiClient.getList('/adherents/$adherentId/recettes');
      return response.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des recettes: $e');
    }
  }
}

