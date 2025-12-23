import 'package:flutter/foundation.dart';
import '../../data/models/adherent_model.dart';
import '../../data/models/adherent_historique_model.dart';
import '../../services/adherent/adherent_service.dart';

class AdherentViewModel extends ChangeNotifier {
  final AdherentService _adherentService = AdherentService();
  
  List<AdherentModel> _adherents = [];
  AdherentModel? _selectedAdherent;
  List<AdherentHistoriqueModel> _historique = [];
  List<Map<String, dynamic>> _depots = [];
  List<Map<String, dynamic>> _ventes = [];
  List<Map<String, dynamic>> _recettes = [];
  List<String> _villages = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filtres
  bool? _filterActive;
  String? _filterVillage;
  String _searchQuery = '';

  // Getters
  List<AdherentModel> get adherents => _adherents;
  AdherentModel? get selectedAdherent => _selectedAdherent;
  List<AdherentHistoriqueModel> get historique => _historique;
  List<Map<String, dynamic>> get depots => _depots;
  List<Map<String, dynamic>> get ventes => _ventes;
  List<Map<String, dynamic>> get recettes => _recettes;
  List<String> get villages => _villages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool? get filterActive => _filterActive;
  String? get filterVillage => _filterVillage;
  String get searchQuery => _searchQuery;

