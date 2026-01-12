import '../database/db_initializer.dart';
import '../../data/models/user_model.dart';
import '../../data/models/audit_log_model.dart';
import 'auth_service.dart';
import 'audit_service.dart';
import '../../config/app_config.dart';

class UserService {
  final AuthService _authService = AuthService();
  final AuditService _auditService = AuditService();

  /// Créer un nouvel utilisateur
  Future<UserModel> createUser({
    required String username,
    required String password,
    required String nom,
    required String prenom,
    required String role,
    String? email,
    String? phone,
    required int createdBy,
  }) async {
    try {
      // Vérifier si l'utilisateur existe déjà
      if (await _authService.userExists(username)) {
        throw Exception('Ce nom d\'utilisateur existe déjà');
      }

      // Valider le rôle
      if (!_isValidRole(role)) {
        throw Exception('Rôle invalide');
      }

      final db = await DatabaseInitializer.database;
      
      final user = UserModel(
        username: username,
        passwordHash: _authService.hashPassword(password),
        nom: nom,
        prenom: prenom,
        role: role,
        email: email,
        phone: phone,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final id = await db.insert('users', user.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: AuditActions.createUser,
        entityType: 'users',
        entityId: id,
        details: 'Création de l\'utilisateur: $username',
      );

      return user.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  /// Mettre à jour un utilisateur
  Future<UserModel> updateUser({
    required int id,
    String? nom,
    String? prenom,
    String? role,
    String? email,
    String? phone,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer l'utilisateur actuel
      final currentResult = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (currentResult.isEmpty) {
        throw Exception('Utilisateur non trouvé');
      }

      final currentUser = UserModel.fromMap(currentResult.first);
      
      // Vérifier le rôle si modifié
      if (role != null && !_isValidRole(role)) {
        throw Exception('Rôle invalide');
      }

      // Préparer les données à mettre à jour
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nom != null) updateData['nom'] = nom;
      if (prenom != null) updateData['prenom'] = prenom;
      if (role != null) updateData['role'] = role;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;

      await db.update(
        'users',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );

      // Logger le changement de rôle si applicable
      if (role != null && role != currentUser.role) {
        await _auditService.logAction(
          userId: updatedBy,
          action: AuditActions.changeRole,
          entityType: 'users',
          entityId: id,
          details: 'Changement de rôle: ${currentUser.role} -> $role',
        );
      }

      await _auditService.logAction(
        userId: updatedBy,
        action: AuditActions.updateUser,
        entityType: 'users',
        entityId: id,
        details: 'Mise à jour de l\'utilisateur',
      );

      // Récupérer l'utilisateur mis à jour
      final updatedResult = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return UserModel.fromMap(updatedResult.first);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Supprimer un utilisateur (soft delete)
  Future<bool> deleteUser(int id, int deletedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer l'utilisateur
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return false;

      final user = UserModel.fromMap(result.first);

      // Ne pas permettre la suppression de l'utilisateur actuel
      if (id == deletedBy) {
        throw Exception('Vous ne pouvez pas supprimer votre propre compte');
      }

      // Désactiver l'utilisateur au lieu de le supprimer
      await db.update(
        'users',
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: deletedBy,
        action: AuditActions.deleteUser,
        entityType: 'users',
        entityId: id,
        details: 'Suppression de l\'utilisateur: ${user.username}',
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Activer/Désactiver un utilisateur
  Future<bool> toggleUserStatus(int id, bool isActive, int updatedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      await db.update(
        'users',
        {
          'is_active': isActive ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: isActive ? AuditActions.activateUser : AuditActions.deactivateUser,
        entityType: 'users',
        entityId: id,
        details: isActive ? 'Activation de l\'utilisateur' : 'Désactivation de l\'utilisateur',
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors du changement de statut: $e');
    }
  }

  /// Récupérer tous les utilisateurs
  Future<List<UserModel>> getAllUsers({bool includeInactive = false}) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String where = includeInactive ? '1=1' : 'is_active = ?';
      List<dynamic> whereArgs = includeInactive ? [] : [1];

      final result = await db.query(
        'users',
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'created_at DESC',
      );

      return result.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs: $e');
    }
  }

  /// Récupérer un utilisateur par ID
  Future<UserModel?> getUserById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return UserModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  /// Rechercher des utilisateurs
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'users',
        where: '''
          (username LIKE ? OR nom LIKE ? OR prenom LIKE ? OR email LIKE ?)
          AND is_active = ?
        ''',
        whereArgs: [
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          1,
        ],
        orderBy: 'nom, prenom',
      );

      return result.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Vérifier si un rôle est valide
  bool _isValidRole(String role) {
    return [
      AppConfig.roleSuperAdmin,
      AppConfig.roleAdmin,
      AppConfig.roleComptable,
      AppConfig.roleCaissier,
      AppConfig.roleMagasinier,
      // Rôles obsolètes pour compatibilité
      AppConfig.roleGestionnaireStock,
      AppConfig.roleConsultation,
      AppConfig.roleResponsableSocial,
    ].contains(role);
  }

  /// Obtenir tous les rôles disponibles
  List<String> getAvailableRoles() {
    return [
      AppConfig.roleSuperAdmin,
      AppConfig.roleAdmin,
      AppConfig.roleComptable,
      AppConfig.roleCaissier,
      AppConfig.roleMagasinier,
    ];
  }
  
  /// Obtenir tous les rôles disponibles pour un utilisateur donné
  /// (un Admin ne peut pas créer de SuperAdmin)
  List<String> getAvailableRolesForUser(UserModel? currentUser) {
    final allRoles = getAvailableRoles();
    
    // Seul un SuperAdmin peut créer un SuperAdmin
    if (currentUser == null || currentUser.role != AppConfig.roleSuperAdmin) {
      return allRoles.where((role) => role != AppConfig.roleSuperAdmin).toList();
    }
    
    return allRoles;
  }
}
