import 'dart:convert';
import '../../data/models/document/document_model.dart';
import '../../services/database/db_initializer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Repository pour la gestion des documents générés
class DocumentRepository {
  /// Créer un nouveau document
  Future<DocumentModel> create(DocumentModel document) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Adapter le map pour correspondre à la structure de la table existante
      final map = {
        'numero': document.reference,
        'type': document.type,
        'operation_id': null,
        'operation_type': document.type,
        'contenu': jsonEncode(document.metadata),
        'pdf_path': document.filePath ?? '',
        'qr_code_hash': document.hash,
        'qr_code_image_path': null,
        'statut': 'valide',
        'est_immuable': 1,
        'date_generation': document.generatedAt.toIso8601String(),
        'created_by': document.generatedBy,
        'created_at': document.generatedAt.toIso8601String(),
        'nombre_verifications': document.isVerified ? 1 : 0,
        if (document.isVerified && document.verifiedAt != null)
          'derniere_verification': document.verifiedAt!.toIso8601String(),
      };
      
      final id = await db.insert(
        'documents',
        map,
      );

      return document.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création du document: $e');
    }
  }

  /// Récupérer un document par son ID
  Future<DocumentModel?> getById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final results = await db.query(
        'documents',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return _mapToDocumentModel(results.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du document: $e');
    }
  }

  /// Récupérer un document par sa référence
  Future<DocumentModel?> getByReference(String reference) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final results = await db.query(
        'documents',
        where: 'numero = ?',
        whereArgs: [reference],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return _mapToDocumentModel(results.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du document: $e');
    }
  }

  /// Mapper les données de la table vers DocumentModel
  DocumentModel _mapToDocumentModel(Map<String, dynamic> map) {
    final metadata = map['contenu'] != null
        ? jsonDecode(map['contenu'] as String) as Map<String, dynamic>
        : <String, dynamic>{};

    return DocumentModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      reference: map['numero'] as String,
      cooperativeId: metadata['cooperative_id'] as int? ?? 0,
      hash: map['qr_code_hash'] as String? ?? '',
      generatedAt: DateTime.parse(map['date_generation'] as String),
      generatedBy: map['created_by'] as int,
      filePath: map['pdf_path'] as String?,
      metadata: metadata,
      qrCodeData: metadata['qr_code_data'] as String?,
      isVerified: (map['nombre_verifications'] as int? ?? 0) > 0,
      verifiedAt: map['derniere_verification'] != null
          ? DateTime.parse(map['derniere_verification'] as String)
          : null,
    );
  }

  /// Récupérer tous les documents d'un type donné
  Future<List<DocumentModel>> getByType(String type, {int? cooperativeId}) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String where = 'type = ?';
      List<dynamic> whereArgs = [type];
      
      if (cooperativeId != null) {
        where += ' AND cooperative_id = ?';
        whereArgs.add(cooperativeId);
      }

      final results = await db.query(
        'documents',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'generated_at DESC',
      );

      return results.map((map) => _mapToDocumentModel(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des documents: $e');
    }
  }

  /// Marquer un document comme vérifié
  Future<void> markAsVerified(int documentId, int verifiedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer le document actuel
      final doc = await getById(documentId);
      if (doc == null) throw Exception('Document non trouvé');
      
      final currentVerifications = doc.isVerified ? 1 : 0;
      
      await db.update(
        'documents',
        {
          'nombre_verifications': currentVerifications + 1,
          'derniere_verification': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [documentId],
      );
    } catch (e) {
      throw Exception('Erreur lors de la vérification du document: $e');
    }
  }

  /// Récupérer les documents récents
  Future<List<DocumentModel>> getRecent({
    int? cooperativeId,
    int limit = 50,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String where = '1=1';
      List<dynamic> whereArgs = [];
      
      if (cooperativeId != null) {
        where += ' AND cooperative_id = ?';
        whereArgs.add(cooperativeId);
      }

      final results = await db.query(
        'documents',
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'generated_at DESC',
        limit: limit,
      );

      return results.map((map) => _mapToDocumentModel(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des documents récents: $e');
    }
  }
}

