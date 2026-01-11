/// Modèle pour un paiement effectué à un adhérent
/// 
/// Représente un paiement partiel ou total d'une ou plusieurs recettes

class PaiementModel {
  final int? id;
  final int adherentId;
  final int? recetteId; // Peut être null si paiement global
  final double montant;
  final DateTime datePaiement;
  final String modePaiement; // 'especes', 'cheque', 'virement', 'mobile_money'
  final String? numeroCheque; // Si mode_paiement = 'cheque'
  final String? referenceVirement; // Si mode_paiement = 'virement' ou 'mobile_money'
  final String? notes;
  final int createdBy;
  final DateTime createdAt;
  
  // V2: Nouveaux champs
  final String? qrCodeHash; // Hash QR Code pour sécurité du reçu
  final String? pdfRecuPath; // Chemin vers le PDF du reçu
  final int? ecritureComptableId; // Lien avec écriture comptable

  PaiementModel({
    this.id,
    required this.adherentId,
    this.recetteId,
    required this.montant,
    required this.datePaiement,
    required this.modePaiement,
    this.numeroCheque,
    this.referenceVirement,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    this.qrCodeHash,
    this.pdfRecuPath,
    this.ecritureComptableId,
  });

  // Convertir depuis Map (base de données)
  factory PaiementModel.fromMap(Map<String, dynamic> map) {
    return PaiementModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      recetteId: map['recette_id'] as int?,
      montant: (map['montant'] as num).toDouble(),
      datePaiement: DateTime.parse(map['date_paiement'] as String),
      modePaiement: map['mode_paiement'] as String,
      numeroCheque: map['numero_cheque'] as String?,
      referenceVirement: map['reference_virement'] as String?,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      qrCodeHash: map['qr_code_hash'] as String?,
      pdfRecuPath: map['pdf_recu_path'] as String?,
      ecritureComptableId: map['ecriture_comptable_id'] as int?,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      if (recetteId != null) 'recette_id': recetteId,
      'montant': montant,
      'date_paiement': datePaiement.toIso8601String(),
      'mode_paiement': modePaiement,
      if (numeroCheque != null) 'numero_cheque': numeroCheque,
      if (referenceVirement != null) 'reference_virement': referenceVirement,
      if (notes != null) 'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      if (qrCodeHash != null) 'qr_code_hash': qrCodeHash,
      if (pdfRecuPath != null) 'pdf_recu_path': pdfRecuPath,
      if (ecritureComptableId != null) 'ecriture_comptable_id': ecritureComptableId,
    };
  }

  // Créer une copie avec des modifications
  PaiementModel copyWith({
    int? id,
    int? adherentId,
    int? recetteId,
    double? montant,
    DateTime? datePaiement,
    String? modePaiement,
    String? numeroCheque,
    String? referenceVirement,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    String? qrCodeHash,
    String? pdfRecuPath,
    int? ecritureComptableId,
  }) {
    return PaiementModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      recetteId: recetteId ?? this.recetteId,
      montant: montant ?? this.montant,
      datePaiement: datePaiement ?? this.datePaiement,
      modePaiement: modePaiement ?? this.modePaiement,
      numeroCheque: numeroCheque ?? this.numeroCheque,
      referenceVirement: referenceVirement ?? this.referenceVirement,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      qrCodeHash: qrCodeHash ?? this.qrCodeHash,
      pdfRecuPath: pdfRecuPath ?? this.pdfRecuPath,
      ecritureComptableId: ecritureComptableId ?? this.ecritureComptableId,
    );
  }
}

