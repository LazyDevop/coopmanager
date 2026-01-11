import '../api/api_client.dart';

/// Service API pour les paiements
class PaiementApiService {
  final ApiClient _apiClient = ApiClient();

  /// Enregistrer un paiement
  /// POST /paiements
  Future<Map<String, dynamic>> enregistrerPaiement(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/paiements', data);
      return response;
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement du paiement: $e');
    }
  }

  /// Récupérer les paiements d'une vente
  /// GET /paiements/vente/{venteId}
  Future<List<Map<String, dynamic>>> getPaiementsVente(int venteId) async {
    try {
      final response = await _apiClient.getList('/paiements/vente/$venteId');
      return response.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paiements: $e');
    }
  }
}

















