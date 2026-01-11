import 'package:flutter/material.dart';

/// Modèle pour un document officiel de la coopérative
/// 
/// Représente tous les types de documents générés :
/// - Reçu de dépôt cacao
/// - Bordereau de pesée
/// - Facture client
/// - Bon de livraison
/// - Bordereau de paiement adhérent
/// - Reçu de paiement
/// - État de compte adhérent
/// - État de participation actionnaire
/// - Journaux
/// - Rapports sociaux

class DocumentModel {
  final int? id;
  final String numero; // Numéro unique séquentiel
  final String type; // Type de document (voir DocumentType)
  final int? campagneId; // Campagne associée (si applicable)
  
  // Références aux entités métier
  final int? adherentId; // Adhérent concerné (si applicable)
  final int? clientId; // Client concerné (si applicable)
  final int? operationId; // ID de l'opération source (vente_id, recette_id, etc.)
  final String operationType; // Type d'opération ('vente', 'recette', 'depot', etc.)
  
  // Contenu et métadonnées
  final Map<String, dynamic> contenu; // Contenu JSON du document
  final String pdfPath; // Chemin vers le fichier PDF généré
  final String? qrCodeHash; // Hash SHA-256 pour vérification
  final String? qrCodeImagePath; // Chemin vers l'image QR Code
  
  // Statut et traçabilité
  final String statut; // 'brouillon', 'genere', 'annule', 'regularise'
  final bool estImmuable; // true après génération finale
  final DateTime dateGeneration;
  final DateTime? dateAnnulation;
  final String? raisonAnnulation;
  final int? documentAnnuleId; // ID du document annulé (si régularisation)
  
  // Audit
  final int createdBy;
  final DateTime createdAt;
  final int? updatedBy;
  final DateTime? updatedAt;
  
  // Vérification
  final int? nombreVerifications; // Nombre de fois vérifié via QR Code
  final DateTime? derniereVerification;

  DocumentModel({
    this.id,
    required this.numero,
    required this.type,
    this.campagneId,
    this.adherentId,
    this.clientId,
    this.operationId,
    required this.operationType,
    required this.contenu,
    required this.pdfPath,
    this.qrCodeHash,
    this.qrCodeImagePath,
    required this.statut,
    this.estImmuable = false,
    required this.dateGeneration,
    this.dateAnnulation,
    this.raisonAnnulation,
    this.documentAnnuleId,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.nombreVerifications,
    this.derniereVerification,
  });

  // Types de documents disponibles
  static const String typeRecuDepot = 'recu_depot';
  static const String typeBordereauPesee = 'bordereau_pesee';
  static const String typeFactureClient = 'facture_client';
  static const String typeBonLivraison = 'bon_livraison';
  static const String typeBordereauPaiement = 'bordereau_paiement';
  static const String typeRecuPaiement = 'recu_paiement';
  static const String typeEtatCompte = 'etat_compte';
  static const String typeEtatParticipation = 'etat_participation';
  static const String typeJournalVentes = 'journal_ventes';
  static const String typeJournalCaisse = 'journal_caisse';
  static const String typeJournalPaiements = 'journal_paiements';
  static const String typeRapportSocial = 'rapport_social';

  String get typeLabel {
    switch (type) {
      case typeRecuDepot:
        return 'Reçu de dépôt';
      case typeBordereauPesee:
        return 'Bordereau de pesée';
      case typeFactureClient:
        return 'Facture client';
      case typeBonLivraison:
        return 'Bon de livraison';
      case typeBordereauPaiement:
        return 'Bordereau de paiement';
      case typeRecuPaiement:
        return 'Reçu de paiement';
      case typeEtatCompte:
        return 'État de compte';
      case typeEtatParticipation:
        return 'État de participation';
      case typeJournalVentes:
        return 'Journal des ventes';
      case typeJournalCaisse:
        return 'Journal de caisse';
      case typeJournalPaiements:
        return 'Journal des paiements';
      case typeRapportSocial:
        return 'Rapport social';
      default:
        return type;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case typeRecuDepot:
      case typeBordereauPesee:
        return Icons.inventory;
      case typeFactureClient:
      case typeBonLivraison:
        return Icons.receipt;
      case typeBordereauPaiement:
      case typeRecuPaiement:
        return Icons.payment;
      case typeEtatCompte:
      case typeEtatParticipation:
        return Icons.account_balance_wallet;
      case typeJournalVentes:
      case typeJournalCaisse:
      case typeJournalPaiements:
        return Icons.book;
      case typeRapportSocial:
        return Icons.people;
      default:
        return Icons.description;
    }
  }

