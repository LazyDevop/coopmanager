import 'package:flutter/foundation.dart';
import '../../data/models/client_model.dart';
import '../../services/client/client_service.dart';
import '../../services/client/client_payment_service.dart';
import '../../services/client/client_code_generator.dart';

class ClientViewModel extends ChangeNotifier {
  final ClientService _clientService = ClientService();
  final ClientPaymentService _paymentService = ClientPaymentService();
  final ClientCodeGenerator _codeGenerator = ClientCodeGenerator();
  
  List<ClientModel> _clients = [];
  ClientModel? _selectedClient;
  List<VenteClientModel> _ventesClient = [];
  List<PaiementClientModel> _paiementsClient = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filtres
  String? _filterType;
  String? _filterStatut;
  String _searchQuery = '';
  
  // Getters
  List<ClientModel> get clients => _clients;
  ClientModel? get selectedClient => _selectedClient;
  List<VenteClientModel> get ventesClient => _ventesClient;
  List<PaiementClientModel> get paiementsClient => _paiementsClient;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Clients filtrés
  List<ClientModel> get filteredClients {
    List<ClientModel> filtered = _clients;
    
    if (_filterType != null) {
      filtered = filtered.where((c) => c.typeClient == _filterType).toList();
    }
    
    if (_filterStatut != null) {
      filtered = filtered.where((c) => c.statut == _filterStatut).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.codeClient.toLowerCase().contains(query) ||
               c.raisonSociale.toLowerCase().contains(query) ||
               (c.nomResponsable?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    return filtered;
  }
  
  /// Charger tous les clients
  Future<void> loadClients({
    String? type,
    String? statut,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _clients = await _clientService.getClients(
        typeClient: type ?? _filterType,
        statut: statut ?? _filterStatut,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Générer un code client automatiquement (ERP)
  Future<String?> generateNextClientCode() async {
    try {
      final code = await _codeGenerator.generateUniqueCode();
      return code;
    } catch (e) {
      _errorMessage = 'Erreur génération code client: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
  
  /// Charger un client par ID avec détails
  Future<void> loadClientById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _selectedClient = await _clientService.getClientById(id);
      
      if (_selectedClient != null) {
        _ventesClient = await _paymentService.getVentesByClient(id);
        _paiementsClient = await _paymentService.getPaiementsByClient(id);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Créer un client
  Future<bool> createClient({
    required String codeClient,
    required String typeClient,
    required String raisonSociale,
    String? nomResponsable,
    String? telephone,
    String? email,
    String? adresse,
    String? pays,
    String? ville,
    String? nrc,
    String? ifu,
    double? plafondCredit,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _clientService.createClient(
        codeClient: codeClient,
        typeClient: typeClient,
        raisonSociale: raisonSociale,
        nomResponsable: nomResponsable,
        telephone: telephone,
        email: email,
        adresse: adresse,
        pays: pays,
        ville: ville,
        nrc: nrc,
        ifu: ifu,
        plafondCredit: plafondCredit,
        createdBy: createdBy,
      );
      
      await loadClients();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Mettre à jour un client
  Future<bool> updateClient({
    required int id,
    String? codeClient,
    String? typeClient,
    String? raisonSociale,
    String? nomResponsable,
    String? telephone,
    String? email,
    String? adresse,
    String? pays,
    String? ville,
    String? nrc,
    String? ifu,
    double? plafondCredit,
    required int updatedBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _clientService.updateClient(
        id: id,
        codeClient: codeClient,
        typeClient: typeClient,
        raisonSociale: raisonSociale,
        nomResponsable: nomResponsable,
        telephone: telephone,
        email: email,
        adresse: adresse,
        pays: pays,
        ville: ville,
        nrc: nrc,
        ifu: ifu,
        plafondCredit: plafondCredit,
        updatedBy: updatedBy,
      );
      
      await loadClientById(id);
      // Rafraîchir aussi la liste pour refléter les modifications
      await loadClients();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Bloquer un client
  Future<bool> bloquerClient({
    required int id,
    required String raison,
    required int blockedBy,
  }) async {
    try {
      await _clientService.bloquerClient(
        id: id,
        raison: raison,
        blockedBy: blockedBy,
      );
      await loadClientById(id);
      await loadClients();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Suspendre un client
  Future<bool> suspendreClient({
    required int id,
    required String raison,
    required int suspendedBy,
  }) async {
    try {
      await _clientService.suspendreClient(
        id: id,
        raison: raison,
        suspendedBy: suspendedBy,
      );
      await loadClientById(id);
      await loadClients();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Réactiver un client
  Future<bool> reactiverClient({
    required int id,
    required int reactivatedBy,
  }) async {
    try {
      await _clientService.reactiverClient(
        id: id,
        reactivatedBy: reactivatedBy,
      );
      await loadClientById(id);
      await loadClients();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Rechercher des clients
  void searchClients(String query) {
    final normalized = query.trim();
    if (_searchQuery.trim() == normalized) return;
    _searchQuery = normalized;
    loadClients();
  }
  
  /// Définir les filtres
  void setFilterType(String? type) {
    _filterType = type;
    loadClients();
  }
  
  void setFilterStatut(String? statut) {
    _filterStatut = statut;
    loadClients();
  }
  
  /// Réinitialiser les filtres
  void resetFilters() {
    _filterType = null;
    _filterStatut = null;
    _searchQuery = '';
    loadClients();
  }
  
  /// Obtenir les clients impayés
  Future<List<ClientModel>> getClientsImpayes({double? montantMinimum}) async {
    try {
      return await _clientService.getClientsImpayes(montantMinimum: montantMinimum);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }
  
  /// Vérifier si un client peut vendre
  Future<bool> peutClientVendre(int clientId, double montantVente) async {
    try {
      return await _clientService.peutClientVendre(clientId, montantVente);
    } catch (e) {
      return false;
    }
  }
  
  /// Effacer le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
