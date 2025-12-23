/// MODÈLE : AYANT_DROIT / FILIATION
/// 
/// Représente les ayants droit (enfants, conjoint, etc.) d'un adhérent
/// Utilisé pour la gestion des bénéficiaires sociaux et de la succession
class AyantDroitModel {
  /// Identifiant unique de l'ayant droit
  final int? id;
  
  /// Identifiant de l'adhérent parent (clé étrangère)
  /// Contrainte: NOT NULL, FOREIGN KEY -> adherents(id)
  final int adherentId;
  
  /// Nom complet de l'ayant droit
  /// Contrainte: NOT NULL, min 3 caractères
  final String nomComplet;
  
  /// Lien familial avec l'adhérent
  /// Valeurs possibles: 'enfant', 'conjoint', 'parent', 'frere_soeur', 'autre'
  /// Contrainte: NOT NULL
  final String lienFamilial;
  
  /// Date de naissance de l'ayant droit
  final DateTime? dateNaissance;
  
  /// Numéro de téléphone de contact
  final String? contact;
  
  /// Adresse email
  final String? email;
  
  /// Indicateur si l'ayant droit est bénéficiaire d'aides sociales
  /// Défaut: false
  final bool beneficiaireSocial;
  
  /// Priorité dans l'ordre de succession
  /// Valeur: 1 = première priorité, 2 = deuxième, etc.
  /// Défaut: 999 (dernière priorité)
  final int prioriteSuccession;
  
  /// Numéro de pièce d'identité
  final String? numeroPiece;
  
  /// Type de pièce d'identité
  final String? typePiece;
  
  /// Notes et observations
  final String? notes;
  
  /// Date de création
  final DateTime createdAt;
  
  /// Date de modification
  final DateTime? updatedAt;
  
  /// Indicateur de suppression logique
  final bool isDeleted;
  
  AyantDroitModel({
    this.id,
    required this.adherentId,
    required this.nomComplet,
    required this.lienFamilial,
    this.dateNaissance,
    this.contact,
    this.email,
    this.beneficiaireSocial = false,
    this.prioriteSuccession = 999,
    this.numeroPiece,
    this.typePiece,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });
  
  /// Âge calculé
  int? get age {
    if (dateNaissance == null) return null;
    final now = DateTime.now();
    int age = now.year - dateNaissance!.year;
    if (now.month < dateNaissance!.month ||
        (now.month == dateNaissance!.month && now.day < dateNaissance!.day)) {
      age--;
    }
    return age;
  }
  
  factory AyantDroitModel.fromMap(Map<String, dynamic> map) {
    return AyantDroitModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      nomComplet: map['nom_complet'] as String,
      lienFamilial: map['lien_familial'] as String,
      dateNaissance: map['date_naissance'] != null
          ? DateTime.parse(map['date_naissance'] as String)
          : null,
      contact: map['contact'] as String?,
      email: map['email'] as String?,
      beneficiaireSocial: (map['beneficiaire_social'] as int? ?? 0) == 1,
      prioriteSuccession: map['priorite_succession'] as int? ?? 999,
      numeroPiece: map['numero_piece'] as String?,
      typePiece: map['type_piece'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      'nom_complet': nomComplet,
      'lien_familial': lienFamilial,
      'date_naissance': dateNaissance?.toIso8601String(),
      'contact': contact,
      'email': email,
      'beneficiaire_social': beneficiaireSocial ? 1 : 0,
      'priorite_succession': prioriteSuccession,
      'numero_piece': numeroPiece,
      'type_piece': typePiece,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }
  
  AyantDroitModel copyWith({
    int? id,
    int? adherentId,
    String? nomComplet,
    String? lienFamilial,
    DateTime? dateNaissance,
    String? contact,
    String? email,
    bool? beneficiaireSocial,
    int? prioriteSuccession,
    String? numeroPiece,
    String? typePiece,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return AyantDroitModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      nomComplet: nomComplet ?? this.nomComplet,
      lienFamilial: lienFamilial ?? this.lienFamilial,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      beneficiaireSocial: beneficiaireSocial ?? this.beneficiaireSocial,
      prioriteSuccession: prioriteSuccession ?? this.prioriteSuccession,
      numeroPiece: numeroPiece ?? this.numeroPiece,
      typePiece: typePiece ?? this.typePiece,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

