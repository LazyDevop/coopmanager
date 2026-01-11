/// Modèle pour les rôles
class RoleModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final bool isSystem;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RoleModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.isSystem = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      isSystem: (map['is_system'] as int? ?? 0) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      if (description != null) 'description': description,
      'is_system': isSystem ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

