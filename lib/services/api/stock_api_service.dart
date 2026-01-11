import '../api/api_client.dart';

/// Service API pour les opérations sur les stocks
class StockApiService {
  final ApiClient _apiClient = ApiClient();

  /// Récupérer le stock disponible d'un adhérent
  /// GET /stocks/disponibles/{adherentId}
  Future<double> getStockDisponible(int adherentId) async {
    try {
      final response = await _apiClient.get('/stocks/disponibles/$adherentId');
      return (response['stock_disponible'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du stock: $e');
    }
  }

  /// Récupérer tous les stocks disponibles
  /// GET /stocks/disponibles
  Future<List<Map<String, dynamic>>> getAllStocksDisponibles({
    int? adherentId,
    String? qualite,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (adherentId != null) queryParams['adherent_id'] = adherentId;
      if (qualite != null) queryParams['qualite'] = qualite;

      final response = await _apiClient.getList(
        '/stocks/disponibles',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      return response.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des stocks: $e');
    }
  }
}

















