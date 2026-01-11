/// Modèle pour un client (acheteur de cacao)
/// 
/// Représente tous les types d'acheteurs :
/// - Acheteur local
/// - Acheteur grossiste
/// - Exportateur
/// - Industriel / transformateur
/// - Client occasionnel

class ClientModel {
  final int? id;
  final String codeClient; // Code interne unique
  final String typeClient; // 'local', 'grossiste', 'exportateur', 'industriel', 'occasionnel'
  final String raisonSociale; // Nom ou entreprise
  final String? nomResponsable; // Contact principal
  final String? telephone;
  final String? email;
  final String? adresse;
  final String? pays;
  final String? ville;
  final String? nrc; // Numéro de registre de commerce
  final String? ifu; // Identifiant fiscal unique
  final double? plafondCredit; // Crédit maximum autorisé (null = illimité)
  final double soldeClient; // Montant dû actuellement
  final String statut; // 'actif', 'suspendu', 'bloque', 'archive'
  final DateTime? dateBlocage;
  final String? raisonBlocage;
  final DateTime dateCreation;
  final int? createdBy;
  final DateTime? updatedAt;
  final int? updatedBy;
  
  // Statistiques (calculées)
  final int? nombreVentes;
  final double? totalVentes;
  final double? totalPaiements;
  final DateTime? derniereVente;
  final DateTime? dernierPaiement;

  ClientModel({
    this.id,
    required this.codeClient,
    required this.typeClient,
    required this.raisonSociale,
    this.nomResponsable,
    this.telephone,
    this.email,
    this.adresse,
    this.pays,
    this.ville,
    this.nrc,
    this.ifu,
    this.plafondCredit,
    this.soldeClient = 0.0,
    this.statut = 'actif',
    this.dateBlocage,
    this.raisonBlocage,
    required this.dateCreation,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.nombreVentes,
    this.totalVentes,
    this.totalPaiements,
    this.derniereVente,
    this.dernierPaiement,
  });

  // Types de clients
  static const String typeLocal = 'local';
  static const String typeGrossiste = 'grossiste';
  static const String typeExportateur = 'exportateur';
  static const String typeIndustriel = 'industriel';
  static const String typeOccasionnel = 'occasionnel';

  // Statuts
  static const String statutActif = 'actif';
  static const String statutSuspendu = 'suspendu';
  static const String statutBloque = 'bloque';
  static const String statutArchive = 'archive';

  String get typeClientLabel {
    switch (typeClient) {
      case typeLocal:
        return 'Acheteur local';
      case typeGrossiste:
        return 'Grossiste';
      case typeExportateur:
        return 'Exportateur';
      case typeIndustriel:
        return 'Industriel';
      case typeOccasionnel:
        return 'Occasionnel';
      default:
        return typeClient;
    }
  }

  String get statutLabel {
    switch (statut) {
      case statutActif:
        return 'Actif';
      case statutSuspendu:
        return 'Suspendu';
      case statutBloque:
        return 'Bloqué';
      case statutArchive:
        return 'Archivé';
      default:
        return statut;
    }
  }

  /// Vérifier si le client peut effectuer une vente
  bool get peutVendre {
    if (statut == statutBloque || statut == statutArchive) {
      return false;
    }
    
    // Vérifier le plafond de crédit
    if (plafondCredit != null && soldeClient >= plafondCredit!) {
      return false;
    }
    
    return true;
  }

  /// Vérifier si le client est à risque (solde élevé)
  bool get estARisque {
    if (plafondCredit == null) return false;
    final pourcentageUtilise = (soldeClient / plafondCredit!) * 100;
    return pourcentageUtilise >= 80; // Plus de 80% du plafond utilisé
  }

  /// Obtenir le pourcentage d'utilisation du crédit
  double get pourcentageCreditUtilise {
    if (plafondCredit == null || plafondCredit == 0) return 0.0;
    return (soldeClient / plafondCredit!) * 100;
  }

