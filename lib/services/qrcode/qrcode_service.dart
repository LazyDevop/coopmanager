import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../../data/models/document_securise_model.dart';
import '../../config/app_config.dart';

/// Service pour la génération de QR Codes
class QRCodeService {
  /// Générer les données pour le QR Code
  static QRCodeData generateQRCodeData({
    required String documentType,
    required String documentId,
    required Map<String, dynamic> documentContent,
  }) {
    // Générer le hash du document
    final hash = _generateDocumentHash(documentContent);
    
    return QRCodeData(
      type: documentType,
      id: documentId,
      hash: hash,
      date: DateTime.now().toIso8601String(),
      cooperative: AppConfig.appName,
    );
  }

  /// Générer le hash SHA-256 d'un document
  static String _generateDocumentHash(Map<String, dynamic> content) {
    // Convertir le contenu en JSON et générer le hash
    final jsonString = jsonEncode(content);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Générer le hash SHA-256 d'une chaîne
  static String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Vérifier l'intégrité d'un document
  static bool verifyDocument({
    required String hash,
    required Map<String, dynamic> documentContent,
  }) {
    final calculatedHash = _generateDocumentHash(documentContent);
    return hash == calculatedHash;
  }

  /// Encoder les données QR Code en JSON string
  static String encodeQRCodeData(QRCodeData data) {
    return data.toJsonString();
  }

  /// Décoder les données QR Code depuis JSON string
  static QRCodeData decodeQRCodeData(String jsonString) {
    return QRCodeData.fromJsonString(jsonString);
  }
}

