/// Modèle pour les paramètres sociaux
class SocialSettingsModel {
  final List<AideSocialeTypeModel> typesAides;
  final bool validationRequise;
  final int? utilisateurValidateurId;

  SocialSettingsModel({
    this.typesAides = const [],
    this.validationRequise = true,
    this.utilisateurValidateurId,
  });

  factory SocialSettingsModel.fromMap(Map<String, dynamic> map) {
    // Helper function for safe int parsing
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

    return SocialSettingsModel(
      typesAides: map['types_aides'] != null && map['types_aides'] is List
          ? (map['types_aides'] as List)
              .map((e) => e is Map<String, dynamic> 
                  ? AideSocialeTypeModel.fromMap(e)
                  : null)
              .whereType<AideSocialeTypeModel>()
              .toList()
          : [],
      validationRequise: _parseBool(map['validation_requise'], defaultValue: true),
      utilisateurValidateurId: _parseInt(map['utilisateur_validateur_id']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'types_aides': typesAides.map((e) => e.toMap()).toList(),
      'validation_requise': validationRequise ? 1 : 0,
      if (utilisateurValidateurId != null) 'utilisateur_validateur_id': utilisateurValidateurId,
    };
  }

  SocialSettingsModel copyWith({
    List<AideSocialeTypeModel>? typesAides,
    bool? validationRequise,
    int? utilisateurValidateurId,
  }) {
    return SocialSettingsModel(
      typesAides: typesAides ?? this.typesAides,
      validationRequise: validationRequise ?? this.validationRequise,
      utilisateurValidateurId: utilisateurValidateurId ?? this.utilisateurValidateurId,
    );
  }
}

/// Modèle pour un type d'aide sociale
class AideSocialeTypeModel {
  final String code;
  final String libelle;
  final double? plafond;
  final Map<String, dynamic>? conditionsEligibilite;
  final bool actif;

  AideSocialeTypeModel({
    required this.code,
    required this.libelle,
    this.plafond,
    this.conditionsEligibilite,
    this.actif = true,
  });

  factory AideSocialeTypeModel.fromMap(Map<String, dynamic> map) {
    // Helper functions for safe type conversion
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

    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
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

    return AideSocialeTypeModel(
      code: _parseStringRequired(map['code'], ''),
      libelle: _parseStringRequired(map['libelle'], ''),
      plafond: _parseDouble(map['plafond']),
      conditionsEligibilite: map['conditions_eligibilite'] is Map<String, dynamic>
          ? map['conditions_eligibilite'] as Map<String, dynamic>
          : null,
      actif: _parseBool(map['actif'], defaultValue: true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'libelle': libelle,
      if (plafond != null) 'plafond': plafond,
      if (conditionsEligibilite != null) 'conditions_eligibilite': conditionsEligibilite,
      'actif': actif ? 1 : 0,
    };
  }
}