  // Convertir depuis Map (base de données)
  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as int?,
      codeClient: map['code_client'] as String,
      typeClient: map['type_client'] as String,
      raisonSociale: map['raison_sociale'] as String,
      nomResponsable: map['nom_responsable'] as String?,
      telephone: map['telephone'] as String?,
      email: map['email'] as String?,
      adresse: map['adresse'] as String?,
      pays: map['pays'] as String?,
      ville: map['ville'] as String?,
      nrc: map['nrc'] as String?,
      ifu: map['ifu'] as String?,
      plafondCredit: map['plafond_credit'] != null
          ? (map['plafond_credit'] as num).toDouble()
          : null,
      soldeClient: (map['solde_client'] as num?)?.toDouble() ?? 0.0,
      statut: map['statut'] as String? ?? statutActif,
      dateBlocage: map['date_blocage'] != null
          ? DateTime.parse(map['date_blocage'] as String)
          : null,
      raisonBlocage: map['raison_blocage'] as String?,
      dateCreation: DateTime.parse(map['date_creation'] as String),
      createdBy: map['created_by'] as int?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      updatedBy: map['updated_by'] as int?,
      nombreVentes: map['nombre_ventes'] as int?,
      totalVentes: map['total_ventes'] != null
          ? (map['total_ventes'] as num).toDouble()
          : null,
      totalPaiements: map['total_paiements'] != null
          ? (map['total_paiements'] as num).toDouble()
          : null,
      derniereVente: map['derniere_vente'] != null
          ? DateTime.parse(map['derniere_vente'] as String)
          : null,
      dernierPaiement: map['dernier_paiement'] != null
          ? DateTime.parse(map['dernier_paiement'] as String)
          : null,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code_client': codeClient,
      'type_client': typeClient,
      'raison_sociale': raisonSociale,
      if (nomResponsable != null) 'nom_responsable': nomResponsable,
      if (telephone != null) 'telephone': telephone,
      if (email != null) 'email': email,
      if (adresse != null) 'adresse': adresse,
      if (pays != null) 'pays': pays,
      if (ville != null) 'ville': ville,
      if (nrc != null) 'nrc': nrc,
      if (ifu != null) 'ifu': ifu,
      if (plafondCredit != null) 'plafond_credit': plafondCredit,
      'solde_client': soldeClient,
      'statut': statut,
      if (dateBlocage != null) 'date_blocage': dateBlocage!.toIso8601String(),
      if (raisonBlocage != null) 'raison_blocage': raisonBlocage,
      'date_creation': dateCreation.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (updatedBy != null) 'updated_by': updatedBy,
    };
  }

  // Créer une copie avec des modifications
  ClientModel copyWith({
    int? id,
    String? codeClient,
    String? typeClient,
    String? raisonSociale,
    String? nomResponsable,
    String? telephone,
    String? email,
    String? adresse,
    String? pays,
    String? ville,
    String? nrc,
    String? ifu,
    double? plafondCredit,
    double? soldeClient,
    String? statut,
    DateTime? dateBlocage,
    String? raisonBlocage,
    DateTime? dateCreation,
    int? createdBy,
    DateTime? updatedAt,
    int? updatedBy,
    int? nombreVentes,
    double? totalVentes,
    double? totalPaiements,
    DateTime? derniereVente,
    DateTime? dernierPaiement,
  }) {
    return ClientModel(
      id: id ?? this.id,
      codeClient: codeClient ?? this.codeClient,
      typeClient: typeClient ?? this.typeClient,
      raisonSociale: raisonSociale ?? this.raisonSociale,
      nomResponsable: nomResponsable ?? this.nomResponsable,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      pays: pays ?? this.pays,
      ville: ville ?? this.ville,
      nrc: nrc ?? this.nrc,
      ifu: ifu ?? this.ifu,
      plafondCredit: plafondCredit ?? this.plafondCredit,
      soldeClient: soldeClient ?? this.soldeClient,
      statut: statut ?? this.statut,
      dateBlocage: dateBlocage ?? this.dateBlocage,
      raisonBlocage: raisonBlocage ?? this.raisonBlocage,
      dateCreation: dateCreation ?? this.dateCreation,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      nombreVentes: nombreVentes ?? this.nombreVentes,
      totalVentes: totalVentes ?? this.totalVentes,
      totalPaiements: totalPaiements ?? this.totalPaiements,
      derniereVente: derniereVente ?? this.derniereVente,
      dernierPaiement: dernierPaiement ?? this.dernierPaiement,
    );
  }
}

