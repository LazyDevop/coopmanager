/// Modèle pour les paramètres de modules et sécurité
class ModuleSettingsModel {
  final Map<String, bool> modulesActives;
  final bool verrouillageParametrage;
  final bool auditLogsActif;
  final int? dureeConservationLogsJours;
  final List<String>? ipAutorisees;
  final bool authentificationDoubleFacteur;
  final int? dureeSessionMinutes;

  ModuleSettingsModel({
    this.modulesActives = const {},
    this.verrouillageParametrage = false,
    this.auditLogsActif = true,
    this.dureeConservationLogsJours = 365,
    this.ipAutorisees,
    this.authentificationDoubleFacteur = false,
    this.dureeSessionMinutes = 30,
  });

  factory ModuleSettingsModel.fromMap(Map<String, dynamic> map) {
    // Helper functions for safe type conversion
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    bool parseBool(dynamic value, {bool defaultValue = false}) {
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

    final modules = <String, bool>{};
    if (map['modules_actives'] != null && map['modules_actives'] is Map) {
      final modulesMap = map['modules_actives'] as Map<String, dynamic>;
      modulesMap.forEach((key, value) {
        modules[key] = parseBool(value);
      });
    }

    return ModuleSettingsModel(
      modulesActives: modules,
      verrouillageParametrage: parseBool(map['verrouillage_parametrage']),
      auditLogsActif: parseBool(map['audit_logs_actif'], defaultValue: true),
      dureeConservationLogsJours: parseInt(map['duree_conservation_logs_jours']) ?? 365,
      ipAutorisees: map['ip_autorisees'] != null
          ? List<String>.from(map['ip_autorisees'])
          : null,
      authentificationDoubleFacteur: parseBool(map['authentification_double_facteur']),
      dureeSessionMinutes: parseInt(map['duree_session_minutes']) ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    final modulesMap = <String, int>{};
    modulesActives.forEach((key, value) {
      modulesMap[key] = value ? 1 : 0;
    });

    return {
      'modules_actives': modulesMap,
      'verrouillage_parametrage': verrouillageParametrage ? 1 : 0,
      'audit_logs_actif': auditLogsActif ? 1 : 0,
      'duree_conservation_logs_jours': dureeConservationLogsJours,
      if (ipAutorisees != null) 'ip_autorisees': ipAutorisees,
      'authentification_double_facteur': authentificationDoubleFacteur ? 1 : 0,
      'duree_session_minutes': dureeSessionMinutes,
    };
  }

  ModuleSettingsModel copyWith({
    Map<String, bool>? modulesActives,
    bool? verrouillageParametrage,
    bool? auditLogsActif,
    int? dureeConservationLogsJours,
    List<String>? ipAutorisees,
    bool? authentificationDoubleFacteur,
    int? dureeSessionMinutes,
  }) {
    return ModuleSettingsModel(
      modulesActives: modulesActives ?? this.modulesActives,
      verrouillageParametrage: verrouillageParametrage ?? this.verrouillageParametrage,
      auditLogsActif: auditLogsActif ?? this.auditLogsActif,
      dureeConservationLogsJours: dureeConservationLogsJours ?? this.dureeConservationLogsJours,
      ipAutorisees: ipAutorisees ?? this.ipAutorisees,
      authentificationDoubleFacteur: authentificationDoubleFacteur ?? this.authentificationDoubleFacteur,
      dureeSessionMinutes: dureeSessionMinutes ?? this.dureeSessionMinutes,
    );
  }
}

