import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../services/auth/auth_service.dart';
import '../providers/permission_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  PermissionProvider? _permissionProvider;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  /// Définir le PermissionProvider (injection de dépendance)
  void setPermissionProvider(PermissionProvider provider) {
    _permissionProvider = provider;
  }

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
        
        // Charger les permissions de l'utilisateur
        if (_permissionProvider != null && user.id != null) {
          await _permissionProvider!.loadUserPermissions(user.id!);
        }
        
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
    _isLoading = false;
    
    if (_currentUser != null) {
      final username = _currentUser!.username;
      await _authService.logout(_currentUser!.id, username);
    }
    
    // Réinitialiser les permissions
    if (_permissionProvider != null) {
      _permissionProvider!.clearPermissions();
    }
    
    // Réinitialiser complètement l'état
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _isLoading = false;
    
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

