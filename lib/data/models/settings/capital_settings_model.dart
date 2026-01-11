/// Modèle pour les paramètres du capital social
class CapitalSettingsModel {
  final double valeurPart;
  final int nombreMinParts;
  final int? nombreMaxParts;
  final bool liberationObligatoire;
  final int? delaiLiberationJours;
  final bool dividendesActives;
  final double? tauxDividende;

  CapitalSettingsModel({
    required this.valeurPart,
    required this.nombreMinParts,
    this.nombreMaxParts,
    this.liberationObligatoire = false,
    this.delaiLiberationJours,
    this.dividendesActives = false,
    this.tauxDividende,
  });

  factory CapitalSettingsModel.fromMap(Map<String, dynamic> map) {
    // Helper functions for safe type conversion
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      if (value is num) return value.toDouble();
      return defaultValue;
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

    return CapitalSettingsModel(
      valeurPart: _parseDouble(map['valeur_part']),
      nombreMinParts: _parseInt(map['nombre_min_parts']) ?? 1,
      nombreMaxParts: _parseInt(map['nombre_max_parts']),
      liberationObligatoire: _parseBool(map['liberation_obligatoire']),
      delaiLiberationJours: _parseInt(map['delai_liberation_jours']),
      dividendesActives: _parseBool(map['dividendes_actives']),
      tauxDividende: map['taux_dividende'] != null
          ? _parseDouble(map['taux_dividende'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'valeur_part': valeurPart,
      'nombre_min_parts': nombreMinParts,
      if (nombreMaxParts != null) 'nombre_max_parts': nombreMaxParts,
      'liberation_obligatoire': liberationObligatoire ? 1 : 0,
      if (delaiLiberationJours != null) 'delai_liberation_jours': delaiLiberationJours,
      'dividendes_actives': dividendesActives ? 1 : 0,
      if (tauxDividende != null) 'taux_dividende': tauxDividende,
    };
  }

  CapitalSettingsModel copyWith({
    double? valeurPart,
    int? nombreMinParts,
    int? nombreMaxParts,
    bool? liberationObligatoire,
    int? delaiLiberationJours,
    bool? dividendesActives,
    double? tauxDividende,
  }) {
    return CapitalSettingsModel(
      valeurPart: valeurPart ?? this.valeurPart,
      nombreMinParts: nombreMinParts ?? this.nombreMinParts,
      nombreMaxParts: nombreMaxParts ?? this.nombreMaxParts,
      liberationObligatoire: liberationObligatoire ?? this.liberationObligatoire,
      delaiLiberationJours: delaiLiberationJours ?? this.delaiLiberationJours,
      dividendesActives: dividendesActives ?? this.dividendesActives,
      tauxDividende: tauxDividende ?? this.tauxDividende,
    );
  }
}

