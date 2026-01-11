/// Modèle de données pour un Lot de Vente (V2)
/// 
/// Permet de constituer des lots intelligents par campagne, qualité, catégorie producteur
class LotVenteModel {
  final int? id;
  final String codeLot;
  final int? campagneId;
  final String? qualite; // Qualité du cacao dans le lot
  final String? categorieProducteur; // Catégorie des producteurs dans le lot
  final double quantiteTotal;
  final double prixUnitairePropose;
  final int? clientId;
  final String statut; // 'preparation', 'valide', 'exclu', 'vendu'
  final String? notes;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime? dateValidation;
  final DateTime? dateVente;

  LotVenteModel({
    this.id,
    required this.codeLot,
    this.campagneId,
    this.qualite,
    this.categorieProducteur,
    required this.quantiteTotal,
    required this.prixUnitairePropose,
    this.clientId,
    this.statut = 'preparation',
    this.notes,
    this.createdBy,
    required this.createdAt,
    this.dateValidation,
    this.dateVente,
  });

  bool get isEnPreparation => statut == 'preparation';
  bool get isValide => statut == 'valide';
  bool get isExclu => statut == 'exclu';
  bool get isVendu => statut == 'vendu';

  factory LotVenteModel.fromMap(Map<String, dynamic> map) {
    return LotVenteModel(
      id: map['id'] as int?,
      codeLot: map['code_lot'] as String,
      campagneId: map['campagne_id'] as int?,
      qualite: map['qualite'] as String?,
      categorieProducteur: map['categorie_producteur'] as String?,
      quantiteTotal: (map['quantite_total'] as num).toDouble(),
      prixUnitairePropose: (map['prix_unitaire_propose'] as num).toDouble(),
      clientId: map['client_id'] as int?,
      statut: map['statut'] as String? ?? 'preparation',
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      dateValidation: map['date_validation'] != null
          ? DateTime.parse(map['date_validation'] as String)
          : null,
      dateVente: map['date_vente'] != null
          ? DateTime.parse(map['date_vente'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code_lot': codeLot,
      'campagne_id': campagneId,
      'qualite': qualite,
      'categorie_producteur': categorieProducteur,
      'quantite_total': quantiteTotal,
      'prix_unitaire_propose': prixUnitairePropose,
      'client_id': clientId,
      'statut': statut,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'date_validation': dateValidation?.toIso8601String(),
      'date_vente': dateVente?.toIso8601String(),
    };
  }

  LotVenteModel copyWith({
    int? id,
    String? codeLot,
    int? campagneId,
    String? qualite,
    String? categorieProducteur,
    double? quantiteTotal,
    double? prixUnitairePropose,
    int? clientId,
    String? statut,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    DateTime? dateValidation,
    DateTime? dateVente,
  }) {
    return LotVenteModel(
      id: id ?? this.id,
      codeLot: codeLot ?? this.codeLot,
      campagneId: campagneId ?? this.campagneId,
      qualite: qualite ?? this.qualite,
      categorieProducteur: categorieProducteur ?? this.categorieProducteur,
      quantiteTotal: quantiteTotal ?? this.quantiteTotal,
      prixUnitairePropose: prixUnitairePropose ?? this.prixUnitairePropose,
      clientId: clientId ?? this.clientId,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      dateValidation: dateValidation ?? this.dateValidation,
      dateVente: dateVente ?? this.dateVente,
    );
  }
}

