class RecetteModel {
  final int? id;
  final int adherentId;
  final int? venteId;
  final double montantBrut;
  final double commissionRate; // Taux de commission (ex: 0.05 pour 5%)
  final double commissionAmount;
  final double montantNet;
  final DateTime dateRecette;
  final String? notes;
  final int? createdBy;
  final DateTime createdAt;
  
  // V2: Nouveaux champs
  final int? ecritureComptableId; // Lien avec écriture comptable
  final String? qrCodeHash; // Hash QR Code pour sécurité

  RecetteModel({
    this.id,
    required this.adherentId,
    this.venteId,
    required this.montantBrut,
    required this.commissionRate,
    required this.commissionAmount,
    required this.montantNet,
    required this.dateRecette,
    this.notes,
    this.createdBy,
    required this.createdAt,
    // V2: Nouveaux champs
    this.ecritureComptableId,
    this.qrCodeHash,
  });

  // Calculer la recette nette
  static double calculateMontantNet(double montantBrut, double commissionRate) {
    return montantBrut - (montantBrut * commissionRate);
  }

  // Calculer le montant de la commission
  static double calculateCommissionAmount(double montantBrut, double commissionRate) {
    return montantBrut * commissionRate;
  }

  // Convertir depuis Map (base de données)
  factory RecetteModel.fromMap(Map<String, dynamic> map) {
    return RecetteModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      venteId: map['vente_id'] as int?,
      montantBrut: (map['montant_brut'] as num).toDouble(),
      commissionRate: (map['commission_rate'] as num).toDouble(),
      commissionAmount: (map['commission_amount'] as num).toDouble(),
      montantNet: (map['montant_net'] as num).toDouble(),
      dateRecette: DateTime.parse(map['date_recette'] as String),
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      // V2: Nouveaux champs
      ecritureComptableId: map['ecriture_comptable_id'] as int?,
      qrCodeHash: map['qr_code_hash'] as String?,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      if (venteId != null) 'vente_id': venteId,
      'montant_brut': montantBrut,
      'commission_rate': commissionRate,
      'commission_amount': commissionAmount,
      'montant_net': montantNet,
      'date_recette': dateRecette.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      // V2: Nouveaux champs
      'ecriture_comptable_id': ecritureComptableId,
      'qr_code_hash': qrCodeHash,
    };
  }

  // Créer une copie avec des modifications
  RecetteModel copyWith({
    int? id,
    int? adherentId,
    int? venteId,
    double? montantBrut,
    double? commissionRate,
    double? commissionAmount,
    double? montantNet,
    DateTime? dateRecette,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    int? ecritureComptableId,
    String? qrCodeHash,
  }) {
    return RecetteModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      venteId: venteId ?? this.venteId,
      montantBrut: montantBrut ?? this.montantBrut,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      montantNet: montantNet ?? this.montantNet,
      dateRecette: dateRecette ?? this.dateRecette,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      // V2: Nouveaux champs
      ecritureComptableId: ecritureComptableId ?? this.ecritureComptableId,
      qrCodeHash: qrCodeHash ?? this.qrCodeHash,
    );
  }
}

/// Modèle pour le résumé des recettes d'un adhérent
class RecetteSummaryModel {
  final int adherentId;
  final String adherentCode;
  final String adherentNom;
  final String adherentPrenom;
  final double totalMontantBrut;
  final double totalCommission;
  final double totalMontantNet;
  final int nombreRecettes;
  final DateTime? derniereRecette;

  RecetteSummaryModel({
    required this.adherentId,
    required this.adherentCode,
    required this.adherentNom,
    required this.adherentPrenom,
    required this.totalMontantBrut,
    required this.totalCommission,
    required this.totalMontantNet,
    required this.nombreRecettes,
    this.derniereRecette,
  });

  String get adherentFullName => '$adherentPrenom $adherentNom';
}

