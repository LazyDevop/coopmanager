/// Modèle pour une retenue sociale sur les recettes d'un adhérent
/// 
/// Représente une retenue volontaire ou automatique pour :
/// - Crédit
/// - Aide sociale
/// - Épargne coopérative
/// - Autres fonds sociaux

class RetenueSocialeModel {
  final int? id;
  final int adherentId;
  final int? recetteId; // Peut être null si retenue globale
  final String type; // 'credit', 'aide_sociale', 'epargne', 'fonds_social', 'autre'
  final double montant;
  final DateTime dateRetenue;
  final String? justification; // Raison de la retenue
  final bool estVolontaire; // true si consentement adhérent, false si automatique
  final bool estConsentement; // true si adhérent a donné son accord
  final String? notes;
  final int createdBy;
  final DateTime createdAt;
  
  // V2: Nouveaux champs
  final int? campagneId; // Campagne associée
  final String? qrCodeHash; // Hash QR Code pour traçabilité
  final int? ecritureComptableId; // Lien avec écriture comptable

  RetenueSocialeModel({
    this.id,
    required this.adherentId,
    this.recetteId,
    required this.type,
    required this.montant,
    required this.dateRetenue,
    this.justification,
    required this.estVolontaire,
    required this.estConsentement,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    this.campagneId,
    this.qrCodeHash,
    this.ecritureComptableId,
  });

  String get typeLabel {
    switch (type) {
      case 'credit':
        return 'Crédit';
      case 'aide_sociale':
        return 'Aide sociale';
      case 'epargne':
        return 'Épargne coopérative';
      case 'fonds_social':
        return 'Fonds social';
      case 'autre':
        return 'Autre';
      default:
        return type;
    }
  }

  // Convertir depuis Map (base de données)
  factory RetenueSocialeModel.fromMap(Map<String, dynamic> map) {
    return RetenueSocialeModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      recetteId: map['recette_id'] as int?,
      type: map['type'] as String,
      montant: (map['montant'] as num).toDouble(),
      dateRetenue: DateTime.parse(map['date_retenue'] as String),
      justification: map['justification'] as String?,
      estVolontaire: (map['est_volontaire'] as int) == 1,
      estConsentement: (map['est_consentement'] as int) == 1,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      campagneId: map['campagne_id'] as int?,
      qrCodeHash: map['qr_code_hash'] as String?,
      ecritureComptableId: map['ecriture_comptable_id'] as int?,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      if (recetteId != null) 'recette_id': recetteId,
      'type': type,
      'montant': montant,
      'date_retenue': dateRetenue.toIso8601String(),
      if (justification != null) 'justification': justification,
      'est_volontaire': estVolontaire ? 1 : 0,
      'est_consentement': estConsentement ? 1 : 0,
      if (notes != null) 'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      if (campagneId != null) 'campagne_id': campagneId,
      if (qrCodeHash != null) 'qr_code_hash': qrCodeHash,
      if (ecritureComptableId != null) 'ecriture_comptable_id': ecritureComptableId,
    };
  }

  // Créer une copie avec des modifications
  RetenueSocialeModel copyWith({
    int? id,
    int? adherentId,
    int? recetteId,
    String? type,
    double? montant,
    DateTime? dateRetenue,
    String? justification,
    bool? estVolontaire,
    bool? estConsentement,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    int? campagneId,
    String? qrCodeHash,
    int? ecritureComptableId,
  }) {
    return RetenueSocialeModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      recetteId: recetteId ?? this.recetteId,
      type: type ?? this.type,
      montant: montant ?? this.montant,
      dateRetenue: dateRetenue ?? this.dateRetenue,
      justification: justification ?? this.justification,
      estVolontaire: estVolontaire ?? this.estVolontaire,
      estConsentement: estConsentement ?? this.estConsentement,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      campagneId: campagneId ?? this.campagneId,
      qrCodeHash: qrCodeHash ?? this.qrCodeHash,
      ecritureComptableId: ecritureComptableId ?? this.ecritureComptableId,
    );
  }
}

