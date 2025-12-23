/// MODÈLE EXPERT : ADHÉRENT / PRODUCTEUR
/// 
/// Entité principale du module Adhérents
/// Contient TOUS les champs nécessaires pour la gestion complète d'un adhérent/producteur
class AdherentExpertModel {
  // ============================================
  // SECTION 1 : IDENTIFICATION
  // ============================================
  
  /// Identifiant unique de l'adhérent (clé primaire)
  final int? id;
  
  /// Code unique de l'adhérent (ex: ADH-2024-001)
  /// Contrainte: UNIQUE, NOT NULL, format: ADH-YYYY-NNNN
  final String codeAdherent;
  
  /// Type de personne dans la coopérative
  /// Valeurs possibles: 'producteur', 'adherent', 'adherent_actionnaire'
  /// Défaut: 'producteur'
  final String typePersonne;
  
  /// Statut de l'adhérent dans la coopérative
  /// Valeurs possibles: 'actif', 'suspendu', 'radie'
  /// Défaut: 'actif'
  final String statut;
  
  /// Date d'adhésion à la coopérative
  /// Contrainte: NOT NULL, date valide
  final DateTime dateAdhesion;
  
  /// Site/Unité coopérative d'appartenance
  /// Ex: 'Site-Centre', 'Site-Nord', etc.
  final String? siteCooperative;
  
  /// Section administrative (région/département)
  final String? section;
  
  /// Village/Localité de résidence
  final String? village;
  
  // ============================================
  // SECTION 2 : IDENTITÉ PERSONNELLE
  // ============================================
  
  /// Nom de famille
  /// Contrainte: NOT NULL, min 2 caractères
  final String nom;
  
  /// Prénom(s)
  /// Contrainte: NOT NULL, min 2 caractères
  final String prenom;
  
  /// Sexe
  /// Valeurs possibles: 'M', 'F', 'Autre'
  final String? sexe;
  
  /// Date de naissance
  /// Contrainte: Date valide, doit être dans le passé
  final DateTime? dateNaissance;
  
  /// Lieu de naissance
  final String? lieuNaissance;
  
  /// Nationalité
  /// Défaut: 'Camerounais'
  final String nationalite;
  
  /// Type de pièce d'identité
  /// Valeurs possibles: 'CNI', 'Passeport', 'Acte_naissance', 'Autre'
  final String? typePiece;
  
  /// Numéro de la pièce d'identité
  /// Contrainte: UNIQUE si fourni
  final String? numeroPiece;
  
  /// Numéro de téléphone principal
  /// Format: +237 6XX XXX XXX ou 6XX XXX XXX
  final String? telephone;
  
  /// Numéro de téléphone secondaire
  final String? telephoneSecondaire;
  
  /// Adresse email
  /// Contrainte: Format email valide si fourni
  final String? email;
  
  /// Adresse complète de résidence
  final String? adresse;
  
  /// Code postal (si applicable)
  final String? codePostal;
  
  // ============================================
  // SECTION 3 : SITUATION FAMILIALE / FILIATION
  // ============================================
  
  /// Nom complet du père
  final String? nomPere;
  
  /// Nom complet de la mère
  final String? nomMere;
  
  /// Nom complet du conjoint(e)
  final String? conjoint;
  
  /// Nombre d'enfants à charge
  /// Défaut: 0
  final int nombreEnfants;
  
  /// Situation matrimoniale
  /// Valeurs possibles: 'celibataire', 'marie', 'divorce', 'veuf', 'concubinage'
  final String? situationMatrimoniale;
  
  // ============================================
  // SECTION 4 : INDICATEURS AGRICOLES GLOBAUX
  // ============================================
  
  /// Superficie totale cultivée (en hectares)
  /// Calculé automatiquement depuis la somme des superficies des champs actifs
  /// Format: REAL (décimal)
  final double superficieTotaleCultivee;
  
  /// Nombre total de champs/parcelles
  /// Calculé automatiquement depuis la table champs
  final int nombreChamps;
  
  /// Rendement moyen par hectare (en tonnes/ha)
  /// Calculé: tonnage_total_produit / superficie_totale_cultivee
  /// Format: REAL
  final double rendementMoyenHa;
  
  /// Tonnage total produit depuis l'adhésion (en tonnes)
  /// Calculé depuis la table production
  /// Format: REAL
  final double tonnageTotalProduit;
  
