/// MODÈLE : TRAITEMENT AGRICOLE
/// 
/// Représente un traitement agricole effectué sur un champ
/// Types possibles: engrais, pesticide, entretien, autre
class TraitementAgricoleModel {
  /// Identifiant unique du traitement
  final int? id;
  
  /// Identifiant du champ traité (clé étrangère)
  /// Contrainte: NOT NULL, FOREIGN KEY -> champs_parcelles(id)
  final int champId;
  
  /// Type de traitement
  /// Valeurs possibles: 'engrais', 'pesticide', 'entretien', 'autre'
  /// Contrainte: NOT NULL
  final String typeTraitement;
  
  /// Nom du produit utilisé
  /// Contrainte: NOT NULL
  final String produitUtilise;
  
  /// Quantité de produit utilisée
  /// Contrainte: NOT NULL, > 0
  final double quantite;
  
  /// Unité de mesure de la quantité
  /// Valeurs possibles: 'kg', 'L', 'g', 'ml', etc.
  /// Défaut: 'kg'
  final String uniteQuantite;
  
  /// Date du traitement
  /// Contrainte: NOT NULL
  final DateTime dateTraitement;
  
  /// Coût du traitement (en FCFA)
  /// Défaut: 0.0
  final double coutTraitement;
  
  /// Nom de l'opérateur qui a effectué le traitement
  final String? operateur;
  
  /// Observations et notes sur le traitement
  final String? observation;
  
  /// Date de création
  final DateTime createdAt;
  
  /// Identifiant de l'utilisateur ayant créé le traitement
  final int? createdBy;
  
  TraitementAgricoleModel({
    this.id,
    required this.champId,
    required this.typeTraitement,
    required this.produitUtilise,
    required this.quantite,
    this.uniteQuantite = 'kg',
    required this.dateTraitement,
    this.coutTraitement = 0.0,
    this.operateur,
    this.observation,
    required this.createdAt,
    this.createdBy,
  });
  
  /// Convertir depuis Map (base de données)
  factory TraitementAgricoleModel.fromMap(Map<String, dynamic> map) {
    return TraitementAgricoleModel(
      id: map['id'] as int?,
      champId: map['champ_id'] as int,
      typeTraitement: map['type_traitement'] as String,
      produitUtilise: map['produit_utilise'] as String,
      quantite: (map['quantite'] as num).toDouble(),
      uniteQuantite: map['unite_quantite'] as String? ?? 'kg',
      dateTraitement: DateTime.parse(map['date_traitement'] as String),
      coutTraitement: (map['cout_traitement'] as num?)?.toDouble() ?? 0.0,
      operateur: map['operateur'] as String?,
      observation: map['observation'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as int?,
    );
  }
  
  /// Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'champ_id': champId,
      'type_traitement': typeTraitement,
      'produit_utilise': produitUtilise,
      'quantite': quantite,
      'unite_quantite': uniteQuantite,
      'date_traitement': dateTraitement.toIso8601String(),
      'cout_traitement': coutTraitement,
      if (operateur != null) 'operateur': operateur,
      if (observation != null) 'observation': observation,
      'created_at': createdAt.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }
  
  /// Créer une copie avec des modifications
  TraitementAgricoleModel copyWith({
    int? id,
    int? champId,
    String? typeTraitement,
    String? produitUtilise,
    double? quantite,
    String? uniteQuantite,
    DateTime? dateTraitement,
    double? coutTraitement,
    String? operateur,
    String? observation,
    DateTime? createdAt,
    int? createdBy,
  }) {
    return TraitementAgricoleModel(
      id: id ?? this.id,
      champId: champId ?? this.champId,
      typeTraitement: typeTraitement ?? this.typeTraitement,
      produitUtilise: produitUtilise ?? this.produitUtilise,
      quantite: quantite ?? this.quantite,
      uniteQuantite: uniteQuantite ?? this.uniteQuantite,
      dateTraitement: dateTraitement ?? this.dateTraitement,
      coutTraitement: coutTraitement ?? this.coutTraitement,
      operateur: operateur ?? this.operateur,
      observation: observation ?? this.observation,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