  Color get typeColor {
    switch (type) {
      case typeRecuDepot:
      case typeBordereauPesee:
        return Colors.blue;
      case typeFactureClient:
      case typeBonLivraison:
        return Colors.green;
      case typeBordereauPaiement:
      case typeRecuPaiement:
        return Colors.purple;
      case typeEtatCompte:
      case typeEtatParticipation:
        return Colors.teal;
      case typeJournalVentes:
      case typeJournalCaisse:
      case typeJournalPaiements:
        return Colors.orange;
      case typeRapportSocial:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  // Convertir depuis Map (base de données)
  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    // Parser contenu JSON
    Map<String, dynamic> contenu = {};
    if (map['contenu'] != null) {
      final contenuStr = map['contenu'] as String;
      // TODO: Parser JSON si nécessaire
      try {
        // contenu = jsonDecode(contenuStr);
      } catch (e) {
        print('Erreur parsing contenu JSON: $e');
      }
    }

    return DocumentModel(
      id: map['id'] as int?,
      numero: map['numero'] as String,
      type: map['type'] as String,
      campagneId: map['campagne_id'] as int?,
      adherentId: map['adherent_id'] as int?,
      clientId: map['client_id'] as int?,
      operationId: map['operation_id'] as int?,
      operationType: map['operation_type'] as String,
      contenu: contenu,
      pdfPath: map['pdf_path'] as String,
      qrCodeHash: map['qr_code_hash'] as String?,
      qrCodeImagePath: map['qr_code_image_path'] as String?,
      statut: map['statut'] as String,
      estImmuable: (map['est_immuable'] as int?) == 1,
      dateGeneration: DateTime.parse(map['date_generation'] as String),
      dateAnnulation: map['date_annulation'] != null
          ? DateTime.parse(map['date_annulation'] as String)
          : null,
      raisonAnnulation: map['raison_annulation'] as String?,
      documentAnnuleId: map['document_annule_id'] as int?,
      createdBy: map['created_by'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedBy: map['updated_by'] as int?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      nombreVerifications: map['nombre_verifications'] as int?,
      derniereVerification: map['derniere_verification'] != null
          ? DateTime.parse(map['derniere_verification'] as String)
          : null,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numero': numero,
      'type': type,
      if (campagneId != null) 'campagne_id': campagneId,
      if (adherentId != null) 'adherent_id': adherentId,
      if (clientId != null) 'client_id': clientId,
      if (operationId != null) 'operation_id': operationId,
      'operation_type': operationType,
      'contenu': contenu.toString(), // TODO: Sérialiser en JSON
      'pdf_path': pdfPath,
      if (qrCodeHash != null) 'qr_code_hash': qrCodeHash,
      if (qrCodeImagePath != null) 'qr_code_image_path': qrCodeImagePath,
      'statut': statut,
      'est_immuable': estImmuable ? 1 : 0,
      'date_generation': dateGeneration.toIso8601String(),
      if (dateAnnulation != null) 'date_annulation': dateAnnulation!.toIso8601String(),
      if (raisonAnnulation != null) 'raison_annulation': raisonAnnulation,
      if (documentAnnuleId != null) 'document_annule_id': documentAnnuleId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      if (updatedBy != null) 'updated_by': updatedBy,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (nombreVerifications != null) 'nombre_verifications': nombreVerifications,
      if (derniereVerification != null) 'derniere_verification': derniereVerification!.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  DocumentModel copyWith({
    int? id,
    String? numero,
    String? type,
    int? campagneId,
    int? adherentId,
    int? clientId,
    int? operationId,
    String? operationType,
    Map<String, dynamic>? contenu,
    String? pdfPath,
    String? qrCodeHash,
    String? qrCodeImagePath,
    String? statut,
    bool? estImmuable,
    DateTime? dateGeneration,
    DateTime? dateAnnulation,
    String? raisonAnnulation,
    int? documentAnnuleId,
    int? createdBy,
    DateTime? createdAt,
    int? updatedBy,
    DateTime? updatedAt,
    int? nombreVerifications,
    DateTime? derniereVerification,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      type: type ?? this.type,
      campagneId: campagneId ?? this.campagneId,
      adherentId: adherentId ?? this.adherentId,
      clientId: clientId ?? this.clientId,
      operationId: operationId ?? this.operationId,
      operationType: operationType ?? this.operationType,
      contenu: contenu ?? this.contenu,
      pdfPath: pdfPath ?? this.pdfPath,
      qrCodeHash: qrCodeHash ?? this.qrCodeHash,
      qrCodeImagePath: qrCodeImagePath ?? this.qrCodeImagePath,
      statut: statut ?? this.statut,
      estImmuable: estImmuable ?? this.estImmuable,
      dateGeneration: dateGeneration ?? this.dateGeneration,
      dateAnnulation: dateAnnulation ?? this.dateAnnulation,
      raisonAnnulation: raisonAnnulation ?? this.raisonAnnulation,
      documentAnnuleId: documentAnnuleId ?? this.documentAnnuleId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      nombreVerifications: nombreVerifications ?? this.nombreVerifications,
      derniereVerification: derniereVerification ?? this.derniereVerification,
    );
  }
}

/// Modèle pour la numérotation des documents
class DocumentNumerotationModel {
  final int? id;
  final String typeDocument;
  final int? campagneId; // null pour numérotation globale
  final int dernierNumero;
  final String prefixe; // Ex: "FAC", "REC", "DEP"
  final String format; // Ex: "FAC-{YYYY}-{NUM}"
  final DateTime updatedAt;

  DocumentNumerotationModel({
    this.id,
    required this.typeDocument,
    this.campagneId,
    required this.dernierNumero,
    required this.prefixe,
    required this.format,
    required this.updatedAt,
  });

  /// Générer le prochain numéro de document
  String genererProchainNumero() {
    final year = DateTime.now().year;
    final numero = dernierNumero + 1;
    
    if (format.contains('{YYYY}') && format.contains('{NUM}')) {
      return format
          .replaceAll('{YYYY}', year.toString())
          .replaceAll('{NUM}', numero.toString().padLeft(5, '0'));
    }
    
    return '$prefixe-${year.toString()}-${numero.toString().padLeft(5, '0')}';
  }

  factory DocumentNumerotationModel.fromMap(Map<String, dynamic> map) {
    return DocumentNumerotationModel(
      id: map['id'] as int?,
      typeDocument: map['type_document'] as String,
      campagneId: map['campagne_id'] as int?,
      dernierNumero: map['dernier_numero'] as int,
      prefixe: map['prefixe'] as String,
      format: map['format'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type_document': typeDocument,
      if (campagneId != null) 'campagne_id': campagneId,
      'dernier_numero': dernierNumero,
      'prefixe': prefixe,
      'format': format,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Modèle pour une vérification de document via QR Code
class DocumentVerificationModel {
  final int? id;
  final int documentId;
  final String hashVerifie;
  final bool estValide;
  final DateTime dateVerification;
  final String? ipAddress;
  final String? userAgent;

  DocumentVerificationModel({
    this.id,
    required this.documentId,
    required this.hashVerifie,
    required this.estValide,
    required this.dateVerification,
    this.ipAddress,
    this.userAgent,
  });

  factory DocumentVerificationModel.fromMap(Map<String, dynamic> map) {
    return DocumentVerificationModel(
      id: map['id'] as int?,
      documentId: map['document_id'] as int,
      hashVerifie: map['hash_verifie'] as String,
      estValide: (map['est_valide'] as int) == 1,
      dateVerification: DateTime.parse(map['date_verification'] as String),
      ipAddress: map['ip_address'] as String?,
      userAgent: map['user_agent'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'document_id': documentId,
      'hash_verifie': hashVerifie,
      'est_valide': estValide ? 1 : 0,
      'date_verification': dateVerification.toIso8601String(),
      if (ipAddress != null) 'ip_address': ipAddress,
      if (userAgent != null) 'user_agent': userAgent,
    };
  }
}

