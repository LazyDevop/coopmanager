import 'package:flutter/foundation.dart';
import '../../services/auth/user_service.dart';
import '../../data/models/user_model.dart';

class UserViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _includeInactive = false;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get includeInactive => _includeInactive;

  /// Charger tous les utilisateurs
  Future<void> loadUsers({bool? includeInactive}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _includeInactive = includeInactive ?? _includeInactive;
      _users = await _userService.getAllUsers(includeInactive: _includeInactive);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      if (kDebugMode) {
        print('⚠️ $_errorMessage');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Créer un nouvel utilisateur
  Future<bool> createUser({
    required String username,
    required String password,
    required String nom,
    required String prenom,
    required String role,
    String? email,
    String? phone,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _userService.createUser(
        username: username,
        password: password,
        nom: nom,
        prenom: prenom,
        role: role,
        email: email,
        phone: phone,
        createdBy: createdBy,
      );
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création: ${e.toString()}';
      if (kDebugMode) {
        print('⚠️ $_errorMessage');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mettre à jour un utilisateur
  Future<bool> updateUser({
    required int id,
    String? nom,
    String? prenom,
    String? role,
    String? email,
    String? phone,
    required int updatedBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _userService.updateUser(
        id: id,
        nom: nom,
        prenom: prenom,
        role: role,
        email: email,
        phone: phone,
        updatedBy: updatedBy,
      );
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: ${e.toString()}';
      if (kDebugMode) {
        print('⚠️ $_errorMessage');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprimer un utilisateur
  Future<bool> deleteUser(int id, int deletedBy) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _userService.deleteUser(id, deletedBy);
      if (success) {
        await loadUsers();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: ${e.toString()}';
      if (kDebugMode) {
        print('⚠️ $_errorMessage');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Activer/Désactiver un utilisateur
  Future<bool> toggleUserStatus(int id, bool isActive, int updatedBy) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _userService.toggleUserStatus(id, isActive, updatedBy);
      if (success) {
        await loadUsers();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors du changement de statut: ${e.toString()}';
      if (kDebugMode) {
        print('⚠️ $_errorMessage');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rechercher des utilisateurs
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      await loadUsers();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userService.searchUsers(query);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur lors de la recherche: ${e.toString()}';
      if (kDebugMode) {
        print('⚠️ $_errorMessage');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtenir les rôles disponibles
  List<String> getAvailableRoles() {
    return _userService.getAvailableRoles();
  }

  /// Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