  // Adhérents filtrés
  List<AdherentModel> get filteredAdherents {
    List<AdherentModel> filtered = _adherents;

    // Filtre par statut
    if (_filterActive != null) {
      filtered = filtered.where((a) => a.isActive == _filterActive).toList();
    }

    // Filtre par village
    if (_filterVillage != null && _filterVillage!.isNotEmpty) {
      filtered = filtered.where((a) => a.village == _filterVillage).toList();
    }

    // Recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        return a.code.toLowerCase().contains(query) ||
               a.nom.toLowerCase().contains(query) ||
               a.prenom.toLowerCase().contains(query) ||
               (a.telephone?.toLowerCase().contains(query) ?? false) ||
               (a.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  AdherentViewModel() {
    // Ne pas charger immédiatement pour éviter notifyListeners() pendant le build initial
    // Le chargement sera déclenché explicitement par les écrans qui en ont besoin
  }

  /// Charger tous les adhérents
  Future<void> loadAdherents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _adherents = await _adherentService.getAllAdherents(
        isActive: _filterActive,
        village: _filterVillage,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des adhérents: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les villages
  Future<void> loadVillages() async {
    try {
      _villages = await _adherentService.getAllVillages();
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des villages: $e');
    }
  }

  /// Rechercher des adhérents
  Future<void> searchAdherents(String query) async {
    _searchQuery = query;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (query.isEmpty) {
        await loadAdherents();
      } else {
        _adherents = await _adherentService.searchAdherents(query);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors de la recherche: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtrer par statut
  void setFilterActive(bool? active) {
    _filterActive = active;
    loadAdherents();
  }

  /// Filtrer par village
  void setFilterVillage(String? village) {
    _filterVillage = village;
    loadAdherents();
  }

  /// Réinitialiser les filtres
  void resetFilters() {
    _filterActive = null;
    _filterVillage = null;
    _searchQuery = '';
    loadAdherents();
  }

  /// Créer un adhérent
  Future<bool> createAdherent({
    String? code,
    required String nom,
    required String prenom,
    String? telephone,
    String? email,
    String? village,
    String? adresse,
    String? cnib,
    DateTime? dateNaissance,
    required DateTime dateAdhesion,
    required int createdBy,
    // Nouveaux champs - Identification
    String? categorie,
    String? statut,
    String? siteCooperative,
    String? section,
    // Nouveaux champs - Identité personnelle
    String? sexe,
    String? lieuNaissance,
    String? nationalite,
    String? typePiece,
    String? numeroPiece,
    // Nouveaux champs - Situation familiale
    String? nomPere,
    String? nomMere,
    String? conjoint,
    int? nombreEnfants,
    // Nouveaux champs - Indicateurs agricoles
    double? superficieTotaleCultivee,
    int? nombreChamps,
    double? rendementMoyenHa,
    double? tonnageTotalProduit,
    double? tonnageTotalVendu,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adherentService.createAdherent(
        code: code, // Peut être null, sera auto-généré
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email,
        village: village,
        adresse: adresse,
        cnib: cnib,
        dateNaissance: dateNaissance,
        dateAdhesion: dateAdhesion,
        createdBy: createdBy,
        categorie: categorie,
        statut: statut,
        siteCooperative: siteCooperative,
        section: section,
        sexe: sexe,
        lieuNaissance: lieuNaissance,
        nationalite: nationalite,
        typePiece: typePiece,
        numeroPiece: numeroPiece,
        nomPere: nomPere,
        nomMere: nomMere,
        conjoint: conjoint,
        nombreEnfants: nombreEnfants,
        superficieTotaleCultivee: superficieTotaleCultivee,
        nombreChamps: nombreChamps,
        rendementMoyenHa: rendementMoyenHa,
        tonnageTotalProduit: tonnageTotalProduit,
        tonnageTotalVendu: tonnageTotalVendu,
      );
      
      await loadAdherents();
      await loadVillages();
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

  /// Mettre à jour un adhérent
  Future<bool> updateAdherent({
    required int id,
    String? code,
    String? nom,
    String? prenom,
    String? telephone,
    String? email,
    String? village,
    String? adresse,
    String? cnib,
    DateTime? dateNaissance,
    DateTime? dateAdhesion,
    required int updatedBy,
    // Nouveaux champs - Identification
    String? categorie,
    String? statut,
    String? siteCooperative,
    String? section,
    // Nouveaux champs - Identité personnelle
    String? sexe,
    String? lieuNaissance,
    String? nationalite,
    String? typePiece,
    String? numeroPiece,
    // Nouveaux champs - Situation familiale
    String? nomPere,
    String? nomMere,
    String? conjoint,
    int? nombreEnfants,
    // Nouveaux champs - Indicateurs agricoles
    double? superficieTotaleCultivee,
    int? nombreChamps,
    double? rendementMoyenHa,
    double? tonnageTotalProduit,
    double? tonnageTotalVendu,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adherentService.updateAdherent(
        id: id,
        code: code,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email,
        village: village,
        adresse: adresse,
        cnib: cnib,
        dateNaissance: dateNaissance,
        dateAdhesion: dateAdhesion,
        updatedBy: updatedBy,
        categorie: categorie,
        statut: statut,
        siteCooperative: siteCooperative,
        section: section,
        sexe: sexe,
        lieuNaissance: lieuNaissance,
        nationalite: nationalite,
        typePiece: typePiece,
        numeroPiece: numeroPiece,
        nomPere: nomPere,
        nomMere: nomMere,
        conjoint: conjoint,
        nombreEnfants: nombreEnfants,
        superficieTotaleCultivee: superficieTotaleCultivee,
        nombreChamps: nombreChamps,
        rendementMoyenHa: rendementMoyenHa,
        tonnageTotalProduit: tonnageTotalProduit,
        tonnageTotalVendu: tonnageTotalVendu,
      );
      
      await loadAdherents();
      if (_selectedAdherent?.id == id) {
        await loadAdherentDetails(id);
      }
      await loadVillages();
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

  /// Activer/Désactiver un adhérent
  Future<bool> toggleAdherentStatus(int id, bool isActive, int updatedBy) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adherentService.toggleAdherentStatus(id, isActive, updatedBy);
      await loadAdherents();
      if (_selectedAdherent?.id == id) {
        await loadAdherentDetails(id);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors du changement de statut: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les détails d'un adhérent
  Future<void> loadAdherentDetails(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedAdherent = await _adherentService.getAdherentById(id);
      
      if (_selectedAdherent != null) {
        // Charger l'historique
        _historique = await _adherentService.getHistorique(adherentId: id);
        
        // Charger les dépôts
        _depots = await _adherentService.getDepots(id);
        
        // Charger les ventes
        _ventes = await _adherentService.getVentes(id);
        
        // Charger les recettes
        _recettes = await _adherentService.getRecettes(id);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des détails: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sélectionner un adhérent
  void selectAdherent(AdherentModel? adherent) {
    _selectedAdherent = adherent;
    if (adherent != null) {
      loadAdherentDetails(adherent.id!);
    } else {
      _historique = [];
      _depots = [];
      _ventes = [];
      _recettes = [];
    }
    notifyListeners();
  }

  /// Générer le prochain code adhérent disponible
  Future<String> generateNextCode() async {
    try {
      return await _adherentService.generateNextCode();
    } catch (e) {
      _errorMessage = 'Erreur lors de la génération du code: ${e.toString()}';
      notifyListeners();
      // En cas d'erreur, retourner un code par défaut
      return 'ADH001';
    }
  }

  /// Vérifier si un code existe
  Future<bool> codeExists(String code, {int? excludeId}) async {
    try {
      return await _adherentService.codeExists(code, excludeId: excludeId);
    } catch (e) {
      return false;
    }
  }

  /// Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Calculer les indicateurs expert pour l'adhérent sélectionné
  Future<Map<String, double>> calculateExpertIndicators(int adherentId) async {
    return await _adherentService.calculateExpertIndicators(adherentId);
  }
}
