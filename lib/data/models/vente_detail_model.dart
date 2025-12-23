class VenteDetailModel {
  final int? id;
  final int venteId;
  final int adherentId;
  final double quantite;
  final double prixUnitaire;
  final double montant;

  VenteDetailModel({
    this.id,
    required this.venteId,
    required this.adherentId,
    required this.quantite,
    required this.prixUnitaire,
    required this.montant,
  });

  // Convertir depuis Map (base de données)
  factory VenteDetailModel.fromMap(Map<String, dynamic> map) {
    return VenteDetailModel(
      id: map['id'] as int?,
      venteId: map['vente_id'] as int,
      adherentId: map['adherent_id'] as int,
      quantite: (map['quantite'] as num).toDouble(),
      prixUnitaire: (map['prix_unitaire'] as num).toDouble(),
      montant: (map['montant'] as num).toDouble(),
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vente_id': venteId,
      'adherent_id': adherentId,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'montant': montant,
    };
  }

  // Créer une copie avec des modifications
  VenteDetailModel copyWith({
    int? id,
    int? venteId,
    int? adherentId,
    double? quantite,
    double? prixUnitaire,
    double? montant,
  }) {
    return VenteDetailModel(
      id: id ?? this.id,
      venteId: venteId ?? this.venteId,
      adherentId: adherentId ?? this.adherentId,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      montant: montant ?? this.montant,
    );
  }
}
