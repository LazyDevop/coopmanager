/// Modèle de données pour une Créance Client (V2)
/// 
/// Gestion du paiement différé et suivi des créances clients
class CreanceClientModel {
  final int? id;
  final int venteId;
  final int clientId;
  final double montantTotal;
  final double montantPaye;
  final double montantRestant;
  final DateTime dateVente;
  final DateTime dateEcheance;
  final DateTime? datePaiement;
  final String statut; // 'en_attente', 'partiellement_payee', 'payee', 'en_retard', 'bloquee'
  final int? joursRetard;
  final bool isClientBloque; // Blocage automatique si retard
  final String? notes;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CreanceClientModel({
    this.id,
    required this.venteId,
    required this.clientId,
    required this.montantTotal,
    this.montantPaye = 0.0,
    required this.montantRestant,
    required this.dateVente,
    required this.dateEcheance,
    this.datePaiement,
    this.statut = 'en_attente',
    this.joursRetard,
    this.isClientBloque = false,
    this.notes,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isEnAttente => statut == 'en_attente';
  bool get isPartiellementPayee => statut == 'partiellement_payee';
  bool get isPayee => statut == 'payee';
  bool get isEnRetard => statut == 'en_retard';
  bool get isBloquee => statut == 'bloquee';

  double get pourcentagePaye => montantTotal > 0 
      ? (montantPaye / montantTotal) * 100 
      : 0.0;

  bool get isEcheanceDepassee => DateTime.now().isAfter(dateEcheance) && !isPayee;

  factory CreanceClientModel.fromMap(Map<String, dynamic> map) {
    final dateEcheance = DateTime.parse(map['date_echeance'] as String);
    final now = DateTime.now();
    final joursRetard = dateEcheance.isBefore(now) && map['statut'] != 'payee'
        ? now.difference(dateEcheance).inDays
        : null;

    return CreanceClientModel(
      id: map['id'] as int?,
      venteId: map['vente_id'] as int,
      clientId: map['client_id'] as int,
      montantTotal: (map['montant_total'] as num).toDouble(),
      montantPaye: (map['montant_paye'] as num?)?.toDouble() ?? 0.0,
      montantRestant: (map['montant_restant'] as num).toDouble(),
      dateVente: DateTime.parse(map['date_vente'] as String),
      dateEcheance: dateEcheance,
      datePaiement: map['date_paiement'] != null
          ? DateTime.parse(map['date_paiement'] as String)
          : null,
      statut: map['statut'] as String? ?? 'en_attente',
      joursRetard: joursRetard,
      isClientBloque: (map['is_client_bloque'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vente_id': venteId,
      'client_id': clientId,
      'montant_total': montantTotal,
      'montant_paye': montantPaye,
      'montant_restant': montantRestant,
      'date_vente': dateVente.toIso8601String(),
      'date_echeance': dateEcheance.toIso8601String(),
      'date_paiement': datePaiement?.toIso8601String(),
      'statut': statut,
      'jours_retard': joursRetard,
      'is_client_bloque': isClientBloque ? 1 : 0,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CreanceClientModel copyWith({
    int? id,
    int? venteId,
    int? clientId,
    double? montantTotal,
    double? montantPaye,
    double? montantRestant,
    DateTime? dateVente,
    DateTime? dateEcheance,
    DateTime? datePaiement,
    String? statut,
    int? joursRetard,
    bool? isClientBloque,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreanceClientModel(
      id: id ?? this.id,
      venteId: venteId ?? this.venteId,
      clientId: clientId ?? this.clientId,
      montantTotal: montantTotal ?? this.montantTotal,
      montantPaye: montantPaye ?? this.montantPaye,
      montantRestant: montantRestant ?? this.montantRestant,
      dateVente: dateVente ?? this.dateVente,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      datePaiement: datePaiement ?? this.datePaiement,
      statut: statut ?? this.statut,
      joursRetard: joursRetard ?? this.joursRetard,
      isClientBloque: isClientBloque ?? this.isClientBloque,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

