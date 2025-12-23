class StockMovementModel {
  final int? id;
  final int adherentId;
  final String type; // depot, vente, ajustement
  final double quantite; // positif pour dépôt, négatif pour vente/ajustement
  final int? depotId; // Référence au dépôt si type = depot
  final int? venteId; // Référence à la vente si type = vente
  final DateTime dateMouvement;
  final String? commentaire;
  final int? createdBy;
  final DateTime createdAt;

  StockMovementModel({
    this.id,
    required this.adherentId,
    required this.type,
    required this.quantite,
    this.depotId,
    this.venteId,
    required this.dateMouvement,
    this.commentaire,
    this.createdBy,
    required this.createdAt,
  });

  // Convertir depuis Map (base de données)
  factory StockMovementModel.fromMap(Map<String, dynamic> map) {
    return StockMovementModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      type: map['type'] as String,
      quantite: (map['quantite'] as num).toDouble(),
      depotId: map['stock_depot_id'] as int?,
      venteId: map['vente_id'] as int?,
      dateMouvement: DateTime.parse(map['date_mouvement'] as String),
      commentaire: map['notes'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      'type': type,
      'quantite': quantite,
      if (depotId != null) 'stock_depot_id': depotId,
      if (venteId != null) 'vente_id': venteId,
      'date_mouvement': dateMouvement.toIso8601String(),
      if (commentaire != null) 'notes': commentaire,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  StockMovementModel copyWith({
    int? id,
    int? adherentId,
    String? type,
    double? quantite,
    int? depotId,
    int? venteId,
    DateTime? dateMouvement,
    String? commentaire,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return StockMovementModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      type: type ?? this.type,
      quantite: quantite ?? this.quantite,
      depotId: depotId ?? this.depotId,
      venteId: venteId ?? this.venteId,
      dateMouvement: dateMouvement ?? this.dateMouvement,
      commentaire: commentaire ?? this.commentaire,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Type de mouvement
  bool get isDepot => type == 'depot';
  bool get isVente => type == 'vente';
  bool get isAjustement => type == 'ajustement';

  String get typeLabel {
    switch (type) {
      case 'depot':
        return 'Dépôt';
      case 'vente':
        return 'Vente';
      case 'ajustement':
        return 'Ajustement';
      default:
        return type;
    }
  }
}