  /// Tonnage total vendu depuis l'adhésion (en tonnes)
  /// Calculé depuis la table ventes
  /// Format: REAL
  final double tonnageTotalVendu;
  
  /// Tonnage disponible en stock (en tonnes)
  /// Calculé: tonnage_total_produit - tonnage_total_vendu - pertes
  /// Format: REAL
  final double tonnageDisponibleStock;
  
  // ============================================
  // SECTION 5 : INDICATEURS FINANCIERS
  // ============================================
  
  /// Capital social total souscrit (en FCFA)
  /// Calculé depuis la table capital_social
  /// Format: REAL
  final double capitalSocialSouscrit;
  
  /// Capital social libéré (en FCFA)
  /// Format: REAL
  final double capitalSocialLibere;
  
  /// Capital social restant à libérer (en FCFA)
  /// Calculé: capital_social_souscrit - capital_social_libere
  /// Format: REAL
  final double capitalSocialRestant;
  
  /// Montant total des ventes (en FCFA)
  /// Calculé depuis la table ventes
  /// Format: REAL
  final double montantTotalVentes;
  
  /// Montant total des paiements reçus (en FCFA)
  /// Calculé depuis la table journal_paie
  /// Format: REAL
  final double montantTotalPaye;
  
  /// Solde créditeur (montant dû à l'adhérent) (en FCFA)
  /// Calculé: montant_total_ventes - montant_total_paye - retenues
  /// Format: REAL
  final double soldeCrediteur;
  
  /// Solde débiteur (montant dû par l'adhérent) (en FCFA)
  /// Format: REAL
  final double soldeDebiteur;
  
  // ============================================
  // SECTION 6 : MÉTADONNÉES
  // ============================================
  
  /// Date de création de l'enregistrement
  /// Contrainte: NOT NULL
  final DateTime createdAt;
  
  /// Date de dernière modification
  final DateTime? updatedAt;
  
  /// Identifiant de l'utilisateur ayant créé l'adhérent
  final int? createdBy;
  
  /// Identifiant de l'utilisateur ayant modifié l'adhérent
  final int? updatedBy;
  
  /// Photo de profil (chemin vers le fichier)
  final String? photoPath;
  
  /// Notes et observations générales
  final String? notes;
  
  /// Indicateur de suppression logique
  /// Défaut: false
  final bool isDeleted;
  
  /// Date de suppression logique
  final DateTime? deletedAt;
  
  // ============================================
  // CONSTRUCTEUR
  // ============================================
  
  AdherentExpertModel({
    this.id,
    required this.codeAdherent,
    this.typePersonne = 'producteur',
    this.statut = 'actif',
    required this.dateAdhesion,
    this.siteCooperative,
    this.section,
    this.village,
    required this.nom,
    required this.prenom,
    this.sexe,
    this.dateNaissance,
    this.lieuNaissance,
    this.nationalite = 'Camerounais',
    this.typePiece,
    this.numeroPiece,
    this.telephone,
    this.telephoneSecondaire,
    this.email,
    this.adresse,
    this.codePostal,
    this.nomPere,
    this.nomMere,
    this.conjoint,
    this.nombreEnfants = 0,
    this.situationMatrimoniale,
    this.superficieTotaleCultivee = 0.0,
    this.nombreChamps = 0,
    this.rendementMoyenHa = 0.0,
    this.tonnageTotalProduit = 0.0,
    this.tonnageTotalVendu = 0.0,
    this.tonnageDisponibleStock = 0.0,
    this.capitalSocialSouscrit = 0.0,
    this.capitalSocialLibere = 0.0,
    this.capitalSocialRestant = 0.0,
    this.montantTotalVentes = 0.0,
    this.montantTotalPaye = 0.0,
    this.soldeCrediteur = 0.0,
    this.soldeDebiteur = 0.0,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.photoPath,
    this.notes,
    this.isDeleted = false,
    this.deletedAt,
  });
  
  // ============================================
  // GETTERS CALCULÉS
  // ============================================
  
  /// Nom complet de l'adhérent
  String get fullName => '$prenom $nom';
  
  /// Code complet avec type
  String get codeComplet => '$codeAdherent ($typePersonne)';
  
  /// Âge calculé depuis la date de naissance
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
  
  /// Indicateur si l'adhérent est actif
  bool get isActif => statut == 'actif' && !isDeleted;
  
  /// Indicateur si l'adhérent est producteur
  bool get isProducteur => typePersonne == 'producteur';
  
