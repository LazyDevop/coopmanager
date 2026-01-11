/// Modèle pour le journal des ventes (audit)
/// 
/// Enregistre toutes les modifications apportées aux ventes
/// pour traçabilité et audit
class JournalVenteModel {
  final int? id;
  final int venteId;
  final String action; // 'CREATE', 'UPDATE', 'CANCEL', 'PAY', etc.
  final String? ancienStatut;
  final String? nouveauStatut;
  final double? ancienMontant;
  final double? nouveauMontant;
  final String? details; // Détails supplémentaires (JSON ou texte)
  final int? createdBy;
  final DateTime createdAt;

  JournalVenteModel({
    this.id,
    required this.venteId,
    required this.action,
    this.ancienStatut,
    this.nouveauStatut,
    this.ancienMontant,
    this.nouveauMontant,
    this.details,
    this.createdBy,
    required this.createdAt,
  });

  // Convertir depuis Map (base de données)
  factory JournalVenteModel.fromMap(Map<String, dynamic> map) {
    return JournalVenteModel(
      id: map['id'] as int?,
      venteId: map['vente_id'] as int,
      action: map['action'] as String,
      ancienStatut: map['ancien_statut'] as String?,
      nouveauStatut: map['nouveau_statut'] as String?,
      ancienMontant: map['ancien_montant'] != null
          ? (map['ancien_montant'] as num).toDouble()
          : null,
      nouveauMontant: map['nouveau_montant'] != null
          ? (map['nouveau_montant'] as num).toDouble()
          : null,
      details: map['details'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vente_id': venteId,
      'action': action,
      if (ancienStatut != null) 'ancien_statut': ancienStatut,
      if (nouveauStatut != null) 'nouveau_statut': nouveauStatut,
      if (ancienMontant != null) 'ancien_montant': ancienMontant,
      if (nouveauMontant != null) 'nouveau_montant': nouveauMontant,
      if (details != null) 'details': details,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  JournalVenteModel copyWith({
    int? id,
    int? venteId,
    String? action,
    String? ancienStatut,
    String? nouveauStatut,
    double? ancienMontant,
    double? nouveauMontant,
    String? details,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return JournalVenteModel(
      id: id ?? this.id,
      venteId: venteId ?? this.venteId,
      action: action ?? this.action,
      ancienStatut: ancienStatut ?? this.ancienStatut,
      nouveauStatut: nouveauStatut ?? this.nouveauStatut,
      ancienMontant: ancienMontant ?? this.ancienMontant,
      nouveauMontant: nouveauMontant ?? this.nouveauMontant,
      details: details ?? this.details,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

