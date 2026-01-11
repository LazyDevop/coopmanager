/// MODÈLE : TRÉSORERIE
/// 
/// Suivi de la trésorerie de la coopérative

class TresorerieModel {
  final int? id;
  final double soldeInitial; // Solde au début de la période
  final double soldeActuel; // Solde actuel
  final DateTime dateReference; // Date de référence
  final String? periode; // 'Mois', 'Campagne', etc.
  final DateTime? updatedAt;

  TresorerieModel({
    this.id,
    required this.soldeInitial,
    required this.soldeActuel,
    required this.dateReference,
    this.periode,
    this.updatedAt,
  });

  // Calculer la variation
  double get variation => soldeActuel - soldeInitial;

  // Convertir depuis Map (base de données)
  factory TresorerieModel.fromMap(Map<String, dynamic> map) {
    return TresorerieModel(
      id: map['id'] as int?,
      soldeInitial: (map['solde_initial'] as num).toDouble(),
      soldeActuel: (map['solde_actuel'] as num).toDouble(),
      dateReference: DateTime.parse(map['date_reference'] as String),
      periode: map['periode'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'solde_initial': soldeInitial,
      'solde_actuel': soldeActuel,
      'date_reference': dateReference.toIso8601String(),
      if (periode != null) 'periode': periode,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  TresorerieModel copyWith({
    int? id,
    double? soldeInitial,
    double? soldeActuel,
    DateTime? dateReference,
    String? periode,
    DateTime? updatedAt,
  }) {
    return TresorerieModel(
      id: id ?? this.id,
      soldeInitial: soldeInitial ?? this.soldeInitial,
      soldeActuel: soldeActuel ?? this.soldeActuel,
      dateReference: dateReference ?? this.dateReference,
      periode: periode ?? this.periode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

