import 'dart:async';
import '../../data/dto/sync_queue_item.dart';
import '../../data/dto/api_response.dart';
import '../api/api_client.dart';
import '../database/db_initializer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'error_handler.dart';

/// Service de synchronisation offline ↔ backend
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ApiClient _apiClient = ApiClient();
  Database? _database;
  Timer? _syncTimer;
  bool _isSyncing = false;
  final int maxRetries = 3;

  /// Initialiser le service de synchronisation
  Future<void> initialize() async {
    _database = await DatabaseInitializer.database;
    await _createSyncTable();
    _startPeriodicSync();
  }

  /// Créer la table de synchronisation
  Future<void> _createSyncTable() async {
    await _database?.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        module TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced_at TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0,
        local_id TEXT
      )
    ''');
  }

  /// Ajouter un élément à la queue de synchronisation
  Future<int> addToQueue({
    required String action,
    required String module,
    required String endpoint,
    required Map<String, dynamic> data,
    Map<String, dynamic>? localId,
  }) async {
    final item = SyncQueueItem(
      action: action,
      module: module,
      endpoint: endpoint,
      data: data,
      createdAt: DateTime.now(),
      localId: localId,
    );

    final id = await _database?.insert(
      'sync_queue',
      item.toMap(),
    );

    // Tenter une synchronisation immédiate si en ligne
    if (await _isOnline()) {
      unawaited(syncQueue());
    }

    return id ?? 0;
  }

  /// Synchroniser la queue avec le backend
  Future<void> syncQueue() async {
    if (_isSyncing) return;
    if (!await _isOnline()) return;

    _isSyncing = true;

    try {
      final items = await _getPendingItems();

      for (final item in items) {
        try {
          await _syncItem(item);
        } catch (e) {
          await _handleSyncError(item, e);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Obtenir les éléments en attente de synchronisation
  Future<List<SyncQueueItem>> _getPendingItems() async {
    final maps = await _database?.query(
      'sync_queue',
      where: 'is_synced = ? AND retry_count < ?',
      whereArgs: [0, maxRetries],
      orderBy: 'created_at ASC',
      limit: 50, // Traiter par lots de 50
    );

    return maps?.map((map) => SyncQueueItem.fromMap(map)).toList() ?? [];
  }

  /// Synchroniser un élément individuel
  Future<void> _syncItem(SyncQueueItem item) async {
    Map<String, dynamic> response;

    switch (item.action) {
      case 'create':
        response = await _apiClient.post(item.endpoint, item.data);
        break;
      case 'update':
        response = await _apiClient.put(item.endpoint, item.data);
        break;
      case 'delete':
        await _apiClient.delete(item.endpoint);
        response = {'success': true};
        break;
      default:
        throw Exception('Action non supportée: ${item.action}');
    }

    // Vérifier la réponse
    final apiResponse = ApiResponse.fromJson(response, null);
    if (!apiResponse.success) {
      throw Exception(apiResponse.message);
    }

    // Marquer comme synchronisé
    await _database?.update(
      'sync_queue',
      {
        'is_synced': 1,
        'synced_at': DateTime.now().toIso8601String(),
        'error_message': null,
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );

    // Mapper l'ID local à l'ID serveur si nécessaire
    if (item.localId != null && apiResponse.data is Map) {
      final serverId = (apiResponse.data as Map)['id'];
      if (serverId != null) {
        // Notifier les repositories pour mettre à jour les IDs locaux
        // Cette logique sera implémentée dans les repositories spécifiques
      }
    }
  }

  /// Gérer les erreurs de synchronisation
  Future<void> _handleSyncError(SyncQueueItem item, dynamic error) async {
    final apiError = ErrorHandler.handleException(error);
    final newRetryCount = item.retryCount + 1;

    await _database?.update(
      'sync_queue',
      {
        'retry_count': newRetryCount,
        'error_message': apiError.message,
        'is_synced': newRetryCount >= maxRetries ? 1 : 0, // Marquer comme échoué après max retries
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Vérifier si l'appareil est en ligne
  Future<bool> _isOnline() async {
    try {
      // Tenter une requête HEAD simple
      await _apiClient.get('/api/v1/health', includeAuth: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Vérifier si l'appareil est en ligne (méthode publique)
  Future<bool> isOnline() async {
    return _isOnline();
  }

  /// Démarrer la synchronisation périodique
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncQueue();
    });
  }

  /// Arrêter la synchronisation périodique
  void stopPeriodicSync() {
    _syncTimer?.cancel();
  }

  /// Obtenir les statistiques de synchronisation
  Future<Map<String, dynamic>> getSyncStats() async {
    final total = await _database?.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue',
    );
    final pending = await _database?.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE is_synced = 0',
    );
    final failed = await _database?.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE is_synced = 0 AND retry_count >= ?',
      [maxRetries],
    );

    return {
      'total': total?.first['count'] ?? 0,
      'pending': pending?.first['count'] ?? 0,
      'failed': failed?.first['count'] ?? 0,
      'synced': (total?.first['count'] ?? 0) - (pending?.first['count'] ?? 0),
    };
  }

  /// Nettoyer les éléments synchronisés anciens (plus de 30 jours)
  Future<void> cleanupOldSyncedItems() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    await _database?.delete(
      'sync_queue',
      where: 'is_synced = 1 AND synced_at < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );
  }
}

/// Helper pour éviter les warnings sur les futures non attendus
void unawaited(Future<void> future) {
  // Ignore
}

