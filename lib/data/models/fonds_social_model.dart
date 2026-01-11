/// Modèle de données pour le Fonds Social (V2)
/// 
/// Gestion de l'impact social avec pourcentage ou montant affecté au fonds social
class FondsSocialModel {
  final int? id;
  final int? venteId; // Lien avec la vente
  final String source; // 'vente', 'don', 'autre'
  final double montant;
  final double? pourcentage; // Si calculé en pourcentage
  final String description;
  final DateTime dateContribution;
  final String? notes;
  final int? createdBy;
  final DateTime createdAt;
  final int? ecritureComptableId; // Écriture comptable automatique

  FondsSocialModel({
    this.id,
    this.venteId,
    required this.source,
    required this.montant,
    this.pourcentage,
    required this.description,
    required this.dateContribution,
    this.notes,
    this.createdBy,
    required this.createdAt,
    this.ecritureComptableId,
  });

  bool get isFromVente => source == 'vente';
  bool get isFromDon => source == 'don';

  factory FondsSocialModel.fromMap(Map<String, dynamic> map) {
    return FondsSocialModel(
      id: map['id'] as int?,
      venteId: map['vente_id'] as int?,
      source: map['source'] as String,
      montant: (map['montant'] as num).toDouble(),
      pourcentage: map['pourcentage'] != null
          ? (map['pourcentage'] as num).toDouble()
          : null,
      description: map['description'] as String,
      dateContribution: DateTime.parse(map['date_contribution'] as String),
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      ecritureComptableId: map['ecriture_comptable_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vente_id': venteId,
      'source': source,
      'montant': montant,
      'pourcentage': pourcentage,
      'description': description,
      'date_contribution': dateContribution.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'ecriture_comptable_id': ecritureComptableId,
    };
  }

  FondsSocialModel copyWith({
    int? id,
    int? venteId,
    String? source,
    double? montant,
    double? pourcentage,
    String? description,
    DateTime? dateContribution,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    int? ecritureComptableId,
  }) {
    return FondsSocialModel(
      id: id ?? this.id,
      venteId: venteId ?? this.venteId,
      source: source ?? this.source,
      montant: montant ?? this.montant,
      pourcentage: pourcentage ?? this.pourcentage,
      description: description ?? this.description,
      dateContribution: dateContribution ?? this.dateContribution,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      ecritureComptableId: ecritureComptableId ?? this.ecritureComptableId,
    );
  }
}

