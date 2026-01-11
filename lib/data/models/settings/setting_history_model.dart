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
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    int _parseIntRequired(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is num) return value.toInt();
      return defaultValue;
    }

    String _parseStringRequired(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      return value.toString();
    }

    String? _parseString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final changedAtValue = _parseDateTime(map['changed_at']);
    if (changedAtValue == null) {
      throw FormatException('changed_at is required and must be a valid date');
    }

    return SettingHistoryModel(
      id: _parseInt(map['id']),
      category: _parseStringRequired(map['category'], ''),
      key: _parseStringRequired(map['key'], ''),
      oldValue: _parseString(map['old_value']),
      newValue: _parseString(map['new_value']),
      userId: _parseIntRequired(map['user_id']),
      userName: _parseString(map['user_name']),
      reason: _parseString(map['reason']),
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

