/// Élément de la queue de synchronisation offline
class SyncQueueItem {
  final int? id;
  final String action; // 'create', 'update', 'delete'
  final String module; // 'vente', 'adherent', 'stock', etc.
  final String endpoint;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final bool isSynced;
  final String? errorMessage;
  final int retryCount;
  final Map<String, dynamic>? localId; // Pour mapper l'ID local à l'ID serveur

  SyncQueueItem({
    this.id,
    required this.action,
    required this.module,
    required this.endpoint,
    required this.data,
    required this.createdAt,
    this.syncedAt,
    this.isSynced = false,
    this.errorMessage,
    this.retryCount = 0,
    this.localId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'module': module,
      'endpoint': endpoint,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'error_message': errorMessage,
      'retry_count': retryCount,
      'local_id': localId?.toString(),
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int?,
      action: map['action'] as String,
      module: map['module'] as String,
      endpoint: map['endpoint'] as String,
      data: map['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(map['created_at'] as String),
      syncedAt: map['synced_at'] != null 
          ? DateTime.parse(map['synced_at'] as String) 
          : null,
      isSynced: (map['is_synced'] as int) == 1,
      errorMessage: map['error_message'] as String?,
      retryCount: map['retry_count'] as int? ?? 0,
      localId: map['local_id'] != null 
          ? Map<String, dynamic>.from(map['local_id'] as Map) 
          : null,
    );
  }

  SyncQueueItem copyWith({
    int? id,
    String? action,
    String? module,
    String? endpoint,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? syncedAt,
    bool? isSynced,
    String? errorMessage,
    int? retryCount,
    Map<String, dynamic>? localId,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      action: action ?? this.action,
      module: module ?? this.module,
      endpoint: endpoint ?? this.endpoint,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      isSynced: isSynced ?? this.isSynced,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      localId: localId ?? this.localId,
    );
  }
}

