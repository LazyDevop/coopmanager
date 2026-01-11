import '../../data/dto/api_response.dart';
import '../api/api_exception.dart';

/// Gestionnaire d'erreurs centralisé pour l'intégration
class ErrorHandler {
  /// Convertir une exception en ApiError
  static ApiError handleException(dynamic exception) {
    if (exception is ApiException) {
      return ApiError(
        code: _getErrorCode(exception.statusCode),
        message: exception.message,
        statusCode: exception.statusCode,
        details: exception.data is Map<String, dynamic> 
            ? exception.data as Map<String, dynamic>
            : {'raw': exception.data?.toString()},
      );
    }

    if (exception is FormatException) {
      return ApiError(
        code: ErrorCodes.validationError,
        message: 'Erreur de format: ${exception.message}',
      );
    }

    if (exception.toString().contains('SocketException') || 
        exception.toString().contains('network')) {
      return ApiError(
        code: ErrorCodes.networkError,
        message: 'Erreur de connexion réseau. Vérifiez votre connexion internet.',
      );
    }

    if (exception.toString().contains('timeout')) {
      return ApiError(
        code: ErrorCodes.timeoutError,
        message: 'La requête a expiré. Veuillez réessayer.',
      );
    }

    return ApiError(
      code: ErrorCodes.unknownError,
      message: exception.toString(),
    );
  }

  /// Obtenir le code d'erreur depuis le status code HTTP
  static String _getErrorCode(int? statusCode) {
    if (statusCode == null) return ErrorCodes.unknownError;

    switch (statusCode) {
      case 400:
        return ErrorCodes.validationError;
      case 401:
        return ErrorCodes.unauthorized;
      case 403:
        return ErrorCodes.forbidden;
      case 404:
        return ErrorCodes.notFound;
      case 500:
      case 502:
      case 503:
        return ErrorCodes.serverError;
      default:
        return ErrorCodes.unknownError;
    }
  }

  /// Obtenir un message utilisateur-friendly depuis le code d'erreur
  static String getUserFriendlyMessage(String errorCode, {String? defaultMessage}) {
    switch (errorCode) {
      case ErrorCodes.networkError:
        return 'Erreur de connexion. Vérifiez votre connexion internet.';
      case ErrorCodes.timeoutError:
        return 'La requête a pris trop de temps. Veuillez réessayer.';
      case ErrorCodes.unauthorized:
        return 'Session expirée. Veuillez vous reconnecter.';
      case ErrorCodes.forbidden:
        return 'Vous n\'avez pas les permissions nécessaires.';
      case ErrorCodes.notFound:
        return 'Ressource introuvable.';
      case ErrorCodes.validationError:
        return defaultMessage ?? 'Données invalides. Vérifiez les informations saisies.';
      case ErrorCodes.insufficientStock:
        return 'Stock insuffisant pour cette opération.';
      case ErrorCodes.invalidPrice:
        return 'Prix invalide. Vérifiez les barèmes de prix configurés.';
      case ErrorCodes.transactionFailed:
        return 'La transaction a échoué. Veuillez réessayer.';
      case ErrorCodes.syncConflict:
        return 'Conflit de synchronisation détecté. Les données ont été mises à jour.';
      case ErrorCodes.offlineMode:
        return 'Mode hors ligne. Les modifications seront synchronisées plus tard.';
      default:
        return defaultMessage ?? 'Une erreur est survenue. Veuillez réessayer.';
    }
  }

  /// Vérifier si l'erreur est récupérable (peut être réessayée)
  static bool isRetryable(String errorCode) {
    return [
      ErrorCodes.networkError,
      ErrorCodes.timeoutError,
      ErrorCodes.serverError,
    ].contains(errorCode);
  }

  /// Vérifier si l'erreur nécessite une reconnexion
  static bool requiresReauth(String errorCode) {
    return [
      ErrorCodes.unauthorized,
      ErrorCodes.forbidden,
    ].contains(errorCode);
  }
}

