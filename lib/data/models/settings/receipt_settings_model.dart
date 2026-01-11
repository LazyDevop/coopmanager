/// Modèle pour les paramètres de recettes et commissions
class ReceiptSettingsModel {
  final List<CommissionTypeModel> typesCommissions;
  final double tauxRetenueSociale;
  final double tauxRetenueCapital;
  final List<String> ordreCalcul; // Ordre d'application des retenues
  final bool calculAutomatique;

  ReceiptSettingsModel({
    this.typesCommissions = const [],
    this.tauxRetenueSociale = 0.0,
    this.tauxRetenueCapital = 0.0,
    this.ordreCalcul = const [],
    this.calculAutomatique = true,
  });

  factory ReceiptSettingsModel.fromMap(Map<String, dynamic> map) {
    // Helper functions for safe type conversion
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

    return ReceiptSettingsModel(
      typesCommissions: map['types_commissions'] != null && map['types_commissions'] is List
          ? (map['types_commissions'] as List)
              .map((e) => e is Map<String, dynamic>
                  ? CommissionTypeModel.fromMap(e)
                  : null)
              .whereType<CommissionTypeModel>()
              .toList()
          : [],
      tauxRetenueSociale: _parseDouble(map['taux_retenue_sociale']),
      tauxRetenueCapital: _parseDouble(map['taux_retenue_capital']),
      ordreCalcul: map['ordre_calcul'] != null && map['ordre_calcul'] is List
          ? List<String>.from(map['ordre_calcul'])
          : [],
      calculAutomatique: _parseBool(map['calcul_automatique'], defaultValue: true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'types_commissions': typesCommissions.map((e) => e.toMap()).toList(),
      'taux_retenue_sociale': tauxRetenueSociale,
      'taux_retenue_capital': tauxRetenueCapital,
      'ordre_calcul': ordreCalcul,
      'calcul_automatique': calculAutomatique ? 1 : 0,
    };
  }

  ReceiptSettingsModel copyWith({
    List<CommissionTypeModel>? typesCommissions,
    double? tauxRetenueSociale,
    double? tauxRetenueCapital,
    List<String>? ordreCalcul,
    bool? calculAutomatique,
  }) {
    return ReceiptSettingsModel(
      typesCommissions: typesCommissions ?? this.typesCommissions,
      tauxRetenueSociale: tauxRetenueSociale ?? this.tauxRetenueSociale,
      tauxRetenueCapital: tauxRetenueCapital ?? this.tauxRetenueCapital,
      ordreCalcul: ordreCalcul ?? this.ordreCalcul,
      calculAutomatique: calculAutomatique ?? this.calculAutomatique,
    );
  }
}

/// Modèle pour un type de commission
class CommissionTypeModel {
  final String code;
  final String libelle;
  final double taux;
  final String? categorieAdherent; // null = tous

  CommissionTypeModel({
    required this.code,
    required this.libelle,
    required this.taux,
    this.categorieAdherent,
  });

  factory CommissionTypeModel.fromMap(Map<String, dynamic> map) {
    // Helper functions for safe type conversion
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

    double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      if (value is num) return value.toDouble();
      return defaultValue;
    }

    return CommissionTypeModel(
      code: _parseStringRequired(map['code'], ''),
      libelle: _parseStringRequired(map['libelle'], ''),
      taux: _parseDouble(map['taux']),
      categorieAdherent: _parseString(map['categorie_adherent']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'libelle': libelle,
      'taux': taux,
      if (categorieAdherent != null) 'categorie_adherent': categorieAdherent,
    };
  }
}

