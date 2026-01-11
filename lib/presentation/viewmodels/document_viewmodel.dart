import 'package:flutter/foundation.dart';
import '../../data/models/document_model.dart';
import '../../services/document/document_service.dart';

class DocumentViewModel extends ChangeNotifier {
  final DocumentService _documentService = DocumentService();
  
  List<DocumentModel> _documents = [];
  DocumentModel? _selectedDocument;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filtres
  String? _filterType;
  String? _filterStatut;
  int? _filterAdherentId;
  int? _filterClientId;
  int? _filterCampagneId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _searchQuery = '';
  
  // Getters
  List<DocumentModel> get documents => _documents;
  DocumentModel? get selectedDocument => _selectedDocument;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Documents filtrés
  List<DocumentModel> get filteredDocuments {
    List<DocumentModel> filtered = _documents;
    
    if (_filterType != null) {
      filtered = filtered.where((d) => d.type == _filterType).toList();
    }
    
    if (_filterStatut != null) {
      filtered = filtered.where((d) => d.statut == _filterStatut).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((d) {
        return d.numero.toLowerCase().contains(query) ||
               d.typeLabel.toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
  }
  
  /// Charger tous les documents
  Future<void> loadDocuments({
    String? type,
    String? statut,
    int? adherentId,
    int? clientId,
    int? campagneId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _documents = await _documentService.getDocuments(
        type: type ?? _filterType,
        statut: statut ?? _filterStatut,
        adherentId: adherentId ?? _filterAdherentId,
        clientId: clientId ?? _filterClientId,
        campagneId: campagneId ?? _filterCampagneId,
        startDate: startDate ?? _filterStartDate,
        endDate: endDate ?? _filterEndDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Charger un document par ID
  Future<void> loadDocumentById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _selectedDocument = await _documentService.getDocumentById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Rechercher des documents
  void searchDocuments(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  /// Définir les filtres
  void setFilterType(String? type) {
    _filterType = type;
    loadDocuments();
  }
  
  void setFilterStatut(String? statut) {
    _filterStatut = statut;
    loadDocuments();
  }
  
  void setFilterAdherent(int? adherentId) {
    _filterAdherentId = adherentId;
    loadDocuments();
  }
  
  void setFilterClient(int? clientId) {
    _filterClientId = clientId;
    loadDocuments();
  }
  
  void setFilterCampagne(int? campagneId) {
    _filterCampagneId = campagneId;
    loadDocuments();
  }
  
  void setFilterDates(DateTime? startDate, DateTime? endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    loadDocuments();
  }
  
  /// Réinitialiser les filtres
  void resetFilters() {
    _filterType = null;
    _filterStatut = null;
    _filterAdherentId = null;
    _filterClientId = null;
    _filterCampagneId = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _searchQuery = '';
    loadDocuments();
  }
  
  /// Vérifier un document via QR Code
  Future<bool> verifierDocument({
    required int documentId,
    required String hash,
  }) async {
    try {
      return await _documentService.verifierDocument(
        documentId: documentId,
        hashVerifie: hash,
      );
    } catch (e) {
      _errorMessage = 'Erreur lors de la vérification: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  /// Effacer le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

