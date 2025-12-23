import '../../config/app_config.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/user_model.dart';

/// Service pour filtrer les notifications selon le rôle de l'utilisateur
class NotificationFilterService {
  /// Filtrer les notifications selon le rôle de l'utilisateur
  static List<NotificationModel> filterByRole(
    List<NotificationModel> notifications,
    UserModel user,
  ) {
    return notifications.where((notification) {
      return _shouldShowNotification(notification, user);
    }).toList();
  }

  /// Déterminer si une notification doit être affichée selon le rôle
  static bool _shouldShowNotification(
    NotificationModel notification,
    UserModel user,
  ) {
    // Admin voit toutes les notifications
    if (user.role == AppConfig.roleAdmin) {
      return true;
    }

    // Notifications spécifiques à l'utilisateur
    if (notification.userId != null && notification.userId == user.id) {
      return true;
    }

    // Notifications globales filtrées par module et type
    if (notification.userId == null) {
      return _isNotificationRelevantForRole(notification, user.role);
    }

    return false;
  }

  /// Vérifier si une notification est pertinente pour un rôle
  static bool _isNotificationRelevantForRole(
    NotificationModel notification,
    String role,
  ) {
    switch (role) {
      case AppConfig.roleCaissier:
        // Caisse voit : Ventes, Recettes, Facturation
        return _isRelevantForCaissier(notification);

      case AppConfig.roleGestionnaireStock:
        // Magasinier voit : Stock, Adhérents (lecture seule)
        return _isRelevantForMagasinier(notification);

      default:
        return false;
    }
  }

  /// Vérifier si une notification est pertinente pour le Caissier
  static bool _isRelevantForCaissier(NotificationModel notification) {
    // Modules pertinents
    if (notification.module != null) {
      final relevantModules = ['ventes', 'recettes', 'factures'];
      if (relevantModules.contains(notification.module)) {
        return true;
      }
    }

    // Types pertinents
    final relevantTypes = [
      'vente',
      'recette',
      'facture',
      'paiement',
      'bordereau',
    ];
    if (relevantTypes.any((type) => notification.type.contains(type))) {
      return true;
    }

    return false;
  }

  /// Vérifier si une notification est pertinente pour le Magasinier
  static bool _isRelevantForMagasinier(NotificationModel notification) {
    // Modules pertinents
    if (notification.module != null) {
      final relevantModules = ['stock', 'adherents'];
      if (relevantModules.contains(notification.module)) {
        return true;
      }
    }

    // Types pertinents
    final relevantTypes = [
      'stock_low',
      'stock_critical',
      'depot',
      'stock',
    ];
    if (relevantTypes.any((type) => notification.type.contains(type))) {
      return true;
    }

    return false;
  }

  /// Obtenir les types de notifications pertinents pour un rôle
  static List<String> getRelevantTypesForRole(String role) {
    switch (role) {
      case AppConfig.roleAdmin:
        return [
          'info',
          'success',
          'warning',
          'error',
          'stock_low',
          'stock_critical',
          'vente',
          'recette',
          'facture',
        ];

      case AppConfig.roleCaissier:
        return [
          'vente',
          'recette',
          'facture',
          'paiement',
          'bordereau',
        ];

      case AppConfig.roleGestionnaireStock:
        return [
          'stock_low',
          'stock_critical',
          'depot',
          'stock',
        ];

      default:
        return [];
    }
  }

  /// Obtenir les modules pertinents pour un rôle
  static List<String> getRelevantModulesForRole(String role) {
    switch (role) {
      case AppConfig.roleAdmin:
        return [
          'stock',
          'ventes',
          'recettes',
          'factures',
          'adherents',
          'settings',
        ];

      case AppConfig.roleCaissier:
        return [
          'ventes',
          'recettes',
          'factures',
        ];

      case AppConfig.roleGestionnaireStock:
        return [
          'stock',
          'adherents',
        ];

      default:
        return [];
    }
  }
}
