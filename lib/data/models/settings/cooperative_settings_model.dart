/// Modèle pour les informations de la coopérative
class CooperativeSettingsModel {
  final int? id;
  final String raisonSociale;
  final String? sigle;
  final String? formeJuridique;
  final String? numeroAgrement;
  final String? rccm;
  final DateTime? dateCreation;
  final String? adresse;
  final String? region;
  final String? departement;
  final String? telephone;
  final String? email;
  final String devise;
  final String langue;
  final String? logoPath;
  final bool isActive;
  final DateTime? updatedAt;
  final int? updatedBy;

  CooperativeSettingsModel({
    this.id,
    required this.raisonSociale,
    this.sigle,
    this.formeJuridique,
    this.numeroAgrement,
    this.rccm,
    this.dateCreation,
    this.adresse,
    this.region,
    this.departement,
    this.telephone,
    this.email,
    this.devise = 'XOF',
    this.langue = 'fr',
    this.logoPath,
    this.isActive = true,
    this.updatedAt,
    this.updatedBy,
  });

  factory CooperativeSettingsModel.fromMap(Map<String, dynamic> map) {
    // Gérer les valeurs null de manière sécurisée
    String? getString(String key, {String? defaultValue}) {
      final value = map[key];
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }
    
    // Helper pour convertir en int? de manière sécurisée
    int? getInt(String key) {
      final value = map[key];
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    return CooperativeSettingsModel(
      id: getInt('id'),
      raisonSociale: getString('raison_sociale', defaultValue: 'Coopérative de Cacaoculteurs') ?? 'Coopérative de Cacaoculteurs',
      sigle: getString('sigle'),
      formeJuridique: getString('forme_juridique'),
      numeroAgrement: getString('numero_agrement'),
      rccm: getString('rccm'),
      dateCreation: map['date_creation'] != null && map['date_creation'] is String
          ? DateTime.tryParse(map['date_creation'] as String)
          : null,
      adresse: getString('adresse'),
      region: getString('region'),
      departement: getString('departement'),
      telephone: getString('telephone'),
      email: getString('email'),
      devise: getString('devise', defaultValue: 'XAF') ?? 'XAF',
      langue: getString('langue', defaultValue: 'FR') ?? 'FR',
      logoPath: getString('logo_path'),
      isActive: map['is_active'] != null 
          ? ((map['is_active'] is int && (map['is_active'] as int) == 1) ||
             (map['is_active'] is bool && map['is_active'] as bool))
          : true,
      updatedAt: map['updated_at'] != null && map['updated_at'] is String
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      updatedBy: getInt('updated_by'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'raison_sociale': raisonSociale,
      if (sigle != null) 'sigle': sigle,
      if (formeJuridique != null) 'forme_juridique': formeJuridique,
      if (numeroAgrement != null) 'numero_agrement': numeroAgrement,
      if (rccm != null) 'rccm': rccm,
      if (dateCreation != null) 'date_creation': dateCreation!.toIso8601String(),
      if (adresse != null) 'adresse': adresse,
      if (region != null) 'region': region,
      if (departement != null) 'departement': departement,
      if (telephone != null) 'telephone': telephone,
      if (email != null) 'email': email,
      'devise': devise,
      'langue': langue,
      if (logoPath != null) 'logo_path': logoPath,
      'is_active': isActive ? 1 : 0,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (updatedBy != null) 'updated_by': updatedBy,
    };
  }

  CooperativeSettingsModel copyWith({
    int? id,
    String? raisonSociale,
    String? sigle,
    String? formeJuridique,
    String? numeroAgrement,
    String? rccm,
    DateTime? dateCreation,
    String? adresse,
    String? region,
    String? departement,
    String? telephone,
    String? email,
    String? devise,
    String? langue,
    String? logoPath,
    bool? isActive,
    DateTime? updatedAt,
    int? updatedBy,
  }) {
    return CooperativeSettingsModel(
      id: id ?? this.id,
      raisonSociale: raisonSociale ?? this.raisonSociale,
      sigle: sigle ?? this.sigle,
      formeJuridique: formeJuridique ?? this.formeJuridique,
      numeroAgrement: numeroAgrement ?? this.numeroAgrement,
      rccm: rccm ?? this.rccm,
      dateCreation: dateCreation ?? this.dateCreation,
      adresse: adresse ?? this.adresse,
      region: region ?? this.region,
      departement: departement ?? this.departement,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      devise: devise ?? this.devise,
      langue: langue ?? this.langue,
      logoPath: logoPath ?? this.logoPath,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

