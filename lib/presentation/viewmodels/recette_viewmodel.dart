import 'package:flutter/foundation.dart';
import '../../data/models/recette_model.dart';
import '../../services/recette/recette_service.dart';

class RecetteViewModel extends ChangeNotifier {
  final RecetteService _recetteService = RecetteService();
  
  List<RecetteModel> _recettes = [];
  List<RecetteSummaryModel> _recettesSummary = [];
  
  RecetteModel? _selectedRecette;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filtres
  int? _filterAdherentId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _searchQuery = '';
  
  // Getters
  List<RecetteModel> get recettes => _recettes;
  List<RecetteSummaryModel> get recettesSummary => _recettesSummary;
  RecetteModel? get selectedRecette => _selectedRecette;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get filterAdherentId => _filterAdherentId;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String get searchQuery => _searchQuery;
  
  // Recettes filtrées
  List<RecetteModel> get filteredRecettes {
    List<RecetteModel> filtered = _recettes;
    
    if (_searchQuery.isNotEmpty) {
      // La recherche se fait sur les résumés, pas directement sur les recettes
      // Cette fonctionnalité sera implémentée dans l'écran
    }
    
    return filtered;
  }
  
  // Statistiques globales
  double get totalMontantBrut {
    return _recettes.fold(0.0, (sum, recette) => sum + recette.montantBrut);
  }
  
  double get totalCommission {
    return _recettes.fold(0.0, (sum, recette) => sum + recette.commissionAmount);
  }
  
  double get totalMontantNet {
    return _recettes.fold(0.0, (sum, recette) => sum + recette.montantNet);
  }
  
  /// Alias pour compatibilité
  double get totalRecettes => totalMontantNet;
  
  /// Charger toutes les recettes
  Future<void> loadRecettes({
    int? adherentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _recettes = await _recetteService.getRecettes(
        adherentId: adherentId,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des recettes: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Charger le résumé des recettes par adhérent
  Future<void> loadRecettesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _recettesSummary = await _recetteService.getRecettesSummary(
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement du résumé: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Charger les recettes d'un adhérent
  Future<void> loadRecettesByAdherent(int adherentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _recettes = await _recetteService.getRecettesByAdherent(adherentId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des recettes: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Sélectionner une recette
  void selectRecette(RecetteModel? recette) {
    _selectedRecette = recette;
    notifyListeners();
  }
  
  /// Définir les filtres
  void setFilterAdherent(int? adherentId) {
    _filterAdherentId = adherentId;
    notifyListeners();
  }
  
  void setFilterDates(DateTime? startDate, DateTime? endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    notifyListeners();
  }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  /// Réinitialiser les filtres
  void resetFilters() {
    _filterAdherentId = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _searchQuery = '';
    notifyListeners();
  }
  
  /// Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Obtenir le taux de commission actuel
  Future<double> getCommissionRate() async {
    return await _recetteService.getCommissionRate();
  }
}

