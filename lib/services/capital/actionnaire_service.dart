import '../database/db_initializer.dart';
import '../../data/models/capital_social_model.dart';
import '../auth/audit_service.dart';

/// Service pour la gestion des actionnaires
class ActionnaireService {
  final AuditService _auditService = AuditService();

  /// Créer un actionnaire à partir d'un adhérent
  Future<ActionnaireModel> createActionnaire({
    required int adherentId,
    required String codeActionnaire,
    required DateTime dateEntree,
    bool droitsVote = true,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;

    try {
      // Vérifier l'unicité du code
      final existing = await db.query(
        'actionnaires',
        where: 'code_actionnaire = ?',
        whereArgs: [codeActionnaire],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw Exception(
          'Un actionnaire avec le code $codeActionnaire existe déjà',
        );
      }

      // Vérifier si l'adhérent est déjà actionnaire
      final existingAdherent = await db.query(
        'actionnaires',
        where: 'adherent_id = ?',
        whereArgs: [adherentId],
        limit: 1,
      );

      if (existingAdherent.isNotEmpty) {
        throw Exception('Cet adhérent est déjà actionnaire');
      }

      final actionnaire = ActionnaireModel(
        adherentId: adherentId,
        codeActionnaire: codeActionnaire,
        dateEntree: dateEntree,
        statut: ActionnaireModel.statutActif,
        droitsVote: droitsVote,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      final id = await db.insert('actionnaires', actionnaire.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_ACTIONNAIRE',
        entityType: 'actionnaires',
        entityId: id,
        details: 'Actionnaire créé: $codeActionnaire',
      );

      return actionnaire.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  /// Obtenir un actionnaire par ID
  Future<ActionnaireModel?> getActionnaireById(int id) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.rawQuery(
        '''
        SELECT a.*,
               ad.code AS adherent_code,
               ad.nom AS adherent_nom,
               ad.prenom AS adherent_prenom,
               ad.telephone AS adherent_telephone
        FROM actionnaires a
        LEFT JOIN adherents ad ON ad.id = a.adherent_id
        WHERE a.id = ?
        LIMIT 1
        ''',
        [id],
      );

      if (result.isEmpty) return null;

      // Calculer les statistiques
      final stats = await _calculateActionnaireStats(id);

      return ActionnaireModel.fromMap({...result.first, ...stats});
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Obtenir un actionnaire par adhérent ID
  Future<ActionnaireModel?> getActionnaireByAdherentId(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.rawQuery(
        '''
        SELECT a.*,
               ad.code AS adherent_code,
               ad.nom AS adherent_nom,
               ad.prenom AS adherent_prenom,
               ad.telephone AS adherent_telephone
        FROM actionnaires a
        LEFT JOIN adherents ad ON ad.id = a.adherent_id
        WHERE a.adherent_id = ?
        LIMIT 1
        ''',
        [adherentId],
      );

      if (result.isEmpty) return null;

      final id = result.first['id'] as int;
      final stats = await _calculateActionnaireStats(id);

      return ActionnaireModel.fromMap({...result.first, ...stats});
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Obtenir tous les actionnaires
  Future<List<ActionnaireModel>> getAllActionnaires({String? statut}) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (statut != null) {
        where += ' AND a.statut = ?';
        whereArgs.add(statut);
      }

      final result = await db.rawQuery('''
        SELECT a.*,
               ad.code AS adherent_code,
               ad.nom AS adherent_nom,
               ad.prenom AS adherent_prenom,
               ad.telephone AS adherent_telephone
        FROM actionnaires a
        LEFT JOIN adherents ad ON ad.id = a.adherent_id
        WHERE $where
        ORDER BY a.date_entree DESC
        ''', whereArgs);

      final actionnaires = <ActionnaireModel>[];
      for (final row in result) {
        final id = row['id'] as int;
        final stats = await _calculateActionnaireStats(id);
        actionnaires.add(ActionnaireModel.fromMap({...row, ...stats}));
      }

      return actionnaires;
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Calculer les statistiques d'un actionnaire
  Future<Map<String, dynamic>> _calculateActionnaireStats(
    int actionnaireId,
  ) async {
    final db = await DatabaseInitializer.database;

    // Nombre de parts et capital souscrit
    final souscriptionsResult = await db.rawQuery(
      '''
      SELECT 
        SUM(nombre_parts_souscrites) as nombre_parts,
        SUM(montant_souscrit) as capital_souscrit,
        MAX(date_souscription) as derniere_souscription
      FROM souscriptions_capital
      WHERE actionnaire_id = ? AND statut != ?
    ''',
      [actionnaireId, SouscriptionCapitalModel.statutAnnule],
    );

    final nombreParts = souscriptionsResult.first['nombre_parts'] as int? ?? 0;
    final capitalSouscrit =
        (souscriptionsResult.first['capital_souscrit'] as num?)?.toDouble() ??
        0.0;
    final derniereSouscription =
        souscriptionsResult.first['derniere_souscription'] as String?;

    // Capital libéré
    final liberationsResult = await db.rawQuery(
      '''
      SELECT 
        SUM(l.montant_libere) as capital_libere,
        MAX(l.date_paiement) as derniere_liberation
      FROM liberations_capital l
      INNER JOIN souscriptions_capital s ON l.souscription_id = s.id
      WHERE s.actionnaire_id = ?
    ''',
      [actionnaireId],
    );

    final capitalLibere =
        (liberationsResult.first['capital_libere'] as num?)?.toDouble() ?? 0.0;
    final derniereLiberation =
        liberationsResult.first['derniere_liberation'] as String?;

    final capitalRestant = capitalSouscrit - capitalLibere;

    return {
      'nombre_parts_detenues': nombreParts,
      'capital_souscrit': capitalSouscrit,
      'capital_libere': capitalLibere,
      'capital_restant': capitalRestant,
      'derniere_souscription': derniereSouscription,
      'derniere_liberation': derniereLiberation,
    };
  }

  /// Suspendre un actionnaire
  Future<ActionnaireModel> suspendreActionnaire({
    required int id,
    required int suspendedBy,
  }) async {
    final db = await DatabaseInitializer.database;

    try {
      await db.update(
        'actionnaires',
        {
          'statut': ActionnaireModel.statutSuspendu,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: suspendedBy,
        action: 'SUSPEND_ACTIONNAIRE',
        entityType: 'actionnaires',
        entityId: id,
        details: 'Actionnaire suspendu',
      );

      return (await getActionnaireById(id))!;
    } catch (e) {
      throw Exception('Erreur lors de la suspension: $e');
    }
  }

  /// Réactiver un actionnaire
  Future<ActionnaireModel> reactiverActionnaire({
    required int id,
    required int reactivatedBy,
  }) async {
    final db = await DatabaseInitializer.database;

    try {
      await db.update(
        'actionnaires',
        {
          'statut': ActionnaireModel.statutActif,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: reactivatedBy,
        action: 'REACTIVATE_ACTIONNAIRE',
        entityType: 'actionnaires',
        entityId: id,
        details: 'Actionnaire réactivé',
      );

      return (await getActionnaireById(id))!;
    } catch (e) {
      throw Exception('Erreur lors de la réactivation: $e');
    }
  }
}
