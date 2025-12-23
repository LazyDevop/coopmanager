/// MODÈLE : CRÉDIT SOCIAL
/// 
/// Représente un crédit social accordé à un adhérent
/// Types possibles: 'credit_produit' (crédit en produits) ou 'credit_argent' (crédit en argent)
class CreditSocialModel {
  /// Identifiant unique du crédit
  final int? id;
  
  /// Identifiant de l'adhérent (clé étrangère)
  /// Contrainte: NOT NULL, FOREIGN KEY -> adherents(id)
  final int adherentId;
  
  /// Type de crédit
  /// Valeurs possibles: 'credit_produit', 'credit_argent'
  /// Contrainte: NOT NULL
  final String typeCredit;
  
  /// Type d'aide sociale (pour classification)
  /// Valeurs possibles: 'credit', 'don', 'soutien', 'aide_sante', 'aide_education', 'autre'
  final String typeAide;
  
  /// Montant du crédit (en FCFA) - pour crédit_argent
  /// Pour crédit_produit, représente la valeur estimée du produit
  /// Contrainte: NOT NULL, > 0
  final double montant;
  
  /// Quantité de produit (en kg) - pour crédit_produit uniquement
  final double? quantiteProduit;
  
  /// Type de produit - pour crédit_produit uniquement
  /// Ex: 'cacao', 'engrais', 'pesticide', etc.
  final String? typeProduit;
  
  /// Date d'octroi du crédit
  /// Contrainte: NOT NULL
  final DateTime dateOctroi;
  
  /// Motif du crédit
  /// Contrainte: NOT NULL
  final String motif;
  
  /// Statut de remboursement
  /// Valeurs possibles: 'non_rembourse', 'partiellement_rembourse', 'rembourse', 'annule'
  /// Défaut: 'non_rembourse'
  final String statutRemboursement;
  
  /// Solde restant à rembourser (en FCFA)
  /// Pour crédit_produit, représente la valeur restante
  /// Contrainte: NOT NULL, >= 0, <= montant
  final double soldeRestant;
  
  /// Date d'échéance de remboursement
  final DateTime? echeanceRemboursement;
  
  /// Observations et notes
  final String? observation;
  
  /// Date de création
  final DateTime createdAt;
  
  /// Identifiant de l'utilisateur ayant créé le crédit
  final int? createdBy;
  
  CreditSocialModel({
    this.id,
    required this.adherentId,
    required this.typeCredit,
    this.typeAide = 'credit',
    required this.montant,
    this.quantiteProduit,
    this.typeProduit,
    required this.dateOctroi,
    required this.motif,
    this.statutRemboursement = 'non_rembourse',
    required this.soldeRestant,
    this.echeanceRemboursement,
    this.observation,
    required this.createdAt,
    this.createdBy,
  });
  
  /// Convertir depuis Map (base de données)
  factory CreditSocialModel.fromMap(Map<String, dynamic> map) {
    return CreditSocialModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      typeCredit: (map['type_credit'] as String?) ?? 
                  ((map['type_aide'] as String?) == 'credit' ? 'credit_argent' : 'credit_produit'),
      typeAide: map['type_aide'] as String? ?? 'credit',
      montant: (map['montant'] as num).toDouble(),
      quantiteProduit: map['quantite_produit'] != null 
          ? (map['quantite_produit'] as num).toDouble() 
          : null,
      typeProduit: map['type_produit'] as String?,
      dateOctroi: DateTime.parse(map['date_octroi'] as String),
      motif: map['motif'] as String,
      statutRemboursement: map['statut_remboursement'] as String? ?? 'non_rembourse',
      soldeRestant: (map['solde_restant'] as num).toDouble(),
      echeanceRemboursement: map['echeance_remboursement'] != null
          ? DateTime.parse(map['echeance_remboursement'] as String)
          : null,
      observation: map['observation'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as int?,
    );
  }
  
  /// Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      'type_credit': typeCredit,
      'type_aide': typeAide,
      'montant': montant,
      if (quantiteProduit != null) 'quantite_produit': quantiteProduit,
      if (typeProduit != null) 'type_produit': typeProduit,
      'date_octroi': dateOctroi.toIso8601String(),
      'motif': motif,
      'statut_remboursement': statutRemboursement,
      'solde_restant': soldeRestant,
      if (echeanceRemboursement != null) 'echeance_remboursement': echeanceRemboursement!.toIso8601String(),
      if (observation != null) 'observation': observation,
      'created_at': createdAt.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }
  
  /// Créer une copie avec des modifications
  CreditSocialModel copyWith({
    int? id,
    int? adherentId,
    String? typeCredit,
    String? typeAide,
    double? montant,
    double? quantiteProduit,
    String? typeProduit,
    DateTime? dateOctroi,
    String? motif,
    String? statutRemboursement,
    double? soldeRestant,
    DateTime? echeanceRemboursement,
    String? observation,
    DateTime? createdAt,
    int? createdBy,
  }) {
    return CreditSocialModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      typeCredit: typeCredit ?? this.typeCredit,
      typeAide: typeAide ?? this.typeAide,
      montant: montant ?? this.montant,
      quantiteProduit: quantiteProduit ?? this.quantiteProduit,
      typeProduit: typeProduit ?? this.typeProduit,
      dateOctroi: dateOctroi ?? this.dateOctroi,
      motif: motif ?? this.motif,
      statutRemboursement: statutRemboursement ?? this.statutRemboursement,
      soldeRestant: soldeRestant ?? this.soldeRestant,
      echeanceRemboursement: echeanceRemboursement ?? this.echeanceRemboursement,
      observation: observation ?? this.observation,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
  
  bool get isCreditProduit => typeCredit == 'credit_produit';
  bool get isCreditArgent => typeCredit == 'credit_argent';
  bool get isNonRembourse => statutRemboursement == 'non_rembourse';
  bool get isPartiellementRembourse => statutRemboursement == 'partiellement_rembourse';
  bool get isRembourse => statutRemboursement == 'rembourse';
  bool get isAnnule => statutRemboursement == 'annule';
  
  /// Calculer le montant remboursé
  double get montantRembourse => montant - soldeRestant;
  
  /// Calculer le pourcentage de remboursement
  double get pourcentageRembourse => montant > 0 ? (montantRembourse / montant) * 100 : 0.0;
}

