/// Réponse API standardisée selon les spécifications
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final ApiMeta? meta;
  final ApiError? error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
    this.error,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null 
          ? fromJsonT(json['data']) 
          : json['data'] as T?,
      meta: json['meta'] != null ? ApiMeta.fromJson(json['meta']) : null,
      error: json['error'] != null ? ApiError.fromJson(json['error']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'meta': meta?.toJson(),
      'error': error?.toJson(),
    };
  }

  bool get hasError => !success || error != null;
}

/// Métadonnées de la réponse API
class ApiMeta {
  final String timestamp;
  final int? userId;
  final String? module;
  final Map<String, dynamic>? additional;

  ApiMeta({
    required this.timestamp,
    this.userId,
    this.module,
    this.additional,
  });

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      userId: json['user_id'],
      module: json['module'],
      additional: json['additional'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'user_id': userId,
      'module': module,
      'additional': additional,
    };
  }
}

/// Erreur API standardisée
class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final int? statusCode;

  ApiError({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] ?? 'UNKNOWN_ERROR',
      message: json['message'] ?? 'Une erreur est survenue',
      details: json['details'] as Map<String, dynamic>?,
      statusCode: json['status_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'details': details,
      'status_code': statusCode,
    };
  }
}

/// Codes d'erreur normalisés
class ErrorCodes {
  // Erreurs générales
  static const String networkError = 'NETWORK_ERROR';
  static const String timeoutError = 'TIMEOUT_ERROR';
  static const String unknownError = 'UNKNOWN_ERROR';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String notFound = 'NOT_FOUND';
  static const String validationError = 'VALIDATION_ERROR';
  static const String serverError = 'SERVER_ERROR';

  // Erreurs métier
  static const String insufficientStock = 'INSUFFICIENT_STOCK';
  static const String invalidPrice = 'INVALID_PRICE';
  static const String adherentNotFound = 'ADHERENT_NOT_FOUND';
  static const String clientNotFound = 'CLIENT_NOT_FOUND';
  static const String campagneNotFound = 'CAMPAGNE_NOT_FOUND';
  static const String venteNotFound = 'VENTE_NOT_FOUND';
  static const String transactionFailed = 'TRANSACTION_FAILED';
  static const String syncConflict = 'SYNC_CONFLICT';
  static const String offlineMode = 'OFFLINE_MODE';
}

