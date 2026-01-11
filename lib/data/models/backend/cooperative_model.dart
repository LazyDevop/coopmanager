/// Modèle de données pour la coopérative (backend multi-coopérative)
import 'package:uuid/uuid.dart';

enum CooperativeStatut { active, inactive, suspended }

class CooperativeModel {
  final String id;
  final String raisonSociale;
  final String? sigle;
  final String? formeJuridique;
  final String? numeroAgrement;
  final String? rccm;
  final DateTime? dateCreation;
  final String? telephone;
  final String? email;
  final String? adresse;
  final String? region;
  final String? departement;
  final String devise; // XAF, EUR, USD, etc.
  final String langue; // FR, EN, etc.
  final String? logo; // URL ou chemin
  final CooperativeStatut statut;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CooperativeModel({
    String? id,
    required this.raisonSociale,
    this.sigle,
    this.formeJuridique,
    this.numeroAgrement,
    this.rccm,
    this.dateCreation,
    this.telephone,
    this.email,
    this.adresse,
    this.region,
    this.departement,
    this.devise = 'XAF',
    this.langue = 'FR',
    this.logo,
    this.statut = CooperativeStatut.active,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory CooperativeModel.fromMap(Map<String, dynamic> map) {
    return CooperativeModel(
      id: map['id'] as String,
      raisonSociale: map['raison_sociale'] as String,
      sigle: map['sigle'] as String?,
      formeJuridique: map['forme_juridique'] as String?,
      numeroAgrement: map['numero_agrement'] as String?,
      rccm: map['rccm'] as String?,
      dateCreation: map['date_creation'] != null
          ? DateTime.parse(map['date_creation'] as String)
          : null,
      telephone: map['telephone'] as String?,
      email: map['email'] as String?,
      adresse: map['adresse'] as String?,
      region: map['region'] as String?,
      departement: map['departement'] as String?,
      devise: map['devise'] as String? ?? 'XAF',
      langue: map['langue'] as String? ?? 'FR',
      logo: map['logo'] as String?,
      statut: CooperativeStatut.values.firstWhere(
        (e) => e.name.toUpperCase() == (map['statut'] as String? ?? 'ACTIVE').toUpperCase(),
        orElse: () => CooperativeStatut.active,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'raison_sociale': raisonSociale,
      if (sigle != null) 'sigle': sigle,
      if (formeJuridique != null) 'forme_juridique': formeJuridique,
      if (numeroAgrement != null) 'numero_agrement': numeroAgrement,
      if (rccm != null) 'rccm': rccm,
      if (dateCreation != null) 'date_creation': dateCreation!.toIso8601String(),
      if (telephone != null) 'telephone': telephone,
      if (email != null) 'email': email,
      if (adresse != null) 'adresse': adresse,
      if (region != null) 'region': region,
      if (departement != null) 'departement': departement,
      'devise': devise,
      'langue': langue,
      if (logo != null) 'logo': logo,
      'statut': statut.name.toUpperCase(),
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  CooperativeModel copyWith({
    String? id,
    String? raisonSociale,
    String? sigle,
    String? formeJuridique,
    String? numeroAgrement,
    String? rccm,
    DateTime? dateCreation,
    String? telephone,
    String? email,
    String? adresse,
    String? region,
    String? departement,
    String? devise,
    String? langue,
    String? logo,
    CooperativeStatut? statut,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CooperativeModel(
      id: id ?? this.id,
      raisonSociale: raisonSociale ?? this.raisonSociale,
      sigle: sigle ?? this.sigle,
      formeJuridique: formeJuridique ?? this.formeJuridique,
      numeroAgrement: numeroAgrement ?? this.numeroAgrement,
      rccm: rccm ?? this.rccm,
      dateCreation: dateCreation ?? this.dateCreation,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      region: region ?? this.region,
      departement: departement ?? this.departement,
      devise: devise ?? this.devise,
      langue: langue ?? this.langue,
      logo: logo ?? this.logo,
      statut: statut ?? this.statut,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

