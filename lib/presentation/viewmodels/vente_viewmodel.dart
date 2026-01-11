import 'package:flutter/foundation.dart';
import '../../data/models/vente_model.dart';
import '../../data/models/vente_detail_model.dart';
import '../../data/models/vente_adherent_model.dart';
import '../../data/models/adherent_model.dart';
import '../../data/models/client_model.dart';
import '../../data/models/parametres_cooperative_model.dart';
// V2: Nouveaux modèles
import '../../data/models/lot_vente_model.dart';
import '../../data/models/lot_vente_detail_model.dart';
import '../../data/models/simulation_vente_model.dart';
import '../../data/models/validation_vente_model.dart';
import '../../data/models/creance_client_model.dart';
import '../../data/models/fonds_social_model.dart';
import '../../services/vente/vente_service.dart';
import '../../services/adherent/adherent_service.dart';
import '../../services/stock/stock_service.dart';
import '../../services/client/client_service.dart';
import '../../services/parametres/parametres_service.dart';
import '../../services/database/db_initializer.dart';
// V2: Nouveaux services
import '../../services/vente/simulation_vente_service.dart';
import '../../services/vente/lot_vente_service.dart';
import '../../services/vente/creance_client_service.dart';
import '../../services/vente/validation_workflow_service.dart';
import '../../services/vente/fonds_social_service.dart';

class VenteViewModel extends ChangeNotifier {
  final VenteService _venteService = VenteService();
  final AdherentService _adherentService = AdherentService();
  final StockService _stockService = StockService();
  final ClientService _clientService = ClientService();
  final ParametresService _parametresService = ParametresService();
  // V2: Nouveaux services
  final SimulationVenteService _simulationVenteService = SimulationVenteService();
  final LotVenteService _lotVenteService = LotVenteService();
  final CreanceClientService _creanceClientService = CreanceClientService();
  final ValidationWorkflowService _validationWorkflowService = ValidationWorkflowService();
  final FondsSocialService _fondsSocialService = FondsSocialService();

  List<VenteModel> _ventes = [];
  VenteModel? _selectedVente;
  List<VenteDetailModel> _venteDetails = [];
  List<AdherentModel> _adherents = [];
  List<ClientModel> _clients = [];
  List<CampagneModel> _campagnes = [];
  CampagneModel? _campagneActive;
  ParametresCooperativeModel? _parametres;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filtres V1
  int? _filterAdherentId;
  int? _filterClientId;
  int? _filterCampagneId;
  String? _filterType;
  String? _filterStatut;
  String? _filterStatutPaiement; // 'payee' ou 'non_payee'
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _searchQuery = '';
  
  // Calculs temps réel pour formulaire V1
  double? _prixUnitaireSaisi;
  double? _quantiteSaisie;
  double? _montantBrutCalcule;
  double? _montantCommissionCalcule;
  double? _montantNetCalcule;
  String? _prixValidationMessage;
  bool _prixHorsSeuil = false;

  // Getters
  List<VenteModel> get ventes => _ventes;
  VenteModel? get selectedVente => _selectedVente;
  List<VenteDetailModel> get venteDetails => _venteDetails;
  List<AdherentModel> get adherents => _adherents;
  List<ClientModel> get clients => _clients;
  List<CampagneModel> get campagnes => _campagnes;
  CampagneModel? get campagneActive => _campagneActive;
  ParametresCooperativeModel? get parametres => _parametres;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get filterAdherentId => _filterAdherentId;
  int? get filterClientId => _filterClientId;
  int? get filterCampagneId => _filterCampagneId;
  String? get filterType => _filterType;
  String? get filterStatut => _filterStatut;
  String? get filterStatutPaiement => _filterStatutPaiement;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String get searchQuery => _searchQuery;
  
  // Calculs temps réel
  double? get montantBrutCalcule => _montantBrutCalcule;
  double? get montantCommissionCalcule => _montantCommissionCalcule;
  double? get montantNetCalcule => _montantNetCalcule;
  String? get prixValidationMessage => _prixValidationMessage;
  bool get prixHorsSeuil => _prixHorsSeuil;

