class AdherentModel {
  final int? id;
  final String code; // Format: [2 lettres][2 chiffres][4 alphanumériques] (ex: CE25A9F2)
  final String nom;
  final String prenom;
  final String? telephone;
  final String? email;
  final String? village;
  final String? adresse;
  final String? cnib;
  final DateTime? dateNaissance;
  final DateTime dateAdhesion;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // V2: Nouveaux champs pour catégorisation
  final String? categorie; // 'producteur', 'adherent', 'actionnaire'
  final String? statut; // 'actif', 'suspendu', 'radie'
  final DateTime? dateStatut;
  
  // Identification complémentaire
  final String? siteCooperative;
  final String? section;
  
  // Identité personnelle complémentaire
  final String? sexe; // 'M', 'F'
  final String? lieuNaissance;
  final String? nationalite;
  final String? typePiece; // 'CNIB', 'PASSEPORT', 'CARTE_CONSULAIRE', etc.
  final String? numeroPiece; // Remplace cnib si typePiece est défini
  
  // Situation familiale / filiation
  final String? nomPere;
  final String? nomMere;
  final String? conjoint;
  final int? nombreEnfants;
  
  // Indicateurs agricoles globaux
  final double? superficieTotaleCultivee; // en hectares
  final int? nombreChamps;
  final double? rendementMoyenHa; // en tonnes/hectare
  final double? tonnageTotalProduit; // en tonnes
  final double? tonnageTotalVendu; // en tonnes
  
  // Photo de profil
  final String? photoPath;

  AdherentModel({
    this.id,
    required this.code,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.email,
    this.village,
    this.adresse,
    this.cnib,
    this.dateNaissance,
    required this.dateAdhesion,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    // V2: Nouveaux champs
    this.categorie,
    this.statut,
    this.dateStatut,
    // Identification complémentaire
    this.siteCooperative,
    this.section,
    // Identité personnelle complémentaire
    this.sexe,
    this.lieuNaissance,
    this.nationalite,
    this.typePiece,
    this.numeroPiece,
    // Situation familiale
    this.nomPere,
    this.nomMere,
    this.conjoint,
    this.nombreEnfants,
    // Indicateurs agricoles
    this.superficieTotaleCultivee,
    this.nombreChamps,
    this.rendementMoyenHa,
    this.tonnageTotalProduit,
    this.tonnageTotalVendu,
    // Photo de profil
    this.photoPath,
  });

  String get fullName => '$prenom $nom';
  
  // V2: Getters pour catégorisation
  bool get isProducteur => categorie == 'producteur' || categorie == null;
  bool get isAdherent => categorie == 'adherent';
  bool get isActionnaire => categorie == 'actionnaire';
  bool get isStatutActif => statut == 'actif' || statut == null;
  bool get isStatutSuspendu => statut == 'suspendu';
  bool get isStatutRadie => statut == 'radie';

