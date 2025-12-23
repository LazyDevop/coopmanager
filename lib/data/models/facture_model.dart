class FactureModel {
  final int? id;
  final String numero;
  final int adherentId;
  final String type; // 'vente', 'recette', 'bordereau'
  final double montantTotal;
  final DateTime dateFacture;
  final DateTime? dateEcheance;
  final String statut; // 'brouillon', 'validee', 'payee', 'annulee'
  final String? notes;
  final String? pdfPath;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // V2: Nouveaux champs
  final String? qrCodeHash; // Hash QR Code pour sécurité
  final int? documentSecuriseId; // Lien avec document sécurisé

  // Relations (optionnelles, chargées séparément)
  final int? venteId;
  final int? recetteId;

  FactureModel({
    this.id,
    required this.numero,
    required this.adherentId,
    required this.type,
    required this.montantTotal,
    required this.dateFacture,
    this.dateEcheance,
    this.statut = 'validee',
    this.notes,
    this.pdfPath,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.venteId,
    this.recetteId,
    // V2: Nouveaux champs
    this.qrCodeHash,
    this.documentSecuriseId,
  });

  bool get isValidee => statut == 'validee';
  bool get isPayee => statut == 'payee';
  bool get isAnnulee => statut == 'annulee';
  bool get isBrouillon => statut == 'brouillon';
  bool get isPourVente => type == 'vente';
  bool get isPourRecette => type == 'recette' || type == 'bordereau';

  // Convertir depuis Map (base de données)
  factory FactureModel.fromMap(Map<String, dynamic> map) {
    return FactureModel(
      id: map['id'] as int?,
      numero: map['numero'] as String,
      adherentId: map['adherent_id'] as int,
      type: map['type'] as String,
      montantTotal: (map['montant_total'] as num).toDouble(),
      dateFacture: DateTime.parse(map['date_facture'] as String),
      dateEcheance: map['date_echeance'] != null
          ? DateTime.parse(map['date_echeance'] as String)
          : null,
      statut: map['statut'] as String? ?? 'validee',
      notes: map['notes'] as String?,
      pdfPath: map['pdf_path'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      // V2: Nouveaux champs
      qrCodeHash: map['qr_code_hash'] as String?,
      documentSecuriseId: map['document_securise_id'] as int?,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numero': numero,
      'adherent_id': adherentId,
      'type': type,
      'montant_total': montantTotal,
      'date_facture': dateFacture.toIso8601String(),
      'date_echeance': dateEcheance?.toIso8601String(),
      'statut': statut,
      'notes': notes,
      'pdf_path': pdfPath,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // V2: Nouveaux champs
      'qr_code_hash': qrCodeHash,
      'document_securise_id': documentSecuriseId,
    };
  }

  // Créer une copie avec des modifications
  FactureModel copyWith({
    int? id,
    String? numero,
    int? adherentId,
    String? type,
    double? montantTotal,
    DateTime? dateFacture,
    DateTime? dateEcheance,
    String? statut,
    String? notes,
    String? pdfPath,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? venteId,
    int? recetteId,
    String? qrCodeHash,
    int? documentSecuriseId,
  }) {
    return FactureModel(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      adherentId: adherentId ?? this.adherentId,
      type: type ?? this.type,
      montantTotal: montantTotal ?? this.montantTotal,
      dateFacture: dateFacture ?? this.dateFacture,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      pdfPath: pdfPath ?? this.pdfPath,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      venteId: venteId ?? this.venteId,
      recetteId: recetteId ?? this.recetteId,
      // V2: Nouveaux champs
      qrCodeHash: qrCodeHash ?? this.qrCodeHash,
      documentSecuriseId: documentSecuriseId ?? this.documentSecuriseId,
    );
  }

  /// Générer un numéro de facture unique
  static String generateNumero({
    required String type,
    required DateTime date,
    required int sequence,
  }) {
    final prefix = type == 'vente' ? 'FAC-V' : type == 'recette' ? 'FAC-R' : 'FAC-B';
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final sequenceStr = sequence.toString().padLeft(4, '0');
    return '$prefix-$year$month-$sequenceStr';
  }
}
