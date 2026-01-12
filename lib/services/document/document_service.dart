import 'dart:convert';
import '../database/db_initializer.dart';
import '../../data/models/document_model.dart';
import '../auth/audit_service.dart';
import 'pdf_generator_service.dart';
import '../qrcode/qrcode_service.dart';
import '../qrcode/document_security_service.dart';

/// Service principal pour la gestion des documents officiels
/// 
/// Orchestre la création, génération, stockage et vérification des documents
class DocumentService {
  final AuditService _auditService = AuditService();
  final PdfGeneratorService _pdfGeneratorService = PdfGeneratorService();
  final DocumentSecurityService _documentSecurityService = DocumentSecurityService();

  /// Générer un document officiel
  /// 
  /// Cette méthode :
  /// 1. Génère le numéro unique séquentiel
  /// 2. Crée le contenu du document
  /// 3. Génère le PDF
  /// 4. Génère le QR Code avec hash SHA-256
  /// 5. Enregistre en base de données
  /// 6. Journalise l'opération
  Future<DocumentModel> genererDocument({
    required String type,
    required String operationType,
    required Map<String, dynamic> contenu,
    int? campagneId,
    int? adherentId,
    int? clientId,
    int? operationId,
    required int createdBy,
    bool estImmuable = true, // Par défaut, les documents sont immuables après génération
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      // Démarrer une transaction
      await db.execute('BEGIN TRANSACTION');
      
      try {
        // 1. Générer le numéro unique
        final numero = await _genererNumeroDocument(type, campagneId);
        
        // 2. Préparer le contenu complet
        final contenuComplet = {
          ...contenu,
          'numero': numero,
          'type': type,
          'date_generation': DateTime.now().toIso8601String(),
          'campagne_id': campagneId,
          'adherent_id': adherentId,
          'client_id': clientId,
          'operation_id': operationId,
        };
        
        // 3. Générer le PDF
        final pdfPath = await _pdfGeneratorService.genererPDF(
          type: type,
          numero: numero,
          contenu: contenuComplet,
        );
        
        // 4. Générer le hash SHA-256 et QR Code
        final hash = await _genererHashDocument(contenuComplet);
        final qrCodeImagePath = await _genererQRCodeImage(numero, hash);
        
        // 5. Créer le document en base
        final document = DocumentModel(
          numero: numero,
          type: type,
          campagneId: campagneId,
          adherentId: adherentId,
          clientId: clientId,
          operationId: operationId,
          operationType: operationType,
          contenu: contenuComplet,
          pdfPath: pdfPath,
          qrCodeHash: hash,
          qrCodeImagePath: qrCodeImagePath,
          statut: 'genere',
          estImmuable: estImmuable,
          dateGeneration: DateTime.now(),
          createdBy: createdBy,
          createdAt: DateTime.now(),
        );
        
        final documentId = await db.insert('documents', document.toMap());
        
        // 6. Mettre à jour la numérotation
        await _incrementerNumerotation(type, campagneId);
        
        // 7. Journaliser
        await _auditService.logAction(
          userId: createdBy,
          action: 'GENERATE_DOCUMENT',
          entityType: 'documents',
          entityId: documentId,
          details: 'Document $type généré: $numero',
        );
        
        // Commit transaction
        await db.execute('COMMIT');
        
        return document.copyWith(id: documentId);
      } catch (e) {
        // Rollback en cas d'erreur
        await db.execute('ROLLBACK');
        rethrow;
      }
    } catch (e) {
      throw Exception('Erreur lors de la génération du document: $e');
    }
  }

  /// Générer un numéro de document unique et séquentiel
  Future<String> _genererNumeroDocument(String type, int? campagneId) async {
    final db = await DatabaseInitializer.database;
    
    // Récupérer ou créer la numérotation
    final numerotationResult = await db.query(
      'document_numerotation',
      where: 'type_document = ? AND (campagne_id = ? OR (campagne_id IS NULL AND ? IS NULL))',
      whereArgs: [type, campagneId, campagneId],
      limit: 1,
    );
    
    DocumentNumerotationModel numerotation;
    
    if (numerotationResult.isEmpty) {
      // Créer une nouvelle numérotation
      final typeResult = await db.query(
        'document_types',
        where: 'code = ?',
        whereArgs: [type],
        limit: 1,
      );
      
      if (typeResult.isEmpty) {
        throw Exception('Type de document non trouvé: $type');
      }
      
      final prefixe = typeResult.first['prefixe'] as String;
      final format = typeResult.first['format'] as String;
      
      final id = await db.insert('document_numerotation', {
        'type_document': type,
        'campagne_id': campagneId,
        'dernier_numero': 0,
        'prefixe': prefixe,
        'format': format,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      numerotation = DocumentNumerotationModel(
        id: id,
        typeDocument: type,
        campagneId: campagneId,
        dernierNumero: 0,
        prefixe: prefixe,
        format: format,
        updatedAt: DateTime.now(),
      );
    } else {
      numerotation = DocumentNumerotationModel.fromMap(numerotationResult.first);
    }
    
    return numerotation.genererProchainNumero();
  }

  /// Incrémenter la numérotation après génération
  Future<void> _incrementerNumerotation(String type, int? campagneId) async {
    final db = await DatabaseInitializer.database;
    
    await db.rawUpdate('''
      UPDATE document_numerotation
      SET dernier_numero = dernier_numero + 1,
          updated_at = ?
      WHERE type_document = ? 
        AND (campagne_id = ? OR (campagne_id IS NULL AND ? IS NULL))
    ''', [
      DateTime.now().toIso8601String(),
      type,
      campagneId,
      campagneId,
    ]);
  }

  /// Générer le hash SHA-256 d'un document
  Future<String> _genererHashDocument(Map<String, dynamic> contenu) async {
    // Sérialiser le contenu en JSON de manière déterministe
    final jsonString = jsonEncode(contenu);
    
    // Générer le hash SHA-256
    final hash = await DocumentSecurityService.generateQRCodeHash(
      type: contenu['type'] as String,
      id: contenu['operation_id'] as int? ?? 0,
      adherentId: contenu['adherent_id'] as int? ?? 0,
      montant: (contenu['montant'] as num?)?.toDouble() ?? 0.0,
    );
    
    return hash;
  }

  /// Générer l'image QR Code
  Future<String> _genererQRCodeImage(String numero, String hash) async {
    final qrCodeData = {
      'numero': numero,
      'hash': hash,
      'date': DateTime.now().toIso8601String(),
    };
    
    final qrCodeImagePath = await QRCodeService.generateQRCodeImage(
      data: jsonEncode(qrCodeData),
      filename: 'qr_$numero.png',
    );
    
    return qrCodeImagePath;
  }

  /// Obtenir un document par ID
  Future<DocumentModel?> getDocumentById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'documents',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      return DocumentModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du document: $e');
    }
  }

