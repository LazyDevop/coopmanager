/// Modèle de données pour un détail de lot de vente (V2)
/// 
/// Représente un adhérent inclus dans un lot de vente
class LotVenteDetailModel {
  final int? id;
  final int lotVenteId;
  final int adherentId;
  final double quantite;
  final bool isExclu; // Exclusion manuelle possible
  final String? raisonExclusion;
  final DateTime createdAt;

  LotVenteDetailModel({
    this.id,
    required this.lotVenteId,
    required this.adherentId,
    required this.quantite,
    this.isExclu = false,
    this.raisonExclusion,
    required this.createdAt,
  });

  factory LotVenteDetailModel.fromMap(Map<String, dynamic> map) {
    return LotVenteDetailModel(
      id: map['id'] as int?,
      lotVenteId: map['lot_vente_id'] as int,
      adherentId: map['adherent_id'] as int,
      quantite: (map['quantite'] as num).toDouble(),
      isExclu: (map['is_exclu'] as int? ?? 0) == 1,
      raisonExclusion: map['raison_exclusion'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'lot_vente_id': lotVenteId,
      'adherent_id': adherentId,
      'quantite': quantite,
      'is_exclu': isExclu ? 1 : 0,
      'raison_exclusion': raisonExclusion,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LotVenteDetailModel copyWith({
    int? id,
    int? lotVenteId,
    int? adherentId,
    double? quantite,
    bool? isExclu,
    String? raisonExclusion,
    DateTime? createdAt,
  }) {
    return LotVenteDetailModel(
      id: id ?? this.id,
      lotVenteId: lotVenteId ?? this.lotVenteId,
      adherentId: adherentId ?? this.adherentId,
      quantite: quantite ?? this.quantite,
      isExclu: isExclu ?? this.isExclu,
      raisonExclusion: raisonExclusion ?? this.raisonExclusion,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

