/// Modèle pour les paramètres de ventes et prix
class SalesSettingsModel {
  final double prixMinimumCacao;
  final double prixMaximumCacao;
  final double? prixDuJour;
  final String modeValidationPrix; // 'auto', 'manuel', 'validation_requise'
  final double commissionCooperative;
  final List<String> retenuesAutomatiques; // ['social', 'capital', 'reserve']
  final bool alertePrixHorsPlage;
  final bool historiquePrixActif;

  SalesSettingsModel({
    required this.prixMinimumCacao,
    required this.prixMaximumCacao,
    this.prixDuJour,
    this.modeValidationPrix = 'auto',
    this.commissionCooperative = 0.05,
    this.retenuesAutomatiques = const [],
    this.alertePrixHorsPlage = true,
    this.historiquePrixActif = true,
  });

  factory SalesSettingsModel.fromMap(Map<String, dynamic> map) {
    // Helper functions for safe type conversion
    double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      if (value is num) return value.toDouble();
      return defaultValue;
    }

    String _parseStringRequired(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      return value.toString();
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

    return SalesSettingsModel(
      prixMinimumCacao: _parseDouble(map['prix_minimum_cacao']),
      prixMaximumCacao: _parseDouble(map['prix_maximum_cacao']),
      prixDuJour: map['prix_du_jour'] != null
          ? _parseDouble(map['prix_du_jour'])
          : null,
      modeValidationPrix: _parseStringRequired(map['mode_validation_prix'], 'auto'),
      commissionCooperative: _parseDouble(map['commission_cooperative'], defaultValue: 0.05),
      retenuesAutomatiques: map['retenues_automatiques'] != null && map['retenues_automatiques'] is List
          ? List<String>.from(map['retenues_automatiques'])
          : [],
      alertePrixHorsPlage: _parseBool(map['alerte_prix_hors_plage'], defaultValue: true),
      historiquePrixActif: _parseBool(map['historique_prix_actif'], defaultValue: true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prix_minimum_cacao': prixMinimumCacao,
      'prix_maximum_cacao': prixMaximumCacao,
      if (prixDuJour != null) 'prix_du_jour': prixDuJour,
      'mode_validation_prix': modeValidationPrix,
      'commission_cooperative': commissionCooperative,
      'retenues_automatiques': retenuesAutomatiques,
      'alerte_prix_hors_plage': alertePrixHorsPlage ? 1 : 0,
      'historique_prix_actif': historiquePrixActif ? 1 : 0,
    };
  }

  SalesSettingsModel copyWith({
    double? prixMinimumCacao,
    double? prixMaximumCacao,
    double? prixDuJour,
    String? modeValidationPrix,
    double? commissionCooperative,
    List<String>? retenuesAutomatiques,
    bool? alertePrixHorsPlage,
    bool? historiquePrixActif,
  }) {
    return SalesSettingsModel(
      prixMinimumCacao: prixMinimumCacao ?? this.prixMinimumCacao,
      prixMaximumCacao: prixMaximumCacao ?? this.prixMaximumCacao,
      prixDuJour: prixDuJour ?? this.prixDuJour,
      modeValidationPrix: modeValidationPrix ?? this.modeValidationPrix,
      commissionCooperative: commissionCooperative ?? this.commissionCooperative,
      retenuesAutomatiques: retenuesAutomatiques ?? this.retenuesAutomatiques,
      alertePrixHorsPlage: alertePrixHorsPlage ?? this.alertePrixHorsPlage,
      historiquePrixActif: historiquePrixActif ?? this.historiquePrixActif,
    );
  }

  bool isPrixValide(double prix) {
    return prix >= prixMinimumCacao && prix <= prixMaximumCacao;
  }
}

