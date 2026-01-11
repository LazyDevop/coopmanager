/// MODÈLE : CHAMP / PARCELLE AGRICOLE
/// 
/// Représente un champ ou une parcelle agricole appartenant à un adhérent
class ChampParcelleModel {
  /// Identifiant unique du champ
  final int? id;
  
  /// Identifiant de l'adhérent propriétaire (clé étrangère)
  /// Contrainte: NOT NULL, FOREIGN KEY -> adherents(id)
  final int adherentId;
  
  /// Code unique du champ (ex: CH-ADH001-001)
  /// Contrainte: UNIQUE, NOT NULL
  final String codeChamp;
  
  /// Nom ou désignation du champ
  /// Ex: "Champ Nord", "Parcelle A", etc.
  final String? nomChamp;
  
  /// Localisation précise du champ
  /// Peut contenir: coordonnées GPS, description géographique, etc.
  final String? localisation;
  
  /// Coordonnées GPS - Latitude
  final double? latitude;
  
  /// Coordonnées GPS - Longitude
  final double? longitude;
  
  /// Superficie du champ en hectares
  /// Contrainte: NOT NULL, > 0
  /// Format: REAL
  final double superficie;
  
  /// Type de sol
  /// Valeurs possibles: 'argileux', 'sableux', 'limoneux', 'volcanique', 'autre'
  final String? typeSol;
  
  /// Année de mise en culture
  /// Contrainte: Année valide
  final int? anneeMiseEnCulture;
  
  /// État actuel du champ
  /// Valeurs possibles: 'actif', 'repos', 'abandonne', 'en_preparation'
  /// Défaut: 'actif'
  final String etatChamp;
  
  /// Rendement estimé par hectare (en tonnes/ha)
  /// Format: REAL
  final double rendementEstime;
  
  /// Campagne agricole actuelle
  /// Format: YYYY-YYYY (ex: 2023-2024)
  final String? campagneAgricole;
  
  /// Variété de cacao cultivée
  /// Valeurs possibles: 'forastero', 'criollo', 'trinitario', 'hybride'
  final String? varieteCacao;
  
  /// Nombre d'arbres plantés
  final int? nombreArbres;
  
  /// Âge moyen des arbres (en années)
  final int? ageMoyenArbres;
  
  /// Densité des arbres associés (arbres/hectare)
  final double? densiteArbresAssocies;
  
  /// Système d'irrigation
  /// Valeurs possibles: 'pluvial', 'irrigue', 'mixte'
  final String? systemeIrrigation;
  
  /// Notes et observations
  final String? notes;
  
  /// Date de création
  final DateTime createdAt;
  
  /// Date de modification
  final DateTime? updatedAt;
  
  /// Indicateur de suppression logique
  final bool isDeleted;
  
  ChampParcelleModel({
    this.id,
    required this.adherentId,
    required this.codeChamp,
    this.nomChamp,
    this.localisation,
    this.latitude,
    this.longitude,
    required this.superficie,
    this.typeSol,
    this.anneeMiseEnCulture,
    this.etatChamp = 'actif',
    this.rendementEstime = 0.0,
    this.campagneAgricole,
    this.varieteCacao,
    this.nombreArbres,
    this.ageMoyenArbres,
    this.densiteArbresAssocies,
    this.systemeIrrigation,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });
  
  /// Production potentielle estimée (superficie × rendement)
  double get productionPotentielle => superficie * rendementEstime;
  
  /// Indicateur si le champ est actif
  bool get isActif => etatChamp == 'actif' && !isDeleted;
  
  factory ChampParcelleModel.fromMap(Map<String, dynamic> map) {
    return ChampParcelleModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      codeChamp: map['code_champ'] as String,
      nomChamp: map['nom_champ'] as String?,
      localisation: map['localisation'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      superficie: (map['superficie'] as num).toDouble(),
      typeSol: map['type_sol'] as String?,
      anneeMiseEnCulture: map['annee_mise_en_culture'] as int?,
      etatChamp: map['etat_champ'] as String? ?? 'actif',
      rendementEstime: (map['rendement_estime'] as num?)?.toDouble() ?? 0.0,
      campagneAgricole: map['campagne_agricole'] as String?,
      varieteCacao: map['variete_cacao'] as String?,
      nombreArbres: map['nombre_arbres'] as int?,
      ageMoyenArbres: map['age_moyen_arbres'] as int?,
      densiteArbresAssocies: (map['densite_arbres_associes'] as num?)?.toDouble(),
      systemeIrrigation: map['systeme_irrigation'] as String?,
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
      'code_champ': codeChamp,
      'nom_champ': nomChamp,
      'localisation': localisation,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'superficie': superficie,
      'type_sol': typeSol,
      'annee_mise_en_culture': anneeMiseEnCulture,
      'etat_champ': etatChamp,
      'rendement_estime': rendementEstime,
      'campagne_agricole': campagneAgricole,
      'variete_cacao': varieteCacao,
      'nombre_arbres': nombreArbres,
      'age_moyen_arbres': ageMoyenArbres,
      'densite_arbres_associes': densiteArbresAssocies,
      'systeme_irrigation': systemeIrrigation,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }
  
  ChampParcelleModel copyWith({
    int? id,
    int? adherentId,
    String? codeChamp,
    String? nomChamp,
    String? localisation,
    double? latitude,
    double? longitude,
    double? superficie,
    String? typeSol,
    int? anneeMiseEnCulture,
    String? etatChamp,
    double? rendementEstime,
    String? campagneAgricole,
    String? varieteCacao,
    int? nombreArbres,
    int? ageMoyenArbres,
    double? densiteArbresAssocies,
    String? systemeIrrigation,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return ChampParcelleModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      codeChamp: codeChamp ?? this.codeChamp,
      nomChamp: nomChamp ?? this.nomChamp,
      localisation: localisation ?? this.localisation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      superficie: superficie ?? this.superficie,
      typeSol: typeSol ?? this.typeSol,
      anneeMiseEnCulture: anneeMiseEnCulture ?? this.anneeMiseEnCulture,
      etatChamp: etatChamp ?? this.etatChamp,
      rendementEstime: rendementEstime ?? this.rendementEstime,
      campagneAgricole: campagneAgricole ?? this.campagneAgricole,
      varieteCacao: varieteCacao ?? this.varieteCacao,
      nombreArbres: nombreArbres ?? this.nombreArbres,
      ageMoyenArbres: ageMoyenArbres ?? this.ageMoyenArbres,
      densiteArbresAssocies: densiteArbresAssocies ?? this.densiteArbresAssocies,
      systemeIrrigation: systemeIrrigation ?? this.systemeIrrigation,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

