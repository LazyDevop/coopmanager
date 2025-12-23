class NotificationModel {
  final int? id;
  final String type; // 'info', 'success', 'warning', 'error', 'stock_low', 'vente', 'recette', etc.
  final String titre;
  final String message;
  final String? module; // 'stock', 'ventes', 'recettes', 'factures', etc.
  final String? entityType; // 'adherent', 'vente', 'recette', etc.
  final int? entityId;
  final int? userId; // null pour notifications globales
  final bool isRead;
  final String priority; // 'low', 'normal', 'high', 'critical'
  final DateTime createdAt;

  NotificationModel({
    this.id,
    required this.type,
    required this.titre,
    required this.message,
    this.module,
    this.entityType,
    this.entityId,
    this.userId,
    this.isRead = false,
    this.priority = 'normal',
    required this.createdAt,
  });

  bool get isUnread => !isRead;
  bool get isHighPriority => priority == 'high' || priority == 'critical';
  bool get isCritical => priority == 'critical';

  // Convertir depuis Map (base de données)
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      titre: map['titre'] as String,
      message: map['message'] as String,
      module: map['module'] as String?,
      entityType: map['entity_type'] as String?,
      entityId: map['entity_id'] as int?,
      userId: map['user_id'] as int?,
      isRead: (map['is_read'] as int? ?? 0) == 1,
      priority: map['priority'] as String? ?? 'normal',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'titre': titre,
      'message': message,
      'module': module,
      'entity_type': entityType,
      'entity_id': entityId,
      'user_id': userId,
      'is_read': isRead ? 1 : 0,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  NotificationModel copyWith({
    int? id,
    String? type,
    String? titre,
    String? message,
    String? module,
    String? entityType,
    int? entityId,
    int? userId,
    bool? isRead,
    String? priority,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      titre: titre ?? this.titre,
      message: message ?? this.message,
      module: module ?? this.module,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      userId: userId ?? this.userId,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
