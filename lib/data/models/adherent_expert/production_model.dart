/// MODÈLE : PRODUCTION
/// 
/// Représente une production agricole (récolte) d'un adhérent
class ProductionModel {
  /// Identifiant unique de la production
  final int? id;
  
  /// Identifiant de l'adhérent (clé étrangère)
  /// Contrainte: NOT NULL, FOREIGN KEY -> adherents(id)
  final int adherentId;
  
  /// Identifiant du champ (clé étrangère, optionnel)
  /// FOREIGN KEY -> champs_parcelles(id)
  final int? champId;
  
  /// Campagne agricole (ex: "2023-2024")
  /// Contrainte: NOT NULL
  final String campagne;
  
  /// Tonnage brut récolté (en tonnes)
  /// Contrainte: NOT NULL, > 0
  final double tonnageBrut;
  
  /// Tonnage net après traitement (en tonnes)
  /// Contrainte: NOT NULL, > 0, <= tonnageBrut
  final double tonnageNet;
  
  /// Taux d'humidité (en pourcentage)
  /// Défaut: 0.0
  /// Contrainte: >= 0 AND <= 100
  final double tauxHumidite;
  
  /// Date de récolte
  /// Contrainte: NOT NULL
  final DateTime dateRecolte;
  
  /// Qualité du produit
  /// Valeurs possibles: 'standard', 'premium', 'bio'
  /// Défaut: 'standard'
  final String qualite;
  
  /// Observations et notes sur la production
  final String? observation;
  
  /// Date de création
  final DateTime createdAt;
  
  /// Identifiant de l'utilisateur ayant créé la production
  final int? createdBy;
  
  ProductionModel({
    this.id,
    required this.adherentId,
    this.champId,
    required this.campagne,
    required this.tonnageBrut,
    required this.tonnageNet,
    this.tauxHumidite = 0.0,
    required this.dateRecolte,
    this.qualite = 'standard',
    this.observation,
    required this.createdAt,
    this.createdBy,
  });
  
  /// Convertir depuis Map (base de données)
  factory ProductionModel.fromMap(Map<String, dynamic> map) {
    return ProductionModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      champId: map['champ_id'] as int?,
      campagne: map['campagne'] as String,
      tonnageBrut: (map['tonnage_brut'] as num).toDouble(),
      tonnageNet: (map['tonnage_net'] as num).toDouble(),
      tauxHumidite: (map['taux_humidite'] as num?)?.toDouble() ?? 0.0,
      dateRecolte: DateTime.parse(map['date_recolte'] as String),
      qualite: map['qualite'] as String? ?? 'standard',
      observation: map['observation'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as int?,
    );
  }
  
  /// Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      if (champId != null) 'champ_id': champId,
      'campagne': campagne,
      'tonnage_brut': tonnageBrut,
      'tonnage_net': tonnageNet,
      'taux_humidite': tauxHumidite,
      'date_recolte': dateRecolte.toIso8601String(),
      'qualite': qualite,
      if (observation != null) 'observation': observation,
      'created_at': createdAt.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }
  
  /// Créer une copie avec des modifications
  ProductionModel copyWith({
    int? id,
    int? adherentId,
    int? champId,
    String? campagne,
    double? tonnageBrut,
    double? tonnageNet,
    double? tauxHumidite,
    DateTime? dateRecolte,
    String? qualite,
    String? observation,
    DateTime? createdAt,
    int? createdBy,
  }) {
    return ProductionModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      champId: champId ?? this.champId,
      campagne: campagne ?? this.campagne,
      tonnageBrut: tonnageBrut ?? this.tonnageBrut,
      tonnageNet: tonnageNet ?? this.tonnageNet,
      tauxHumidite: tauxHumidite ?? this.tauxHumidite,
      dateRecolte: dateRecolte ?? this.dateRecolte,
      qualite: qualite ?? this.qualite,
      observation: observation ?? this.observation,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

