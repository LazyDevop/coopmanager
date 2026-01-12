/// Service pour la gestion des permissions et rôles
import 'package:sqflite_common/sqlite_api.dart';
import '../../data/models/permissions/role_model.dart';
import '../../data/models/permissions/permission_model.dart';
import '../../data/models/permissions/ui_view_model.dart';
import '../../data/models/permissions/role_ui_view_model.dart';
import '../database/db_initializer.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Cache des permissions de l'utilisateur connecté
  Map<String, bool> _permissionsCache = {};
  Map<String, RoleUIViewModel> _uiViewsCache = {};
  Map<String, String> _uiViewCodeToIdCache = {}; // Cache code -> id pour les vues UI
  List<RoleModel> _userRoles = [];
  bool _isLoaded = false;

  /// Charger les permissions d'un utilisateur
  Future<void> loadUserPermissions(int userId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer les rôles de l'utilisateur
      final userRolesResult = await db.query(
        'user_roles',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      if (userRolesResult.isEmpty) {
        // Si aucun rôle n'est assigné, utiliser le rôle depuis users.role
        final userResult = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
          limit: 1,
        );
        
        if (userResult.isNotEmpty) {
          final roleCode = userResult.first['role'] as String;
          final roleResult = await db.query(
            'roles',
            where: 'code = ?',
            whereArgs: [roleCode],
            limit: 1,
          );
          
          if (roleResult.isNotEmpty) {
            _userRoles = [RoleModel.fromMap(roleResult.first)];
            // Créer l'association user_roles si elle n'existe pas
            await _createUserRoleAssociation(db, userId, roleResult.first['id'] as String);
          }
        }
      } else {
        // Récupérer les rôles complets
        final roleIds = userRolesResult.map((r) => r['role_id'] as String).toList();
        final rolesResult = await db.query(
          'roles',
          where: 'id IN (${roleIds.map((_) => '?').join(',')})',
          whereArgs: roleIds,
        );
        _userRoles = rolesResult.map((r) => RoleModel.fromMap(r)).toList();
      }

      // Récupérer les permissions de tous les rôles de l'utilisateur
      final roleIds = _userRoles.map((r) => r.id).toList();
      if (roleIds.isEmpty) {
        _permissionsCache = {};
        _uiViewsCache = {};
        _isLoaded = true;
        return;
      }

      final permissionsResult = await db.query(
        'role_permissions',
        where: 'role_id IN (${roleIds.map((_) => '?').join(',')}) AND granted = 1',
        whereArgs: roleIds,
      );

      final permissionIds = permissionsResult.map((p) => p['permission_id'] as String).toSet().toList();
      
      if (permissionIds.isNotEmpty) {
        final permDetails = await db.query(
          'permissions',
          where: 'id IN (${permissionIds.map((_) => '?').join(',')}) AND is_active = 1',
          whereArgs: permissionIds,
        );

        _permissionsCache = {};
        for (final perm in permDetails) {
          _permissionsCache[perm['code'] as String] = true;
        }
      } else {
        _permissionsCache = {};
      }

      // Récupérer les vues UI autorisées
      final uiViewsResult = await db.query(
        'role_ui_views',
        where: 'role_id IN (${roleIds.map((_) => '?').join(',')})',
        whereArgs: roleIds,
      );

      _uiViewsCache = {};
      _uiViewCodeToIdCache = {};
      
      // Charger toutes les vues UI pour le cache code -> id
      final allViews = await db.query('ui_views', where: 'is_active = 1');
      for (final view in allViews) {
        _uiViewCodeToIdCache[view['code'] as String] = view['id'] as String;
      }
      
      for (final ruv in uiViewsResult) {
        final viewId = ruv['ui_view_id'] as String;
        if (!_uiViewsCache.containsKey(viewId) || ruv['can_read'] == 1) {
          _uiViewsCache[viewId] = RoleUIViewModel.fromMap(ruv);
        } else {
          // Fusionner les droits (OR logique)
          final existing = _uiViewsCache[viewId]!;
          _uiViewsCache[viewId] = RoleUIViewModel(
            id: existing.id,
            roleId: existing.roleId,
            uiViewId: existing.uiViewId,
            canRead: existing.canRead || (ruv['can_read'] as int) == 1,
            canWrite: existing.canWrite || (ruv['can_write'] as int) == 1,
            canDelete: existing.canDelete || (ruv['can_delete'] as int) == 1,
            createdAt: existing.createdAt,
          );
        }
      }

      _isLoaded = true;
    } catch (e) {
      print('⚠️ Erreur lors du chargement des permissions: $e');
      _permissionsCache = {};
      _uiViewsCache = {};
      _isLoaded = true;
    }
  }

  /// Créer l'association user_roles si elle n'existe pas
  Future<void> _createUserRoleAssociation(Database db, int userId, String roleId) async {
    try {
      await db.insert('user_roles', {
        'id': 'ur-$userId-$roleId',
        'user_id': userId,
        'role_id': roleId,
        'is_primary': 1,
        'granted_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      print('⚠️ Erreur lors de la création de l\'association user_roles: $e');
    }
  }

  /// Vérifier si l'utilisateur a une permission
  bool hasPermission(String permissionCode) {
    if (!_isLoaded) return false;
    return _permissionsCache[permissionCode] ?? false;
  }

  /// Vérifier si l'utilisateur peut accéder à une vue UI
  bool canAccess(String uiViewCode) {
    if (!_isLoaded) return false;
    
    // Récupérer la vue UI par son code
    // Note: On devrait charger les vues UI en cache aussi, mais pour simplifier,
    // on vérifie directement dans la base si nécessaire
    return _uiViewsCache.values.any((ruv) {
      // On vérifiera le code dans canAccessViewByCode
      return ruv.canRead;
    });
  }

  /// Vérifier si l'utilisateur peut accéder à une vue UI par son code
  Future<bool> canAccessViewByCode(String uiViewCode) async {
    if (!_isLoaded) return false;
    
    // Utiliser le cache code -> id
    final viewId = _uiViewCodeToIdCache[uiViewCode];
    if (viewId == null) return false;
    
    return _uiViewsCache.containsKey(viewId) && _uiViewsCache[viewId]!.canRead;
  }

  /// Vérifier si l'utilisateur peut écrire dans une vue UI
  Future<bool> canWrite(String uiViewCode) async {
    if (!_isLoaded) return false;
    
    // Utiliser le cache code -> id
    final viewId = _uiViewCodeToIdCache[uiViewCode];
    if (viewId == null) return false;
    
    return _uiViewsCache.containsKey(viewId) && _uiViewsCache[viewId]!.canWrite;
  }

  /// Vérifier si l'utilisateur peut supprimer dans une vue UI
  Future<bool> canDelete(String uiViewCode) async {
    if (!_isLoaded) return false;
    
    // Utiliser le cache code -> id
    final viewId = _uiViewCodeToIdCache[uiViewCode];
    if (viewId == null) return false;
    
    return _uiViewsCache.containsKey(viewId) && _uiViewsCache[viewId]!.canDelete;
  }

  /// Obtenir toutes les vues UI accessibles par l'utilisateur
  Future<List<UIViewModel>> getAccessibleViews() async {
    if (!_isLoaded) return [];
    
    try {
      final db = await DatabaseInitializer.database;
      final viewIds = _uiViewsCache.keys.toList();
      
      if (viewIds.isEmpty) return [];
      
      final viewsResult = await db.query(
        'ui_views',
        where: 'id IN (${viewIds.map((_) => '?').join(',')}) AND is_active = 1',
        whereArgs: viewIds,
        orderBy: 'display_order ASC',
      );
      
      return viewsResult.map((v) => UIViewModel.fromMap(v)).toList();
    } catch (e) {
      print('⚠️ Erreur lors de la récupération des vues accessibles: $e');
      return [];
    }
  }

  /// Obtenir les rôles de l'utilisateur
  List<RoleModel> getUserRoles() {
    return _userRoles;
  }

  /// Vérifier si l'utilisateur a un rôle spécifique
  bool hasRole(String roleCode) {
    return _userRoles.any((r) => r.code == roleCode && r.isActive);
  }

  /// Réinitialiser le cache (déconnexion)
  void clearCache() {
    _permissionsCache = {};
    _uiViewsCache = {};
    _uiViewCodeToIdCache = {};
    _userRoles = [];
    _isLoaded = false;
  }

  /// Vérifier si les permissions sont chargées
  bool get isLoaded => _isLoaded;
}

