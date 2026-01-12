import '../../data/models/document_securise_model.dart';
import '../../services/database/db_initializer.dart';
import 'qrcode_service.dart';

/// Service de vérification des documents sécurisés
class VerificationService {
  /// Vérifier un document depuis un QR Code scanné
  static Future<VerificationResult> verifyFromQRCode(String qrCodeJsonString) async {
    try {
      // Décoder les données QR Code
      final qrCodeData = QRCodeService.decodeQRCodeData(qrCodeJsonString);
      
      // Récupérer le document sécurisé depuis la base
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'documents_securises',
        where: 'document_type = ? AND document_id = ?',
        whereArgs: [qrCodeData.type, int.parse(qrCodeData.id)],
        limit: 1,
      );
      
      if (result.isEmpty) {
        return VerificationResult(
          isValid: false,
          message: 'Document non trouvé dans la base de données',
        );
      }
      
      final documentSecurise = DocumentSecuriseModel.fromMap(result.first);
      
      // Vérifier le hash
      final hashMatch = documentSecurise.hashVerification == qrCodeData.hash;
      
      if (!hashMatch) {
        return VerificationResult(
          isValid: false,
          message: 'Hash de vérification invalide - Document modifié',
        );
      }
      
      return VerificationResult(
        isValid: true,
        message: 'Document vérifié avec succès',
        documentType: qrCodeData.type,
        documentId: qrCodeData.id,
        dateGeneration: documentSecurise.dateGeneration,
      );
    } catch (e) {
      return VerificationResult(
        isValid: false,
        message: 'Erreur lors de la vérification: $e',
      );
    }
  }

  /// Vérifier un document avec son hash
  static Future<VerificationResult> verifyWithHash({
    required String documentType,
    required int documentId,
    required String hash,
  }) async {
    final db = await DatabaseInitializer.database;
    
    final result = await db.query(
      'documents_securises',
      where: 'document_type = ? AND document_id = ?',
      whereArgs: [documentType, documentId],
      limit: 1,
    );
    
    if (result.isEmpty) {
      return VerificationResult(
        isValid: false,
        message: 'Document non trouvé',
      );
    }
    
    final documentSecurise = DocumentSecuriseModel.fromMap(result.first);
    
    if (documentSecurise.hashVerification != hash) {
      return VerificationResult(
        isValid: false,
        message: 'Hash invalide - Document modifié',
      );
    }
    
    return VerificationResult(
      isValid: true,
      message: 'Document vérifié avec succès',
      documentType: documentType,
      documentId: documentId.toString(),
      dateGeneration: documentSecurise.dateGeneration,
    );
  }
}

/// Résultat de vérification
class VerificationResult {
  final bool isValid;
  final String message;
  final String? documentType;
  final String? documentId;
  final DateTime? dateGeneration;

  VerificationResult({
    required this.isValid,
    required this.message,
    this.documentType,
    this.documentId,
    this.dateGeneration,
  });
}

