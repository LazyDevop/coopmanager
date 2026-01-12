/// Modèles pour le module Capital Social & Actionnariat
///
/// Gère les parts sociales, souscriptions, libérations et mouvements de capital

/// Modèle pour un actionnaire (adhérent possédant des parts)
class ActionnaireModel {
  final int? id;
  final int adherentId; // Référence à l'adhérent
  final String codeActionnaire; // Code unique
  final DateTime dateEntree; // Date d'accès au capital
  final String statut; // 'actif', 'suspendu', 'radie'
  final bool droitsVote; // Droit de vote en AG
  final DateTime createdAt;
  final int? createdBy;
  final DateTime? updatedAt;

  // Infos adhérent (pour affichage/recherche)
  final String? adherentCode;
  final String? adherentNom;
  final String? adherentPrenom;
  final String? adherentTelephone;

  // Statistiques calculées
  final int? nombrePartsDetenues;
  final double? capitalSouscrit;
  final double? capitalLibere;
  final double? capitalRestant;
  final DateTime? derniereSouscription;
  final DateTime? derniereLiberation;

  ActionnaireModel({
    this.id,
    required this.adherentId,
    required this.codeActionnaire,
    required this.dateEntree,
    this.statut = 'actif',
    this.droitsVote = true,
    required this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.adherentCode,
    this.adherentNom,
    this.adherentPrenom,
    this.adherentTelephone,
    this.nombrePartsDetenues,
    this.capitalSouscrit,
    this.capitalLibere,
    this.capitalRestant,
    this.derniereSouscription,
    this.derniereLiberation,
  });

  String get adherentDisplayName {
    final prenom = (adherentPrenom ?? '').trim();
    final nom = (adherentNom ?? '').trim();
    final full = '$prenom $nom'.trim();
    return full.isEmpty ? codeActionnaire : full;
  }

  // Statuts
  static const String statutActif = 'actif';
  static const String statutSuspendu = 'suspendu';
  static const String statutRadie = 'radie';

  String get statutLabel {
    switch (statut) {
      case statutActif:
        return 'Actif';
      case statutSuspendu:
        return 'Suspendu';
      case statutRadie:
        return 'Radié';
      default:
        return statut;
    }
  }

  /// Vérifier si l'actionnaire est à jour (capital libéré = capital souscrit)
  bool get estAJour {
    if (capitalSouscrit == null || capitalSouscrit == 0) return true;
    return capitalLibere != null && capitalLibere! >= capitalSouscrit!;
  }

  /// Pourcentage de libération du capital
  double get pourcentageLiberation {
    if (capitalSouscrit == null || capitalSouscrit == 0) return 0.0;
    if (capitalLibere == null) return 0.0;
    return (capitalLibere! / capitalSouscrit!) * 100;
  }

