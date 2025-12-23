import 'package:flutter/foundation.dart';
import '../../data/models/facture_model.dart';
import '../../data/models/adherent_model.dart';
import '../../data/models/vente_model.dart';
import '../../data/models/recette_model.dart';
import '../../data/models/vente_detail_model.dart';
import '../../services/facture/facture_service.dart';
import '../../services/facture/facture_pdf_service.dart';
import '../../services/adherent/adherent_service.dart';
import '../../services/vente/vente_service.dart';
import '../../services/recette/recette_service.dart';

class FactureViewModel extends ChangeNotifier {
  final FactureService _factureService = FactureService();
  final FacturePdfService _pdfService = FacturePdfService();
  final AdherentService _adherentService = AdherentService();
  final VenteService _venteService = VenteService();
  final RecetteService _recetteService = RecetteService();

  List<FactureModel> _factures = [];
  FactureModel? _selectedFacture;
  AdherentModel? _selectedAdherent;
  VenteModel? _selectedVente;
  RecetteModel? _selectedRecette;
  List<RecetteModel> _selectedRecettes = [];
  List<VenteDetailModel> _venteDetails = [];
  
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
  List<FactureModel> get factures => _factures;
  FactureModel? get selectedFacture => _selectedFacture;
  AdherentModel? get selectedAdherent => _selectedAdherent;
  VenteModel? get selectedVente => _selectedVente;
  RecetteModel? get selectedRecette => _selectedRecette;
  List<RecetteModel> get selectedRecettes => _selectedRecettes;
  List<VenteDetailModel> get venteDetails => _venteDetails;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get filterAdherentId => _filterAdherentId;
  String? get filterType => _filterType;
  String? get filterStatut => _filterStatut;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String get searchQuery => _searchQuery;

