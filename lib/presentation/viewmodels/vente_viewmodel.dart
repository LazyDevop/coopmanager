import 'package:flutter/foundation.dart';
import '../../data/models/vente_model.dart';
import '../../data/models/vente_detail_model.dart';
import '../../data/models/adherent_model.dart';
import '../../services/vente/vente_service.dart';
import '../../services/adherent/adherent_service.dart';
import '../../services/stock/stock_service.dart';

class VenteViewModel extends ChangeNotifier {
  final VenteService _venteService = VenteService();
  final AdherentService _adherentService = AdherentService();
  final StockService _stockService = StockService();

  List<VenteModel> _ventes = [];
  VenteModel? _selectedVente;
  List<VenteDetailModel> _venteDetails = [];
  List<AdherentModel> _adherents = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filtres
  int? _filterAdherentId;
  String? _filterType;
  String? _filterStatut;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _searchQuery = '';

  // Getters
  List<VenteModel> get ventes => _ventes;
  VenteModel? get selectedVente => _selectedVente;
  List<VenteDetailModel> get venteDetails => _venteDetails;
  List<AdherentModel> get adherents => _adherents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get filterAdherentId => _filterAdherentId;
  String? get filterType => _filterType;
  String? get filterStatut => _filterStatut;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String get searchQuery => _searchQuery;

  // Ventes filtrées
  List<VenteModel> get filteredVentes {
    List<VenteModel> filtered = _ventes;

    // Recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((v) {
        return (v.acheteur?.toLowerCase().contains(query) ?? false) ||
               (v.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  VenteViewModel() {
    // Ne pas charger immédiatement pour éviter notifyListeners() pendant le build initial
    // Le chargement sera déclenché explicitement par les écrans qui en ont besoin
  }

  /// Charger toutes les ventes
  Future<void> loadVentes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ventes = await _venteService.getAllVentes(
        adherentId: _filterAdherentId,
        type: _filterType,
        statut: _filterStatut,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des ventes: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les adhérents
  Future<void> loadAdherents() async {
    try {
      _adherents = await _adherentService.getAllAdherents(isActive: true);
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des adhérents: $e');
    }
  }

  /// Rechercher des ventes
  Future<void> searchVentes(String query) async {
    _searchQuery = query;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (query.isEmpty) {
        await loadVentes();
      } else {
        _ventes = await _venteService.searchVentes(query);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors de la recherche: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtrer par adhérent
  void setFilterAdherent(int? adherentId) {
    _filterAdherentId = adherentId;
    loadVentes();
  }

  /// Filtrer par type
  void setFilterType(String? type) {
    _filterType = type;
    loadVentes();
  }

  /// Filtrer par statut
  void setFilterStatut(String? statut) {
    _filterStatut = statut;
    loadVentes();
  }

  /// Filtrer par dates
  void setFilterDates(DateTime? startDate, DateTime? endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    loadVentes();
  }

  /// Réinitialiser les filtres
  void resetFilters() {
    _filterAdherentId = null;
    _filterType = null;
    _filterStatut = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _searchQuery = '';
    loadVentes();
  }

  /// Créer une vente individuelle
  Future<bool> createVenteIndividuelle({
    required int adherentId,
    required double quantite,
    required double prixUnitaire,
    String? acheteur,
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _venteService.createVenteIndividuelle(
        adherentId: adherentId,
        quantite: quantite,
        prixUnitaire: prixUnitaire,
        acheteur: acheteur,
        modePaiement: modePaiement,
        dateVente: dateVente,
        notes: notes,
        createdBy: createdBy,
      );

      await loadVentes();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Créer une vente groupée
  Future<bool> createVenteGroupee({
    required List<VenteDetailModel> details,
    required double prixUnitaire,
    String? acheteur,
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _venteService.createVenteGroupee(
        details: details,
        prixUnitaire: prixUnitaire,
        acheteur: acheteur,
        modePaiement: modePaiement,
        dateVente: dateVente,
        notes: notes,
        createdBy: createdBy,
      );

      await loadVentes();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Annuler une vente
  Future<bool> annulerVente(int venteId, int annulePar, String? raison) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _venteService.annulerVente(venteId, annulePar, raison);
      await loadVentes();
      if (_selectedVente?.id == venteId) {
        await loadVenteDetails(venteId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'annulation: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les détails d'une vente
  Future<void> loadVenteDetails(int venteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedVente = await _venteService.getVenteById(venteId);
      
      if (_selectedVente != null && _selectedVente!.isGroupee) {
        _venteDetails = await _venteService.getVenteDetails(venteId);
      } else {
        _venteDetails = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des détails: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sélectionner une vente
  void selectVente(VenteModel? vente) {
    _selectedVente = vente;
    if (vente != null) {
      loadVenteDetails(vente.id!);
    } else {
      _venteDetails = [];
    }
    notifyListeners();
  }

  /// Obtenir le stock disponible d'un adhérent
  Future<double> getStockDisponible(int adherentId) async {
    try {
      return await _stockService.getStockActuel(adherentId);
    } catch (e) {
      return 0.0;
    }
  }

  /// Obtenir les statistiques
  Future<Map<String, dynamic>> getStatistiques({
    DateTime? startDate,
    DateTime? endDate,
    int? adherentId,
  }) async {
    try {
      return await _venteService.getStatistiques(
        startDate: startDate,
        endDate: endDate,
        adherentId: adherentId,
      );
    } catch (e) {
      return {
        'nombreVentes': 0,
        'quantiteTotale': 0.0,
        'montantTotal': 0.0,
      };
    }
  }

  /// Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
