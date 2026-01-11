/// Modèle pour une ligne de vente (gestion FIFO des stocks)
/// 
/// Chaque ligne correspond à un dépôt de stock utilisé dans la vente
/// Permet de tracer précisément quels dépôts ont été vendus (FIFO)
class VenteLigneModel {
  final int? id;
  final int venteId;
  final int stockDepotId; // ID du dépôt de stock utilisé
  final int adherentId;
  final double quantite; // Quantité prélevée de ce dépôt
  final double prixUnitaire;
  final double montant;
  final DateTime createdAt;

  VenteLigneModel({
    this.id,
    required this.venteId,
    required this.stockDepotId,
    required this.adherentId,
    required this.quantite,
    required this.prixUnitaire,
    required this.montant,
    required this.createdAt,
  });

  // Convertir depuis Map (base de données)
  factory VenteLigneModel.fromMap(Map<String, dynamic> map) {
    return VenteLigneModel(
      id: map['id'] as int?,
      venteId: map['vente_id'] as int,
      stockDepotId: map['stock_depot_id'] as int,
      adherentId: map['adherent_id'] as int,
      quantite: (map['quantite'] as num).toDouble(),
      prixUnitaire: (map['prix_unitaire'] as num).toDouble(),
      montant: (map['montant'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vente_id': venteId,
      'stock_depot_id': stockDepotId,
      'adherent_id': adherentId,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'montant': montant,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  VenteLigneModel copyWith({
    int? id,
    int? venteId,
    int? stockDepotId,
    int? adherentId,
    double? quantite,
    double? prixUnitaire,
    double? montant,
    DateTime? createdAt,
  }) {
    return VenteLigneModel(
      id: id ?? this.id,
      venteId: venteId ?? this.venteId,
      stockDepotId: stockDepotId ?? this.stockDepotId,
      adherentId: adherentId ?? this.adherentId,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      montant: montant ?? this.montant,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