  // Factures filtrées
  List<FactureModel> get filteredFactures {
    List<FactureModel> filtered = _factures;

    // Recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((f) {
        return f.numero.toLowerCase().contains(query) ||
               (f.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  FactureViewModel() {
    // Ne pas charger immédiatement pour éviter notifyListeners() pendant le build initial
    // Le chargement sera déclenché explicitement par les écrans qui en ont besoin
  }

  /// Charger toutes les factures
  Future<void> loadFactures() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _factures = await _factureService.getAllFactures(
        adherentId: _filterAdherentId,
        type: _filterType,
        statut: _filterStatut,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des factures: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rechercher des factures
  Future<void> searchFactures(String query) async {
    _searchQuery = query;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (query.isEmpty) {
        await loadFactures();
      } else {
        _factures = await _factureService.searchFactures(query);
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
    loadFactures();
  }

  /// Filtrer par type
  void setFilterType(String? type) {
    _filterType = type;
    loadFactures();
  }

  /// Filtrer par statut
  void setFilterStatut(String? statut) {
    _filterStatut = statut;
    loadFactures();
  }

  /// Filtrer par dates
  void setFilterDates(DateTime? startDate, DateTime? endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    loadFactures();
  }

  /// Réinitialiser les filtres
  void resetFilters() {
    _filterAdherentId = null;
    _filterType = null;
    _filterStatut = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _searchQuery = '';
    loadFactures();
  }

  /// Générer une facture depuis une vente
  Future<String?> generateFactureFromVente({
    required int adherentId,
    required int venteId,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Récupérer la vente
      final vente = await _venteService.getVenteById(venteId);
      if (vente == null) {
        throw Exception('Vente non trouvée');
      }

      // Récupérer l'adhérent
      final adherent = await _adherentService.getAdherentById(adherentId);
      if (adherent == null) {
        throw Exception('Adhérent non trouvé');
      }

      // Récupérer les détails si vente groupée
      List<VenteDetailModel>? details;
      if (vente.isGroupee) {
        details = await _venteService.getVenteDetails(venteId);
      }

      // Créer la facture
      final facture = await _factureService.createFactureFromVente(
        adherentId: adherentId,
        venteId: venteId,
        montantTotal: vente.montantTotal,
        dateVente: vente.dateVente,
        createdBy: createdBy,
      );

      // Générer le PDF
      final pdfPath = await _pdfService.generateFactureVente(
        facture: facture,
        adherent: adherent,
        vente: vente,
        venteDetails: details,
      );

      // Mettre à jour la facture avec le chemin PDF
      await _factureService.updateFacture(
        id: facture.id!,
        pdfPath: pdfPath,
        updatedBy: createdBy,
      );

      await loadFactures();
      _isLoading = false;
      notifyListeners();
      return pdfPath;
    } catch (e) {
      _errorMessage = 'Erreur lors de la génération: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Générer une facture depuis une recette
  Future<String?> generateFactureFromRecette({
    required int adherentId,
    required int recetteId,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Récupérer la recette
      final recette = await _recetteService.getRecetteById(recetteId);
      if (recette == null) {
        throw Exception('Recette non trouvée');
      }

      // Récupérer l'adhérent
      final adherent = await _adherentService.getAdherentById(adherentId);
      if (adherent == null) {
        throw Exception('Adhérent non trouvé');
      }

      // Créer la facture
      final facture = await _factureService.createFactureFromRecette(
        adherentId: adherentId,
        recetteId: recetteId,
        montantNet: recette.montantNet,
        dateRecette: recette.dateRecette,
        createdBy: createdBy,
      );

      // Générer le PDF
      final pdfPath = await _pdfService.generateFactureRecette(
        facture: facture,
        adherent: adherent,
        recette: recette,
      );

      // Mettre à jour la facture avec le chemin PDF
      await _factureService.updateFacture(
        id: facture.id!,
        pdfPath: pdfPath,
        updatedBy: createdBy,
      );

      await loadFactures();
      _isLoading = false;
      notifyListeners();
      return pdfPath;
    } catch (e) {
      _errorMessage = 'Erreur lors de la génération: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Générer un bordereau de recettes
  Future<String?> generateBordereauRecettes({
    required int adherentId,
    required List<int> recetteIds,
    DateTime? startDate,
    DateTime? endDate,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Récupérer l'adhérent
      final adherent = await _adherentService.getAdherentById(adherentId);
      if (adherent == null) {
        throw Exception('Adhérent non trouvé');
      }

      // Récupérer les recettes
      final recettes = <RecetteModel>[];
      for (final recetteId in recetteIds) {
        final recette = await _recetteService.getRecetteById(recetteId);
        if (recette != null) {
          recettes.add(recette);
        }
      }

      if (recettes.isEmpty) {
        throw Exception('Aucune recette trouvée');
      }

      final totalNet = recettes.fold<double>(0.0, (sum, r) => sum + r.montantNet);
      final dateFacture = startDate ?? recettes.first.dateRecette;

      // Créer la facture
      final facture = await _factureService.createFacture(
        adherentId: adherentId,
        type: 'bordereau',
        montantTotal: totalNet,
        dateFacture: dateFacture,
        createdBy: createdBy,
      );

      // Générer le PDF
      final pdfPath = await _pdfService.generateBordereauRecettes(
        facture: facture,
        adherent: adherent,
        recettes: recettes,
      );

      // Mettre à jour la facture avec le chemin PDF
      await _factureService.updateFacture(
        id: facture.id!,
        pdfPath: pdfPath,
        updatedBy: createdBy,
      );

      await loadFactures();
      _isLoading = false;
      notifyListeners();
      return pdfPath;
    } catch (e) {
      _errorMessage = 'Erreur lors de la génération: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Charger les détails d'une facture
  Future<void> loadFactureDetails(int factureId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedFacture = await _factureService.getFactureById(factureId);
      
      if (_selectedFacture != null) {
        // Charger l'adhérent
        _selectedAdherent = await _adherentService.getAdherentById(_selectedFacture!.adherentId);
        
        // Charger les données selon le type
        if (_selectedFacture!.isPourVente) {
          final venteId = _extractVenteIdFromNotes(_selectedFacture!.notes);
          if (venteId != null) {
            _selectedVente = await _venteService.getVenteById(venteId);
            if (_selectedVente != null && _selectedVente!.isGroupee) {
              _venteDetails = await _venteService.getVenteDetails(venteId);
            }
          }
        } else if (_selectedFacture!.isPourRecette) {
          final recetteId = _extractRecetteIdFromNotes(_selectedFacture!.notes);
          if (recetteId != null) {
            _selectedRecette = await _recetteService.getRecetteById(recetteId);
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des détails: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sélectionner une facture
  void selectFacture(FactureModel? facture) {
    _selectedFacture = facture;
    if (facture != null) {
      loadFactureDetails(facture.id!);
    } else {
      _selectedAdherent = null;
      _selectedVente = null;
      _selectedRecette = null;
      _selectedRecettes = [];
      _venteDetails = [];
    }
    notifyListeners();
  }

  /// Marquer une facture comme payée
  Future<bool> marquerPayee(int factureId, int updatedBy) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _factureService.marquerPayee(factureId, updatedBy);
      await loadFactures();
      if (_selectedFacture?.id == factureId) {
        await loadFactureDetails(factureId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Annuler une facture
  Future<bool> annulerFacture(int factureId, int updatedBy, String? raison) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _factureService.annulerFacture(factureId, updatedBy, raison);
      await loadFactures();
      if (_selectedFacture?.id == factureId) {
        await loadFactureDetails(factureId);
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

  /// Obtenir les statistiques
  Future<Map<String, dynamic>> getStatistiques({
    DateTime? startDate,
    DateTime? endDate,
    int? adherentId,
  }) async {
    try {
      return await _factureService.getStatistiques(
        startDate: startDate,
        endDate: endDate,
        adherentId: adherentId,
      );
    } catch (e) {
      return {
        'nombreFactures': 0,
        'montantTotal': 0.0,
        'nombrePayees': 0,
        'montantPaye': 0.0,
      };
    }
  }

  /// Extraire l'ID de vente depuis les notes
  int? _extractVenteIdFromNotes(String? notes) {
    if (notes == null) return null;
    final match = RegExp(r'Vente #(\d+)').firstMatch(notes);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Extraire l'ID de recette depuis les notes
  int? _extractRecetteIdFromNotes(String? notes) {
    if (notes == null) return null;
    final match = RegExp(r'Recette #(\d+)').firstMatch(notes);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
