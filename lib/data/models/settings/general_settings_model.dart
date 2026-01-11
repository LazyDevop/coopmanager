/// Modèle pour les paramètres généraux
class GeneralSettingsModel {
  final String devise;
  final String dateFormat;
  final bool offlineMode;
  final int sessionDurationMinutes;
  final bool notificationsEnabled;
  final String uiTheme;
  final bool autoBackup;
  final int backupIntervalDays;

  GeneralSettingsModel({
    this.devise = 'XAF',
    this.dateFormat = 'dd/MM/yyyy',
    this.offlineMode = false,
    this.sessionDurationMinutes = 30,
    this.notificationsEnabled = true,
    this.uiTheme = 'light',
    this.autoBackup = true,
    this.backupIntervalDays = 7,
  });

  factory GeneralSettingsModel.fromMap(Map<String, dynamic> map) {
    // Helper functions for safe type conversion
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    bool _parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        if (value.toLowerCase() == 'true' || value == '1') return true;
        if (value.toLowerCase() == 'false' || value == '0') return false;
        return defaultValue;
      }
      return defaultValue;
    }

    String? _parseString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    String _parseStringRequired(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      return value.toString();
    }

    return GeneralSettingsModel(
      devise: _parseStringRequired(map['devise'], 'XAF'),
      dateFormat: _parseStringRequired(map['date_format'], 'dd/MM/yyyy'),
      offlineMode: _parseBool(map['offline_mode'], defaultValue: false),
      sessionDurationMinutes: _parseInt(map['session_duration_minutes']) ?? 30,
      notificationsEnabled: _parseBool(map['notifications_enabled'], defaultValue: true),
      uiTheme: _parseStringRequired(map['ui_theme'], 'light'),
      autoBackup: _parseBool(map['auto_backup'], defaultValue: true),
      backupIntervalDays: _parseInt(map['backup_interval_days']) ?? 7,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'devise': devise,
      'date_format': dateFormat,
      'offline_mode': offlineMode ? 1 : 0,
      'session_duration_minutes': sessionDurationMinutes,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'ui_theme': uiTheme,
      'auto_backup': autoBackup ? 1 : 0,
      'backup_interval_days': backupIntervalDays,
    };
  }

  GeneralSettingsModel copyWith({
    String? devise,
    String? dateFormat,
    bool? offlineMode,
    int? sessionDurationMinutes,
    bool? notificationsEnabled,
    String? uiTheme,
    bool? autoBackup,
    int? backupIntervalDays,
  }) {
    return GeneralSettingsModel(
      devise: devise ?? this.devise,
      dateFormat: dateFormat ?? this.dateFormat,
      offlineMode: offlineMode ?? this.offlineMode,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      uiTheme: uiTheme ?? this.uiTheme,
      autoBackup: autoBackup ?? this.autoBackup,
      backupIntervalDays: backupIntervalDays ?? this.backupIntervalDays,
    );
  }
}

