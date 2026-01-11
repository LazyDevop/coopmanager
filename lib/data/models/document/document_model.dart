/// Modèle pour représenter un document généré par le système
class DocumentModel {
  final int? id;
  final String type; // FACTURE, RECU, BORDEREAU, etc.
  final String reference; // Numéro unique du document
  final int cooperativeId;
  final String hash; // Hash SHA-256 pour vérification
  final DateTime generatedAt;
  final int generatedBy; // ID utilisateur
  final String? filePath; // Chemin du fichier PDF
  final Map<String, dynamic> metadata; // Métadonnées spécifiques au type
  final String? qrCodeData; // Données encodées dans le QR code
  final bool isVerified; // Si le document a été vérifié
  final DateTime? verifiedAt;
  final int? verifiedBy;

  DocumentModel({
    this.id,
    required this.type,
    required this.reference,
    required this.cooperativeId,
    required this.hash,
    required this.generatedAt,
    required this.generatedBy,
    this.filePath,
    this.metadata = const {},
    this.qrCodeData,
    this.isVerified = false,
    this.verifiedAt,
    this.verifiedBy,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      reference: map['reference'] as String,
      cooperativeId: map['cooperative_id'] as int,
      hash: map['hash'] as String,
      generatedAt: DateTime.parse(map['generated_at'] as String),
      generatedBy: map['generated_by'] as int,
      filePath: map['file_path'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : {},
      qrCodeData: map['qr_code_data'] as String?,
      isVerified: (map['is_verified'] as int? ?? 0) == 1,
      verifiedAt: map['verified_at'] != null
          ? DateTime.parse(map['verified_at'] as String)
          : null,
      verifiedBy: map['verified_by'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'reference': reference,
      'cooperative_id': cooperativeId,
      'hash': hash,
      'generated_at': generatedAt.toIso8601String(),
      'generated_by': generatedBy,
      if (filePath != null) 'file_path': filePath,
      'metadata': metadata,
      if (qrCodeData != null) 'qr_code_data': qrCodeData,
      'is_verified': isVerified ? 1 : 0,
      if (verifiedAt != null) 'verified_at': verifiedAt!.toIso8601String(),
      if (verifiedBy != null) 'verified_by': verifiedBy,
    };
  }

  DocumentModel copyWith({
    int? id,
    String? type,
    String? reference,
    int? cooperativeId,
    String? hash,
    DateTime? generatedAt,
    int? generatedBy,
    String? filePath,
    Map<String, dynamic>? metadata,
    String? qrCodeData,
    bool? isVerified,
    DateTime? verifiedAt,
    int? verifiedBy,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      reference: reference ?? this.reference,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      hash: hash ?? this.hash,
      generatedAt: generatedAt ?? this.generatedAt,
      generatedBy: generatedBy ?? this.generatedBy,
      filePath: filePath ?? this.filePath,
      metadata: metadata ?? this.metadata,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }
}

/// Types de documents supportés
enum DocumentType {
  factureVente('FACTURE_VENTE', 'Facture de vente'),
  factureRecette('FACTURE_RECETTE', 'Facture de recette'),
  recuDepot('RECU_DEPOT', 'Reçu de dépôt cacao'),
  recuPaiementAdherent('RECU_PAIEMENT_ADHERENT', 'Reçu de paiement adhérent'),
  recuPaiementClient('RECU_PAIEMENT_CLIENT', 'Reçu de paiement client'),
  bordereauRecette('BORDEREAU_RECETTE', 'Bordereau de recette'),
  journalCaisse('JOURNAL_CAISSE', 'Journal de caisse'),
  etatCompteAdherent('ETAT_COMPTE_ADHERENT', 'État de compte adhérent'),
  etatCapitalSocial('ETAT_CAPITAL_SOCIAL', 'État du capital social'),
  ficheActionnaire('FICHE_ACTIONNAIRE', 'Fiche actionnaire'),
  rapportSocial('RAPPORT_SOCIAL', 'Rapport social');

  final String code;
  final String label;

  const DocumentType(this.code, this.label);
}

