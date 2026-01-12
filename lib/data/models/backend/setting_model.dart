/// Modèle de données pour les settings (backend multi-coopérative)
import 'package:uuid/uuid.dart';

enum SettingValueType { string, int, double, bool, json }

class SettingModel {
  final String id;
  final String? cooperativeId; // null = setting global
  final String category; // finance, vente, coop, sécurité, etc.
  final String key;
  final String? value;
  final SettingValueType valueType;
  final String? description; // Description du paramètre
  final bool isActive; // Actif/Inactif
  final bool editable; // Modifiable ou non
  final DateTime createdAt;
  final DateTime? updatedAt;

  SettingModel({
    String? id,
    this.cooperativeId,
    required this.category,
    required this.key,
    this.value,
    this.valueType = SettingValueType.string,
    this.description,
    this.isActive = true,
    this.editable = true,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory SettingModel.fromMap(Map<String, dynamic> map) {
    return SettingModel(
      id: map['id'] as String,
      cooperativeId: map['cooperative_id'] as String?,
      category: map['category'] as String,
      key: map['key'] as String,
      value: map['value'] as String?,
      valueType: SettingValueType.values.firstWhere(
        (e) => e.name == (map['value_type'] as String? ?? 'string'),
        orElse: () => SettingValueType.string,
      ),
      description: map['description'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      editable: (map['editable'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (cooperativeId != null) 'cooperative_id': cooperativeId,
      'category': category,
      'key': key,
      if (value != null) 'value': value,
      'value_type': valueType.name,
      if (description != null) 'description': description,
      'is_active': isActive ? 1 : 0,
      'editable': editable ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Convertir la valeur selon son type
  dynamic getTypedValue() {
    if (value == null) return null;
    
    switch (valueType) {
      case SettingValueType.int:
        return int.tryParse(value!);
      case SettingValueType.double:
        return double.tryParse(value!);
      case SettingValueType.bool:
        return value!.toLowerCase() == 'true' || value == '1';
      case SettingValueType.json:
        // Le parsing JSON se fera ailleurs si nécessaire
        return value;
      case SettingValueType.string:
      default:
        return value;
    }
  }

  /// Convertir une valeur en string pour stockage
  static String valueToString(dynamic value, SettingValueType type) {
    switch (type) {
      case SettingValueType.bool:
        return (value == true || value == 1 || value == '1' || value == 'true') ? 'true' : 'false';
      case SettingValueType.int:
      case SettingValueType.double:
      case SettingValueType.string:
      case SettingValueType.json:
      default:
        return value.toString();
    }
  }

  SettingModel copyWith({
    String? id,
    String? cooperativeId,
    String? category,
    String? key,
    String? value,
    SettingValueType? valueType,
    String? description,
    bool? isActive,
    bool? editable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SettingModel(
      id: id ?? this.id,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      category: category ?? this.category,
      key: key ?? this.key,
      value: value ?? this.value,
      valueType: valueType ?? this.valueType,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      editable: editable ?? this.editable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

