import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/document/document_model.dart';
import '../../services/document/document_generator_service.dart';
import '../../services/document/repositories/document_repository.dart';

/// Provider pour la gestion des documents dans Flutter
class DocumentProvider extends ChangeNotifier {
  final DocumentGeneratorService _documentService;
  final DocumentRepository _documentRepository;

  DocumentModel? _currentDocument;
  List<DocumentModel> _recentDocuments = [];
  bool _isLoading = false;
  String? _errorMessage;

  DocumentProvider({
    DocumentGeneratorService? documentService,
    DocumentRepository? documentRepository,
  })  : _documentService = documentService ?? DocumentGeneratorService(),
        _documentRepository = documentRepository ?? DocumentRepository();

  // Getters
  DocumentModel? get currentDocument => _currentDocument;
  List<DocumentModel> get recentDocuments => _recentDocuments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Générer un document
  Future<DocumentModel?> generateDocument({
    required DocumentType documentType,
    required String documentReference,
    required int cooperativeId,
    required int generatedBy,
    required String documentTitle,
    required Function(pw.Context) buildContent,
    required Map<String, dynamic> contentData,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final document = await _documentService.generateDocument(
        documentType: documentType,
        documentReference: documentReference,
        cooperativeId: cooperativeId,
        generatedBy: generatedBy,
        documentTitle: documentTitle,
        buildContent: buildContent,
        contentData: contentData,
        additionalMetadata: additionalMetadata,
      );

      _currentDocument = document;
      await loadRecentDocuments(cooperativeId: cooperativeId);
      
      _isLoading = false;
      notifyListeners();
      return document;
    } catch (e) {
      _errorMessage = 'Erreur lors de la génération du document: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Charger les documents récents
  Future<void> loadRecentDocuments({int? cooperativeId, int limit = 50}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recentDocuments = await _documentRepository.getRecent(
        cooperativeId: cooperativeId,
        limit: limit,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des documents: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupérer un document par sa référence
  Future<DocumentModel?> getDocumentByReference(String reference) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final document = await _documentRepository.getByReference(reference);
      _currentDocument = document;
      
      _isLoading = false;
      notifyListeners();
      return document;
    } catch (e) {
      _errorMessage = 'Erreur lors de la récupération du document: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Vérifier un document
  Future<bool> verifyDocument(int documentId, int verifiedBy) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _documentRepository.markAsVerified(documentId, verifiedBy);
      
      // Recharger le document
      if (_currentDocument?.id == documentId) {
        await getDocumentByReference(_currentDocument!.reference);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la vérification: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Réinitialiser l'état
  void reset() {
    _currentDocument = null;
    _errorMessage = null;
    notifyListeners();
  }
}

