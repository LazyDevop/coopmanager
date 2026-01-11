/// Modèle de données pour une Validation de Vente (V2)
/// 
/// Workflow de validation multi-niveaux : Préparation -> Validation Prix -> Confirmation Finale
class ValidationVenteModel {
  final int? id;
  final int venteId;
  final String etape; // 'preparation', 'validation_prix', 'confirmation_finale'
  final String statut; // 'en_attente', 'approuvee', 'rejetee'
  final int? validePar; // User ID
  final String? commentaire;
  final DateTime createdAt;
  final DateTime? dateValidation;

  ValidationVenteModel({
    this.id,
    required this.venteId,
    required this.etape,
    this.statut = 'en_attente',
    this.validePar,
    this.commentaire,
    required this.createdAt,
    this.dateValidation,
  });

  bool get isEnAttente => statut == 'en_attente';
  bool get isApprouvee => statut == 'approuvee';
  bool get isRejetee => statut == 'rejetee';
  
  bool get isPreparation => etape == 'preparation';
  bool get isValidationPrix => etape == 'validation_prix';
  bool get isConfirmationFinale => etape == 'confirmation_finale';

  factory ValidationVenteModel.fromMap(Map<String, dynamic> map) {
    return ValidationVenteModel(
      id: map['id'] as int?,
      venteId: map['vente_id'] as int,
      etape: map['etape'] as String,
      statut: map['statut'] as String? ?? 'en_attente',
      validePar: map['valide_par'] as int?,
      commentaire: map['commentaire'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      dateValidation: map['date_validation'] != null
          ? DateTime.parse(map['date_validation'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vente_id': venteId,
      'etape': etape,
      'statut': statut,
      'valide_par': validePar,
      'commentaire': commentaire,
      'created_at': createdAt.toIso8601String(),
      'date_validation': dateValidation?.toIso8601String(),
    };
  }

  ValidationVenteModel copyWith({
    int? id,
    int? venteId,
    String? etape,
    String? statut,
    int? validePar,
    String? commentaire,
    DateTime? createdAt,
    DateTime? dateValidation,
  }) {
    return ValidationVenteModel(
      id: id ?? this.id,
      venteId: venteId ?? this.venteId,
      etape: etape ?? this.etape,
      statut: statut ?? this.statut,
      validePar: validePar ?? this.validePar,
      commentaire: commentaire ?? this.commentaire,
      createdAt: createdAt ?? this.createdAt,
      dateValidation: dateValidation ?? this.dateValidation,
    );
  }
}

