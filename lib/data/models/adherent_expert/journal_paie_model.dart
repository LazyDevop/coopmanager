/// MODÈLE : JOURNAL DE PAIE
/// 
/// Représente un paiement/règlement après vente
class JournalPaieModel {
  final int? id;
  final int venteId;
  final int adherentId;
  final double montantBrut;
  final double commission;
  final double fraisGestion;
  final double retenueSocial;
  final double retenueCredit;
  final double totalRetenues;
  final double montantNetPaye;
  final String modePaiement;
  final DateTime datePaiement;
  final String? referencePaiement;
  final String? qrCode;
  final String? qrCodeHash;
  final String? notes;
  final DateTime createdAt;
  final int? createdBy;
  
  JournalPaieModel({
    this.id,
    required this.venteId,
    required this.adherentId,
    required this.montantBrut,
    this.commission = 0.0,
    this.fraisGestion = 0.0,
    this.retenueSocial = 0.0,
    this.retenueCredit = 0.0,
    required this.totalRetenues,
    required this.montantNetPaye,
    required this.modePaiement,
    required this.datePaiement,
    this.referencePaiement,
    this.qrCode,
    this.qrCodeHash,
    this.notes,
    required this.createdAt,
    this.createdBy,
  });
  
  factory JournalPaieModel.fromMap(Map<String, dynamic> map) {
    return JournalPaieModel(
      id: map['id'] as int?,
      venteId: map['vente_id'] as int,
      adherentId: map['adherent_id'] as int,
      montantBrut: (map['montant_brut'] as num).toDouble(),
      commission: (map['commission'] as num?)?.toDouble() ?? 0.0,
      fraisGestion: (map['frais_gestion'] as num?)?.toDouble() ?? 0.0,
      retenueSocial: (map['retenue_social'] as num?)?.toDouble() ?? 0.0,
      retenueCredit: (map['retenue_credit'] as num?)?.toDouble() ?? 0.0,
      totalRetenues: (map['total_retenues'] as num).toDouble(),
      montantNetPaye: (map['montant_net_paye'] as num).toDouble(),
      modePaiement: map['mode_paiement'] as String,
      datePaiement: DateTime.parse(map['date_paiement'] as String),
      referencePaiement: map['reference_paiement'] as String?,
      qrCode: map['qr_code'] as String?,
      qrCodeHash: map['qr_code_hash'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as int?,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vente_id': venteId,
      'adherent_id': adherentId,
      'montant_brut': montantBrut,
      'commission': commission,
      'frais_gestion': fraisGestion,
      'retenue_social': retenueSocial,
      'retenue_credit': retenueCredit,
      'total_retenues': totalRetenues,
      'montant_net_paye': montantNetPaye,
      'mode_paiement': modePaiement,
      'date_paiement': datePaiement.toIso8601String(),
      'reference_paiement': referencePaiement,
      'qr_code': qrCode,
      'qr_code_hash': qrCodeHash,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
  
  JournalPaieModel copyWith({
    int? id,
    int? venteId,
    int? adherentId,
    double? montantBrut,
    double? commission,
    double? fraisGestion,
    double? retenueSocial,
    double? retenueCredit,
    double? totalRetenues,
    double? montantNetPaye,
    String? modePaiement,
    DateTime? datePaiement,
    String? referencePaiement,
    String? qrCode,
    String? qrCodeHash,
    String? notes,
    DateTime? createdAt,
    int? createdBy,
  }) {
    return JournalPaieModel(
      id: id ?? this.id,
      venteId: venteId ?? this.venteId,
      adherentId: adherentId ?? this.adherentId,
      montantBrut: montantBrut ?? this.montantBrut,
      commission: commission ?? this.commission,
      fraisGestion: fraisGestion ?? this.fraisGestion,
      retenueSocial: retenueSocial ?? this.retenueSocial,
      retenueCredit: retenueCredit ?? this.retenueCredit,
      totalRetenues: totalRetenues ?? this.totalRetenues,
      montantNetPaye: montantNetPaye ?? this.montantNetPaye,
      modePaiement: modePaiement ?? this.modePaiement,
      datePaiement: datePaiement ?? this.datePaiement,
      referencePaiement: referencePaiement ?? this.referencePaiement,
      qrCode: qrCode ?? this.qrCode,
      qrCodeHash: qrCodeHash ?? this.qrCodeHash,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

