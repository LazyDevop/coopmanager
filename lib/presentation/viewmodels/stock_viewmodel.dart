import 'package:flutter/foundation.dart';
import '../../data/models/stock_model.dart';
import '../../data/models/stock_movement_model.dart';
import '../../data/models/adherent_model.dart';
import '../../services/stock/stock_service.dart';
import '../../services/adherent/adherent_service.dart';

class StockViewModel extends ChangeNotifier {
  final StockService _stockService = StockService();
  final AdherentService _adherentService = AdherentService();
  
  List<StockActuelModel> _stocks = [];
  List<StockDepotModel> _depots = [];
  List<StockMovementModel> _mouvements = [];
  List<AdherentModel> _adherents = [];
  
  StockActuelModel? _selectedStock;
  AdherentModel? _selectedAdherent;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filtres
  String? _filterQualite;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterTypeMouvement;
  String _searchQuery = '';
  
  // Getters
  List<StockActuelModel> get stocks => _stocks;
  List<StockDepotModel> get depots => _depots;
  List<StockMovementModel> get mouvements => _mouvements;
  List<AdherentModel> get adherents => _adherents;
  StockActuelModel? get selectedStock => _selectedStock;
  AdherentModel? get selectedAdherent => _selectedAdherent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get filterQualite => _filterQualite;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String? get filterTypeMouvement => _filterTypeMouvement;
  String get searchQuery => _searchQuery;
  
  // Stocks filtrés
  List<StockActuelModel> get filteredStocks {
    List<StockActuelModel> filtered = _stocks;
    
    // Recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) =>
        s.adherentCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.adherentNom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.adherentPrenom.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }
  
  // Mouvements filtrés
  List<StockMovementModel> get filteredMouvements {
    List<StockMovementModel> filtered = _mouvements;
    
    if (_filterTypeMouvement != null && _filterTypeMouvement!.isNotEmpty) {
      filtered = filtered.where((m) => m.type == _filterTypeMouvement).toList();
    }
    
    if (_filterStartDate != null) {
      filtered = filtered.where((m) => 
        m.dateMouvement.isAfter(_filterStartDate!) || 
        m.dateMouvement.isAtSameMomentAs(_filterStartDate!)
      ).toList();
    }
    
    if (_filterEndDate != null) {
      filtered = filtered.where((m) => 
        m.dateMouvement.isBefore(_filterEndDate!) || 
        m.dateMouvement.isAtSameMomentAs(_filterEndDate!)
      ).toList();
    }
    
    return filtered;
  }
  
  // Statistiques globales
  double get totalStockGlobal {
    return _stocks.fold(0.0, (sum, stock) => sum + stock.stockTotal);
  }
  
  int get nombreAdherentsAvecStock {
    return _stocks.where((s) => s.stockTotal > 0).length;
  }
  
  int get nombreAdherentsStockCritique {
    return _stocks.where((s) => s.status == StockStatus.critique || s.status == StockStatus.vide).length;
  }
  
  /// Calculer le stock total
  double get totalStock {
    return _stocks.fold(0.0, (sum, stock) => sum + stock.stockTotal);
  }
  
  /// Charger tous les stocks (alias pour compatibilité)
  Future<void> loadStock() async {
    await loadStocks();
  }
  
  /// Charger tous les stocks
  Future<void> loadStocks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _stocks = await _stockService.getAllStocksActuels();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des stocks: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Charger les adhérents
  Future<void> loadAdherents() async {
    try {
      _adherents = await _adherentService.getAllAdherents();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des adhérents: ${e.toString()}';
      notifyListeners();
    }
  }
  
  /// Charger les dépôts d'un adhérent
  Future<void> loadDepotsByAdherent(int adherentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _depots = await _stockService.getDepotsByAdherent(adherentId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des dépôts: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Charger l'historique des mouvements
  Future<void> loadMouvements({
    int? adherentId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _mouvements = await _stockService.getMouvements(
        adherentId: adherentId,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des mouvements: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Créer un dépôt
  Future<bool> createDepot({
    required int adherentId,
    double? quantite, // Pour compatibilité avec l'ancien code
    required double stockBrut,
    double? poidsSac,
    double? poidsDechets,
    double? autres,
    required double poidsNet,
    double? prixUnitaire,
    required DateTime dateDepot,
    String? qualite,
    double? humidite,
    double? densiteArbresAssocies,
    String? photoPath,
    String? observations,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _stockService.createDepot(
        adherentId: adherentId,
        stockBrut: stockBrut,
        poidsSac: poidsSac,
        poidsDechets: poidsDechets,
        autres: autres,
        poidsNet: poidsNet,
        prixUnitaire: prixUnitaire,
        dateDepot: dateDepot,
        qualite: qualite,
        humidite: humidite,
        densiteArbresAssocies: densiteArbresAssocies,
        photoPath: photoPath,
        observations: observations,
        createdBy: createdBy,
      );
      
      // Recharger les stocks
      await loadStocks();
      await loadDepotsByAdherent(adherentId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création du dépôt: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Créer un ajustement
  Future<bool> createAjustement({
    required int adherentId,
    required double quantite,
    required String raison,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _stockService.createAjustement(
        adherentId: adherentId,
        quantite: quantite,
        raison: raison,
        createdBy: createdBy,
      );
      
      // Recharger les stocks
      await loadStocks();
      await loadMouvements(adherentId: adherentId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajustement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Sélectionner un stock
  void selectStock(StockActuelModel? stock) {
    _selectedStock = stock;
    if (stock != null) {
      loadDepotsByAdherent(stock.adherentId);
      loadMouvements(adherentId: stock.adherentId);
    }
    notifyListeners();
  }
  
  /// Sélectionner un adhérent
  void selectAdherent(AdherentModel? adherent) {
    _selectedAdherent = adherent;
    if (adherent != null) {
      loadDepotsByAdherent(adherent.id!);
      loadMouvements(adherentId: adherent.id);
    }
    notifyListeners();
  }
  
  /// Définir les filtres
  void setFilterQualite(String? qualite) {
    _filterQualite = qualite;
    notifyListeners();
  }
  
  void setFilterDates(DateTime? startDate, DateTime? endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    notifyListeners();
  }
  
  void setFilterTypeMouvement(String? type) {
    _filterTypeMouvement = type;
    notifyListeners();
  }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  /// Réinitialiser les filtres
  void resetFilters() {
    _filterQualite = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _filterTypeMouvement = null;
    _searchQuery = '';
    notifyListeners();
  }
  
  /// Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

