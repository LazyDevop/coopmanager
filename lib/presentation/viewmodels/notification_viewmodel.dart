import 'package:flutter/foundation.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/user_model.dart';
import '../../services/notification/notification_service.dart';
import '../../services/notification/notification_filter_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filtres
  int? _filterUserId;
  String? _filterType;
  String? _filterModule;
  bool? _filterIsRead;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _searchQuery = '';

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get filterUserId => _filterUserId;
  String? get filterType => _filterType;
  String? get filterModule => _filterModule;
  bool? get filterIsRead => _filterIsRead;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String get searchQuery => _searchQuery;

  // Notifications filtrées
  List<NotificationModel> get filteredNotifications {
    List<NotificationModel> filtered = _notifications;

    // Recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((n) {
        return n.titre.toLowerCase().contains(query) ||
               n.message.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  NotificationViewModel() {
    // Ne pas initialiser immédiatement pour éviter notifyListeners() pendant le build initial
    // L'initialisation sera déclenchée explicitement par les widgets qui en ont besoin
  }

  /// Initialiser le service de notifications
  Future<void> initialize({UserModel? user}) async {
    await _notificationService.initialize();
    if (user != null) {
      await loadNotifications(user: user);
    } else {
      await loadNotifications();
    }
  }

  /// Charger toutes les notifications
  Future<void> loadNotifications({int? userId, UserModel? user}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getAllNotifications(
        userId: userId ?? _filterUserId,
        type: _filterType,
        module: _filterModule,
        isRead: _filterIsRead,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
      );

      // Filtrer par rôle si un utilisateur est fourni
      if (user != null) {
        _notifications = NotificationFilterService.filterByRole(_notifications, user);
      }

      // Mettre à jour le compteur de non lues (filtré par rôle)
      final filteredUnread = user != null
          ? NotificationFilterService.filterByRole(_notifications, user)
              .where((n) => !n.isRead)
              .length
          : await _notificationService.getUnreadCount(
              userId: userId ?? _filterUserId,
            );
      _unreadCount = filteredUnread is int ? filteredUnread : _notifications.where((n) => !n.isRead).length;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtrer par utilisateur
  void setFilterUser(int? userId) {
    _filterUserId = userId;
    loadNotifications();
  }

  /// Filtrer par type
  void setFilterType(String? type) {
    _filterType = type;
    loadNotifications();
  }

  /// Filtrer par module
  void setFilterModule(String? module) {
    _filterModule = module;
    loadNotifications();
  }

  /// Filtrer par statut de lecture
  void setFilterIsRead(bool? isRead) {
    _filterIsRead = isRead;
    loadNotifications();
  }

  /// Filtrer par dates
  void setFilterDates(DateTime? startDate, DateTime? endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    loadNotifications();
  }

  /// Réinitialiser les filtres
  void resetFilters() {
    _filterUserId = null;
    _filterType = null;
    _filterModule = null;
    _filterIsRead = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _searchQuery = '';
    loadNotifications();
  }

  /// Rechercher des notifications
  void searchNotifications(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Marquer une notification comme lue
  Future<bool> markAsRead(int notificationId) async {
    try {
      final success = await _notificationService.markAsRead(notificationId);
      if (success) {
        await loadNotifications();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors du marquage: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead({int? userId}) async {
    try {
      final success = await _notificationService.markAllAsRead(userId: userId);
      if (success) {
        await loadNotifications();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors du marquage: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Supprimer une notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final success = await _notificationService.deleteNotification(notificationId);
      if (success) {
        await loadNotifications();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Supprimer toutes les notifications lues
  Future<bool> deleteReadNotifications({int? userId}) async {
    try {
      final success = await _notificationService.deleteReadNotifications(userId: userId);
      if (success) {
        await loadNotifications();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Rafraîchir le compteur de non lues
  Future<void> refreshUnreadCount({int? userId}) async {
    try {
      _unreadCount = await _notificationService.getUnreadCount(userId: userId);
      notifyListeners();
    } catch (e) {
      print('Erreur lors du rafraîchissement du compteur: $e');
    }
  }

  /// Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
