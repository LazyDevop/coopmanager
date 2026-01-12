import '../api/api_client.dart';
import '../../data/models/parametres_cooperative_model.dart';

/// Service API pour les paramètres
class ParametresApiService {
  final ApiClient _apiClient = ApiClient();

  /// Récupérer les paramètres de la coopérative
  /// GET /parametres
  Future<ParametresCooperativeModel> getParametres() async {
    try {
      final response = await _apiClient.get('/parametres');
      return ParametresCooperativeModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paramètres: $e');
    }
  }

  /// Récupérer tous les barèmes de prix
  /// GET /parametres/prix
  Future<List<Map<String, dynamic>>> getAllBaremesPrix() async {
    try {
      final response = await _apiClient.getList('/parametres/prix');
      return response.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des barèmes de prix: $e');
    }
  }

  /// Récupérer les commissions
  /// GET /parametres/commissions
  Future<Map<String, dynamic>> getCommissions() async {
    try {
      final response = await _apiClient.get('/parametres/commissions');
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des commissions: $e');
    }
  }

  /// Récupérer toutes les campagnes
  /// GET /parametres/campagnes
  Future<List<CampagneModel>> getAllCampagnes() async {
    try {
      final response = await _apiClient.getList('/parametres/campagnes');
      return response
          .map((json) => CampagneModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des campagnes: $e');
    }
  }

  /// Récupérer la campagne active
  /// GET /parametres/campagnes/active
  Future<CampagneModel?> getCampagneActive() async {
    try {
      final response = await _apiClient.get('/parametres/campagnes/active');
      if (response.isEmpty) return null;
      return CampagneModel.fromMap(response);
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      throw Exception('Erreur lors de la récupération de la campagne active: $e');
    }
  }

  /// Récupérer tous les barèmes de qualité
  /// GET /parametres/baremes-qualite
  Future<List<BaremeQualiteModel>> getAllBaremesQualite() async {
    try {
      final response = await _apiClient.getList('/parametres/baremes-qualite');
      return response
          .map((json) => BaremeQualiteModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des barèmes de qualité: $e');
    }
  }
}

