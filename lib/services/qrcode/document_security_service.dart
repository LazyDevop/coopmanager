import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../data/models/document_securise_model.dart';
import '../../services/database/db_initializer.dart';
import 'qrcode_service.dart';

/// Service pour la sécurité documentaire (QR Code + Hash)
class DocumentSecurityService {
  /// Générer et sauvegarder un document sécurisé
  static Future<DocumentSecuriseModel> generateSecureDocument({
    required String documentType,
    required int documentId,
    required Map<String, dynamic> documentContent,
    int? createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    // Générer les données QR Code
    final qrCodeData = QRCodeService.generateQRCodeData(
      documentType: documentType,
      documentId: documentId.toString(),
      documentContent: documentContent,
    );
    
    // Encoder les données QR Code
    final qrCodeDataString = QRCodeService.encodeQRCodeData(qrCodeData);
    
    // Générer le hash de vérification
    final hash = QRCodeService.generateHash(qrCodeDataString);
    
    // Créer le document sécurisé
    final documentSecurise = DocumentSecuriseModel(
      documentType: documentType,
      documentId: documentId,
      qrCodeData: qrCodeDataString,
      hashVerification: hash,
      dateGeneration: DateTime.now(),
      createdBy: createdBy,
    );
    
    // Sauvegarder en base de données
    final id = await db.insert(
      'documents_securises',
      documentSecurise.toMap(),
    );
    
    return documentSecurise.copyWith(id: id);
  }

  /// Récupérer un document sécurisé par type et ID
  static Future<DocumentSecuriseModel?> getSecureDocument({
    required String documentType,
    required int documentId,
  }) async {
    final db = await DatabaseInitializer.database;
    
    final result = await db.query(
      'documents_securises',
      where: 'document_type = ? AND document_id = ?',
      whereArgs: [documentType, documentId],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    
    return DocumentSecuriseModel.fromMap(result.first);
  }

  /// Vérifier l'intégrité d'un document
  static Future<bool> verifyDocument({
    required String documentType,
    required int documentId,
    required Map<String, dynamic> documentContent,
  }) async {
    final documentSecurise = await getSecureDocument(
      documentType: documentType,
      documentId: documentId,
    );
    
    if (documentSecurise == null) return false;
    
    // Décoder les données QR Code
    final qrCodeData = QRCodeService.decodeQRCodeData(documentSecurise.qrCodeData);
    
    // Vérifier le hash
    return QRCodeService.verifyDocument(
      hash: qrCodeData.hash,
      documentContent: documentContent,
    );
  }

  /// Mettre à jour le chemin de l'image QR Code
  static Future<void> updateQRCodeImagePath({
    required int documentSecuriseId,
    required String imagePath,
  }) async {
    final db = await DatabaseInitializer.database;
    
    await db.update(
      'documents_securises',
      {'qr_code_image_path': imagePath},
      where: 'id = ?',
      whereArgs: [documentSecuriseId],
    );
  }
}

