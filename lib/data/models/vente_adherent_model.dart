/// Modèle pour la table pivot vente_adherents
/// 
/// Représente la répartition d'une vente sur un adhérent spécifique
/// avec tous les calculs de commission et montants nets

class VenteAdherentModel {
  final int? id;
  final int venteId;
  final int adherentId;
  final double poidsUtilise; // Poids utilisé pour cet adhérent (en kg)
  final double prixKg; // Prix unitaire par kg
  final double montantBrut; // Montant brut (poids * prix)
  final double commissionRate; // Taux de commission appliqué
  final double commissionAmount; // Montant de la commission
  final double montantNet; // Montant net après commission
  final int? campagneId; // Campagne agricole
  final String? qualite; // Qualité du cacao
  final DateTime createdAt;
  final int? createdBy;

  VenteAdherentModel({
    this.id,
    required this.venteId,
    required this.adherentId,
    required this.poidsUtilise,
    required this.prixKg,
    required this.montantBrut,
    required this.commissionRate,
    required this.commissionAmount,
    required this.montantNet,
    this.campagneId,
    this.qualite,
    required this.createdAt,
    this.createdBy,
  });

  /// Calculer le montant brut
  static double calculateMontantBrut(double poidsUtilise, double prixKg) {
    return poidsUtilise * prixKg;
  }

  /// Calculer le montant de la commission
  static double calculateCommissionAmount(double montantBrut, double commissionRate) {
    return montantBrut * commissionRate;
  }

  /// Calculer le montant net
  static double calculateMontantNet(double montantBrut, double commissionRate) {
    return montantBrut - calculateCommissionAmount(montantBrut, commissionRate);
  }

  /// Créer depuis Map (base de données)
  factory VenteAdherentModel.fromMap(Map<String, dynamic> map) {
    return VenteAdherentModel(
      id: map['id'] as int?,
      venteId: map['vente_id'] as int,
      adherentId: map['adherent_id'] as int,
      poidsUtilise: (map['poids_utilise'] as num).toDouble(),
      prixKg: (map['prix_kg'] as num).toDouble(),
      montantBrut: (map['montant_brut'] as num).toDouble(),
      commissionRate: (map['commission_rate'] as num).toDouble(),
      commissionAmount: (map['commission_amount'] as num).toDouble(),
      montantNet: (map['montant_net'] as num).toDouble(),
      campagneId: map['campagne_id'] as int?,
      qualite: map['qualite'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as int?,
    );
  }

  /// Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vente_id': venteId,
      'adherent_id': adherentId,
      'poids_utilise': poidsUtilise,
      'prix_kg': prixKg,
      'montant_brut': montantBrut,
      'commission_rate': commissionRate,
      'commission_amount': commissionAmount,
      'montant_net': montantNet,
      if (campagneId != null) 'campagne_id': campagneId,
      if (qualite != null) 'qualite': qualite,
      'created_at': createdAt.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  /// Créer une copie avec des modifications
  VenteAdherentModel copyWith({
    int? id,
    int? venteId,
    int? adherentId,
    double? poidsUtilise,
    double? prixKg,
    double? montantBrut,
    double? commissionRate,
    double? commissionAmount,
    double? montantNet,
    int? campagneId,
    String? qualite,
    DateTime? createdAt,
    int? createdBy,
  }) {
    return VenteAdherentModel(
      id: id ?? this.id,
      venteId: venteId ?? this.venteId,
      adherentId: adherentId ?? this.adherentId,
      poidsUtilise: poidsUtilise ?? this.poidsUtilise,
      prixKg: prixKg ?? this.prixKg,
      montantBrut: montantBrut ?? this.montantBrut,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      montantNet: montantNet ?? this.montantNet,
      campagneId: campagneId ?? this.campagneId,
      qualite: qualite ?? this.qualite,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
