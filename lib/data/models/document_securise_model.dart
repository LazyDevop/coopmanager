import 'dart:convert';

/// Modèle de données pour un Document Sécurisé (avec QR Code)
class DocumentSecuriseModel {
  final int? id;
  final String documentType; // 'facture', 'recu', 'bordereau', 'etat_compte'
  final int documentId;
  final String qrCodeData; // JSON encodé dans le QR Code
  final String hashVerification; // Hash SHA-256 du document
  final String? qrCodeImagePath; // Chemin vers l'image du QR Code
  final DateTime dateGeneration;
  final int? createdBy;

  DocumentSecuriseModel({
    this.id,
    required this.documentType,
    required this.documentId,
    required this.qrCodeData,
    required this.hashVerification,
    this.qrCodeImagePath,
    required this.dateGeneration,
    this.createdBy,
  });

  bool get isFacture => documentType == 'facture';
  bool get isRecu => documentType == 'recu';
  bool get isBordereau => documentType == 'bordereau';
  bool get isEtatCompte => documentType == 'etat_compte';

  // Convertir depuis Map (base de données)
  factory DocumentSecuriseModel.fromMap(Map<String, dynamic> map) {
    return DocumentSecuriseModel(
      id: map['id'] as int?,
      documentType: map['document_type'] as String,
      documentId: map['document_id'] as int,
      qrCodeData: map['qr_code_data'] as String,
      hashVerification: map['hash_verification'] as String,
      qrCodeImagePath: map['qr_code_image_path'] as String?,
      dateGeneration: DateTime.parse(map['date_generation'] as String),
      createdBy: map['created_by'] as int?,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'document_type': documentType,
      'document_id': documentId,
      'qr_code_data': qrCodeData,
      'hash_verification': hashVerification,
      'qr_code_image_path': qrCodeImagePath,
      'date_generation': dateGeneration.toIso8601String(),
      'created_by': createdBy,
    };
  }

  // Créer une copie avec des modifications
  DocumentSecuriseModel copyWith({
    int? id,
    String? documentType,
    int? documentId,
    String? qrCodeData,
    String? hashVerification,
    String? qrCodeImagePath,
    DateTime? dateGeneration,
    int? createdBy,
  }) {
    return DocumentSecuriseModel(
      id: id ?? this.id,
      documentType: documentType ?? this.documentType,
      documentId: documentId ?? this.documentId,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      hashVerification: hashVerification ?? this.hashVerification,
      qrCodeImagePath: qrCodeImagePath ?? this.qrCodeImagePath,
      dateGeneration: dateGeneration ?? this.dateGeneration,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

/// Données encodées dans le QR Code
class QRCodeData {
  final String type;
  final String id;
  final String hash;
  final String date;
  final String cooperative;

  QRCodeData({
    required this.type,
    required this.id,
    required this.hash,
    required this.date,
    required this.cooperative,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'hash': hash,
      'date': date,
      'cooperative': cooperative,
    };
  }

  factory QRCodeData.fromJson(Map<String, dynamic> json) {
    return QRCodeData(
      type: json['type'] as String,
      id: json['id'] as String,
      hash: json['hash'] as String,
      date: json['date'] as String,
      cooperative: json['cooperative'] as String,
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory QRCodeData.fromJsonString(String jsonString) {
    return QRCodeData.fromJson(jsonDecode(jsonString));
  }
}