  /// Obtenir un document par numéro
  Future<DocumentModel?> getDocumentByNumero(String numero) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'documents',
        where: 'numero = ?',
        whereArgs: [numero],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      return DocumentModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du document: $e');
    }
  }

  /// Obtenir tous les documents avec filtres
  Future<List<DocumentModel>> getDocuments({
    String? type,
    int? adherentId,
    int? clientId,
    int? campagneId,
    String? statut,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String where = '1=1';
      List<dynamic> whereArgs = [];
      
      if (type != null) {
        where += ' AND type = ?';
        whereArgs.add(type);
      }
      
      if (adherentId != null) {
        where += ' AND adherent_id = ?';
        whereArgs.add(adherentId);
      }
      
      if (clientId != null) {
        where += ' AND client_id = ?';
        whereArgs.add(clientId);
      }
      
      if (campagneId != null) {
        where += ' AND campagne_id = ?';
        whereArgs.add(campagneId);
      }
      
      if (statut != null) {
        where += ' AND statut = ?';
        whereArgs.add(statut);
      }
      
      if (startDate != null) {
        where += ' AND date_generation >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        where += ' AND date_generation <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      final result = await db.query(
        'documents',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'date_generation DESC',
        limit: limit,
      );
      
      return result.map((map) => DocumentModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des documents: $e');
    }
  }

  /// Annuler un document (créer un document d'annulation)
  Future<DocumentModel> annulerDocument({
    required int documentId,
    required String raison,
    required int annulePar,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      await db.execute('BEGIN TRANSACTION');
      
      try {
        // Récupérer le document à annuler
        final document = await getDocumentById(documentId);
        if (document == null) {
          throw Exception('Document non trouvé');
        }
        
        if (document.estImmuable && document.statut == 'genere') {
          throw Exception('Document immuable, impossible d\'annuler directement');
        }
        
        // Marquer le document comme annulé
        await db.update(
          'documents',
          {
            'statut': 'annule',
            'date_annulation': DateTime.now().toIso8601String(),
            'raison_annulation': raison,
            'updated_by': annulePar,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [documentId],
        );
        
        // Créer un document d'annulation
        final documentAnnulation = await genererDocument(
          type: '${document.type}_annulation',
          operationType: 'annulation',
          contenu: {
            'document_annule_numero': document.numero,
            'document_annule_id': document.id,
            'raison': raison,
            'date_annulation': DateTime.now().toIso8601String(),
          },
          campagneId: document.campagneId,
          adherentId: document.adherentId,
          clientId: document.clientId,
          operationId: documentId,
          createdBy: annulePar,
          estImmuable: true,
        );
        
        // Mettre à jour le document annulé avec la référence au document d'annulation
        await db.update(
          'documents',
          {'document_annule_id': documentAnnulation.id},
          where: 'id = ?',
          whereArgs: [documentId],
        );
        
        await db.execute('COMMIT');
        
        return documentAnnulation;
      } catch (e) {
        await db.execute('ROLLBACK');
        rethrow;
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation du document: $e');
    }
  }

  /// Vérifier un document via QR Code hash
  Future<bool> verifierDocument({
    required int documentId,
    required String hashVerifie,
    String? ipAddress,
    String? userAgent,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      final document = await getDocumentById(documentId);
      if (document == null) {
        return false;
      }
      
      final estValide = document.qrCodeHash == hashVerifie;
      
      // Enregistrer la vérification
      await db.insert('document_verifications', {
        'document_id': documentId,
        'hash_verifie': hashVerifie,
        'est_valide': estValide ? 1 : 0,
        'date_verification': DateTime.now().toIso8601String(),
        if (ipAddress != null) 'ip_address': ipAddress,
        if (userAgent != null) 'user_agent': userAgent,
      });
      
      // Mettre à jour le compteur de vérifications
      if (estValide) {
        await db.rawUpdate('''
          UPDATE documents
          SET nombre_verifications = nombre_verifications + 1,
              derniere_verification = ?
          WHERE id = ?
        ''', [DateTime.now().toIso8601String(), documentId]);
      }
      
      return estValide;
    } catch (e) {
      throw Exception('Erreur lors de la vérification: $e');
    }
  }
}

