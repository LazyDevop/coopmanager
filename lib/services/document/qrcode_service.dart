import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../data/models/document/document_model.dart';

/// Service pour générer et vérifier les QR codes des documents
class QRCodeService {
  /// Générer les données JSON pour le QR code
  String generateQRCodeData({
    required DocumentType documentType,
    required String documentId,
    required int cooperativeId,
    required String hash,
    required DateTime generatedAt,
    Map<String, dynamic>? additionalData,
  }) {
    final data = {
      'document_type': documentType.code,
      'document_id': documentId,
      'cooperative_id': 'COOP-$cooperativeId',
      'hash': hash,
      'generated_at': generatedAt.toIso8601String(),
      if (additionalData != null) ...additionalData,
    };

    return jsonEncode(data);
  }

  /// Générer le hash SHA-256 d'un document
  String generateHash({
    required String documentType,
    required String documentId,
    required int cooperativeId,
    required DateTime generatedAt,
    required Map<String, dynamic> content,
  }) {
    final contentString = jsonEncode({
      'type': documentType,
      'id': documentId,
      'cooperative_id': cooperativeId,
      'generated_at': generatedAt.toIso8601String(),
      'content': content,
    });

    final bytes = utf8.encode(contentString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Vérifier l'authenticité d'un document via son hash
  bool verifyDocument({
    required String hash,
    required String documentType,
    required String documentId,
    required int cooperativeId,
    required DateTime generatedAt,
    required Map<String, dynamic> content,
  }) {
    final calculatedHash = generateHash(
      documentType: documentType,
      documentId: documentId,
      cooperativeId: cooperativeId,
      generatedAt: generatedAt,
      content: content,
    );

    return calculatedHash == hash;
  }

  /// Parser les données du QR code
  Map<String, dynamic>? parseQRCodeData(String qrCodeData) {
    try {
      return jsonDecode(qrCodeData) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Vérifier un document via son QR code
  bool verifyFromQRCode({
    required String qrCodeData,
    required DocumentModel document,
  }) {
    final parsed = parseQRCodeData(qrCodeData);
    if (parsed == null) return false;

    // Vérifier que les données correspondent
    if (parsed['document_id'] != document.reference) return false;
    if (parsed['document_type'] != document.type) return false;
    if (parsed['hash'] != document.hash) return false;

    return true;
  }
}

