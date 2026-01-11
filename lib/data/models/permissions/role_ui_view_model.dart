/// Modèle pour la liaison rôle-vue UI (droits d'accès)
class RoleUIViewModel {
  final String id;
  final String roleId;
  final String uiViewId;
  final bool canRead;
  final bool canWrite;
  final bool canDelete;
  final DateTime createdAt;

  RoleUIViewModel({
    required this.id,
    required this.roleId,
    required this.uiViewId,
    this.canRead = true,
    this.canWrite = false,
    this.canDelete = false,
    required this.createdAt,
  });

  factory RoleUIViewModel.fromMap(Map<String, dynamic> map) {
    return RoleUIViewModel(
      id: map['id'] as String,
      roleId: map['role_id'] as String,
      uiViewId: map['ui_view_id'] as String,
      canRead: (map['can_read'] as int? ?? 1) == 1,
      canWrite: (map['can_write'] as int? ?? 0) == 1,
      canDelete: (map['can_delete'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role_id': roleId,
      'ui_view_id': uiViewId,
      'can_read': canRead ? 1 : 0,
      'can_write': canWrite ? 1 : 0,
      'can_delete': canDelete ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