  // Ventes filtrées
  List<VenteModel> get filteredVentes {
    List<VenteModel> filtered = _ventes;

    // Filtre par client (V1)
    if (_filterClientId != null) {
      filtered = filtered.where((v) => v.clientId == _filterClientId).toList();
    }

    // Filtre par campagne (V1)
    if (_filterCampagneId != null) {
      filtered = filtered.where((v) => v.campagneId == _filterCampagneId).toList();
    }

    // Filtre par statut paiement (V1)
    if (_filterStatutPaiement != null) {
      filtered = filtered.where((v) => v.statutPaiement == _filterStatutPaiement).toList();
    }

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

  /// Charger les clients
  Future<void> loadClients() async {
    try {
      _clients = await _clientService.getClients(statut: ClientModel.statutActif);
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des clients: $e');
    }
  }

  /// Charger les campagnes
  Future<void> loadCampagnes() async {
    try {
      _campagnes = await _parametresService.getAllCampagnes();
      _campagneActive = await _parametresService.getCampagneActive();
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des campagnes: $e');
    }
  }

  /// Charger les paramètres
  Future<void> loadParametres() async {
    try {
      _parametres = await _parametresService.getParametres();
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des paramètres: $e');
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

  /// Filtrer par client (V1)
  void setFilterClient(int? clientId) {
    _filterClientId = clientId;
    loadVentes();
  }

  /// Filtrer par campagne (V1)
  void setFilterCampagne(int? campagneId) {
    _filterCampagneId = campagneId;
    loadVentes();
  }

  /// Filtrer par statut paiement (V1)
  void setFilterStatutPaiement(String? statutPaiement) {
    _filterStatutPaiement = statutPaiement;
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
    _filterClientId = null;
    _filterCampagneId = null;
    _filterType = null;
    _filterStatut = null;
    _filterStatutPaiement = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _searchQuery = '';
    loadVentes();
  }

  /// Créer une vente individuelle
  int? _lastCreatedFactureId;

  int? get lastCreatedFactureId => _lastCreatedFactureId;

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
    _lastCreatedFactureId = null;
    notifyListeners();

    try {
      final vente = await _venteService.createVenteIndividuelle(
        adherentId: adherentId,
        quantite: quantite,
        prixUnitaire: prixUnitaire,
        acheteur: acheteur,
        modePaiement: modePaiement,
        dateVente: dateVente,
        notes: notes,
        createdBy: createdBy,
      );

      // Récupérer l'ID de la facture depuis la base de données
      // Attendre un peu pour que la facture soit créée et le lien mis à jour
      if (vente.id != null) {
        try {
          // Attendre un court délai pour que la facture soit créée
          await Future.delayed(const Duration(milliseconds: 500));
          
          final db = await DatabaseInitializer.database;
          final result = await db.query(
            'ventes',
            columns: ['facture_id'],
            where: 'id = ?',
            whereArgs: [vente.id],
          );
          if (result.isNotEmpty) {
            _lastCreatedFactureId = result.first['facture_id'] as int?;
            print('📄 Facture ID récupérée pour vente #${vente.id}: $_lastCreatedFactureId');
          } else {
            print('⚠️ Aucune facture trouvée pour vente #${vente.id}');
          }
          
          // Si facture_id n'est pas trouvé dans ventes, chercher directement dans factures
          if (_lastCreatedFactureId == null) {
            final factureResult = await db.query(
              'factures',
              columns: ['id'],
              where: 'vente_id = ?',
              whereArgs: [vente.id],
              orderBy: 'created_at DESC',
              limit: 1,
            );
            if (factureResult.isNotEmpty) {
              _lastCreatedFactureId = factureResult.first['id'] as int?;
              print('📄 Facture ID trouvée directement dans factures: $_lastCreatedFactureId');
            }
          }
        } catch (e) {
          print('❌ Erreur lors de la récupération de la facture: $e');
        }
      }

      await loadVentes();
      
      // Notifier les autres ViewModels pour recharger les stocks
      // Le StockViewModel sera notifié via Provider et rechargera automatiquement
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
    _lastCreatedFactureId = null;
    notifyListeners();

    try {
      final vente = await _venteService.createVenteGroupee(
        details: details,
        prixUnitaire: prixUnitaire,
        acheteur: acheteur,
        modePaiement: modePaiement,
        dateVente: dateVente,
        notes: notes,
        createdBy: createdBy,
      );

      // Récupérer l'ID de la facture depuis la base de données
      if (vente.id != null) {
        try {
          // Attendre un court délai pour que la facture soit créée
          await Future.delayed(const Duration(milliseconds: 500));
          
          final db = await DatabaseInitializer.database;
          final result = await db.query(
            'ventes',
            columns: ['facture_id'],
            where: 'id = ?',
            whereArgs: [vente.id],
          );
          if (result.isNotEmpty) {
            _lastCreatedFactureId = result.first['facture_id'] as int?;
            print('📄 Facture ID récupérée pour vente groupée #${vente.id}: $_lastCreatedFactureId');
          }
          
          // Si facture_id n'est pas trouvé dans ventes, chercher directement dans factures
          if (_lastCreatedFactureId == null) {
            final factureResult = await db.query(
              'factures',
              columns: ['id'],
              where: 'vente_id = ?',
              whereArgs: [vente.id],
              orderBy: 'created_at DESC',
              limit: 1,
            );
            if (factureResult.isNotEmpty) {
              _lastCreatedFactureId = factureResult.first['id'] as int?;
              print('📄 Facture ID trouvée directement dans factures pour vente groupée: $_lastCreatedFactureId');
            }
          }
        } catch (e) {
          print('❌ Erreur lors de la récupération de la facture pour vente groupée: $e');
        }
      }

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

  /// Obtenir le stock disponible d'un adhérent par campagne
  Future<double> getStockByCampagne({
    required int adherentId,
    int? campagneId,
  }) async {
    try {
      return await _adherentService.getStockByCampagne(
        adherentId: adherentId,
        campagneId: campagneId,
      );
    } catch (e) {
      return 0.0;
    }
  }

  /// Créer une vente avec répartition automatique
  Future<bool> createVenteWithRepartition({
    required double quantiteTotal,
    required double prixUnitaire,
    required int campagneId,
    String? qualite,
    String? acheteur,
    int? clientId,
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
    List<int>? adherentIdsPrioritaires,
    bool overridePrixValidation = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _venteService.createVenteWithRepartition(
        quantiteTotal: quantiteTotal,
        prixUnitaire: prixUnitaire,
        campagneId: campagneId,
        qualite: qualite,
        acheteur: acheteur,
        clientId: clientId,
        modePaiement: modePaiement,
        dateVente: dateVente,
        notes: notes,
        createdBy: createdBy,
        adherentIdsPrioritaires: adherentIdsPrioritaires,
        overridePrixValidation: overridePrixValidation,
      );

      await loadVentes();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création avec répartition: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Récupérer la répartition d'une vente
  Future<List<VenteAdherentModel>> getRepartitionVente(int venteId) async {
    try {
      return await _venteService.getRepartitionVente(venteId);
    } catch (e) {
      _errorMessage = 'Erreur lors de la récupération de la répartition: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  /// Vérifier si un adhérent peut vendre
  Future<bool> canAdherentSell(int adherentId) async {
    try {
      return await _adherentService.canAdherentSell(adherentId);
    } catch (e) {
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

  // ========== MODULE VENTES V1 ==========

  /// Créer une vente V1 (avec client obligatoire et campagne)
  Future<bool> createVenteV1({
    required int clientId,
    required int campagneId,
    required int adherentId,
    required double quantiteTotal,
    required double prixUnitaire,
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
    bool overridePrixValidation = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _venteService.createVenteV1(
        clientId: clientId,
        campagneId: campagneId,
        adherentId: adherentId,
        quantiteTotal: quantiteTotal,
        prixUnitaire: prixUnitaire,
        modePaiement: modePaiement,
        dateVente: dateVente,
        notes: notes,
        createdBy: createdBy,
        overridePrixValidation: overridePrixValidation,
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

  /// Calculer les montants en temps réel (pour aperçu dans le formulaire)
  Future<void> calculateMontants({
    required double quantite,
    required double prixUnitaire,
  }) async {
    _quantiteSaisie = quantite;
    _prixUnitaireSaisi = prixUnitaire;
    
    // Calculer montant brut
    _montantBrutCalcule = quantite * prixUnitaire;
    
    // Charger les paramètres si nécessaire
    if (_parametres == null) {
      await loadParametres();
    }
    
    // Calculer commission et net
    final commissionRate = _parametres?.commissionRate ?? 0.05;
    _montantCommissionCalcule = _montantBrutCalcule! * commissionRate;
    _montantNetCalcule = _montantBrutCalcule! - _montantCommissionCalcule!;
    
    // Valider le prix
    await _validatePrix(prixUnitaire);
    
    notifyListeners();
  }

  /// Valider le prix par rapport aux seuils
  Future<void> _validatePrix(double prixUnitaire) async {
    try {
      final baremes = await _parametresService.getAllBaremesQualite();
      
      _prixHorsSeuil = false;
      _prixValidationMessage = null;
      
      if (baremes.isEmpty) {
        // Pas de barèmes configurés, prix accepté
        return;
      }
      
      bool prixValide = false;
      
      for (final bareme in baremes) {
        final prixMin = bareme.prixMin;
        final prixMax = bareme.prixMax;
        
        if (prixMin != null && prixUnitaire < prixMin) {
          _prixHorsSeuil = true;
          _prixValidationMessage = 'Prix trop bas: ${prixUnitaire.toStringAsFixed(0)} FCFA/kg < ${prixMin.toStringAsFixed(0)} FCFA/kg (minimum)';
          return;
        }
        
        if (prixMax != null && prixUnitaire > prixMax) {
          _prixHorsSeuil = true;
          _prixValidationMessage = 'Prix trop élevé: ${prixUnitaire.toStringAsFixed(0)} FCFA/kg > ${prixMax.toStringAsFixed(0)} FCFA/kg (maximum)';
          return;
        }
        
        // Si on arrive ici, le prix est dans les seuils pour au moins un barème
        if ((prixMin == null || prixUnitaire >= prixMin) && 
            (prixMax == null || prixUnitaire <= prixMax)) {
          prixValide = true;
        }
      }
      
      if (!prixValide) {
        _prixHorsSeuil = true;
        _prixValidationMessage = 'Prix hors des seuils configurés';
      }
    } catch (e) {
      print('Erreur lors de la validation du prix: $e');
    }
  }

  /// Réinitialiser les calculs
  void resetCalculs() {
    _prixUnitaireSaisi = null;
    _quantiteSaisie = null;
    _montantBrutCalcule = null;
    _montantCommissionCalcule = null;
    _montantNetCalcule = null;
    _prixValidationMessage = null;
    _prixHorsSeuil = false;
    notifyListeners();
  }

  // ========== MODULE VENTES V2 ==========

  // État V2
  List<LotVenteModel> _lotsVente = [];
  LotVenteModel? _selectedLot;
  List<LotVenteDetailModel> _lotDetails = [];
  List<SimulationVenteModel> _simulations = [];
  SimulationVenteModel? _selectedSimulation;
  List<CreanceClientModel> _creances = [];
  List<ValidationVenteModel> _workflowValidations = [];
  List<FondsSocialModel> _contributionsFondsSocial = [];

  // Getters V2
  List<LotVenteModel> get lotsVente => _lotsVente;
  LotVenteModel? get selectedLot => _selectedLot;
  List<LotVenteDetailModel> get lotDetails => _lotDetails;
  List<SimulationVenteModel> get simulations => _simulations;
  SimulationVenteModel? get selectedSimulation => _selectedSimulation;
  List<CreanceClientModel> get creances => _creances;
  List<ValidationVenteModel> get workflowValidations => _workflowValidations;
  List<FondsSocialModel> get contributionsFondsSocial => _contributionsFondsSocial;

  // ========== LOTS DE VENTE V2 ==========

  /// Charger tous les lots
  Future<void> loadLotsVente({int? campagneId, String? statut}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lotsVente = await _lotVenteService.getAllLots(
        campagneId: campagneId,
        statut: statut,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des lots: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Créer un lot par campagne
  Future<bool> createLotParCampagne({
    required int campagneId,
    required double prixUnitairePropose,
    int? clientId,
    String? notes,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _lotVenteService.createLotParCampagne(
        campagneId: campagneId,
        prixUnitairePropose: prixUnitairePropose,
        clientId: clientId,
        notes: notes,
        createdBy: createdBy,
      );
      await loadLotsVente();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création du lot: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Créer un lot par qualité
  Future<bool> createLotParQualite({
    required String qualite,
    int? campagneId,
    required double prixUnitairePropose,
    int? clientId,
    String? notes,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _lotVenteService.createLotParQualite(
        qualite: qualite,
        campagneId: campagneId,
        prixUnitairePropose: prixUnitairePropose,
        clientId: clientId,
        notes: notes,
        createdBy: createdBy,
      );
      await loadLotsVente();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création du lot: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Créer un lot par catégorie producteur
  Future<bool> createLotParCategorie({
    required String categorieProducteur,
    int? campagneId,
    required double prixUnitairePropose,
    int? clientId,
    String? notes,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _lotVenteService.createLotParCategorie(
        categorieProducteur: categorieProducteur,
        campagneId: campagneId,
        prixUnitairePropose: prixUnitairePropose,
        clientId: clientId,
        notes: notes,
        createdBy: createdBy,
      );
      await loadLotsVente();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création du lot: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Exclure un adhérent d'un lot
  Future<bool> exclureAdherentDuLot({
    required int lotId,
    required int adherentId,
    required String raison,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _lotVenteService.exclureAdherentDuLot(
        lotId: lotId,
        adherentId: adherentId,
        raison: raison,
      );
      if (_selectedLot?.id == lotId) {
        await loadLotDetails(lotId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'exclusion: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les détails d'un lot
  Future<void> loadLotDetails(int lotId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedLot = await _lotVenteService.getLotById(lotId);
      if (_selectedLot != null) {
        _lotDetails = await _lotVenteService.getLotDetails(lotId);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des détails: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== SIMULATIONS V2 ==========

  /// Charger toutes les simulations
  Future<void> loadSimulations({int? clientId, int? campagneId, String? statut}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _simulations = await _simulationVenteService.getAllSimulations(
        clientId: clientId,
        campagneId: campagneId,
        statut: statut,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des simulations: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Créer une simulation
  Future<bool> createSimulation({
    int? lotVenteId,
    int? clientId,
    int? campagneId,
    required double quantiteTotal,
    required double prixUnitairePropose,
    double? pourcentageFondsSocial,
    String? notes,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _simulationVenteService.createSimulation(
        lotVenteId: lotVenteId,
        clientId: clientId,
        campagneId: campagneId,
        quantiteTotal: quantiteTotal,
        prixUnitairePropose: prixUnitairePropose,
        pourcentageFondsSocial: pourcentageFondsSocial,
        notes: notes,
        createdBy: createdBy,
      );
      await loadSimulations();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création de la simulation: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger une simulation par ID
  Future<void> loadSimulationById(int simulationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedSimulation = await _simulationVenteService.getSimulationById(simulationId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement de la simulation: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== CRÉANCES CLIENTS V2 ==========

  /// Charger toutes les créances
  Future<void> loadCreances({int? clientId, String? statut}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _creances = await _creanceClientService.getAllCreances(
        clientId: clientId,
        statut: statut,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des créances: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Créer une créance
  Future<bool> createCreance({
    required int venteId,
    required int clientId,
    required double montantTotal,
    required DateTime dateEcheance,
    String? notes,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _creanceClientService.createCreance(
        venteId: venteId,
        clientId: clientId,
        montantTotal: montantTotal,
        dateEcheance: dateEcheance,
        notes: notes,
        createdBy: createdBy,
      );
      await loadCreances();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création de la créance: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Enregistrer un paiement
  Future<bool> enregistrerPaiement({
    required int creanceId,
    required double montantPaye,
    required int userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _creanceClientService.enregistrerPaiement(
        creanceId: creanceId,
        montantPaye: montantPaye,
        userId: userId,
      );
      await loadCreances();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'enregistrement du paiement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== WORKFLOW DE VALIDATION V2 ==========

  /// Charger le workflow d'une vente
  Future<void> loadWorkflowVente(int venteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _workflowValidations = await _validationWorkflowService.getWorkflowVente(venteId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement du workflow: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtenir le workflow d'une vente (pour FutureBuilder)
  Future<List<ValidationVenteModel>> getWorkflowVente(int venteId) async {
    try {
      return await _validationWorkflowService.getWorkflowVente(venteId);
    } catch (e) {
      return [];
    }
  }

  /// Initialiser le workflow pour une vente
  Future<bool> initialiserWorkflow({
    required int venteId,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _validationWorkflowService.initialiserWorkflow(
        venteId: venteId,
        createdBy: createdBy,
      );
      await loadWorkflowVente(venteId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'initialisation du workflow: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== FONDS SOCIAL V2 ==========

  /// Charger toutes les contributions au fonds social
  Future<void> loadContributionsFondsSocial({
    String? source,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contributionsFondsSocial = await _fondsSocialService.getAllContributions(
        source: source,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des contributions: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Créer une contribution au fonds social depuis une vente
  Future<bool> createContributionFondsSocialFromVente({
    required int venteId,
    required double montantVente,
    double? pourcentage,
    double? montantFixe,
    String? notes,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _fondsSocialService.createContributionFromVente(
        venteId: venteId,
        montantVente: montantVente,
        pourcentage: pourcentage,
        montantFixe: montantFixe,
        notes: notes,
        createdBy: createdBy,
      );
      await loadContributionsFondsSocial();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création de la contribution: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
