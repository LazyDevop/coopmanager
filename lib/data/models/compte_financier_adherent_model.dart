/// Modèle pour le compte financier d'un adhérent
/// 
/// Représente l'état financier complet d'un adhérent avec :
/// - Solde total disponible
/// - Total des recettes générées
/// - Total payé
/// - Total en attente
/// - Total des retenues sociales
/// - Historique complet des opérations

class CompteFinancierAdherentModel {
  final int adherentId;
  final String adherentCode;
  final String adherentNom;
  final String adherentPrenom;
  
  // Soldes
  final double soldeTotal; // Montant total disponible (recettes nettes - paiements - retenues)
  final double totalRecettesGenerees; // Total des recettes nettes générées
  final double totalPaye; // Total des paiements effectués
  final double totalEnAttente; // Total non payé (recettes - paiements)
  final double totalRetenuesSociales; // Total des retenues sociales
  
  // Détails par campagne
  final Map<int, double> soldeParCampagne; // campagneId -> solde
  
  // Dates
  final DateTime? dateDerniereRecette;
  final DateTime? dateDernierPaiement;
  final DateTime? dateDerniereRetenue;
  
  // Statistiques
  final int nombreRecettes;
  final int nombrePaiements;
  final int nombreRetenues;

  CompteFinancierAdherentModel({
    required this.adherentId,
    required this.adherentCode,
    required this.adherentNom,
    required this.adherentPrenom,
    required this.soldeTotal,
    required this.totalRecettesGenerees,
    required this.totalPaye,
    required this.totalEnAttente,
    required this.totalRetenuesSociales,
    required this.soldeParCampagne,
    this.dateDerniereRecette,
    this.dateDernierPaiement,
    this.dateDerniereRetenue,
    required this.nombreRecettes,
    required this.nombrePaiements,
    required this.nombreRetenues,
  });

  String get adherentFullName => '$adherentPrenom $adherentNom';
  
  /// Calculer le solde disponible (recettes - paiements - retenues)
  double get soldeDisponible => soldeTotal;
  
  /// Vérifier si le compte a un solde positif
  bool get aSoldePositif => soldeTotal > 0;
  
  /// Vérifier si le compte a un solde en attente
  bool get aSoldeEnAttente => totalEnAttente > 0;
  
  /// Obtenir le pourcentage payé
  double get pourcentagePaye {
    if (totalRecettesGenerees == 0) return 0.0;
    return (totalPaye / totalRecettesGenerees) * 100;
  }

  // Convertir depuis Map (base de données)
  factory CompteFinancierAdherentModel.fromMap(Map<String, dynamic> map) {
    // Parser soldeParCampagne depuis JSON string si présent
    Map<int, double> soldeParCampagne = {};
    if (map['solde_par_campagne'] != null) {
      final json = map['solde_par_campagne'] as String;
      // TODO: Parser JSON si nécessaire
    }
    
    return CompteFinancierAdherentModel(
      adherentId: map['adherent_id'] as int,
      adherentCode: map['adherent_code'] as String,
      adherentNom: map['adherent_nom'] as String,
      adherentPrenom: map['adherent_prenom'] as String,
      soldeTotal: (map['solde_total'] as num).toDouble(),
      totalRecettesGenerees: (map['total_recettes_generees'] as num).toDouble(),
      totalPaye: (map['total_paye'] as num).toDouble(),
      totalEnAttente: (map['total_en_attente'] as num).toDouble(),
      totalRetenuesSociales: (map['total_retenues_sociales'] as num).toDouble(),
      soldeParCampagne: soldeParCampagne,
      dateDerniereRecette: map['date_derniere_recette'] != null
          ? DateTime.parse(map['date_derniere_recette'] as String)
          : null,
      dateDernierPaiement: map['date_dernier_paiement'] != null
          ? DateTime.parse(map['date_dernier_paiement'] as String)
          : null,
      dateDerniereRetenue: map['date_derniere_retenue'] != null
          ? DateTime.parse(map['date_derniere_retenue'] as String)
          : null,
      nombreRecettes: map['nombre_recettes'] as int,
      nombrePaiements: map['nombre_paiements'] as int,
      nombreRetenues: map['nombre_retenues'] as int,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      'adherent_id': adherentId,
      'adherent_code': adherentCode,
      'adherent_nom': adherentNom,
      'adherent_prenom': adherentPrenom,
      'solde_total': soldeTotal,
      'total_recettes_generees': totalRecettesGenerees,
      'total_paye': totalPaye,
      'total_en_attente': totalEnAttente,
      'total_retenues_sociales': totalRetenuesSociales,
      'date_derniere_recette': dateDerniereRecette?.toIso8601String(),
      'date_dernier_paiement': dateDernierPaiement?.toIso8601String(),
      'date_derniere_retenue': dateDerniereRetenue?.toIso8601String(),
      'nombre_recettes': nombreRecettes,
      'nombre_paiements': nombrePaiements,
      'nombre_retenues': nombreRetenues,
    };
  }

  // Créer une copie avec des modifications
  CompteFinancierAdherentModel copyWith({
    int? adherentId,
    String? adherentCode,
    String? adherentNom,
    String? adherentPrenom,
    double? soldeTotal,
    double? totalRecettesGenerees,
    double? totalPaye,
    double? totalEnAttente,
    double? totalRetenuesSociales,
    Map<int, double>? soldeParCampagne,
    DateTime? dateDerniereRecette,
    DateTime? dateDernierPaiement,
    DateTime? dateDerniereRetenue,
    int? nombreRecettes,
    int? nombrePaiements,
    int? nombreRetenues,
  }) {
    return CompteFinancierAdherentModel(
      adherentId: adherentId ?? this.adherentId,
      adherentCode: adherentCode ?? this.adherentCode,
      adherentNom: adherentNom ?? this.adherentNom,
      adherentPrenom: adherentPrenom ?? this.adherentPrenom,
      soldeTotal: soldeTotal ?? this.soldeTotal,
      totalRecettesGenerees: totalRecettesGenerees ?? this.totalRecettesGenerees,
      totalPaye: totalPaye ?? this.totalPaye,
      totalEnAttente: totalEnAttente ?? this.totalEnAttente,
      totalRetenuesSociales: totalRetenuesSociales ?? this.totalRetenuesSociales,
      soldeParCampagne: soldeParCampagne ?? this.soldeParCampagne,
      dateDerniereRecette: dateDerniereRecette ?? this.dateDerniereRecette,
      dateDernierPaiement: dateDernierPaiement ?? this.dateDernierPaiement,
      dateDerniereRetenue: dateDerniereRetenue ?? this.dateDerniereRetenue,
      nombreRecettes: nombreRecettes ?? this.nombreRecettes,
      nombrePaiements: nombrePaiements ?? this.nombrePaiements,
      nombreRetenues: nombreRetenues ?? this.nombreRetenues,
    );
  }
}

