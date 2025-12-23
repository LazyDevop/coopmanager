/// MODÈLE : VENTE EXPERT
/// 
/// Représente une vente de production avec tous les détails
class VenteExpertModel {
  final int? id;
  final int adherentId;
  final int? clientId;
  final String campagne;
  final double quantiteVendue;
  final double? prixMarche;
  final double? prixPlancher;
  final double prixJour;
  final double montantBrut;
  final DateTime dateVente;
  final String? referenceVente;
  final String? notes;
  final DateTime createdAt;
  final int? createdBy;
  
  VenteExpertModel({
    this.id,
    required this.adherentId,
    this.clientId,
    required this.campagne,
    required this.quantiteVendue,
    this.prixMarche,
    this.prixPlancher,
    required this.prixJour,
    required this.montantBrut,
    required this.dateVente,
    this.referenceVente,
    this.notes,
    required this.createdAt,
    this.createdBy,
  });
  
  factory VenteExpertModel.fromMap(Map<String, dynamic> map) {
    return VenteExpertModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      clientId: map['client_id'] as int?,
      campagne: map['campagne'] as String,
      quantiteVendue: (map['quantite_vendue'] as num).toDouble(),
      prixMarche: (map['prix_marche'] as num?)?.toDouble(),
      prixPlancher: (map['prix_plancher'] as num?)?.toDouble(),
      prixJour: (map['prix_jour'] as num).toDouble(),
      montantBrut: (map['montant_brut'] as num).toDouble(),
      dateVente: DateTime.parse(map['date_vente'] as String),
      referenceVente: map['reference_vente'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as int?,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      'client_id': clientId,
      'campagne': campagne,
      'quantite_vendue': quantiteVendue,
      'prix_marche': prixMarche,
      'prix_plancher': prixPlancher,
      'prix_jour': prixJour,
      'montant_brut': montantBrut,
      'date_vente': dateVente.toIso8601String(),
      'reference_vente': referenceVente,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
  
  VenteExpertModel copyWith({
    int? id,
    int? adherentId,
    int? clientId,
    String? campagne,
    double? quantiteVendue,
    double? prixMarche,
    double? prixPlancher,
    double? prixJour,
    double? montantBrut,
    DateTime? dateVente,
    String? referenceVente,
    String? notes,
    DateTime? createdAt,
    int? createdBy,
  }) {
    return VenteExpertModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      clientId: clientId ?? this.clientId,
      campagne: campagne ?? this.campagne,
      quantiteVendue: quantiteVendue ?? this.quantiteVendue,
      prixMarche: prixMarche ?? this.prixMarche,
      prixPlancher: prixPlancher ?? this.prixPlancher,
      prixJour: prixJour ?? this.prixJour,
      montantBrut: montantBrut ?? this.montantBrut,
      dateVente: dateVente ?? this.dateVente,
      referenceVente: referenceVente ?? this.referenceVente,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

