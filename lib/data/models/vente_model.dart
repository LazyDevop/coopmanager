class VenteModel {
  final int? id;
  final String type; // 'individuelle' ou 'groupee'
  final int? adherentId; // null pour ventes groupées
  final double quantiteTotal;
  final double prixUnitaire;
  final double montantTotal;
  final String? acheteur;
  final String? modePaiement; // 'especes', 'mobile_money', 'virement'
  final DateTime dateVente;
  final String? notes;
  final String statut; // 'valide', 'annulee'
  final int? createdBy;
  final DateTime createdAt;
  
  // V2: Nouveaux champs
  final int? clientId; // Lien avec client
  final int? ecritureComptableId; // Lien avec écriture comptable
  final String? qrCodeHash; // Hash QR Code pour sécurité

  VenteModel({
    this.id,
    required this.type,
    this.adherentId,
    required this.quantiteTotal,
    required this.prixUnitaire,
    required this.montantTotal,
    this.acheteur,
    this.modePaiement,
    required this.dateVente,
    this.notes,
    this.statut = 'valide',
    this.createdBy,
    required this.createdAt,
    // V2: Nouveaux champs
    this.clientId,
    this.ecritureComptableId,
    this.qrCodeHash,
  });

  bool get isValide => statut == 'valide';
  bool get isAnnulee => statut == 'annulee';
  bool get isIndividuelle => type == 'individuelle';
  bool get isGroupee => type == 'groupee';

  // Convertir depuis Map (base de données)
  factory VenteModel.fromMap(Map<String, dynamic> map) {
    return VenteModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      adherentId: map['adherent_id'] as int?,
      quantiteTotal: (map['quantite_total'] as num).toDouble(),
      prixUnitaire: (map['prix_unitaire'] as num).toDouble(),
      montantTotal: (map['montant_total'] as num).toDouble(),
      acheteur: map['acheteur'] as String?,
      modePaiement: map['mode_paiement'] as String?,
      dateVente: DateTime.parse(map['date_vente'] as String),
      notes: map['notes'] as String?,
      statut: map['statut'] as String? ?? 'valide',
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      // V2: Nouveaux champs
      clientId: map['client_id'] as int?,
      ecritureComptableId: map['ecriture_comptable_id'] as int?,
      qrCodeHash: map['qr_code_hash'] as String?,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'adherent_id': adherentId,
      'quantite_total': quantiteTotal,
      'prix_unitaire': prixUnitaire,
      'montant_total': montantTotal,
      'acheteur': acheteur,
      'mode_paiement': modePaiement,
      'date_vente': dateVente.toIso8601String(),
      'notes': notes,
      'statut': statut,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      // V2: Nouveaux champs
      'client_id': clientId,
      'ecriture_comptable_id': ecritureComptableId,
      'qr_code_hash': qrCodeHash,
    };
  }

  // Créer une copie avec des modifications
  VenteModel copyWith({
    int? id,
    String? type,
    int? adherentId,
    double? quantiteTotal,
    double? prixUnitaire,
    double? montantTotal,
    String? acheteur,
    String? modePaiement,
    DateTime? dateVente,
    String? notes,
    String? statut,
    int? createdBy,
    DateTime? createdAt,
    int? clientId,
    int? ecritureComptableId,
    String? qrCodeHash,
  }) {
    return VenteModel(
      id: id ?? this.id,
      type: type ?? this.type,
      adherentId: adherentId ?? this.adherentId,
      quantiteTotal: quantiteTotal ?? this.quantiteTotal,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      montantTotal: montantTotal ?? this.montantTotal,
      acheteur: acheteur ?? this.acheteur,
      modePaiement: modePaiement ?? this.modePaiement,
      dateVente: dateVente ?? this.dateVente,
      notes: notes ?? this.notes,
      statut: statut ?? this.statut,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      // V2: Nouveaux champs
      clientId: clientId ?? this.clientId,
      ecritureComptableId: ecritureComptableId ?? this.ecritureComptableId,
      qrCodeHash: qrCodeHash ?? this.qrCodeHash,
    );
  }
}
