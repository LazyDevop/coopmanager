class ParametresCooperativeModel {
  final int? id;
  final String nomCooperative;
  final String? logoPath;
  final String? adresse;
  final String? telephone;
  final String? email;
  final double commissionRate;
  final int periodeCampagneDays;
  final DateTime? dateDebutCampagne;
  final DateTime? dateFinCampagne;
  final DateTime? updatedAt;

  ParametresCooperativeModel({
    this.id,
    required this.nomCooperative,
    this.logoPath,
    this.adresse,
    this.telephone,
    this.email,
    required this.commissionRate,
    required this.periodeCampagneDays,
    this.dateDebutCampagne,
    this.dateFinCampagne,
    this.updatedAt,
  });

  // Convertir depuis Map (base de données)
  factory ParametresCooperativeModel.fromMap(Map<String, dynamic> map) {
    return ParametresCooperativeModel(
      id: map['id'] as int?,
      nomCooperative: map['nom_cooperative'] as String,
      logoPath: map['logo_path'] as String?,
      adresse: map['adresse'] as String?,
      telephone: map['telephone'] as String?,
      email: map['email'] as String?,
      commissionRate: (map['commission_rate'] as num).toDouble(),
      periodeCampagneDays: map['periode_campagne_days'] as int,
      dateDebutCampagne: map['date_debut_campagne'] != null
          ? DateTime.parse(map['date_debut_campagne'] as String)
          : null,
      dateFinCampagne: map['date_fin_campagne'] != null
          ? DateTime.parse(map['date_fin_campagne'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nom_cooperative': nomCooperative,
      if (logoPath != null) 'logo_path': logoPath,
      if (adresse != null) 'adresse': adresse,
      if (telephone != null) 'telephone': telephone,
      if (email != null) 'email': email,
      'commission_rate': commissionRate,
      'periode_campagne_days': periodeCampagneDays,
      if (dateDebutCampagne != null) 'date_debut_campagne': dateDebutCampagne!.toIso8601String(),
      if (dateFinCampagne != null) 'date_fin_campagne': dateFinCampagne!.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  ParametresCooperativeModel copyWith({
    int? id,
    String? nomCooperative,
    String? logoPath,
    String? adresse,
    String? telephone,
    String? email,
    double? commissionRate,
    int? periodeCampagneDays,
    DateTime? dateDebutCampagne,
    DateTime? dateFinCampagne,
    DateTime? updatedAt,
  }) {
    return ParametresCooperativeModel(
      id: id ?? this.id,
      nomCooperative: nomCooperative ?? this.nomCooperative,
      logoPath: logoPath ?? this.logoPath,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      commissionRate: commissionRate ?? this.commissionRate,
      periodeCampagneDays: periodeCampagneDays ?? this.periodeCampagneDays,
      dateDebutCampagne: dateDebutCampagne ?? this.dateDebutCampagne,
      dateFinCampagne: dateFinCampagne ?? this.dateFinCampagne,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Vérifier si une campagne est active
  bool get isCampagneActive {
    if (dateDebutCampagne == null || dateFinCampagne == null) {
      return false;
    }
    final now = DateTime.now();
    return now.isAfter(dateDebutCampagne!) && now.isBefore(dateFinCampagne!);
  }
}

/// Modèle pour une campagne
class CampagneModel {
  final int? id;
  final String nom;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CampagneModel({
    this.id,
    required this.nom,
    required this.dateDebut,
    required this.dateFin,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Vérifier si la campagne est en cours
  bool get isEnCours {
    final now = DateTime.now();
    return now.isAfter(dateDebut) && now.isBefore(dateFin);
  }

  // Convertir depuis Map (base de données)
  factory CampagneModel.fromMap(Map<String, dynamic> map) {
    return CampagneModel(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      dateDebut: DateTime.parse(map['date_debut'] as String),
      dateFin: DateTime.parse(map['date_fin'] as String),
      description: map['description'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
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
      'nom': nom,
      'date_debut': dateDebut.toIso8601String(),
      'date_fin': dateFin.toIso8601String(),
      if (description != null) 'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  CampagneModel copyWith({
    int? id,
    String? nom,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampagneModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Modèle pour les barèmes de qualité
class BaremeQualiteModel {
  final String qualite;
  final double? prixMin;
  final double? prixMax;
  final double? commissionRate; // Taux de commission spécifique (optionnel)

  BaremeQualiteModel({
    required this.qualite,
    this.prixMin,
    this.prixMax,
    this.commissionRate,
  });

  // Convertir depuis Map
  factory BaremeQualiteModel.fromMap(Map<String, dynamic> map) {
    return BaremeQualiteModel(
      qualite: map['qualite'] as String,
      prixMin: map['prix_min'] != null ? (map['prix_min'] as num).toDouble() : null,
      prixMax: map['prix_max'] != null ? (map['prix_max'] as num).toDouble() : null,
      commissionRate: map['commission_rate'] != null ? (map['commission_rate'] as num).toDouble() : null,
    );
  }

  // Convertir vers Map
  Map<String, dynamic> toMap() {
    return {
      'qualite': qualite,
      if (prixMin != null) 'prix_min': prixMin,
      if (prixMax != null) 'prix_max': prixMax,
      if (commissionRate != null) 'commission_rate': commissionRate,
    };
  }
}

