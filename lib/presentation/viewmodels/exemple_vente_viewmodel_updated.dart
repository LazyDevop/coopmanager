/// EXEMPLE : ViewModel mis à jour pour utiliser le Repository
/// 
/// Ce fichier montre comment migrer un ViewModel existant pour utiliser
/// les nouveaux repositories avec gestion offline intégrée.
/// 
/// Pour utiliser ce code, remplacez les méthodes dans votre VenteViewModel existant.

import 'package:flutter/foundation.dart';
import '../../data/models/vente_model.dart';
import '../../data/repositories/vente_repository.dart';
import '../../services/integration/error_handler.dart';

/// Exemple de ViewModel mis à jour avec Repository
class VenteViewModelUpdated extends ChangeNotifier {
  final VenteRepository _repository = VenteRepository();

  List<VenteModel> _ventes = [];
  VenteModel? _selectedVente;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<VenteModel> get ventes => _ventes;
  VenteModel? get selectedVente => _selectedVente;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charger toutes les ventes (AVANT)
  /// 
  /// AVANT : Utilisation directe du service
  /// 
  /// Future<void> loadVentes() async {
  ///   final venteService = VenteService();
  ///   _ventes = await venteService.getAllVentes();
  ///   notifyListeners();
  /// }

  /// Charger toutes les ventes (APRÈS)
  /// 
  /// APRÈS : Utilisation du repository avec gestion d'erreurs
  Future<void> loadVentes({
    int? adherentId,
    int? clientId,
    int? campagneId,
    String? type,
    String? statut,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (adherentId != null) queryParams['adherent_id'] = adherentId;
      if (clientId != null) queryParams['client_id'] = clientId;
      if (campagneId != null) queryParams['campagne_id'] = campagneId;
      if (type != null) queryParams['type'] = type;
      if (statut != null) queryParams['statut'] = statut;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      _ventes = await _repository.getAll(
        '/api/v1/ventes',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      _errorMessage = ErrorHandler.getUserFriendlyMessage(error.code);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Créer une vente individuelle (AVANT)
  /// 
  /// AVANT : Utilisation directe du service
  /// 
  /// Future<bool> createVenteIndividuelle({...}) async {
  ///   try {
  ///     final venteService = VenteService();
  ///     await venteService.createVenteIndividuelle(...);
  ///     await loadVentes();
  ///     return true;
  ///   } catch (e) {
  ///     _errorMessage = e.toString();
  ///     return false;
  ///   }
  /// }

  /// Créer une vente individuelle (APRÈS)
  /// 
  /// APRÈS : Utilisation du repository avec support offline automatique
  Future<bool> createVenteIndividuelle({
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
      // Le repository gère automatiquement :
      // - L'appel API si en ligne
      // - L'ajout à la queue offline si hors ligne
      // - La gestion d'erreurs normalisée
      final vente = await _repository.createVenteIndividuelle(
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

      // Ajouter à la liste locale
      _ventes.add(vente);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      _errorMessage = ErrorHandler.getUserFriendlyMessage(
        error.code,
        defaultMessage: error.message,
      );
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Simuler une vente (calculs backend)
  Future<Map<String, dynamic>?> simulateVente({
    required int clientId,
    required int campagneId,
    int? adherentId,
    required double quantiteTotal,
    required double prixUnitaire,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.simulateVente(
        clientId: clientId,
        campagneId: campagneId,
        adherentId: adherentId,
        quantiteTotal: quantiteTotal,
        prixUnitaire: prixUnitaire,
      );

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      final error = ErrorHandler.handleException(e);
      _errorMessage = ErrorHandler.getUserFriendlyMessage(error.code);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Obtenir les statistiques
  Future<Map<String, dynamic>> getStatistiques({
    DateTime? startDate,
    DateTime? endDate,
    int? adherentId,
    int? clientId,
    int? campagneId,
  }) async {
    try {
      return await _repository.getStatistiques(
        startDate: startDate,
        endDate: endDate,
        adherentId: adherentId,
        clientId: clientId,
        campagneId: campagneId,
      );
    } catch (e) {
      return {};
    }
  }

  /// Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

