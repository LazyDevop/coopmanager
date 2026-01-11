class ParametresCooperativeModel {
  final int? id;
  final String nomCooperative;
  final String? logoPath;
  final String? adresse;
  final String? telephone;
  final String? email;
  final double commissionRate;
  final double? commissionRateActionnaire; // Taux spécifique pour actionnaires
  final double? commissionRateProducteur; // Taux spécifique pour producteurs
  final int periodeCampagneDays;
  final DateTime? dateDebutCampagne;
  final DateTime? dateFinCampagne;
  final String? codeCooperative; // Code coopérative (2 lettres) pour génération codes adhérents
  final DateTime? updatedAt;

  ParametresCooperativeModel({
    this.id,
    required this.nomCooperative,
    this.logoPath,
    this.adresse,
    this.telephone,
    this.email,
    required this.commissionRate,
    this.commissionRateActionnaire,
    this.commissionRateProducteur,
    required this.periodeCampagneDays,
    this.dateDebutCampagne,
    this.dateFinCampagne,
    this.codeCooperative,
    this.updatedAt,
  });

  // Convertir depuis Map (base de données)
  factory ParametresCooperativeModel.fromMap(Map<String, dynamic> map) {
    // Fonction helper pour convertir en int de manière sûre
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    // Fonction helper pour convertir en double de manière sûre
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    // Fonction helper pour convertir en String de manière sûre (nullable)
    String? _parseString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    // Fonction helper pour convertir en String non-nullable
    String _parseStringRequired(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      final str = value.toString();
      return str.isEmpty ? defaultValue : str;
    }

    return ParametresCooperativeModel(
      id: _parseInt(map['id']),
      nomCooperative: _parseStringRequired(map['nom_cooperative'], 'Coopérative de Cacaoculteurs'),
      logoPath: _parseString(map['logo_path']),
      adresse: _parseString(map['adresse']),
      telephone: _parseString(map['telephone']),
      email: _parseString(map['email']),
      commissionRate: _parseDouble(map['commission_rate']),
      commissionRateActionnaire: map['commission_rate_actionnaire'] != null
          ? _parseDouble(map['commission_rate_actionnaire'])
          : null,
      commissionRateProducteur: map['commission_rate_producteur'] != null
          ? _parseDouble(map['commission_rate_producteur'])
          : null,
      periodeCampagneDays: _parseInt(map['periode_campagne_days']) ?? 365,
      dateDebutCampagne: map['date_debut_campagne'] != null
          ? DateTime.tryParse(map['date_debut_campagne'].toString())
          : null,
      dateFinCampagne: map['date_fin_campagne'] != null
          ? DateTime.tryParse(map['date_fin_campagne'].toString())
          : null,
      codeCooperative: _parseString(map['code_cooperative']),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
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
      if (commissionRateActionnaire != null) 'commission_rate_actionnaire': commissionRateActionnaire,
      if (commissionRateProducteur != null) 'commission_rate_producteur': commissionRateProducteur,
      'periode_campagne_days': periodeCampagneDays,
      if (dateDebutCampagne != null) 'date_debut_campagne': dateDebutCampagne!.toIso8601String(),
      if (dateFinCampagne != null) 'date_fin_campagne': dateFinCampagne!.toIso8601String(),
      if (codeCooperative != null) 'code_cooperative': codeCooperative,
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
    double? commissionRateActionnaire,
    double? commissionRateProducteur,
    int? periodeCampagneDays,
    DateTime? dateDebutCampagne,
    DateTime? dateFinCampagne,
    String? codeCooperative,
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
      commissionRateActionnaire: commissionRateActionnaire ?? this.commissionRateActionnaire,
      commissionRateProducteur: commissionRateProducteur ?? this.commissionRateProducteur,
      periodeCampagneDays: periodeCampagneDays ?? this.periodeCampagneDays,
      dateDebutCampagne: dateDebutCampagne ?? this.dateDebutCampagne,
      dateFinCampagne: dateFinCampagne ?? this.dateFinCampagne,
      codeCooperative: codeCooperative ?? this.codeCooperative,
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
    // Fonction helper pour convertir en int de manière sûre
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    // Fonction helper pour convertir en bool de manière sûre
    bool _parseBool(dynamic value) {
      if (value == null) return true;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return true;
    }

    // Fonction helper pour convertir en String non-nullable
    String _parseStringRequired(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      final str = value.toString();
      return str.isEmpty ? defaultValue : str;
    }

    return CampagneModel(
      id: _parseInt(map['id']),
      nom: _parseStringRequired(map['nom'], 'Nouvelle campagne'),
      dateDebut: DateTime.tryParse(map['date_debut'].toString()) ?? DateTime.now(),
      dateFin: DateTime.tryParse(map['date_fin'].toString()) ?? DateTime.now(),
      description: map['description']?.toString(),
      isActive: _parseBool(map['is_active']),
      createdAt: DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
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
    // Fonction helper pour convertir en double de manière sûre
    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    }

    // Fonction helper pour convertir en String non-nullable
    String _parseStringRequired(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      final str = value.toString();
      return str.isEmpty ? defaultValue : str;
    }

    return BaremeQualiteModel(
      qualite: _parseStringRequired(map['qualite'], 'standard'),
      prixMin: _parseDouble(map['prix_min']),
      prixMax: _parseDouble(map['prix_max']),
      commissionRate: _parseDouble(map['commission_rate']),
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

