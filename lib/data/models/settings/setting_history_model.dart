/// Modèle pour l'historique des modifications de paramètres
class SettingHistoryModel {
  final int? id;
  final String category;
  final String key;
  final String? oldValue;
  final String? newValue;
  final int userId;
  final String? userName;
  final String? reason;
  final DateTime changedAt;

  SettingHistoryModel({
    this.id,
    required this.category,
    required this.key,
    this.oldValue,
    this.newValue,
    required this.userId,
    this.userName,
    this.reason,
    required this.changedAt,
  });

  factory SettingHistoryModel.fromMap(Map<String, dynamic> map) {
    // Helper functions for safe type conversion
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    int parseIntRequired(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is num) return value.toInt();
      return defaultValue;
    }

    String parseStringRequired(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      return value.toString();
    }

    String? parseString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final changedAtValue = parseDateTime(map['changed_at']);
    if (changedAtValue == null) {
      throw const FormatException('changed_at is required and must be a valid date');
    }

    return SettingHistoryModel(
      id: parseInt(map['id']),
      category: parseStringRequired(map['category'], ''),
      key: parseStringRequired(map['key'], ''),
      oldValue: parseString(map['old_value']),
      newValue: parseString(map['new_value']),
      userId: parseIntRequired(map['user_id']),
      userName: parseString(map['user_name']),
      reason: parseString(map['reason']),
      changedAt: changedAtValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'key': key,
      if (oldValue != null) 'old_value': oldValue,
      if (newValue != null) 'new_value': newValue,
      'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (reason != null) 'reason': reason,
      'changed_at': changedAt.toIso8601String(),
    };
  }
}

