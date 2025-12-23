/// Modèle de données pour une Part Sociale
class PartSocialeModel {
  final int? id;
  final int adherentId;
  final int nombreParts;
  final double valeurUnitaire;
  final DateTime dateAcquisition;
  final DateTime? dateCession;
  final String statut; // 'actif', 'cede', 'annule'
  final int? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PartSocialeModel({
    this.id,
    required this.adherentId,
    required this.nombreParts,
    required this.valeurUnitaire,
    required this.dateAcquisition,
    this.dateCession,
    this.statut = 'actif',
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  double get valeurTotale => nombreParts * valeurUnitaire;
  bool get isActif => statut == 'actif';
  bool get isCede => statut == 'cede';
  bool get isAnnule => statut == 'annule';

  // Convertir depuis Map (base de données)
  factory PartSocialeModel.fromMap(Map<String, dynamic> map) {
    return PartSocialeModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      nombreParts: map['nombre_parts'] as int,
      valeurUnitaire: (map['valeur_unitaire'] as num).toDouble(),
      dateAcquisition: DateTime.parse(map['date_acquisition'] as String),
      dateCession: map['date_cession'] != null
          ? DateTime.parse(map['date_cession'] as String)
          : null,
      statut: map['statut'] as String? ?? 'actif',
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      'nombre_parts': nombreParts,
      'valeur_unitaire': valeurUnitaire,
      'date_acquisition': dateAcquisition.toIso8601String(),
      'date_cession': dateCession?.toIso8601String(),
      'statut': statut,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  PartSocialeModel copyWith({
    int? id,
    int? adherentId,
    int? nombreParts,
    double? valeurUnitaire,
    DateTime? dateAcquisition,
    DateTime? dateCession,
    String? statut,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PartSocialeModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      nombreParts: nombreParts ?? this.nombreParts,
      valeurUnitaire: valeurUnitaire ?? this.valeurUnitaire,
      dateAcquisition: dateAcquisition ?? this.dateAcquisition,
      dateCession: dateCession ?? this.dateCession,
      statut: statut ?? this.statut,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Résumé du capital social
class CapitalSocialSummary {
  final int totalParts;
  final double valeurUnitaire;
  final double capitalTotal;
  final int nombreActionnaires;
  final int nombrePartsActives;

  CapitalSocialSummary({
    required this.totalParts,
    required this.valeurUnitaire,
    required this.capitalTotal,
    required this.nombreActionnaires,
    required this.nombrePartsActives,
  });
}

