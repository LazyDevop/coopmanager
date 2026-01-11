/// Provider pour la gestion des permissions (State Management)
import 'package:flutter/foundation.dart';
import '../../services/permissions/permission_service.dart';
import '../../data/models/permissions/ui_view_model.dart';
import '../../data/models/permissions/role_model.dart';

class PermissionProvider extends ChangeNotifier {
  final PermissionService _permissionService = PermissionService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<UIViewModel> _accessibleViews = [];
  List<RoleModel> _userRoles = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UIViewModel> get accessibleViews => _accessibleViews;
  List<RoleModel> get userRoles => _userRoles;
  bool get isLoaded => _permissionService.isLoaded;

  /// Charger les permissions d'un utilisateur
  Future<void> loadUserPermissions(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _permissionService.loadUserPermissions(userId);
      _userRoles = _permissionService.getUserRoles();
      _accessibleViews = await _permissionService.getAccessibleViews();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des permissions: ${e.toString()}';
      print('⚠️ $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vérifier si l'utilisateur a une permission
  bool hasPermission(String permissionCode) {
    return _permissionService.hasPermission(permissionCode);
  }

  /// Vérifier si l'utilisateur peut accéder à une vue UI
  Future<bool> canAccess(String uiViewCode) async {
    return await _permissionService.canAccessViewByCode(uiViewCode);
  }

  /// Vérifier si l'utilisateur peut écrire dans une vue UI
  Future<bool> canWrite(String uiViewCode) async {
    return await _permissionService.canWrite(uiViewCode);
  }

  /// Vérifier si l'utilisateur peut supprimer dans une vue UI
  Future<bool> canDelete(String uiViewCode) async {
    return await _permissionService.canDelete(uiViewCode);
  }

  /// Vérifier si l'utilisateur a un rôle spécifique
  bool hasRole(String roleCode) {
    return _permissionService.hasRole(roleCode);
  }

  /// Réinitialiser les permissions (déconnexion)
  void clearPermissions() {
    _permissionService.clearCache();
    _accessibleViews = [];
    _userRoles = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Rafraîchir les permissions
  Future<void> refreshPermissions(int userId) async {
    await loadUserPermissions(userId);
  }
}

