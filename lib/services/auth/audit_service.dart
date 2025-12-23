import 'package:sqflite_common/sqlite_api.dart';
import '../database/db_initializer.dart';
import '../../data/models/audit_log_model.dart';

class AuditService {
  /// Logger une action
  Future<void> logAction({
    int? userId,
    required String action,
    String? entityType,
    int? entityId,
    String? details,
    String? ipAddress,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final log = AuditLogModel(
        userId: userId,
        action: action,
        entityType: entityType,
        entityId: entityId,
        details: details,
        ipAddress: ipAddress,
        createdAt: DateTime.now(),
      );

      await db.insert('audit_logs', log.toMap());
    } catch (e) {
      // Ne pas faire échouer l'application si l'audit échoue
      print('Erreur lors de l\'enregistrement de l\'audit: $e');
    }
  }

  /// Récupérer les logs d'audit
  Future<List<AuditLogModel>> getAuditLogs({
    int? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        where += ' AND user_id = ?';
        whereArgs.add(userId);
      }

      if (action != null) {
        where += ' AND action = ?';
        whereArgs.add(action);
      }

      if (startDate != null) {
        where += ' AND created_at >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND created_at <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.query(
        'audit_logs',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return result.map((map) => AuditLogModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des logs: $e');
    }
  }

  /// Récupérer les logs de connexion récents
  Future<List<AuditLogModel>> getRecentLogins({int limit = 50}) async {
    return getAuditLogs(
      action: AuditActions.login,
      limit: limit,
    );
  }
}
