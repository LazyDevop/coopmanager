/// Modèle pour les vues UI (interfaces de l'application)
class UIViewModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String route;
  final String? icon;
  final String? category;
  final bool requiresRead;
  final bool requiresWrite;
  final String? parentViewId;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UIViewModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.route,
    this.icon,
    this.category,
    this.requiresRead = true,
    this.requiresWrite = false,
    this.parentViewId,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory UIViewModel.fromMap(Map<String, dynamic> map) {
    return UIViewModel(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      route: map['route'] as String,
      icon: map['icon'] as String?,
      category: map['category'] as String?,
      requiresRead: (map['requires_read'] as int? ?? 1) == 1,
      requiresWrite: (map['requires_write'] as int? ?? 0) == 1,
      parentViewId: map['parent_view_id'] as String?,
      displayOrder: map['display_order'] as int? ?? 0,
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
      'route': route,
      if (icon != null) 'icon': icon,
      if (category != null) 'category': category,
      'requires_read': requiresRead ? 1 : 0,
      'requires_write': requiresWrite ? 1 : 0,
      if (parentViewId != null) 'parent_view_id': parentViewId,
      'display_order': displayOrder,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

