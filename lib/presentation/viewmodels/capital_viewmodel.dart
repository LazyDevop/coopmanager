import 'package:flutter/foundation.dart';
import '../../data/models/capital_social_model.dart';
import '../../services/capital/capital_service.dart';
import '../../services/capital/actionnaire_service.dart';
import '../../services/capital/souscription_service.dart';
import '../../services/capital/liberation_service.dart';

class CapitalViewModel extends ChangeNotifier {
  final CapitalService _capitalService = CapitalService();
  final ActionnaireService _actionnaireService = ActionnaireService();
  final SouscriptionService _souscriptionService = SouscriptionService();
  final LiberationService _liberationService = LiberationService();
  
  List<ActionnaireModel> _actionnaires = [];
  ActionnaireModel? _selectedActionnaire;
  List<SouscriptionCapitalModel> _souscriptions = [];
  List<LiberationCapitalModel> _liberations = [];
  List<MouvementCapitalModel> _mouvements = [];
  
  Map<String, dynamic>? _statistiquesCapital;
  double _valeurPartActuelle = 0.0;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filtres
  String? _filterStatut;
  String _searchQuery = '';
  
  // Getters
  List<ActionnaireModel> get actionnaires => _actionnaires;
  ActionnaireModel? get selectedActionnaire => _selectedActionnaire;
  List<SouscriptionCapitalModel> get souscriptions => _souscriptions;
  List<LiberationCapitalModel> get liberations => _liberations;
  List<MouvementCapitalModel> get mouvements => _mouvements;
  Map<String, dynamic>? get statistiquesCapital => _statistiquesCapital;
  double get valeurPartActuelle => _valeurPartActuelle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Actionnaires filtrés
  List<ActionnaireModel> get filteredActionnaires {
    List<ActionnaireModel> filtered = _actionnaires;
    
    if (_filterStatut != null) {
      filtered = filtered.where((a) => a.statut == _filterStatut).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        return a.codeActionnaire.toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
  }
  
  /// Charger tous les actionnaires
  Future<void> loadActionnaires({String? statut}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _actionnaires = await _actionnaireService.getAllActionnaires(
        statut: statut ?? _filterStatut,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Charger un actionnaire par ID avec détails
  Future<void> loadActionnaireById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _selectedActionnaire = await _actionnaireService.getActionnaireById(id);
      
      if (_selectedActionnaire != null) {
        _souscriptions = await _souscriptionService.getSouscriptionsByActionnaire(id);
        _mouvements = await _liberationService.getMouvementsByActionnaire(id);
        
        // Charger les libérations pour chaque souscription
        _liberations = [];
        for (final souscription in _souscriptions) {
          final libs = await _liberationService.getLiberationsBySouscription(souscription.id!);
          _liberations.addAll(libs);
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Charger les statistiques du capital social
  Future<void> loadStatistiquesCapital() async {
    try {
      _statistiquesCapital = await _capitalService.getStatistiquesCapital();
      _valeurPartActuelle = await _capitalService.getValeurPartActuelle();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des statistiques: ${e.toString()}';
      notifyListeners();
    }
  }
  
  /// Créer un actionnaire
  Future<bool> createActionnaire({
    required int adherentId,
    required String codeActionnaire,
    required DateTime dateEntree,
    bool droitsVote = true,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _actionnaireService.createActionnaire(
        adherentId: adherentId,
        codeActionnaire: codeActionnaire,
        dateEntree: dateEntree,
        droitsVote: droitsVote,
        createdBy: createdBy,
      );
      
      await loadActionnaires();
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
  
  /// Créer une souscription
  Future<bool> createSouscription({
    required int actionnaireId,
    required int nombreParts,
    DateTime? dateSouscription,
    int? campagneId,
    String? notes,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _souscriptionService.createSouscription(
        actionnaireId: actionnaireId,
        nombreParts: nombreParts,
        dateSouscription: dateSouscription,
        campagneId: campagneId,
        notes: notes,
        createdBy: createdBy,
      );
      
      await loadActionnaireById(actionnaireId);
      await loadStatistiquesCapital();
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
  
  /// Créer une libération
  Future<bool> createLiberation({
    required int souscriptionId,
    required double montantLibere,
    required String modePaiement,
    String? reference,
    DateTime? datePaiement,
    String? notes,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final liberation = await _liberationService.createLiberation(
        souscriptionId: souscriptionId,
        montantLibere: montantLibere,
        modePaiement: modePaiement,
        reference: reference,
        datePaiement: datePaiement,
        notes: notes,
        createdBy: createdBy,
      );
      
      // Recharger les données de l'actionnaire
      final souscription = await _souscriptionService.getSouscriptionById(souscriptionId);
      if (souscription != null) {
        await loadActionnaireById(souscription.actionnaireId);
      }
      
      await loadStatistiquesCapital();
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
  
  /// Définir la valeur d'une part
  Future<bool> definirValeurPart({
    required double valeurPart,
    required DateTime dateEffet,
    required int createdBy,
  }) async {
    try {
      await _capitalService.definirValeurPart(
        valeurPart: valeurPart,
        dateEffet: dateEffet,
        createdBy: createdBy,
      );
      await loadStatistiquesCapital();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Rechercher des actionnaires
  void searchActionnaires(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  /// Définir le filtre de statut
  void setFilterStatut(String? statut) {
    _filterStatut = statut;
    loadActionnaires();
  }
  
  /// Réinitialiser les filtres
  void resetFilters() {
    _filterStatut = null;
    _searchQuery = '';
    loadActionnaires();
  }
  
  /// Effacer le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

