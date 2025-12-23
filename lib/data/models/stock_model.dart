class StockDepotModel {
  final int? id;
  final int adherentId;
  final double quantite; // Poids net (utilisé pour compatibilité)
  final double stockBrut; // Stock brut amené par le producteur
  final double? poidsSac; // Poids du sac
  final double? poidsDechets; // Poids des déchets
  final double? autres; // Autres déductions
  final double poidsNet; // Poids net calculé = stockBrut - poidsSac - poidsDechets - autres
  final double? prixUnitaire;
  final DateTime dateDepot;
  final String? qualite; // standard, premium, bio, etc.
  final double? humidite; // Taux d'humidité en pourcentage
  final String? photoPath; // Chemin vers la photo du dépôt
  final String? observations;
  final int? createdBy;
  final DateTime createdAt;

  StockDepotModel({
    this.id,
    required this.adherentId,
    double? quantite, // Pour compatibilité avec l'ancien code
    required this.stockBrut,
    this.poidsSac,
    this.poidsDechets,
    this.autres,
    double? poidsNet, // Si non fourni, sera calculé
    this.prixUnitaire,
    required this.dateDepot,
    this.qualite,
    this.humidite,
    this.photoPath,
    this.observations,
    this.createdBy,
    required this.createdAt,
  }) : quantite = quantite ?? (poidsNet ?? (stockBrut - (poidsSac ?? 0) - (poidsDechets ?? 0) - (autres ?? 0))),
       poidsNet = poidsNet ?? (stockBrut - (poidsSac ?? 0) - (poidsDechets ?? 0) - (autres ?? 0));

  // Convertir depuis Map (base de données)
  factory StockDepotModel.fromMap(Map<String, dynamic> map) {
    final stockBrut = map['stock_brut'] != null 
        ? (map['stock_brut'] as num).toDouble()
        : (map['quantite'] as num).toDouble(); // Compatibilité avec anciennes données
    final poidsSac = map['poids_sac'] != null ? (map['poids_sac'] as num).toDouble() : null;
    final poidsDechets = map['poids_dechets'] != null ? (map['poids_dechets'] as num).toDouble() : null;
    final autres = map['autres'] != null ? (map['autres'] as num).toDouble() : null;
    final poidsNet = map['poids_net'] != null 
        ? (map['poids_net'] as num).toDouble()
        : stockBrut - (poidsSac ?? 0) - (poidsDechets ?? 0) - (autres ?? 0);
    
    return StockDepotModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      quantite: (map['quantite'] as num).toDouble(), // Pour compatibilité
      stockBrut: stockBrut,
      poidsSac: poidsSac,
      poidsDechets: poidsDechets,
      autres: autres,
      poidsNet: poidsNet,
      prixUnitaire: map['prix_unitaire'] != null
          ? (map['prix_unitaire'] as num).toDouble()
          : null,
      dateDepot: DateTime.parse(map['date_depot'] as String),
      qualite: map['qualite'] as String?,
      humidite: map['humidite'] != null ? (map['humidite'] as num).toDouble() : null,
      photoPath: map['photo_path'] as String?,
      observations: map['notes'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      'quantite': poidsNet, // Utiliser poids_net pour la quantité
      'stock_brut': stockBrut,
      if (poidsSac != null) 'poids_sac': poidsSac,
      if (poidsDechets != null) 'poids_dechets': poidsDechets,
      if (autres != null) 'autres': autres,
      'poids_net': poidsNet,
      if (prixUnitaire != null) 'prix_unitaire': prixUnitaire,
      'date_depot': dateDepot.toIso8601String(),
      if (qualite != null) 'qualite': qualite,
      if (humidite != null) 'humidite': humidite,
      if (photoPath != null) 'photo_path': photoPath,
      if (observations != null) 'notes': observations,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  StockDepotModel copyWith({
    int? id,
    int? adherentId,
    double? quantite,
    double? stockBrut,
    double? poidsSac,
    double? poidsDechets,
    double? autres,
    double? poidsNet,
    double? prixUnitaire,
    DateTime? dateDepot,
    String? qualite,
    double? humidite,
    String? photoPath,
    String? observations,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return StockDepotModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      quantite: quantite ?? this.quantite,
      stockBrut: stockBrut ?? this.stockBrut,
      poidsSac: poidsSac ?? this.poidsSac,
      poidsDechets: poidsDechets ?? this.poidsDechets,
      autres: autres ?? this.autres,
      poidsNet: poidsNet ?? this.poidsNet,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      dateDepot: dateDepot ?? this.dateDepot,
      qualite: qualite ?? this.qualite,
      humidite: humidite ?? this.humidite,
      photoPath: photoPath ?? this.photoPath,
      observations: observations ?? this.observations,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Modèle pour le stock actuel d'un adhérent
class StockActuelModel {
  final int adherentId;
  final String adherentCode;
  final String adherentNom;
  final String adherentPrenom;
  final double stockTotal;
  final double stockStandard;
  final double stockPremium;
  final double stockBio;
  final DateTime? dernierDepot;
  final DateTime? dernierMouvement;

  StockActuelModel({
    required this.adherentId,
    required this.adherentCode,
    required this.adherentNom,
    required this.adherentPrenom,
    required this.stockTotal,
    this.stockStandard = 0,
    this.stockPremium = 0,
    this.stockBio = 0,
    this.dernierDepot,
    this.dernierMouvement,
  });

  String get adherentFullName => '$adherentPrenom $adherentNom';

  // Statut du stock
  StockStatus get status {
    if (stockTotal <= 0) return StockStatus.vide;
    if (stockTotal < 10) return StockStatus.critique;
    if (stockTotal < 50) return StockStatus.faible;
    if (stockTotal < 200) return StockStatus.optimal;
    return StockStatus.eleve;
  }
}

enum StockStatus {
  vide,
  critique,
  faible,
  optimal,
  eleve,
}

extension StockStatusExtension on StockStatus {
  String get label {
    switch (this) {
      case StockStatus.vide:
        return 'Stock vide';
      case StockStatus.critique:
        return 'Stock critique';
      case StockStatus.faible:
        return 'Stock faible';
      case StockStatus.optimal:
        return 'Stock optimal';
      case StockStatus.eleve:
        return 'Stock élevé';
    }
  }

  int get colorValue {
    switch (this) {
      case StockStatus.vide:
        return 0xFFE53935; // Rouge
      case StockStatus.critique:
        return 0xFFFF6F00; // Orange foncé
      case StockStatus.faible:
        return 0xFFFFB300; // Orange clair
      case StockStatus.optimal:
        return 0xFF43A047; // Vert
      case StockStatus.eleve:
        return 0xFF1E88E5; // Bleu
    }
  }
}

