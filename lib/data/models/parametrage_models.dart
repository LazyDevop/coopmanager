/// Modèles de données pour le module de paramétrage complet

// ============================================
// 1. PARAMÉTRAGE DE L'ENTITÉ (COOPÉRATIVE)
// ============================================

enum TypeCooperative { agricole, commerciale, mixte }

enum FormeJuridique { gic, scoops, union }

enum StatutJuridique { actif, suspendu }

enum Devise { xaf, eur, usd, cfa }

enum Langue { fr, en }

enum NiveauMaturite { debutant, structure, avance }

class CooperativeEntityModel {
  final int? id;
  final String raisonSociale;
  final String? sigle;
  final TypeCooperative typeCooperative;
  final FormeJuridique formeJuridique;
  final String? numeroAgrement;
  final DateTime? dateCreation;
  final String? registreCommerce; // RCCM
  final StatutJuridique statutJuridique;
  
  // Localisation
  final String? region;
  final String? departement;
  final String? arrondissement;
  final String? villageQuartier;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? siteWeb;
  final String? logoPath; // BLOB ou URL
  
  // Champs innovants
  final Devise devisePrincipale;
  final Langue langueParDefaut;
  final String fuseauHoraire;
  final String? slogan;
  final String? qrCodeCoop;
  final NiveauMaturite niveauMaturite;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  CooperativeEntityModel({
    this.id,
    required this.raisonSociale,
    this.sigle,
    this.typeCooperative = TypeCooperative.agricole,
    this.formeJuridique = FormeJuridique.scoops,
    this.numeroAgrement,
    this.dateCreation,
    this.registreCommerce,
    this.statutJuridique = StatutJuridique.actif,
    this.region,
    this.departement,
    this.arrondissement,
    this.villageQuartier,
    this.adresse,
    this.telephone,
    this.email,
    this.siteWeb,
    this.logoPath,
    this.devisePrincipale = Devise.xaf,
    this.langueParDefaut = Langue.fr,
    this.fuseauHoraire = 'Africa/Douala',
    this.slogan,
    this.qrCodeCoop,
    this.niveauMaturite = NiveauMaturite.debutant,
    required this.createdAt,
    this.updatedAt,
  });

