import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite_common/sqlite_api.dart';
import '../database/db_initializer.dart';
import '../../data/models/notification_model.dart';
import '../../config/app_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialiser les notifications système
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configuration Android (pour compatibilité)
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuration Windows (si disponible)
      const initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
    } catch (e) {
      print('Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  /// Callback lorsqu'une notification est cliquée
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Naviguer vers l'écran approprié selon le payload
    print('Notification cliquée: ${response.payload}');
  }

  /// Afficher un toast (notification in-app)
  /// Nécessite un BuildContext pour utiliser ScaffoldMessenger
  void showToast({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Afficher une notification système Windows
  Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
    String priority = 'default',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Windows notifications (simplifié pour compatibilité)
      const notificationDetails = NotificationDetails();

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 2147483647,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Erreur lors de l\'affichage de la notification système: $e');
    }
  }

  /// Logger une notification dans la base de données
  Future<int> logNotification({
    required String type,
    required String titre,
    required String message,
    String? module,
    String? entityType,
    int? entityId,
    int? userId,
    String priority = 'normal',
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      final notification = NotificationModel(
        type: type,
        titre: titre,
        message: message,
        module: module,
        entityType: entityType,
        entityId: entityId,
        userId: userId,
        priority: priority,
        createdAt: DateTime.now(),
      );

      final id = await db.insert('notifications', notification.toMap());
      return id;
    } catch (e) {
      print('Erreur lors de l\'enregistrement de la notification: $e');
      return -1;
    }
  }

  /// Afficher une notification complète (toast + système + log)
  /// Si showToast est true, un BuildContext doit être fourni
  Future<void> notify({
    required String type,
    required String titre,
    required String message,
    String? module,
    String? entityType,
    int? entityId,
    int? userId,
    String priority = 'normal',
    bool showToast = true,
    bool showSystem = false,
    BuildContext? context,
  }) async {
    // Logger dans la base de données
    await logNotification(
      type: type,
      titre: titre,
      message: message,
      module: module,
      entityType: entityType,
      entityId: entityId,
      userId: userId,
      priority: priority,
    );

    // Afficher le toast si un contexte est disponible
    if (showToast && context != null) {
      _showToastByType(context, type, message);
    }

    // Afficher la notification système si demandée ou si priorité élevée
    if (showSystem || priority == 'high' || priority == 'critical') {
      await showSystemNotification(
        title: titre,
        body: message,
        payload: entityId != null ? '$entityType:$entityId' : null,
        priority: priority,
      );
    }
  }

  /// Afficher un toast selon le type
  void _showToastByType(BuildContext context, String type, String message) {
    Color? backgroundColor;

    switch (type) {
      case 'success':
        backgroundColor = Colors.green;
        break;
      case 'error':
      case 'critical':
        backgroundColor = Colors.red;
        break;
      case 'warning':
        backgroundColor = Colors.orange;
        break;
      case 'info':
      default:
        backgroundColor = Colors.blue;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Convertir la priorité string (pour compatibilité, Windows ne supporte pas les priorités)
  String _getNotificationPriority(String priority) {
    // Windows ne supporte pas les priorités de notification
    // On garde juste pour compatibilité avec le code existant
    return priority;
  }

  /// Récupérer toutes les notifications
  Future<List<NotificationModel>> getAllNotifications({
    int? userId,
    String? type,
    String? module,
    bool? isRead,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        where += ' AND (user_id = ? OR user_id IS NULL)';
        whereArgs.add(userId);
      }

      if (type != null) {
        where += ' AND type = ?';
        whereArgs.add(type);
      }

      if (module != null) {
        where += ' AND module = ?';
        whereArgs.add(module);
      }

      if (isRead != null) {
        where += ' AND is_read = ?';
        whereArgs.add(isRead ? 1 : 0);
      }

      if (startDate != null) {
        where += ' AND created_at >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND created_at <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.query(
        'notifications',
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return result.map((map) => NotificationModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des notifications: $e');
    }
  }

  /// Marquer une notification comme lue
  Future<bool> markAsRead(int notificationId) async {
    try {
      final db = await DatabaseInitializer.database;

      await db.update(
        'notifications',
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [notificationId],
      );

      return true;
    } catch (e) {
      print('Erreur lors du marquage comme lu: $e');
      return false;
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead({int? userId}) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = 'is_read = 0';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        where += ' AND (user_id = ? OR user_id IS NULL)';
        whereArgs.add(userId);
      }

      await db.update(
        'notifications',
        {'is_read': 1},
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
      );

      return true;
    } catch (e) {
      print('Erreur lors du marquage comme lu: $e');
      return false;
    }
  }

  /// Supprimer une notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final db = await DatabaseInitializer.database;

      await db.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [notificationId],
      );

      return true;
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Supprimer toutes les notifications lues
  Future<bool> deleteReadNotifications({int? userId}) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = 'is_read = 1';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        where += ' AND (user_id = ? OR user_id IS NULL)';
        whereArgs.add(userId);
      }

      await db.delete(
        'notifications',
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
      );

      return true;
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Obtenir le nombre de notifications non lues
  Future<int> getUnreadCount({int? userId}) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = 'is_read = 0';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        where += ' AND (user_id = ? OR user_id IS NULL)';
        whereArgs.add(userId);
      }

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications WHERE $where',
        whereArgs.isEmpty ? null : whereArgs,
      );

      return result.first['count'] as int? ?? 0;
    } catch (e) {
      print('Erreur lors du comptage: $e');
      return 0;
    }
  }

  // ========== MÉTHODES SPÉCIALISÉES PAR MODULE ==========

  /// Notification : Dépôt ajouté
  Future<void> notifyDepotAdded({
    required int adherentId,
    required double quantite,
    int? userId,
  }) async {
    await notify(
      type: 'success',
      titre: 'Dépôt ajouté',
      message: 'Dépôt de ${quantite.toStringAsFixed(2)} kg enregistré avec succès',
      module: 'stock',
      entityType: 'depot',
      entityId: adherentId,
      userId: userId,
      priority: 'normal',
      showToast: true,
      showSystem: false,
    );
  }

  /// Notification : Stock faible
  Future<void> notifyStockLow({
    required int adherentId,
    required double stockActuel,
    required double seuil,
    int? userId,
  }) async {
    await notify(
      type: 'warning',
      titre: 'Stock faible',
      message: 'Stock actuel: ${stockActuel.toStringAsFixed(2)} kg (seuil: ${seuil.toStringAsFixed(2)} kg)',
      module: 'stock',
      entityType: 'adherent',
      entityId: adherentId,
      userId: userId,
      priority: 'high',
      showToast: true,
      showSystem: true,
    );
  }

  /// Notification : Stock critique
  Future<void> notifyStockCritical({
    required int adherentId,
    required double stockActuel,
    int? userId,
  }) async {
    await notify(
      type: 'critical',
      titre: 'Stock critique',
      message: 'Stock très faible: ${stockActuel.toStringAsFixed(2)} kg',
      module: 'stock',
      entityType: 'adherent',
      entityId: adherentId,
      userId: userId,
      priority: 'critical',
      showToast: true,
      showSystem: true,
    );
  }

  /// Notification : Vente créée
  Future<void> notifyVenteCreated({
    required int venteId,
    required double montant,
    int? userId,
  }) async {
    await notify(
      type: 'success',
      titre: 'Vente créée',
      message: 'Vente de ${montant.toStringAsFixed(0)} FCFA enregistrée avec succès',
      module: 'ventes',
      entityType: 'vente',
      entityId: venteId,
      userId: userId,
      priority: 'normal',
      showToast: true,
      showSystem: false,
    );
  }

  /// Notification : Vente annulée
  Future<void> notifyVenteAnnulee({
    required int venteId,
    required String raison,
    int? userId,
  }) async {
    await notify(
      type: 'warning',
      titre: 'Vente annulée',
      message: 'Vente #$venteId annulée${raison.isNotEmpty ? ': $raison' : ''}',
      module: 'ventes',
      entityType: 'vente',
      entityId: venteId,
      userId: userId,
      priority: 'normal',
      showToast: true,
      showSystem: false,
    );
  }

  /// Notification : Recette calculée
  /// Notifier qu'un paiement a été effectué
  Future<void> notifyPaiementEffectue({
    required int paiementId,
    required double montant,
    required int userId,
  }) async {
    await notify(
      type: 'success',
      titre: 'Paiement effectué',
      message: 'Un paiement de ${montant.toStringAsFixed(2)} FCFA a été enregistré',
      module: 'paiements',
      entityType: 'paiement',
      entityId: paiementId,
      userId: userId,
      priority: 'normal',
      showToast: true,
      showSystem: false,
    );
  }

  Future<void> notifyRecetteCalculated({
    required int recetteId,
    required double montantNet,
    int? userId,
  }) async {
    await notify(
      type: 'success',
      titre: 'Recette calculée',
      message: 'Recette nette: ${montantNet.toStringAsFixed(0)} FCFA',
      module: 'recettes',
      entityType: 'recette',
      entityId: recetteId,
      userId: userId,
      priority: 'normal',
      showToast: true,
      showSystem: false,
    );
  }

  /// Notification : Facture générée
  Future<void> notifyFactureGenerated({
    required String numeroFacture,
    required double montant,
    int? userId,
  }) async {
    await notify(
      type: 'info',
      titre: 'Facture générée',
      message: 'Facture $numeroFacture générée: ${montant.toStringAsFixed(0)} FCFA',
      module: 'factures',
      entityType: 'facture',
      userId: userId,
      priority: 'normal',
      showToast: true,
      showSystem: false,
    );
  }

  /// Notification : Connexion utilisateur
  Future<void> notifyUserLogin({
    required String username,
    required int userId,
  }) async {
    await notify(
      type: 'info',
      titre: 'Connexion',
      message: 'Utilisateur $username connecté',
      module: 'auth',
      entityType: 'user',
      entityId: userId,
      userId: userId,
      priority: 'low',
      showToast: false,
      showSystem: false,
    );
  }

  /// Notification : Déconnexion utilisateur
  Future<void> notifyUserLogout({
    required String username,
    required int userId,
  }) async {
    await notify(
      type: 'info',
      titre: 'Déconnexion',
      message: 'Utilisateur $username déconnecté',
      module: 'auth',
      entityType: 'user',
      entityId: userId,
      userId: userId,
      priority: 'low',
      showToast: false,
      showSystem: false,
    );
  }

  /// Notification : Paramètres modifiés
  Future<void> notifySettingsChanged({
    required String settingName,
    int? userId,
  }) async {
    await notify(
      type: 'info',
      titre: 'Paramètres modifiés',
      message: 'Le paramètre "$settingName" a été modifié',
      module: 'settings',
      userId: userId,
      priority: 'normal',
      showToast: true,
      showSystem: false,
    );
  }
}