/// Modèle pour la liaison entre une vente et un client
class VenteClientModel {
  final int? id;
  final int clientId;
  final int venteId;
  final double montantTotal;
  final double montantPaye;
  final double soldeRestant;
  final String statutPaiement; // 'paye', 'partiel', 'impaye'
  final DateTime dateVente;
  final DateTime? dateEcheance;
  final DateTime createdAt;

  VenteClientModel({
    this.id,
    required this.clientId,
    required this.venteId,
    required this.montantTotal,
    required this.montantPaye,
    required this.soldeRestant,
    required this.statutPaiement,
    required this.dateVente,
    this.dateEcheance,
    required this.createdAt,
  });

  factory VenteClientModel.fromMap(Map<String, dynamic> map) {
    return VenteClientModel(
      id: map['id'] as int?,
      clientId: map['client_id'] as int,
      venteId: map['vente_id'] as int,
      montantTotal: (map['montant_total'] as num).toDouble(),
      montantPaye: (map['montant_paye'] as num?)?.toDouble() ?? 0.0,
      soldeRestant: (map['solde_restant'] as num?)?.toDouble() ?? 0.0,
      statutPaiement: map['statut_paiement'] as String,
      dateVente: DateTime.parse(map['date_vente'] as String),
      dateEcheance: map['date_echeance'] != null
          ? DateTime.parse(map['date_echeance'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_id': clientId,
      'vente_id': venteId,
      'montant_total': montantTotal,
      'montant_paye': montantPaye,
      'solde_restant': soldeRestant,
      'statut_paiement': statutPaiement,
      'date_vente': dateVente.toIso8601String(),
      if (dateEcheance != null) 'date_echeance': dateEcheance!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Modèle pour un paiement client
class PaiementClientModel {
  final int? id;
  final int clientId;
  final int? venteId; // null si paiement global
  final double montant;
  final String modePaiement; // 'cash', 'virement', 'cheque', 'mobile_money'
  final String? reference; // Référence bancaire ou chèque
  final DateTime datePaiement;
  final String? notes;
  final String? recuPdfPath; // Chemin vers le reçu PDF
  final int createdBy;
  final DateTime createdAt;
  
  // V2: Nouveaux champs
  final String? qrCodeHash;
  final int? ecritureComptableId;

  PaiementClientModel({
    this.id,
    required this.clientId,
    this.venteId,
    required this.montant,
    required this.modePaiement,
    this.reference,
    required this.datePaiement,
    this.notes,
    this.recuPdfPath,
    required this.createdBy,
    required this.createdAt,
    this.qrCodeHash,
    this.ecritureComptableId,
  });

  factory PaiementClientModel.fromMap(Map<String, dynamic> map) {
    return PaiementClientModel(
      id: map['id'] as int?,
      clientId: map['client_id'] as int,
      venteId: map['vente_id'] as int?,
      montant: (map['montant'] as num).toDouble(),
      modePaiement: map['mode_paiement'] as String,
      reference: map['reference'] as String?,
      datePaiement: DateTime.parse(map['date_paiement'] as String),
      notes: map['notes'] as String?,
      recuPdfPath: map['recu_pdf_path'] as String?,
      createdBy: map['created_by'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      qrCodeHash: map['qr_code_hash'] as String?,
      ecritureComptableId: map['ecriture_comptable_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_id': clientId,
      if (venteId != null) 'vente_id': venteId,
      'montant': montant,
      'mode_paiement': modePaiement,
      if (reference != null) 'reference': reference,
      'date_paiement': datePaiement.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (recuPdfPath != null) 'recu_pdf_path': recuPdfPath,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      if (qrCodeHash != null) 'qr_code_hash': qrCodeHash,
      if (ecritureComptableId != null) 'ecriture_comptable_id': ecritureComptableId,
    };
  }

  PaiementClientModel copyWith({
    int? id,
    int? clientId,
    int? venteId,
    double? montant,
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
    return PaiementClientModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      venteId: venteId ?? this.venteId,
      montant: montant ?? this.montant,
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
