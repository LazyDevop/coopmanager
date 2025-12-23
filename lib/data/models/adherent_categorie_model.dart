/// Modèle de données pour l'historique des catégories d'un adhérent
class AdherentCategorieModel {
  final int? id;
  final int adherentId;
  final String categorie; // 'producteur', 'adherent', 'actionnaire'
  final DateTime dateDebut;
  final DateTime? dateFin;
  final bool isActive;
  final DateTime createdAt;

  AdherentCategorieModel({
    this.id,
    required this.adherentId,
    required this.categorie,
    required this.dateDebut,
    this.dateFin,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isProducteur => categorie == 'producteur';
  bool get isAdherent => categorie == 'adherent';
  bool get isActionnaire => categorie == 'actionnaire';
  bool get isTerminee => dateFin != null;

  // Convertir depuis Map (base de données)
  factory AdherentCategorieModel.fromMap(Map<String, dynamic> map) {
    return AdherentCategorieModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      categorie: map['categorie'] as String,
      dateDebut: DateTime.parse(map['date_debut'] as String),
      dateFin: map['date_fin'] != null
          ? DateTime.parse(map['date_fin'] as String)
          : null,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      'categorie': categorie,
      'date_debut': dateDebut.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  AdherentCategorieModel copyWith({
    int? id,
    int? adherentId,
    String? categorie,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AdherentCategorieModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      categorie: categorie ?? this.categorie,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