  // Convertir depuis Map (base de données)
  factory AdherentModel.fromMap(Map<String, dynamic> map) {
    final code = map['code'] as String;
    
    // Valider le format du code (optionnel, pour compatibilité avec anciens codes)
    // Les anciens codes (ADH001) seront acceptés mais les nouveaux doivent respecter le format
    
    return AdherentModel(
      id: map['id'] as int?,
      code: code,
      nom: map['nom'] as String,
      prenom: map['prenom'] as String,
      telephone: map['telephone'] as String?,
      email: map['email'] as String?,
      village: map['village'] as String?,
      adresse: map['adresse'] as String?,
      cnib: map['cnib'] as String?,
      dateNaissance: map['date_naissance'] != null
          ? DateTime.parse(map['date_naissance'] as String)
          : null,
      dateAdhesion: DateTime.parse(map['date_adhesion'] as String),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      // V2: Nouveaux champs
      categorie: map['categorie'] as String?,
      statut: map['statut'] as String?,
      dateStatut: map['date_statut'] != null
          ? DateTime.parse(map['date_statut'] as String)
          : null,
      // Identification complémentaire
      siteCooperative: map['site_cooperative'] as String?,
      section: map['section'] as String?,
      // Identité personnelle complémentaire
      sexe: map['sexe'] as String?,
      lieuNaissance: map['lieu_naissance'] as String?,
      nationalite: map['nationalite'] as String?,
      typePiece: map['type_piece'] as String?,
      numeroPiece: map['numero_piece'] as String?,
      // Situation familiale
      nomPere: map['nom_pere'] as String?,
      nomMere: map['nom_mere'] as String?,
      conjoint: map['conjoint'] as String?,
      nombreEnfants: map['nombre_enfants'] as int?,
      // Indicateurs agricoles
      superficieTotaleCultivee: map['superficie_totale_cultivee'] != null
          ? (map['superficie_totale_cultivee'] as num).toDouble()
          : null,
      nombreChamps: map['nombre_champs'] as int?,
      rendementMoyenHa: map['rendement_moyen_ha'] != null
          ? (map['rendement_moyen_ha'] as num).toDouble()
          : null,
      tonnageTotalProduit: map['tonnage_total_produit'] != null
          ? (map['tonnage_total_produit'] as num).toDouble()
          : null,
      tonnageTotalVendu: map['tonnage_total_vendu'] != null
          ? (map['tonnage_total_vendu'] as num).toDouble()
          : null,
      // Photo de profil
      photoPath: map['photo_path'] as String?,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'village': village,
      'adresse': adresse,
      'cnib': cnib,
      'date_naissance': dateNaissance?.toIso8601String(),
      'date_adhesion': dateAdhesion.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // V2: Nouveaux champs
      'categorie': categorie,
      'statut': statut,
      'date_statut': dateStatut?.toIso8601String(),
      // Identification complémentaire
      'site_cooperative': siteCooperative,
      'section': section,
      // Identité personnelle complémentaire
      'sexe': sexe,
      'lieu_naissance': lieuNaissance,
      'nationalite': nationalite,
      'type_piece': typePiece,
      'numero_piece': numeroPiece,
      // Situation familiale
      'nom_pere': nomPere,
      'nom_mere': nomMere,
      'conjoint': conjoint,
      'nombre_enfants': nombreEnfants,
      // Indicateurs agricoles
      'superficie_totale_cultivee': superficieTotaleCultivee,
      'nombre_champs': nombreChamps,
      'rendement_moyen_ha': rendementMoyenHa,
      'tonnage_total_produit': tonnageTotalProduit,
      'tonnage_total_vendu': tonnageTotalVendu,
      // Photo de profil
      'photo_path': photoPath,
    };
  }

  // Créer une copie avec des modifications
  AdherentModel copyWith({
    int? id,
    String? code,
    String? nom,
    String? prenom,
    String? telephone,
    String? email,
    String? village,
    String? adresse,
    String? cnib,
    DateTime? dateNaissance,
    DateTime? dateAdhesion,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categorie,
    String? statut,
    DateTime? dateStatut,
    String? siteCooperative,
    String? section,
    String? sexe,
    String? lieuNaissance,
    String? nationalite,
    String? typePiece,
    String? numeroPiece,
    String? nomPere,
    String? nomMere,
    String? conjoint,
    int? nombreEnfants,
    double? superficieTotaleCultivee,
    int? nombreChamps,
    double? rendementMoyenHa,
    double? tonnageTotalProduit,
    double? tonnageTotalVendu,
    String? photoPath,
  }) {
    return AdherentModel(
      id: id ?? this.id,
      code: code ?? this.code,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      village: village ?? this.village,
      adresse: adresse ?? this.adresse,
      cnib: cnib ?? this.cnib,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      dateAdhesion: dateAdhesion ?? this.dateAdhesion,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // V2: Nouveaux champs
      categorie: categorie ?? this.categorie,
      statut: statut ?? this.statut,
      dateStatut: dateStatut ?? this.dateStatut,
      // Identification complémentaire
      siteCooperative: siteCooperative ?? this.siteCooperative,
      section: section ?? this.section,
      // Identité personnelle complémentaire
      sexe: sexe ?? this.sexe,
      lieuNaissance: lieuNaissance ?? this.lieuNaissance,
      nationalite: nationalite ?? this.nationalite,
      typePiece: typePiece ?? this.typePiece,
      numeroPiece: numeroPiece ?? this.numeroPiece,
      // Situation familiale
      nomPere: nomPere ?? this.nomPere,
      nomMere: nomMere ?? this.nomMere,
      conjoint: conjoint ?? this.conjoint,
      nombreEnfants: nombreEnfants ?? this.nombreEnfants,
      // Indicateurs agricoles
      superficieTotaleCultivee: superficieTotaleCultivee ?? this.superficieTotaleCultivee,
      nombreChamps: nombreChamps ?? this.nombreChamps,
      rendementMoyenHa: rendementMoyenHa ?? this.rendementMoyenHa,
      tonnageTotalProduit: tonnageTotalProduit ?? this.tonnageTotalProduit,
      tonnageTotalVendu: tonnageTotalVendu ?? this.tonnageTotalVendu,
      // Photo de profil
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
