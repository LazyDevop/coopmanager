import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exception personnalisée pour les erreurs API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

/// Client API REST pour communiquer avec le backend
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final String baseUrl = AppConfig.apiBaseUrl;
  final Duration timeout = AppConfig.apiTimeout;

  /// Obtenir le token d'authentification depuis SharedPreferences
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }

  /// Sauvegarder le token d'authentification
  Future<void> saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      print('Erreur lors de la sauvegarde du token: $e');
    }
  }

  /// Supprimer le token d'authentification
  Future<void> clearAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      print('Erreur lors de la suppression du token: $e');
    }
  }

  /// Construire les headers pour les requêtes
  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? additionalHeaders,
    bool includeAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Gérer les erreurs HTTP
  void _handleError(http.Response response) {
    String errorMessage = 'Une erreur est survenue';
    
    try {
      final errorData = json.decode(response.body);
      if (errorData is Map<String, dynamic>) {
        errorMessage = errorData['message'] ?? 
                      errorData['error'] ?? 
                      errorData['detail'] ?? 
                      errorMessage;
      }
    } catch (e) {
      // Si le body n'est pas du JSON, utiliser le message par défaut
      errorMessage = 'Erreur ${response.statusCode}: ${response.reasonPhrase ?? 'Erreur inconnue'}';
    }

    throw ApiException(
      errorMessage,
      statusCode: response.statusCode,
      data: response.body,
    );
  }

  /// Requête GET
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ));
      }

      final headers = await _buildHeaders(includeAuth: includeAuth);
      
      final response = await http
          .get(uri, headers: headers)
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {};
        }
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        _handleError(response);
        return {};
      }
    } on SocketException {
      throw ApiException('Erreur de connexion réseau. Vérifiez votre connexion internet.');
    } on HttpException {
      throw ApiException('Erreur HTTP lors de la requête.');
    } on FormatException {
      throw ApiException('Erreur de format de réponse du serveur.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Requête GET pour une liste
  Future<List<dynamic>> getList(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ));
      }

      final headers = await _buildHeaders(includeAuth: includeAuth);
      
      final response = await http
          .get(uri, headers: headers)
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return [];
        }
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'] as List;
        } else {
          return [];
        }
      } else {
        _handleError(response);
        return [];
      }
    } on SocketException {
      throw ApiException('Erreur de connexion réseau. Vérifiez votre connexion internet.');
    } on HttpException {
      throw ApiException('Erreur HTTP lors de la requête.');
    } on FormatException {
      throw ApiException('Erreur de format de réponse du serveur.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Requête POST
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(includeAuth: includeAuth);
      
      final response = await http
          .post(
            uri,
            headers: headers,
            body: json.encode(data),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {};
        }
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        _handleError(response);
        return {};
      }
    } on SocketException {
      throw ApiException('Erreur de connexion réseau. Vérifiez votre connexion internet.');
    } on HttpException {
      throw ApiException('Erreur HTTP lors de la requête.');
    } on FormatException {
      throw ApiException('Erreur de format de réponse du serveur.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Requête PUT
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(includeAuth: includeAuth);
      
      final response = await http
          .put(
            uri,
            headers: headers,
            body: json.encode(data),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {};
        }
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        _handleError(response);
        return {};
      }
    } on SocketException {
      throw ApiException('Erreur de connexion réseau. Vérifiez votre connexion internet.');
    } on HttpException {
      throw ApiException('Erreur HTTP lors de la requête.');
    } on FormatException {
      throw ApiException('Erreur de format de réponse du serveur.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Requête DELETE
  Future<void> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(includeAuth: includeAuth);
      
      final response = await http
          .delete(uri, headers: headers)
          .timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _handleError(response);
      }
    } on SocketException {
      throw ApiException('Erreur de connexion réseau. Vérifiez votre connexion internet.');
    } on HttpException {
      throw ApiException('Erreur HTTP lors de la requête.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur inattendue: ${e.toString()}');
    }
  }
}

















