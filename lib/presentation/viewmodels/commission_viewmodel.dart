/// ViewModel pour la gestion des commissions
import 'package:flutter/foundation.dart';
import '../../data/models/commission_model.dart';
import '../../services/commissions/commission_service.dart';

class CommissionViewModel extends ChangeNotifier {
  final CommissionService _commissionService = CommissionService();

  List<CommissionModel> _commissions = [];
  CommissionModel? _selectedCommission;
  bool _isLoading = false;
  String? _errorMessage;

  List<CommissionModel> get commissions => _commissions;
  CommissionModel? get selectedCommission => _selectedCommission;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charger toutes les commissions
  Future<void> loadCommissions() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _commissions = await _commissionService.getAllCommissions();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors du chargement des commissions: $e';
      notifyListeners();
    }
  }

  /// Charger les commissions actives
  Future<List<CommissionModel>> loadCommissionsActives({DateTime? date}) async {
    try {
      return await _commissionService.getCommissionsActives(date: date);
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des commissions actives: $e';
      notifyListeners();
      return [];
    }
  }

  /// Créer une commission
  Future<bool> createCommission({
    required CommissionModel commission,
    required int userId,
    String? reason,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _commissionService.createCommission(
        commission: commission,
        userId: userId,
        reason: reason,
      );

      await loadCommissions();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors de la création: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mettre à jour une commission
  Future<bool> updateCommission({
    required CommissionModel commission,
    required int userId,
    String? reason,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _commissionService.updateCommission(
        commission: commission,
        userId: userId,
        reason: reason,
      );

      await loadCommissions();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors de la mise à jour: $e';
      notifyListeners();
      return false;
    }
  }

  /// Activer une commission
  Future<bool> activateCommission(int id, int userId, {String? reason}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _commissionService.activateCommission(id, userId, reason: reason);
      await loadCommissions();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors de l\'activation: $e';
      notifyListeners();
      return false;
    }
  }

  /// Désactiver une commission
  Future<bool> deactivateCommission(int id, int userId, {String? reason}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _commissionService.deactivateCommission(id, userId, reason: reason);
      await loadCommissions();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors de la désactivation: $e';
      notifyListeners();
      return false;
    }
  }

  /// Reconduire les commissions expirées
  Future<List<CommissionModel>> reconduireCommissions({
    required int userId,
    String? reason,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final reconduites = await _commissionService.reconduireCommissionsExpirees(
        userId: userId,
        reason: reason,
      );

      await loadCommissions();
      
      _isLoading = false;
      notifyListeners();
      return reconduites;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors de la reconduction: $e';
      notifyListeners();
      return [];
    }
  }

  /// Sélectionner une commission
  void selectCommission(CommissionModel? commission) {
    _selectedCommission = commission;
    notifyListeners();
  }

  /// Effacer l'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}


