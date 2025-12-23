/// Modèle de données pour une Aide Sociale
class AideSocialeModel {
  final int? id;
  final int adherentId;
  final String typeAide; // 'sante', 'education', 'urgence', 'autre'
  final double montant;
  final DateTime dateAide;
  final String description;
  final String statut; // 'en_attente', 'approuve', 'verse', 'refuse'
  final int? approuvePar;
  final DateTime? dateApprobation;
  final String? notes;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AideSocialeModel({
    this.id,
    required this.adherentId,
    required this.typeAide,
    required this.montant,
    required this.dateAide,
    required this.description,
    this.statut = 'en_attente',
    this.approuvePar,
    this.dateApprobation,
    this.notes,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isEnAttente => statut == 'en_attente';
  bool get isApprouve => statut == 'approuve';
  bool get isVerse => statut == 'verse';
  bool get isRefuse => statut == 'refuse';
  bool get isSante => typeAide == 'sante';
  bool get isEducation => typeAide == 'education';
  bool get isUrgence => typeAide == 'urgence';

  // Convertir depuis Map (base de données)
  factory AideSocialeModel.fromMap(Map<String, dynamic> map) {
    return AideSocialeModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      typeAide: map['type_aide'] as String,
      montant: (map['montant'] as num).toDouble(),
      dateAide: DateTime.parse(map['date_aide'] as String),
      description: map['description'] as String,
      statut: map['statut'] as String? ?? 'en_attente',
      approuvePar: map['approuve_par'] as int?,
      dateApprobation: map['date_approbation'] != null
          ? DateTime.parse(map['date_approbation'] as String)
          : null,
      notes: map['notes'] as String?,
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
      'type_aide': typeAide,
      'montant': montant,
      'date_aide': dateAide.toIso8601String(),
      'description': description,
      'statut': statut,
      'approuve_par': approuvePar,
      'date_approbation': dateApprobation?.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  AideSocialeModel copyWith({
    int? id,
    int? adherentId,
    String? typeAide,
    double? montant,
    DateTime? dateAide,
    String? description,
    String? statut,
    int? approuvePar,
    DateTime? dateApprobation,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AideSocialeModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      typeAide: typeAide ?? this.typeAide,
      montant: montant ?? this.montant,
      dateAide: dateAide ?? this.dateAide,
      description: description ?? this.description,
      statut: statut ?? this.statut,
      approuvePar: approuvePar ?? this.approuvePar,
      dateApprobation: dateApprobation ?? this.dateApprobation,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