  factory ActionnaireModel.fromMap(Map<String, dynamic> map) {
    return ActionnaireModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      codeActionnaire: map['code_actionnaire'] as String,
      dateEntree: DateTime.parse(map['date_entree'] as String),
      statut: map['statut'] as String? ?? statutActif,
      droitsVote: (map['droits_vote'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as int?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      adherentCode: map['adherent_code'] as String?,
      adherentNom: map['adherent_nom'] as String?,
      adherentPrenom: map['adherent_prenom'] as String?,
      adherentTelephone: map['adherent_telephone'] as String?,
      nombrePartsDetenues: map['nombre_parts_detenues'] as int?,
      capitalSouscrit: map['capital_souscrit'] != null
          ? (map['capital_souscrit'] as num).toDouble()
          : null,
      capitalLibere: map['capital_libere'] != null
          ? (map['capital_libere'] as num).toDouble()
          : null,
      capitalRestant: map['capital_restant'] != null
          ? (map['capital_restant'] as num).toDouble()
          : null,
      derniereSouscription: map['derniere_souscription'] != null
          ? DateTime.parse(map['derniere_souscription'] as String)
          : null,
      derniereLiberation: map['derniere_liberation'] != null
          ? DateTime.parse(map['derniere_liberation'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      'code_actionnaire': codeActionnaire,
      'date_entree': dateEntree.toIso8601String(),
      'statut': statut,
      'droits_vote': droitsVote ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ActionnaireModel copyWith({
    int? id,
    int? adherentId,
    String? codeActionnaire,
    DateTime? dateEntree,
    String? statut,
    bool? droitsVote,
    DateTime? createdAt,
    int? createdBy,
    DateTime? updatedAt,
    String? adherentCode,
    String? adherentNom,
    String? adherentPrenom,
    String? adherentTelephone,
    int? nombrePartsDetenues,
    double? capitalSouscrit,
    double? capitalLibere,
    double? capitalRestant,
    DateTime? derniereSouscription,
    DateTime? derniereLiberation,
  }) {
    return ActionnaireModel(
      id: id ?? this.id,
      adherentId: adherentId ?? this.adherentId,
      codeActionnaire: codeActionnaire ?? this.codeActionnaire,
      dateEntree: dateEntree ?? this.dateEntree,
      statut: statut ?? this.statut,
      droitsVote: droitsVote ?? this.droitsVote,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      adherentCode: adherentCode ?? this.adherentCode,
      adherentNom: adherentNom ?? this.adherentNom,
      adherentPrenom: adherentPrenom ?? this.adherentPrenom,
      adherentTelephone: adherentTelephone ?? this.adherentTelephone,
      nombrePartsDetenues: nombrePartsDetenues ?? this.nombrePartsDetenues,
      capitalSouscrit: capitalSouscrit ?? this.capitalSouscrit,
      capitalLibere: capitalLibere ?? this.capitalLibere,
      capitalRestant: capitalRestant ?? this.capitalRestant,
      derniereSouscription: derniereSouscription ?? this.derniereSouscription,
      derniereLiberation: derniereLiberation ?? this.derniereLiberation,
    );
  }
}

/// Modèle pour la valeur d'une part sociale
class PartSocialeModel {
  final int? id;
  final double valeurPart; // Valeur unitaire d'une part
  final String devise; // 'FCFA'
  final DateTime dateEffet; // Date d'entrée en vigueur
  final bool active; // Si cette valeur est actuellement en vigueur
  final DateTime createdAt;
  final int? createdBy;

  PartSocialeModel({
    this.id,
    required this.valeurPart,
    this.devise = 'FCFA',
    required this.dateEffet,
    this.active = true,
    required this.createdAt,
    this.createdBy,
  });

  factory PartSocialeModel.fromMap(Map<String, dynamic> map) {
    return PartSocialeModel(
      id: map['id'] as int?,
      valeurPart: (map['valeur_part'] as num).toDouble(),
      devise: map['devise'] as String? ?? 'FCFA',
      dateEffet: DateTime.parse(map['date_effet'] as String),
      active: (map['active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'valeur_part': valeurPart,
      'devise': devise,
      'date_effet': dateEffet.toIso8601String(),
      'active': active ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  PartSocialeModel copyWith({
    int? id,
    double? valeurPart,
    String? devise,
    DateTime? dateEffet,
    bool? active,
    DateTime? createdAt,
    int? createdBy,
  }) {
    return PartSocialeModel(
      id: id ?? this.id,
      valeurPart: valeurPart ?? this.valeurPart,
      devise: devise ?? this.devise,
      dateEffet: dateEffet ?? this.dateEffet,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

/// Modèle pour une souscription de capital
class SouscriptionCapitalModel {
  final int? id;
  final int actionnaireId;
  final int nombrePartsSouscrites;
  final double montantSouscrit; // nombreParts * valeurPart
  final DateTime dateSouscription;
  final int? campagneId; // Campagne associée
  final String statut; // 'en_cours', 'cloture', 'annule'
  final String? notes;
  final DateTime createdAt;
  final int createdBy;

  // Documents générés
  final String? certificatPdfPath;
  final String? qrCodeHash;

  SouscriptionCapitalModel({
    this.id,
    required this.actionnaireId,
    required this.nombrePartsSouscrites,
    required this.montantSouscrit,
    required this.dateSouscription,
    this.campagneId,
    this.statut = 'en_cours',
    this.notes,
    required this.createdAt,
    required this.createdBy,
    this.certificatPdfPath,
    this.qrCodeHash,
  });

  // Statuts
  static const String statutEnCours = 'en_cours';
  static const String statutCloture = 'cloture';
  static const String statutAnnule = 'annule';

  factory SouscriptionCapitalModel.fromMap(Map<String, dynamic> map) {
    return SouscriptionCapitalModel(
      id: map['id'] as int?,
      actionnaireId: map['actionnaire_id'] as int,
      nombrePartsSouscrites: map['nombre_parts_souscrites'] as int,
      montantSouscrit: (map['montant_souscrit'] as num).toDouble(),
      dateSouscription: DateTime.parse(map['date_souscription'] as String),
      campagneId: map['campagne_id'] as int?,
      statut: map['statut'] as String? ?? statutEnCours,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as int,
      certificatPdfPath: map['certificat_pdf_path'] as String?,
      qrCodeHash: map['qr_code_hash'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'actionnaire_id': actionnaireId,
      'nombre_parts_souscrites': nombrePartsSouscrites,
      'montant_souscrit': montantSouscrit,
      'date_souscription': dateSouscription.toIso8601String(),
      if (campagneId != null) 'campagne_id': campagneId,
      'statut': statut,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      if (certificatPdfPath != null) 'certificat_pdf_path': certificatPdfPath,
      if (qrCodeHash != null) 'qr_code_hash': qrCodeHash,
    };
  }

  SouscriptionCapitalModel copyWith({
    int? id,
    int? actionnaireId,
    int? nombrePartsSouscrites,
    double? montantSouscrit,
    DateTime? dateSouscription,
    int? campagneId,
    String? statut,
    String? notes,
    String? certificatPdfPath,
    String? qrCodeHash,
    DateTime? createdAt,
    int? createdBy,
  }) {
    return SouscriptionCapitalModel(
      id: id ?? this.id,
      actionnaireId: actionnaireId ?? this.actionnaireId,
      nombrePartsSouscrites:
          nombrePartsSouscrites ?? this.nombrePartsSouscrites,
      montantSouscrit: montantSouscrit ?? this.montantSouscrit,
      dateSouscription: dateSouscription ?? this.dateSouscription,
      campagneId: campagneId ?? this.campagneId,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      certificatPdfPath: certificatPdfPath ?? this.certificatPdfPath,
      qrCodeHash: qrCodeHash ?? this.qrCodeHash,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

/// Modèle pour une libération de capital
class LiberationCapitalModel {
  final int? id;
  final int souscriptionId; // Souscription concernée
  final double montantLibere;
  final String modePaiement; // 'cash', 'virement', 'cheque', 'mobile_money'
  final String? reference; // Référence bancaire
  final DateTime datePaiement;
  final String? notes;
  final String? recuPdfPath;
  final String? qrCodeHash;
  final int createdBy;
  final DateTime createdAt;

  // Lien comptabilité
  final int? ecritureComptableId;

  LiberationCapitalModel({
    this.id,
    required this.souscriptionId,
    required this.montantLibere,
    required this.modePaiement,
    this.reference,
    required this.datePaiement,
    this.notes,
    this.recuPdfPath,
    this.qrCodeHash,
    required this.createdBy,
    required this.createdAt,
    this.ecritureComptableId,
  });

  factory LiberationCapitalModel.fromMap(Map<String, dynamic> map) {
    return LiberationCapitalModel(
      id: map['id'] as int?,
      souscriptionId: map['souscription_id'] as int,
      montantLibere: (map['montant_libere'] as num).toDouble(),
      modePaiement: map['mode_paiement'] as String,
      reference: map['reference'] as String?,
      datePaiement: DateTime.parse(map['date_paiement'] as String),
      notes: map['notes'] as String?,
      recuPdfPath: map['recu_pdf_path'] as String?,
      qrCodeHash: map['qr_code_hash'] as String?,
      createdBy: map['created_by'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      ecritureComptableId: map['ecriture_comptable_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'souscription_id': souscriptionId,
      'montant_libere': montantLibere,
      'mode_paiement': modePaiement,
      if (reference != null) 'reference': reference,
      'date_paiement': datePaiement.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (recuPdfPath != null) 'recu_pdf_path': recuPdfPath,
      if (qrCodeHash != null) 'qr_code_hash': qrCodeHash,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      if (ecritureComptableId != null)
        'ecriture_comptable_id': ecritureComptableId,
    };
  }

  LiberationCapitalModel copyWith({
    int? id,
    int? souscriptionId,
    double? montantLibere,
    String? modePaiement,
    String? reference,
    DateTime? datePaiement,
    String? notes,
    String? recuPdfPath,
    String? qrCodeHash,
    int? createdBy,
    DateTime? createdAt,
    int? ecritureComptableId,
  }) {
    return LiberationCapitalModel(
      id: id ?? this.id,
      souscriptionId: souscriptionId ?? this.souscriptionId,
      montantLibere: montantLibere ?? this.montantLibere,
      modePaiement: modePaiement ?? this.modePaiement,
      reference: reference ?? this.reference,
      datePaiement: datePaiement ?? this.datePaiement,
      notes: notes ?? this.notes,
      recuPdfPath: recuPdfPath ?? this.recuPdfPath,
      qrCodeHash: qrCodeHash ?? this.qrCodeHash,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      ecritureComptableId: ecritureComptableId ?? this.ecritureComptableId,
    );
  }
}

/// Modèle pour un mouvement de capital (historique)
class MouvementCapitalModel {
  final int? id;
  final int actionnaireId;
  final String typeMouvement; // 'souscription', 'liberation', 'cession'
  final int? nombreParts; // Nombre de parts concernées
  final double montant;
  final DateTime dateOperation;
  final String? justification;
  final int? souscriptionId; // Si lié à une souscription
  final int? liberationId; // Si lié à une libération
  final int createdBy;
  final DateTime createdAt;

  MouvementCapitalModel({
    this.id,
    required this.actionnaireId,
    required this.typeMouvement,
    this.nombreParts,
    required this.montant,
    required this.dateOperation,
    this.justification,
    this.souscriptionId,
    this.liberationId,
    required this.createdBy,
    required this.createdAt,
  });

  // Types de mouvement
  static const String typeSouscription = 'souscription';
  static const String typeLiberation = 'liberation';
  static const String typeCession = 'cession';

  String get typeMouvementLabel {
    switch (typeMouvement) {
      case typeSouscription:
        return 'Souscription';
      case typeLiberation:
        return 'Libération';
      case typeCession:
        return 'Cession';
      default:
        return typeMouvement;
    }
  }

  factory MouvementCapitalModel.fromMap(Map<String, dynamic> map) {
    return MouvementCapitalModel(
      id: map['id'] as int?,
      actionnaireId: map['actionnaire_id'] as int,
      typeMouvement: map['type_mouvement'] as String,
      nombreParts: map['nombre_parts'] as int?,
      montant: (map['montant'] as num).toDouble(),
      dateOperation: DateTime.parse(map['date_operation'] as String),
      justification: map['justification'] as String?,
      souscriptionId: map['souscription_id'] as int?,
      liberationId: map['liberation_id'] as int?,
      createdBy: map['created_by'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'actionnaire_id': actionnaireId,
      'type_mouvement': typeMouvement,
      if (nombreParts != null) 'nombre_parts': nombreParts,
      'montant': montant,
      'date_operation': dateOperation.toIso8601String(),
      if (justification != null) 'justification': justification,
      if (souscriptionId != null) 'souscription_id': souscriptionId,
      if (liberationId != null) 'liberation_id': liberationId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