  /// Indicateur si l'adhérent a des ayants droit
  bool get hasAyantsDroit => nombreEnfants > 0;
  
  // ============================================
  // MÉTHODES DE SÉRIALISATION
  // ============================================
  
  /// Convertir depuis Map (base de données)
  factory AdherentExpertModel.fromMap(Map<String, dynamic> map) {
    return AdherentExpertModel(
      id: map['id'] as int?,
      codeAdherent: map['code_adherent'] as String,
      typePersonne: map['type_personne'] as String? ?? 'producteur',
      statut: map['statut'] as String? ?? 'actif',
      dateAdhesion: DateTime.parse(map['date_adhesion'] as String),
      siteCooperative: map['site_cooperative'] as String?,
      section: map['section'] as String?,
      village: map['village'] as String?,
      nom: map['nom'] as String,
      prenom: map['prenom'] as String,
      sexe: map['sexe'] as String?,
      dateNaissance: map['date_naissance'] != null
          ? DateTime.parse(map['date_naissance'] as String)
          : null,
      lieuNaissance: map['lieu_naissance'] as String?,
      nationalite: map['nationalite'] as String? ?? 'Camerounais',
      typePiece: map['type_piece'] as String?,
      numeroPiece: map['numero_piece'] as String?,
      telephone: map['telephone'] as String?,
      telephoneSecondaire: map['telephone_secondaire'] as String?,
      email: map['email'] as String?,
      adresse: map['adresse'] as String?,
      codePostal: map['code_postal'] as String?,
      nomPere: map['nom_pere'] as String?,
      nomMere: map['nom_mere'] as String?,
      conjoint: map['conjoint'] as String?,
      nombreEnfants: map['nombre_enfants'] as int? ?? 0,
      situationMatrimoniale: map['situation_matrimoniale'] as String?,
      superficieTotaleCultivee: (map['superficie_totale_cultivee'] as num?)?.toDouble() ?? 0.0,
      nombreChamps: map['nombre_champs'] as int? ?? 0,
      rendementMoyenHa: (map['rendement_moyen_ha'] as num?)?.toDouble() ?? 0.0,
      tonnageTotalProduit: (map['tonnage_total_produit'] as num?)?.toDouble() ?? 0.0,
      tonnageTotalVendu: (map['tonnage_total_vendu'] as num?)?.toDouble() ?? 0.0,
      tonnageDisponibleStock: (map['tonnage_disponible_stock'] as num?)?.toDouble() ?? 0.0,
      capitalSocialSouscrit: (map['capital_social_souscrit'] as num?)?.toDouble() ?? 0.0,
      capitalSocialLibere: (map['capital_social_libere'] as num?)?.toDouble() ?? 0.0,
      capitalSocialRestant: (map['capital_social_restant'] as num?)?.toDouble() ?? 0.0,
      montantTotalVentes: (map['montant_total_ventes'] as num?)?.toDouble() ?? 0.0,
      montantTotalPaye: (map['montant_total_paye'] as num?)?.toDouble() ?? 0.0,
      soldeCrediteur: (map['solde_crediteur'] as num?)?.toDouble() ?? 0.0,
      soldeDebiteur: (map['solde_debiteur'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      createdBy: map['created_by'] as int?,
      updatedBy: map['updated_by'] as int?,
      photoPath: map['photo_path'] as String?,
      notes: map['notes'] as String?,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
    );
  }
  
  /// Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code_adherent': codeAdherent,
      'type_personne': typePersonne,
      'statut': statut,
      'date_adhesion': dateAdhesion.toIso8601String(),
      'site_cooperative': siteCooperative,
      'section': section,
      'village': village,
      'nom': nom,
      'prenom': prenom,
      'sexe': sexe,
      'date_naissance': dateNaissance?.toIso8601String(),
      'lieu_naissance': lieuNaissance,
      'nationalite': nationalite,
      'type_piece': typePiece,
      'numero_piece': numeroPiece,
      'telephone': telephone,
      'telephone_secondaire': telephoneSecondaire,
      'email': email,
      'adresse': adresse,
      'code_postal': codePostal,
      'nom_pere': nomPere,
      'nom_mere': nomMere,
      'conjoint': conjoint,
      'nombre_enfants': nombreEnfants,
      'situation_matrimoniale': situationMatrimoniale,
      'superficie_totale_cultivee': superficieTotaleCultivee,
      'nombre_champs': nombreChamps,
      'rendement_moyen_ha': rendementMoyenHa,
      'tonnage_total_produit': tonnageTotalProduit,
      'tonnage_total_vendu': tonnageTotalVendu,
      'tonnage_disponible_stock': tonnageDisponibleStock,
      'capital_social_souscrit': capitalSocialSouscrit,
      'capital_social_libere': capitalSocialLibere,
      'capital_social_restant': capitalSocialRestant,
      'montant_total_ventes': montantTotalVentes,
      'montant_total_paye': montantTotalPaye,
      'solde_crediteur': soldeCrediteur,
      'solde_debiteur': soldeDebiteur,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
      'photo_path': photoPath,
      'notes': notes,
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
  
  /// Créer une copie avec des modifications
  AdherentExpertModel copyWith({
    int? id,
    String? codeAdherent,
    String? typePersonne,
    String? statut,
    DateTime? dateAdhesion,
    String? siteCooperative,
    String? section,
    String? village,
    String? nom,
    String? prenom,
    String? sexe,
    DateTime? dateNaissance,
    String? lieuNaissance,
    String? nationalite,
    String? typePiece,
    String? numeroPiece,
    String? telephone,
    String? telephoneSecondaire,
    String? email,
    String? adresse,
    String? codePostal,
    String? nomPere,
    String? nomMere,
    String? conjoint,
    int? nombreEnfants,
    String? situationMatrimoniale,
    double? superficieTotaleCultivee,
    int? nombreChamps,
    double? rendementMoyenHa,
    double? tonnageTotalProduit,
    double? tonnageTotalVendu,
    double? tonnageDisponibleStock,
    double? capitalSocialSouscrit,
    double? capitalSocialLibere,
    double? capitalSocialRestant,
    double? montantTotalVentes,
    double? montantTotalPaye,
    double? soldeCrediteur,
    double? soldeDebiteur,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    int? updatedBy,
    String? photoPath,
    String? notes,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return AdherentExpertModel(
      id: id ?? this.id,
      codeAdherent: codeAdherent ?? this.codeAdherent,
      typePersonne: typePersonne ?? this.typePersonne,
      statut: statut ?? this.statut,
      dateAdhesion: dateAdhesion ?? this.dateAdhesion,
      siteCooperative: siteCooperative ?? this.siteCooperative,
      section: section ?? this.section,
      village: village ?? this.village,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      sexe: sexe ?? this.sexe,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      lieuNaissance: lieuNaissance ?? this.lieuNaissance,
      nationalite: nationalite ?? this.nationalite,
      typePiece: typePiece ?? this.typePiece,
      numeroPiece: numeroPiece ?? this.numeroPiece,
      telephone: telephone ?? this.telephone,
      telephoneSecondaire: telephoneSecondaire ?? this.telephoneSecondaire,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      codePostal: codePostal ?? this.codePostal,
      nomPere: nomPere ?? this.nomPere,
      nomMere: nomMere ?? this.nomMere,
      conjoint: conjoint ?? this.conjoint,
      nombreEnfants: nombreEnfants ?? this.nombreEnfants,
      situationMatrimoniale: situationMatrimoniale ?? this.situationMatrimoniale,
      superficieTotaleCultivee: superficieTotaleCultivee ?? this.superficieTotaleCultivee,
      nombreChamps: nombreChamps ?? this.nombreChamps,
      rendementMoyenHa: rendementMoyenHa ?? this.rendementMoyenHa,
      tonnageTotalProduit: tonnageTotalProduit ?? this.tonnageTotalProduit,
      tonnageTotalVendu: tonnageTotalVendu ?? this.tonnageTotalVendu,
      tonnageDisponibleStock: tonnageDisponibleStock ?? this.tonnageDisponibleStock,
      capitalSocialSouscrit: capitalSocialSouscrit ?? this.capitalSocialSouscrit,
      capitalSocialLibere: capitalSocialLibere ?? this.capitalSocialLibere,
      capitalSocialRestant: capitalSocialRestant ?? this.capitalSocialRestant,
      montantTotalVentes: montantTotalVentes ?? this.montantTotalVentes,
      montantTotalPaye: montantTotalPaye ?? this.montantTotalPaye,
      soldeCrediteur: soldeCrediteur ?? this.soldeCrediteur,
      soldeDebiteur: soldeDebiteur ?? this.soldeDebiteur,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

