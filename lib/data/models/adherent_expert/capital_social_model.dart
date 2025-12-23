/// MODÈLE : CAPITAL SOCIAL
/// 
/// Représente une souscription au capital social d'un adhérent
class CapitalSocialModel {
  /// Identifiant unique de la souscription
  final int? id;
  
  /// Identifiant de l'adhérent (clé étrangère)
  /// Contrainte: NOT NULL, FOREIGN KEY -> adherents(id)
  final int adherentId;
  
  /// Nombre de parts souscrites
  /// Contrainte: NOT NULL, > 0
  final int nombrePartsSouscrites;
  
  /// Nombre de parts libérées
  /// Défaut: 0
  /// Contrainte: >= 0
  final int nombrePartsLiberees;
  
  /// Nombre de parts restantes à libérer
  /// Calculé: nombre_parts_souscrites - nombre_parts_liberees
  /// Contrainte: >= 0
  final int nombrePartsRestantes;
  
  /// Valeur d'une part (en FCFA)
  /// Contrainte: NOT NULL, > 0
  final double valeurPart;
  
  /// Capital total (nombre_parts_souscrites * valeur_part)
  /// Contrainte: NOT NULL
  final double capitalTotal;
  
  /// Date de souscription
  /// Contrainte: NOT NULL
  final DateTime dateSouscription;
  
  /// Date de libération (si libéré)
  final DateTime? dateLiberation;
  
  /// Statut de la souscription
  /// Valeurs possibles: 'souscrit', 'partiellement_libere', 'libere', 'annule'
  /// Défaut: 'souscrit'
  final String statut;
  
  /// Notes et observations
  final String? notes;
  
  /// Date de création
  final DateTime createdAt;
  
  /// Identifiant de l'utilisateur ayant créé la souscription
  final int? createdBy;
  
  CapitalSocialModel({
    this.id,
    required this.adherentId,
    required this.nombrePartsSouscrites,
    this.nombrePartsLiberees = 0,
    int? nombrePartsRestantes,
    required this.valeurPart,
    double? capitalTotal,
    required this.dateSouscription,
    this.dateLiberation,
    this.statut = 'souscrit',
    this.notes,
    required this.createdAt,
    this.createdBy,
  }) : nombrePartsRestantes = nombrePartsRestantes ?? 
                              (nombrePartsSouscrites - (nombrePartsLiberees)),
       capitalTotal = capitalTotal ?? (nombrePartsSouscrites * valeurPart);
  
  /// Convertir depuis Map (base de données)
  factory CapitalSocialModel.fromMap(Map<String, dynamic> map) {
    final nombrePartsSouscrites = map['nombre_parts_souscrites'] as int;
    final nombrePartsLiberees = map['nombre_parts_liberees'] as int? ?? 0;
    
    return CapitalSocialModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      nombrePartsSouscrites: nombrePartsSouscrites,
      nombrePartsLiberees: nombrePartsLiberees,
      nombrePartsRestantes: map['nombre_parts_restantes'] as int? ?? 
                           (nombrePartsSouscrites - nombrePartsLiberees),
      valeurPart: (map['valeur_part'] as num).toDouble(),
      capitalTotal: (map['capital_total'] as num).toDouble(),
      dateSouscription: DateTime.parse(map['date_souscription'] as String),
      dateLiberation: map['date_liberation'] != null
          ? DateTime.parse(map['date_liberation'] as String)
          : null,
      statut: map['statut'] as String? ?? 'souscrit',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as int?,
    );
  }
  
  /// Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      'nombre_parts_souscrites': nombrePartsSouscrites,
      'nombre_parts_liberees': nombrePartsLiberees,
      'nombre_parts_restantes': nombrePartsRestantes,
      'valeur_part': valeurPart,
      'capital_total': capitalTotal,
      'date_souscription': dateSouscription.toIso8601String(),
      if (dateLiberation != null) 'date_liberation': dateLiberation!.toIso8601String(),
      'statut': statut,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }
  
  /// Créer une copie avec des modifications
  CapitalSocialModel copyWith({
    int? id,
    int? adherentId,
    int? nombrePartsSouscrites,
    int? nombrePartsLiberees,
    int? nombrePartsRestantes,
    double? valeurPart,
    double? capitalTotal,
    DateTime? dateSouscription,
    DateTime? dateLiberation,
    String? statut,
    String? notes,
    DateTime? createdAt,
    int? createdBy,
  }) {
    final newNombrePartsSouscrites = nombrePartsSouscrites ?? this.nombrePartsSouscrites;
    final newNombrePartsLiberees = nombrePartsLiberees ?? this.nombrePartsLiberees;
    final newValeurPart = valeurPart ?? this.valeurPart;
    
    return CapitalSocialModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      nombrePartsSouscrites: newNombrePartsSouscrites,
      nombrePartsLiberees: newNombrePartsLiberees,
      nombrePartsRestantes: nombrePartsRestantes ?? (newNombrePartsSouscrites - newNombrePartsLiberees),
      valeurPart: newValeurPart,
      capitalTotal: capitalTotal ?? (newNombrePartsSouscrites * newValeurPart),
      dateSouscription: dateSouscription ?? this.dateSouscription,
      dateLiberation: dateLiberation ?? this.dateLiberation,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
  
  /// Calculer le statut automatiquement
  String calculateStatut() {
    if (nombrePartsLiberees == 0) {
      return 'souscrit';
    } else if (nombrePartsLiberees == nombrePartsSouscrites) {
      return 'libere';
    } else {
      return 'partiellement_libere';
    }
  }
  
  bool get isSouscrit => statut == 'souscrit';
  bool get isPartiellementLibere => statut == 'partiellement_libere';
  bool get isLibere => statut == 'libere';
  bool get isAnnule => statut == 'annule';
}