  factory CooperativeEntityModel.fromMap(Map<String, dynamic> map) {
    return CooperativeEntityModel(
      id: map['id'] as int?,
      raisonSociale: map['raison_sociale'] as String,
      sigle: map['sigle'] as String?,
      typeCooperative: TypeCooperative.values.firstWhere(
        (e) => e.name == map['type_cooperative'],
        orElse: () => TypeCooperative.agricole,
      ),
      formeJuridique: FormeJuridique.values.firstWhere(
        (e) => e.name == map['forme_juridique'],
        orElse: () => FormeJuridique.scoops,
      ),
      numeroAgrement: map['numero_agrement'] as String?,
      dateCreation: map['date_creation'] != null
          ? DateTime.parse(map['date_creation'] as String)
          : null,
      registreCommerce: map['registre_commerce'] as String?,
      statutJuridique: StatutJuridique.values.firstWhere(
        (e) => e.name == map['statut_juridique'],
        orElse: () => StatutJuridique.actif,
      ),
      region: map['region'] as String?,
      departement: map['departement'] as String?,
      arrondissement: map['arrondissement'] as String?,
      villageQuartier: map['village_quartier'] as String?,
      adresse: map['adresse'] as String?,
      telephone: map['telephone'] as String?,
      email: map['email'] as String?,
      siteWeb: map['site_web'] as String?,
      logoPath: map['logo_path'] as String?,
      devisePrincipale: Devise.values.firstWhere(
        (e) => e.name == map['devise_principale'],
        orElse: () => Devise.xaf,
      ),
      langueParDefaut: Langue.values.firstWhere(
        (e) => e.name == map['langue_par_defaut'],
        orElse: () => Langue.fr,
      ),
      fuseauHoraire: map['fuseau_horaire'] as String? ?? 'Africa/Douala',
      slogan: map['slogan'] as String?,
      qrCodeCoop: map['qr_code_coop'] as String?,
      niveauMaturite: NiveauMaturite.values.firstWhere(
        (e) => e.name == map['niveau_maturite'],
        orElse: () => NiveauMaturite.debutant,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'raison_sociale': raisonSociale,
      if (sigle != null) 'sigle': sigle,
      'type_cooperative': typeCooperative.name,
      'forme_juridique': formeJuridique.name,
      if (numeroAgrement != null) 'numero_agrement': numeroAgrement,
      if (dateCreation != null) 'date_creation': dateCreation!.toIso8601String(),
      if (registreCommerce != null) 'registre_commerce': registreCommerce,
      'statut_juridique': statutJuridique.name,
      if (region != null) 'region': region,
      if (departement != null) 'departement': departement,
      if (arrondissement != null) 'arrondissement': arrondissement,
      if (villageQuartier != null) 'village_quartier': villageQuartier,
      if (adresse != null) 'adresse': adresse,
      if (telephone != null) 'telephone': telephone,
      if (email != null) 'email': email,
      if (siteWeb != null) 'site_web': siteWeb,
      if (logoPath != null) 'logo_path': logoPath,
      'devise_principale': devisePrincipale.name,
      'langue_par_defaut': langueParDefaut.name,
      'fuseau_horaire': fuseauHoraire,
      if (slogan != null) 'slogan': slogan,
      if (qrCodeCoop != null) 'qr_code_coop': qrCodeCoop,
      'niveau_maturite': niveauMaturite.name,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  CooperativeEntityModel copyWith({
    int? id,
    String? raisonSociale,
    String? sigle,
    TypeCooperative? typeCooperative,
    FormeJuridique? formeJuridique,
    String? numeroAgrement,
    DateTime? dateCreation,
    String? registreCommerce,
    StatutJuridique? statutJuridique,
    String? region,
    String? departement,
    String? arrondissement,
    String? villageQuartier,
    String? adresse,
    String? telephone,
    String? email,
    String? siteWeb,
    String? logoPath,
    Devise? devisePrincipale,
    Langue? langueParDefaut,
    String? fuseauHoraire,
    String? slogan,
    String? qrCodeCoop,
    NiveauMaturite? niveauMaturite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CooperativeEntityModel(
      id: id ?? this.id,
      raisonSociale: raisonSociale ?? this.raisonSociale,
      sigle: sigle ?? this.sigle,
      typeCooperative: typeCooperative ?? this.typeCooperative,
      formeJuridique: formeJuridique ?? this.formeJuridique,
      numeroAgrement: numeroAgrement ?? this.numeroAgrement,
      dateCreation: dateCreation ?? this.dateCreation,
      registreCommerce: registreCommerce ?? this.registreCommerce,
      statutJuridique: statutJuridique ?? this.statutJuridique,
      region: region ?? this.region,
      departement: departement ?? this.departement,
      arrondissement: arrondissement ?? this.arrondissement,
      villageQuartier: villageQuartier ?? this.villageQuartier,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      siteWeb: siteWeb ?? this.siteWeb,
      logoPath: logoPath ?? this.logoPath,
      devisePrincipale: devisePrincipale ?? this.devisePrincipale,
      langueParDefaut: langueParDefaut ?? this.langueParDefaut,
      fuseauHoraire: fuseauHoraire ?? this.fuseauHoraire,
      slogan: slogan ?? this.slogan,
      qrCodeCoop: qrCodeCoop ?? this.qrCodeCoop,
      niveauMaturite: niveauMaturite ?? this.niveauMaturite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================
// 2. PARAMÉTRAGE ORGANISATIONNEL
// ============================================

class SectionModel {
  final int? id;
  final String code;
  final String nom;
  final String? localisation;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SectionModel({
    this.id,
    required this.code,
    required this.nom,
    this.localisation,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory SectionModel.fromMap(Map<String, dynamic> map) {
    return SectionModel(
      id: map['id'] as int?,
      code: map['code'] as String,
      nom: map['nom'] as String,
      localisation: map['localisation'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'nom': nom,
      if (localisation != null) 'localisation': localisation,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  SectionModel copyWith({
    int? id,
    String? code,
    String? nom,
    String? localisation,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SectionModel(
      id: id ?? this.id,
      code: code ?? this.code,
      nom: nom ?? this.nom,
      localisation: localisation ?? this.localisation,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SiteModel {
  final int? id;
  final String code;
  final String nom;
  final int sectionId;
  final String? localisation;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SiteModel({
    this.id,
    required this.code,
    required this.nom,
    required this.sectionId,
    this.localisation,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory SiteModel.fromMap(Map<String, dynamic> map) {
    return SiteModel(
      id: map['id'] as int?,
      code: map['code'] as String,
      nom: map['nom'] as String,
      sectionId: map['section_id'] as int,
      localisation: map['localisation'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'nom': nom,
      'section_id': sectionId,
      if (localisation != null) 'localisation': localisation,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  SiteModel copyWith({
    int? id,
    String? code,
    String? nom,
    int? sectionId,
    String? localisation,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SiteModel(
      id: id ?? this.id,
      code: code ?? this.code,
      nom: nom ?? this.nom,
      sectionId: sectionId ?? this.sectionId,
      localisation: localisation ?? this.localisation,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum TypeMagasin { principal, secondaire, depot }

class MagasinModel {
  final int? id;
  final String code;
  final String nom;
  final TypeMagasin type;
  final double? capacite; // en kg ou unités
  final int siteId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MagasinModel({
    this.id,
    required this.code,
    required this.nom,
    required this.type,
    this.capacite,
    required this.siteId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory MagasinModel.fromMap(Map<String, dynamic> map) {
    return MagasinModel(
      id: map['id'] as int?,
      code: map['code'] as String,
      nom: map['nom'] as String,
      type: TypeMagasin.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TypeMagasin.depot,
      ),
      capacite: map['capacite'] != null ? (map['capacite'] as num).toDouble() : null,
      siteId: map['site_id'] as int,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'nom': nom,
      'type': type.name,
      if (capacite != null) 'capacite': capacite,
      'site_id': siteId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  MagasinModel copyWith({
    int? id,
    String? code,
    String? nom,
    TypeMagasin? type,
    double? capacite,
    int? siteId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MagasinModel(
      id: id ?? this.id,
      code: code ?? this.code,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      capacite: capacite ?? this.capacite,
      siteId: siteId ?? this.siteId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ComiteModel {
  final int? id;
  final String nom;
  final String role;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ComiteModel({
    this.id,
    required this.nom,
    required this.role,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ComiteModel.fromMap(Map<String, dynamic> map) {
    return ComiteModel(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      role: map['role'] as String,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      'role': role,
      if (description != null) 'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ComiteModel copyWith({
    int? id,
    String? nom,
    String? role,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ComiteModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      role: role ?? this.role,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================
// 3. PARAMÉTRAGE MÉTIER
// ============================================

enum UniteMesure { kg, sac, tonne, quintal }

class ProduitModel {
  final int? id;
  final String codeProduit;
  final String nomProduit;
  final UniteMesure uniteMesure;
  final double? rendementMoyen;
  final double? seuilAlerte; // Stock minimum
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProduitModel({
    this.id,
    required this.codeProduit,
    required this.nomProduit,
    required this.uniteMesure,
    this.rendementMoyen,
    this.seuilAlerte,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProduitModel.fromMap(Map<String, dynamic> map) {
    return ProduitModel(
      id: map['id'] as int?,
      codeProduit: map['code_produit'] as String,
      nomProduit: map['nom_produit'] as String,
      uniteMesure: UniteMesure.values.firstWhere(
        (e) => e.name == map['unite_mesure'],
        orElse: () => UniteMesure.kg,
      ),
      rendementMoyen: map['rendement_moyen'] != null
          ? (map['rendement_moyen'] as num).toDouble()
          : null,
      seuilAlerte: map['seuil_alerte'] != null
          ? (map['seuil_alerte'] as num).toDouble()
          : null,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code_produit': codeProduit,
      'nom_produit': nomProduit,
      'unite_mesure': uniteMesure.name,
      if (rendementMoyen != null) 'rendement_moyen': rendementMoyen,
      if (seuilAlerte != null) 'seuil_alerte': seuilAlerte,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ProduitModel copyWith({
    int? id,
    String? codeProduit,
    String? nomProduit,
    UniteMesure? uniteMesure,
    double? rendementMoyen,
    double? seuilAlerte,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProduitModel(
      id: id ?? this.id,
      codeProduit: codeProduit ?? this.codeProduit,
      nomProduit: nomProduit ?? this.nomProduit,
      uniteMesure: uniteMesure ?? this.uniteMesure,
      rendementMoyen: rendementMoyen ?? this.rendementMoyen,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum MarcheReference { local, export }

enum ModeCalculPrix { pourcentage, fixe }

class PrixMarcheModel {
  final int? id;
  final int produitId;
  final double? prixMin; // Prix plancher
  final double? prixMax; // Prix plafond
  final double? prixJour; // Prix quotidien
  final MarcheReference marcheReference;
  final double? variationAutorisee; // %
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PrixMarcheModel({
    this.id,
    required this.produitId,
    this.prixMin,
    this.prixMax,
    this.prixJour,
    this.marcheReference = MarcheReference.local,
    this.variationAutorisee,
    this.dateDebut,
    this.dateFin,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory PrixMarcheModel.fromMap(Map<String, dynamic> map) {
    return PrixMarcheModel(
      id: map['id'] as int?,
      produitId: map['produit_id'] as int,
      prixMin: map['prix_min'] != null ? (map['prix_min'] as num).toDouble() : null,
      prixMax: map['prix_max'] != null ? (map['prix_max'] as num).toDouble() : null,
      prixJour: map['prix_jour'] != null ? (map['prix_jour'] as num).toDouble() : null,
      marcheReference: MarcheReference.values.firstWhere(
        (e) => e.name == map['marche_reference'],
        orElse: () => MarcheReference.local,
      ),
      variationAutorisee: map['variation_autorisee'] != null
          ? (map['variation_autorisee'] as num).toDouble()
          : null,
      dateDebut: map['date_debut'] != null
          ? DateTime.parse(map['date_debut'] as String)
          : null,
      dateFin: map['date_fin'] != null
          ? DateTime.parse(map['date_fin'] as String)
          : null,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'produit_id': produitId,
      if (prixMin != null) 'prix_min': prixMin,
      if (prixMax != null) 'prix_max': prixMax,
      if (prixJour != null) 'prix_jour': prixJour,
      'marche_reference': marcheReference.name,
      if (variationAutorisee != null) 'variation_autorisee': variationAutorisee,
      if (dateDebut != null) 'date_debut': dateDebut!.toIso8601String(),
      if (dateFin != null) 'date_fin': dateFin!.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  PrixMarcheModel copyWith({
    int? id,
    int? produitId,
    double? prixMin,
    double? prixMax,
    double? prixJour,
    MarcheReference? marcheReference,
    double? variationAutorisee,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrixMarcheModel(
      id: id ?? this.id,
      produitId: produitId ?? this.produitId,
      prixMin: prixMin ?? this.prixMin,
      prixMax: prixMax ?? this.prixMax,
      prixJour: prixJour ?? this.prixJour,
      marcheReference: marcheReference ?? this.marcheReference,
      variationAutorisee: variationAutorisee ?? this.variationAutorisee,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================
// 4. PARAMÉTRAGE FINANCIER & COMPTABLE
// ============================================

class CapitalSocialModel {
  final int? id;
  final double valeurPart;
  final int partsMin;
  final int? partsMax;
  final bool liberationObligatoire;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CapitalSocialModel({
    this.id,
    required this.valeurPart,
    required this.partsMin,
    this.partsMax,
    this.liberationObligatoire = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory CapitalSocialModel.fromMap(Map<String, dynamic> map) {
    return CapitalSocialModel(
      id: map['id'] as int?,
      valeurPart: (map['valeur_part'] as num).toDouble(),
      partsMin: map['parts_min'] as int,
      partsMax: map['parts_max'] as int?,
      liberationObligatoire: (map['liberation_obligatoire'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'valeur_part': valeurPart,
      'parts_min': partsMin,
      if (partsMax != null) 'parts_max': partsMax,
      'liberation_obligatoire': liberationObligatoire ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  CapitalSocialModel copyWith({
    int? id,
    double? valeurPart,
    int? partsMin,
    int? partsMax,
    bool? liberationObligatoire,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CapitalSocialModel(
      id: id ?? this.id,
      valeurPart: valeurPart ?? this.valeurPart,
      partsMin: partsMin ?? this.partsMin,
      partsMax: partsMax ?? this.partsMax,
      liberationObligatoire: liberationObligatoire ?? this.liberationObligatoire,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ParametresComptablesModel {
  final int? id;
  final String planComptable; // SYSCOHADA
  final int exerciceActif; // Année
  final String? compteCaisse;
  final String? compteBanque;
  final double tauxFraisGestion; // %
  final double tauxReserve; // %
  final DateTime createdAt;
  final DateTime? updatedAt;

  ParametresComptablesModel({
    this.id,
    required this.planComptable,
    required this.exerciceActif,
    this.compteCaisse,
    this.compteBanque,
    this.tauxFraisGestion = 0.0,
    this.tauxReserve = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  factory ParametresComptablesModel.fromMap(Map<String, dynamic> map) {
    return ParametresComptablesModel(
      id: map['id'] as int?,
      planComptable: map['plan_comptable'] as String,
      exerciceActif: map['exercice_actif'] as int,
      compteCaisse: map['compte_caisse'] as String?,
      compteBanque: map['compte_banque'] as String?,
      tauxFraisGestion: (map['taux_frais_gestion'] as num? ?? 0).toDouble(),
      tauxReserve: (map['taux_reserve'] as num? ?? 0).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plan_comptable': planComptable,
      'exercice_actif': exerciceActif,
      if (compteCaisse != null) 'compte_caisse': compteCaisse,
      if (compteBanque != null) 'compte_banque': compteBanque,
      'taux_frais_gestion': tauxFraisGestion,
      'taux_reserve': tauxReserve,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ParametresComptablesModel copyWith({
    int? id,
    String? planComptable,
    int? exerciceActif,
    String? compteCaisse,
    String? compteBanque,
    double? tauxFraisGestion,
    double? tauxReserve,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParametresComptablesModel(
      id: id ?? this.id,
      planComptable: planComptable ?? this.planComptable,
      exerciceActif: exerciceActif ?? this.exerciceActif,
      compteCaisse: compteCaisse ?? this.compteCaisse,
      compteBanque: compteBanque ?? this.compteBanque,
      tauxFraisGestion: tauxFraisGestion ?? this.tauxFraisGestion,
      tauxReserve: tauxReserve ?? this.tauxReserve,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RetenueModel {
  final int? id;
  final String typeRetenue; // Transport, manutention, etc.
  final ModeCalculPrix modeCalcul; // % ou fixe
  final double valeur; // % ou montant fixe
  final double? plafondRetenue; // Limite
  final bool retenueAuto; // Application automatique
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RetenueModel({
    this.id,
    required this.typeRetenue,
    required this.modeCalcul,
    required this.valeur,
    this.plafondRetenue,
    this.retenueAuto = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory RetenueModel.fromMap(Map<String, dynamic> map) {
    return RetenueModel(
      id: map['id'] as int?,
      typeRetenue: map['type_retenue'] as String,
      modeCalcul: ModeCalculPrix.values.firstWhere(
        (e) => e.name == map['mode_calcul'],
        orElse: () => ModeCalculPrix.pourcentage,
      ),
      valeur: (map['valeur'] as num).toDouble(),
      plafondRetenue: map['plafond_retenue'] != null
          ? (map['plafond_retenue'] as num).toDouble()
          : null,
      retenueAuto: (map['retenue_auto'] as int? ?? 0) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type_retenue': typeRetenue,
      'mode_calcul': modeCalcul.name,
      'valeur': valeur,
      if (plafondRetenue != null) 'plafond_retenue': plafondRetenue,
      'retenue_auto': retenueAuto ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  RetenueModel copyWith({
    int? id,
    String? typeRetenue,
    ModeCalculPrix? modeCalcul,
    double? valeur,
    double? plafondRetenue,
    bool? retenueAuto,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RetenueModel(
      id: id ?? this.id,
      typeRetenue: typeRetenue ?? this.typeRetenue,
      modeCalcul: modeCalcul ?? this.modeCalcul,
      valeur: valeur ?? this.valeur,
      plafondRetenue: plafondRetenue ?? this.plafondRetenue,
      retenueAuto: retenueAuto ?? this.retenueAuto,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================
// 5. PARAMÉTRAGE COMMERCIAL
// ============================================

class ParametresDocumentsModel {
  final int? id;
  final String prefixFacture; // FAC
  final String prefixRecu; // REC
  final String prefixVente; // VNT
  final String formatNumero; // FAC-2025-0001
  final bool signatureAuto;
  final String formatDefaut; // A4
  final String? piedPage; // Mentions légales
  final bool cachetNumerique;
  final bool exportExcel;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ParametresDocumentsModel({
    this.id,
    this.prefixFacture = 'FAC',
    this.prefixRecu = 'REC',
    this.prefixVente = 'VNT',
    this.formatNumero = '{PREFIX}-{YEAR}-{NUM}',
    this.signatureAuto = false,
    this.formatDefaut = 'A4',
    this.piedPage,
    this.cachetNumerique = false,
    this.exportExcel = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ParametresDocumentsModel.fromMap(Map<String, dynamic> map) {
    return ParametresDocumentsModel(
      id: map['id'] as int?,
      prefixFacture: map['prefix_facture'] as String? ?? 'FAC',
      prefixRecu: map['prefix_recu'] as String? ?? 'REC',
      prefixVente: map['prefix_vente'] as String? ?? 'VNT',
      formatNumero: map['format_numero'] as String? ?? '{PREFIX}-{YEAR}-{NUM}',
      signatureAuto: (map['signature_auto'] as int? ?? 0) == 1,
      formatDefaut: map['format_defaut'] as String? ?? 'A4',
      piedPage: map['pied_page'] as String?,
      cachetNumerique: (map['cachet_numerique'] as int? ?? 0) == 1,
      exportExcel: (map['export_excel'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'prefix_facture': prefixFacture,
      'prefix_recu': prefixRecu,
      'prefix_vente': prefixVente,
      'format_numero': formatNumero,
      'signature_auto': signatureAuto ? 1 : 0,
      'format_defaut': formatDefaut,
      if (piedPage != null) 'pied_page': piedPage,
      'cachet_numerique': cachetNumerique ? 1 : 0,
      'export_excel': exportExcel ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ParametresDocumentsModel copyWith({
    int? id,
    String? prefixFacture,
    String? prefixRecu,
    String? prefixVente,
    String? formatNumero,
    bool? signatureAuto,
    String? formatDefaut,
    String? piedPage,
    bool? cachetNumerique,
    bool? exportExcel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParametresDocumentsModel(
      id: id ?? this.id,
      prefixFacture: prefixFacture ?? this.prefixFacture,
      prefixRecu: prefixRecu ?? this.prefixRecu,
      prefixVente: prefixVente ?? this.prefixVente,
      formatNumero: formatNumero ?? this.formatNumero,
      signatureAuto: signatureAuto ?? this.signatureAuto,
      formatDefaut: formatDefaut ?? this.formatDefaut,
      piedPage: piedPage ?? this.piedPage,
      cachetNumerique: cachetNumerique ?? this.cachetNumerique,
      exportExcel: exportExcel ?? this.exportExcel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================
// 6. PARAMÉTRAGE SÉCURITÉ & UTILISATEURS
// ============================================

class ParametresSecuriteModel {
  final int? id;
  final bool validationDouble; // Pour ventes > X
  final double? seuilValidationDouble; // Montant seuil
  final bool journalAudit; // Traçabilité
  final bool verrouillageExercice;
  final bool sauvegardeAuto;
  final String? frequenceSauvegarde; // Quotidienne, hebdomadaire
  final DateTime createdAt;
  final DateTime? updatedAt;

  ParametresSecuriteModel({
    this.id,
    this.validationDouble = false,
    this.seuilValidationDouble,
    this.journalAudit = true,
    this.verrouillageExercice = false,
    this.sauvegardeAuto = true,
    this.frequenceSauvegarde = 'quotidienne',
    required this.createdAt,
    this.updatedAt,
  });

  factory ParametresSecuriteModel.fromMap(Map<String, dynamic> map) {
    return ParametresSecuriteModel(
      id: map['id'] as int?,
      validationDouble: (map['validation_double'] as int? ?? 0) == 1,
      seuilValidationDouble: map['seuil_validation_double'] != null
          ? (map['seuil_validation_double'] as num).toDouble()
          : null,
      journalAudit: (map['journal_audit'] as int? ?? 1) == 1,
      verrouillageExercice: (map['verrouillage_exercice'] as int? ?? 0) == 1,
      sauvegardeAuto: (map['sauvegarde_auto'] as int? ?? 1) == 1,
      frequenceSauvegarde: map['frequence_sauvegarde'] as String? ?? 'quotidienne',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'validation_double': validationDouble ? 1 : 0,
      if (seuilValidationDouble != null) 'seuil_validation_double': seuilValidationDouble,
      'journal_audit': journalAudit ? 1 : 0,
      'verrouillage_exercice': verrouillageExercice ? 1 : 0,
      'sauvegarde_auto': sauvegardeAuto ? 1 : 0,
      'frequence_sauvegarde': frequenceSauvegarde,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ParametresSecuriteModel copyWith({
    int? id,
    bool? validationDouble,
    double? seuilValidationDouble,
    bool? journalAudit,
    bool? verrouillageExercice,
    bool? sauvegardeAuto,
    String? frequenceSauvegarde,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParametresSecuriteModel(
      id: id ?? this.id,
      validationDouble: validationDouble ?? this.validationDouble,
      seuilValidationDouble: seuilValidationDouble ?? this.seuilValidationDouble,
      journalAudit: journalAudit ?? this.journalAudit,
      verrouillageExercice: verrouillageExercice ?? this.verrouillageExercice,
      sauvegardeAuto: sauvegardeAuto ?? this.sauvegardeAuto,
      frequenceSauvegarde: frequenceSauvegarde ?? this.frequenceSauvegarde,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================
// 7. PARAMÉTRAGE IA & ANALYTIQUE (V2+)
// ============================================

class ParametresIAModel {
  final int? id;
  final double? seuilAnomalie; // Détection fraude
  final bool predictionPrix; // Actif
  final bool scoringAdherent; // Fiabilité
  final bool alertePerformance; // Automatique
  final DateTime createdAt;
  final DateTime? updatedAt;

  ParametresIAModel({
    this.id,
    this.seuilAnomalie,
    this.predictionPrix = false,
    this.scoringAdherent = false,
    this.alertePerformance = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory ParametresIAModel.fromMap(Map<String, dynamic> map) {
    return ParametresIAModel(
      id: map['id'] as int?,
      seuilAnomalie: map['seuil_anomalie'] != null
          ? (map['seuil_anomalie'] as num).toDouble()
          : null,
      predictionPrix: (map['prediction_prix'] as int? ?? 0) == 1,
      scoringAdherent: (map['scoring_adherent'] as int? ?? 0) == 1,
      alertePerformance: (map['alerte_performance'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (seuilAnomalie != null) 'seuil_anomalie': seuilAnomalie,
      'prediction_prix': predictionPrix ? 1 : 0,
      'scoring_adherent': scoringAdherent ? 1 : 0,
      'alerte_performance': alertePerformance ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ParametresIAModel copyWith({
    int? id,
    double? seuilAnomalie,
    bool? predictionPrix,
    bool? scoringAdherent,
    bool? alertePerformance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParametresIAModel(
      id: id ?? this.id,
      seuilAnomalie: seuilAnomalie ?? this.seuilAnomalie,
      predictionPrix: predictionPrix ?? this.predictionPrix,
      scoringAdherent: scoringAdherent ?? this.scoringAdherent,
      alertePerformance: alertePerformance ?? this.alertePerformance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================
// 8. TABLE DE PARAMÉTRAGE TECHNIQUE (GÉNÉRIQUE)
// ============================================

enum SettingType { string, int, bool, json }

class SettingModel {
  final int? id;
  final String category; // finance, vente, coop, sécurité
  final String key;
  final String value;
  final SettingType type;
  final bool editable;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SettingModel({
    this.id,
    required this.category,
    required this.key,
    required this.value,
    required this.type,
    this.editable = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory SettingModel.fromMap(Map<String, dynamic> map) {
    return SettingModel(
      id: map['id'] as int?,
      category: map['category'] as String,
      key: map['key'] as String,
      value: map['value'] as String,
      type: SettingType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SettingType.string,
      ),
      editable: (map['editable'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'key': key,
      'value': value,
      'type': type.name,
      'editable': editable ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Méthodes utilitaires pour convertir la valeur selon le type
  dynamic getTypedValue() {
    switch (type) {
      case SettingType.int:
        return int.tryParse(value);
      case SettingType.bool:
        return value.toLowerCase() == 'true' || value == '1';
      case SettingType.json:
        try {
          return value; // Retourner comme string, le parsing JSON se fera ailleurs
        } catch (e) {
          return value;
        }
      case SettingType.string:
      default:
        return value;
    }
  }

  SettingModel copyWith({
    int? id,
    String? category,
    String? key,
    String? value,
    SettingType? type,
    bool? editable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SettingModel(
      id: id ?? this.id,
      category: category ?? this.category,
      key: key ?? this.key,
      value: value ?? this.value,
      type: type ?? this.type,
      editable: editable ?? this.editable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

