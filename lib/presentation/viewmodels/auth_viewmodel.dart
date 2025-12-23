import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../services/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  AuthViewModel() {
    loadSession();
  }

  /// Charger la session depuis SharedPreferences
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      
      if (userJson != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromMap(userMap);
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors du chargement de la session: $e');
    }
  }

  /// Sauvegarder la session dans SharedPreferences
  Future<void> _saveSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toMap());
      await prefs.setString('current_user', userJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde de la session: $e');
    }
  }

  /// Supprimer la session
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    } catch (e) {
      print('Erreur lors de la suppression de la session: $e');
    }
  }

  /// Connexion
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(username, password);
      
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        await _saveSession(user);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la connexion: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    if (_currentUser != null) {
      final username = _currentUser!.username;
      await _authService.logout(_currentUser!.id, username);
    }
    
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    await _clearSession();
    notifyListeners();
  }

  /// Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Mettre à jour l'utilisateur actuel
  void updateCurrentUser(UserModel user) {
    _currentUser = user;
    _saveSession(user);
    notifyListeners();
  }
}

