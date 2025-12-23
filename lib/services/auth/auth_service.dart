import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sqflite_common/sqlite_api.dart';
import '../database/db_initializer.dart';
import '../../data/models/user_model.dart';
import '../../data/models/audit_log_model.dart';
import 'audit_service.dart';
import '../notification/notification_service.dart';

class AuthService {
  final AuditService _auditService = AuditService();
  final NotificationService _notificationService = NotificationService();
  static const String _saltPrefix = 'CoopManager2024';

  /// Générer un salt unique
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  /// Hasher un mot de passe avec SHA-256 et salt
  /// Format: salt:hash pour permettre la vérification
  String hashPassword(String password) {
    final salt = _generateSalt();
    final saltedPassword = _saltPrefix + password + salt;
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  /// Vérifier un mot de passe
  bool verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) {
        // Ancien format sans salt (pour compatibilité)
        return hashPassword(password) == storedHash;
      }
      
      final salt = parts[0];
      final storedHashValue = parts[1];
      final saltedPassword = _saltPrefix + password + salt;
      final bytes = utf8.encode(saltedPassword);
      final digest = sha256.convert(bytes);
      
      return digest.toString() == storedHashValue;
    } catch (e) {
      return false;
    }
  }

  /// Authentifier un utilisateur
  Future<UserModel?> login(String username, String password) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Rechercher l'utilisateur
      final result = await db.query(
        'users',
        where: 'username = ? AND is_active = ?',
        whereArgs: [username, 1],
        limit: 1,
      );

      if (result.isEmpty) {
        await _auditService.logAction(
          action: AuditActions.login,
          details: 'Tentative de connexion échouée: utilisateur inexistant ($username)',
        );
        return null;
      }

      final userMap = result.first;
      final user = UserModel.fromMap(userMap);

      // Vérifier le mot de passe
      if (!verifyPassword(password, user.passwordHash)) {
        await _auditService.logAction(
          action: AuditActions.login,
          details: 'Tentative de connexion échouée: mot de passe incorrect ($username)',
        );
        return null;
      }

      // Mettre à jour le dernier login
      await db.update(
        'users',
        {
          'dernier_login': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );

      // Logger la connexion réussie
      await _auditService.logAction(
        userId: user.id,
        action: AuditActions.login,
        details: 'Connexion réussie',
      );

      // Notification : Connexion utilisateur
      await _notificationService.notifyUserLogin(
        username: username,
        userId: user.id!,
      );

      return user.copyWith(dernierLogin: DateTime.now());
    } catch (e) {
      throw Exception('Erreur lors de l\'authentification: $e');
    }
  }

  /// Déconnexion
  Future<void> logout(int? userId, String? username) async {
    if (userId != null) {
      await _auditService.logAction(
        userId: userId,
        action: AuditActions.logout,
        details: 'Déconnexion',
      );

      // Notification : Déconnexion utilisateur
      if (username != null) {
        await _notificationService.notifyUserLogout(
          username: username,
          userId: userId,
        );
      }
    }
  }

  /// Vérifier si un utilisateur existe
  Future<bool> userExists(String username) async {
    final db = await DatabaseInitializer.database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Changer le mot de passe
  Future<bool> changePassword(int userId, String oldPassword, String newPassword) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer l'utilisateur
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result.isEmpty) return false;

      final user = UserModel.fromMap(result.first);

      // Vérifier l'ancien mot de passe
      if (!verifyPassword(oldPassword, user.passwordHash)) {
        return false;
      }

      // Mettre à jour le mot de passe
      await db.update(
        'users',
        {
          'password_hash': hashPassword(newPassword),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      await _auditService.logAction(
        userId: userId,
        action: AuditActions.resetPassword,
        details: 'Changement de mot de passe',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Réinitialiser le mot de passe (admin uniquement)
  Future<bool> resetPassword(int userId, String newPassword, int adminUserId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      await db.update(
        'users',
        {
          'password_hash': hashPassword(newPassword),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      await _auditService.logAction(
        userId: adminUserId,
        action: AuditActions.resetPassword,
        entityType: 'users',
        entityId: userId,
        details: 'Réinitialisation du mot de passe par administrateur',
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
