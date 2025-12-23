import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../data/models/aide_sociale_model.dart';
import '../../services/database/db_initializer.dart';
import '../../config/app_config.dart';
import '../auth/audit_service.dart';

/// Service pour la gestion du module social
class SocialService {
  final AuditService _auditService = AuditService();

  /// Créer une aide sociale
  Future<AideSocialeModel> createAideSociale({
    required int adherentId,
    required String typeAide,
    required double montant,
    required DateTime dateAide,
    required String description,
    String? notes,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    final aideSociale = AideSocialeModel(
      adherentId: adherentId,
      typeAide: typeAide,
      montant: montant,
      dateAide: dateAide,
      description: description,
      statut: 'en_attente',
      notes: notes,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    final id = await db.insert('aides_sociales', aideSociale.toMap());
    
    // Audit
    await _auditService.logAction(
      userId: createdBy,
      action: 'create_aide_sociale',
      entityType: 'aide_sociale',
      entityId: id,
      details: 'Création aide sociale: $typeAide - $montant FCFA',
    );

    return aideSociale.copyWith(id: id);
  }

  /// Approuver une aide sociale
  Future<AideSocialeModel> approuverAideSociale({
    required int aideSocialeId,
    required int approuvePar,
    String? notes,
  }) async {
    final db = await DatabaseInitializer.database;
    
    await db.update(
      'aides_sociales',
      {
        'statut': 'approuve',
        'approuve_par': approuvePar,
        'date_approbation': DateTime.now().toIso8601String(),
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [aideSocialeId],
    );
    
    // Audit
    await _auditService.logAction(
      userId: approuvePar,
      action: 'approuve_aide_sociale',
      entityType: 'aide_sociale',
      entityId: aideSocialeId,
      details: 'Approbation aide sociale ID: $aideSocialeId',
    );
    
    return (await getAideSocialeById(aideSocialeId))!;
  }

  /// Refuser une aide sociale
  Future<AideSocialeModel> refuserAideSociale({
    required int aideSocialeId,
    required int refusePar,
    String? notes,
  }) async {
    final db = await DatabaseInitializer.database;
    
    await db.update(
      'aides_sociales',
      {
        'statut': 'refuse',
        'approuve_par': refusePar,
        'date_approbation': DateTime.now().toIso8601String(),
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [aideSocialeId],
    );
    
    // Audit
    await _auditService.logAction(
      userId: refusePar,
      action: 'refuse_aide_sociale',
      entityType: 'aide_sociale',
      entityId: aideSocialeId,
      details: 'Refus aide sociale ID: $aideSocialeId',
    );
    
    return (await getAideSocialeById(aideSocialeId))!;
  }

  /// Verser une aide sociale (marquer comme versée)
  Future<AideSocialeModel> verserAideSociale({
    required int aideSocialeId,
    required int versePar,
  }) async {
    final db = await DatabaseInitializer.database;
    
    await db.update(
      'aides_sociales',
      {
        'statut': 'verse',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [aideSocialeId],
    );
    
    // Audit
    await _auditService.logAction(
      userId: versePar,
      action: 'verse_aide_sociale',
      entityType: 'aide_sociale',
      entityId: aideSocialeId,
      details: 'Versement aide sociale ID: $aideSocialeId',
    );
    
    return (await getAideSocialeById(aideSocialeId))!;
  }

  /// Récupérer toutes les aides sociales
  Future<List<AideSocialeModel>> getAllAidesSociales({
    int? adherentId,
    String? statut,
    String? typeAide,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final db = await DatabaseInitializer.database;
    
    String? where;
    List<Object?>? whereArgs = [];
    
    if (adherentId != null) {
      where = 'adherent_id = ?';
      whereArgs.add(adherentId);
    }
    
    if (statut != null) {
      where = where != null ? '$where AND statut = ?' : 'statut = ?';
      whereArgs.add(statut);
    }
    
    if (typeAide != null) {
      where = where != null ? '$where AND type_aide = ?' : 'type_aide = ?';
      whereArgs.add(typeAide);
    }
    
    if (dateDebut != null) {
      where = where != null ? '$where AND date_aide >= ?' : 'date_aide >= ?';
      whereArgs.add(dateDebut.toIso8601String());
    }
    
    if (dateFin != null) {
      where = where != null ? '$where AND date_aide <= ?' : 'date_aide <= ?';
      whereArgs.add(dateFin.toIso8601String());
    }
    
    final result = await db.query(
      'aides_sociales',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date_aide DESC',
    );
    
    return result.map((map) => AideSocialeModel.fromMap(map)).toList();
  }

  /// Récupérer une aide sociale par ID
  Future<AideSocialeModel?> getAideSocialeById(int id) async {
    final db = await DatabaseInitializer.database;
    final result = await db.query(
      'aides_sociales',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return AideSocialeModel.fromMap(result.first);
  }

  /// Obtenir les statistiques des aides sociales
  Future<SocialStatistics> getStatistics({
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final db = await DatabaseInitializer.database;
    
    String? where;
    List<Object?>? whereArgs = [];
    
    if (dateDebut != null) {
      where = 'date_aide >= ?';
      whereArgs.add(dateDebut.toIso8601String());
    }
    
    if (dateFin != null) {
      where = where != null ? '$where AND date_aide <= ?' : 'date_aide <= ?';
      whereArgs.add(dateFin.toIso8601String());
    }
    
    final total = await db.rawQuery(
      'SELECT COUNT(*) as count FROM aides_sociales${where != null ? ' WHERE $where' : ''}',
      whereArgs.isEmpty ? null : whereArgs,
    );
    
    final approuvees = await db.rawQuery(
      'SELECT COUNT(*) as count FROM aides_sociales WHERE statut = ?${where != null ? ' AND $where' : ''}',
      ['approuve', ...whereArgs],
    );
    
    final versees = await db.rawQuery(
      'SELECT COUNT(*) as count FROM aides_sociales WHERE statut = ?${where != null ? ' AND $where' : ''}',
      ['verse', ...whereArgs],
    );
    
    final montantTotal = await db.rawQuery(
      'SELECT COALESCE(SUM(montant), 0) as total FROM aides_sociales${where != null ? ' WHERE $where' : ''}',
      whereArgs.isEmpty ? null : whereArgs,
    );
    
    final montantVerse = await db.rawQuery(
      'SELECT COALESCE(SUM(montant), 0) as total FROM aides_sociales WHERE statut = ?${where != null ? ' AND $where' : ''}',
      ['verse', ...whereArgs],
    );
    
    return SocialStatistics(
      totalAides: total.first['count'] as int,
      approuvees: approuvees.first['count'] as int,
      versees: versees.first['count'] as int,
      montantTotal: (montantTotal.first['total'] as num?)?.toDouble() ?? 0.0,
      montantVerse: (montantVerse.first['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Statistiques du module social
class SocialStatistics {
  final int totalAides;
  final int approuvees;
  final int versees;
  final double montantTotal;
  final double montantVerse;

  SocialStatistics({
    required this.totalAides,
    required this.approuvees,
    required this.versees,
    required this.montantTotal,
    required this.montantVerse,
  });
}

