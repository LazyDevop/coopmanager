/// Modèle pour les paramètres de comptabilité
class AccountingSettingsModel {
  final String? exerciceActif;
  final double soldeInitialCaisse;
  final double soldeInitialBanque;
  final double tauxFraisGestion;
  final double tauxReserve;
  final String? compteCaisse;
  final String? compteBanque;
  final String? compteVente;
  final String? compteRecette;
  final String? compteCommission;

  AccountingSettingsModel({
    this.exerciceActif,
    this.soldeInitialCaisse = 0.0,
    this.soldeInitialBanque = 0.0,
    this.tauxFraisGestion = 0.0,
    this.tauxReserve = 0.0,
    this.compteCaisse,
    this.compteBanque,
    this.compteVente,
    this.compteRecette,
    this.compteCommission,
  });

  factory AccountingSettingsModel.fromMap(Map<String, dynamic> map) {
    // Helper functions for safe type conversion
    String? parseString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      if (value is num) return value.toDouble();
      return defaultValue;
    }

    return AccountingSettingsModel(
      exerciceActif: parseString(map['exercice_actif']),
      soldeInitialCaisse: parseDouble(map['solde_initial_caisse']),
      soldeInitialBanque: parseDouble(map['solde_initial_banque']),
      tauxFraisGestion: parseDouble(map['taux_frais_gestion']),
      tauxReserve: parseDouble(map['taux_reserve']),
      compteCaisse: parseString(map['compte_caisse']),
      compteBanque: parseString(map['compte_banque']),
      compteVente: parseString(map['compte_vente']),
      compteRecette: parseString(map['compte_recette']),
      compteCommission: parseString(map['compte_commission']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (exerciceActif != null) 'exercice_actif': exerciceActif,
      'solde_initial_caisse': soldeInitialCaisse,
      'solde_initial_banque': soldeInitialBanque,
      'taux_frais_gestion': tauxFraisGestion,
      'taux_reserve': tauxReserve,
      if (compteCaisse != null) 'compte_caisse': compteCaisse,
      if (compteBanque != null) 'compte_banque': compteBanque,
      if (compteVente != null) 'compte_vente': compteVente,
      if (compteRecette != null) 'compte_recette': compteRecette,
      if (compteCommission != null) 'compte_commission': compteCommission,
    };
  }

  AccountingSettingsModel copyWith({
    String? exerciceActif,
    double? soldeInitialCaisse,
    double? soldeInitialBanque,
    double? tauxFraisGestion,
    double? tauxReserve,
    String? compteCaisse,
    String? compteBanque,
    String? compteVente,
    String? compteRecette,
    String? compteCommission,
  }) {
    return AccountingSettingsModel(
      exerciceActif: exerciceActif ?? this.exerciceActif,
      soldeInitialCaisse: soldeInitialCaisse ?? this.soldeInitialCaisse,
      soldeInitialBanque: soldeInitialBanque ?? this.soldeInitialBanque,
      tauxFraisGestion: tauxFraisGestion ?? this.tauxFraisGestion,
      tauxReserve: tauxReserve ?? this.tauxReserve,
      compteCaisse: compteCaisse ?? this.compteCaisse,
      compteBanque: compteBanque ?? this.compteBanque,
      compteVente: compteVente ?? this.compteVente,
      compteRecette: compteRecette ?? this.compteRecette,
      compteCommission: compteCommission ?? this.compteCommission,
    );
  }
}

