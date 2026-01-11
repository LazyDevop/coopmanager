/// Modèle de données pour une Simulation de Vente (V2)
/// 
/// Permet de simuler une vente avant validation avec comparaisons et indicateurs
class SimulationVenteModel {
  final int? id;
  final int? lotVenteId; // Si simulation basée sur un lot
  final int? clientId;
  final int? campagneId;
  final double quantiteTotal;
  final double prixUnitairePropose;
  final double montantBrut;
  final double montantCommission;
  final double montantNet;
  final double montantFondsSocial; // V2: Impact social
  final double prixMoyenJour; // Prix du jour pour comparaison
  final double prixMoyenPrecedent; // Prix moyen des ventes précédentes
  final double margeCooperative; // Marge de la coopérative
  final Map<String, dynamic> indicateurs; // Indicateurs calculés
  final String statut; // 'simulee', 'validee', 'rejetee'
  final String? notes;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime? dateValidation;

  SimulationVenteModel({
    this.id,
    this.lotVenteId,
    this.clientId,
    this.campagneId,
    required this.quantiteTotal,
    required this.prixUnitairePropose,
    required this.montantBrut,
    required this.montantCommission,
    required this.montantNet,
    required this.montantFondsSocial,
    required this.prixMoyenJour,
    required this.prixMoyenPrecedent,
    required this.margeCooperative,
    required this.indicateurs,
    this.statut = 'simulee',
    this.notes,
    this.createdBy,
    required this.createdAt,
    this.dateValidation,
  });

  bool get isSimulee => statut == 'simulee';
  bool get isValidee => statut == 'validee';
  bool get isRejetee => statut == 'rejetee';

  // Indicateurs de risque
  bool get isPrixHorsSeuil {
    final prixMin = indicateurs['prix_min'] as double?;
    final prixMax = indicateurs['prix_max'] as double?;
    if (prixMin != null && prixUnitairePropose < prixMin) return true;
    if (prixMax != null && prixUnitairePropose > prixMax) return true;
    return false;
  }

  bool get isPrixInferieurMoyenne => prixUnitairePropose < prixMoyenPrecedent;
  bool get isPrixSuperieurMoyenne => prixUnitairePropose > prixMoyenPrecedent;

  factory SimulationVenteModel.fromMap(Map<String, dynamic> map) {
    return SimulationVenteModel(
      id: map['id'] as int?,
      lotVenteId: map['lot_vente_id'] as int?,
      clientId: map['client_id'] as int?,
      campagneId: map['campagne_id'] as int?,
      quantiteTotal: (map['quantite_total'] as num).toDouble(),
      prixUnitairePropose: (map['prix_unitaire_propose'] as num).toDouble(),
      montantBrut: (map['montant_brut'] as num).toDouble(),
      montantCommission: (map['montant_commission'] as num).toDouble(),
      montantNet: (map['montant_net'] as num).toDouble(),
      montantFondsSocial: (map['montant_fonds_social'] as num?)?.toDouble() ?? 0.0,
      prixMoyenJour: (map['prix_moyen_jour'] as num?)?.toDouble() ?? 0.0,
      prixMoyenPrecedent: (map['prix_moyen_precedent'] as num?)?.toDouble() ?? 0.0,
      margeCooperative: (map['marge_cooperative'] as num?)?.toDouble() ?? 0.0,
      indicateurs: map['indicateurs'] as Map<String, dynamic>? ?? {},
      statut: map['statut'] as String? ?? 'simulee',
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      dateValidation: map['date_validation'] != null
          ? DateTime.parse(map['date_validation'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'lot_vente_id': lotVenteId,
      'client_id': clientId,
      'campagne_id': campagneId,
      'quantite_total': quantiteTotal,
      'prix_unitaire_propose': prixUnitairePropose,
      'montant_brut': montantBrut,
      'montant_commission': montantCommission,
      'montant_net': montantNet,
      'montant_fonds_social': montantFondsSocial,
      'prix_moyen_jour': prixMoyenJour,
      'prix_moyen_precedent': prixMoyenPrecedent,
      'marge_cooperative': margeCooperative,
      'indicateurs': indicateurs.toString(), // Stocker comme JSON string
      'statut': statut,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'date_validation': dateValidation?.toIso8601String(),
    };
  }

  SimulationVenteModel copyWith({
    int? id,
    int? lotVenteId,
    int? clientId,
    int? campagneId,
    double? quantiteTotal,
    double? prixUnitairePropose,
    double? montantBrut,
    double? montantCommission,
    double? montantNet,
    double? montantFondsSocial,
    double? prixMoyenJour,
    double? prixMoyenPrecedent,
    double? margeCooperative,
    Map<String, dynamic>? indicateurs,
    String? statut,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    DateTime? dateValidation,
  }) {
    return SimulationVenteModel(
      id: id ?? this.id,
      lotVenteId: lotVenteId ?? this.lotVenteId,
      clientId: clientId ?? this.clientId,
      campagneId: campagneId ?? this.campagneId,
      quantiteTotal: quantiteTotal ?? this.quantiteTotal,
      prixUnitairePropose: prixUnitairePropose ?? this.prixUnitairePropose,
      montantBrut: montantBrut ?? this.montantBrut,
      montantCommission: montantCommission ?? this.montantCommission,
      montantNet: montantNet ?? this.montantNet,
      montantFondsSocial: montantFondsSocial ?? this.montantFondsSocial,
      prixMoyenJour: prixMoyenJour ?? this.prixMoyenJour,
      prixMoyenPrecedent: prixMoyenPrecedent ?? this.prixMoyenPrecedent,
      margeCooperative: margeCooperative ?? this.margeCooperative,
      indicateurs: indicateurs ?? this.indicateurs,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      dateValidation: dateValidation ?? this.dateValidation,
    );
  }
}

