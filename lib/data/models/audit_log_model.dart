class AuditLogModel {
  final int? id;
  final int? userId;
  final String action;
  final String? entityType;
  final int? entityId;
  final String? details;
  final String? ipAddress;
  final DateTime createdAt;

  AuditLogModel({
    this.id,
    this.userId,
    required this.action,
    this.entityType,
    this.entityId,
    this.details,
    this.ipAddress,
    required this.createdAt,
  });

  // Convertir depuis Map (base de données)
  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      action: map['action'] as String,
      entityType: map['entity_type'] as String?,
      entityId: map['entity_id'] as int?,
      details: map['details'] as String?,
      ipAddress: map['ip_address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
      'ip_address': ipAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Actions d'audit prédéfinies
class AuditActions {
  static const String login = 'LOGIN';
  static const String logout = 'LOGOUT';
  static const String createUser = 'CREATE_USER';
  static const String updateUser = 'UPDATE_USER';
  static const String deleteUser = 'DELETE_USER';
  static const String activateUser = 'ACTIVATE_USER';
  static const String deactivateUser = 'DEACTIVATE_USER';
  static const String changeRole = 'CHANGE_ROLE';
  static const String resetPassword = 'RESET_PASSWORD';
}
