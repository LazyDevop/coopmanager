import '../database/db_initializer.dart';
import '../../data/models/validation_vente_model.dart';
import '../auth/audit_service.dart';

class ValidationWorkflowService {
  final AuditService _auditService = AuditService();

  /// Initialiser le workflow de validation pour une vente
  Future<void> initialiserWorkflow({
    required int venteId,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Créer l'étape de préparation
      final preparation = ValidationVenteModel(
        venteId: venteId,
        etape: 'preparation',
        statut: 'en_attente',
        createdAt: DateTime.now(),
      );

      await db.insert('validations_vente', preparation.toMap());

      // Mettre à jour la vente avec l'étape du workflow
      await db.update(
        'ventes',
        {
          'workflow_etape': 'preparation',
          'workflow_statut': 'en_attente',
        },
        where: 'id = ?',
        whereArgs: [venteId],
      );

      await _auditService.logAction(
        userId: createdBy,
        action: 'INIT_WORKFLOW_VENTE',
        entityType: 'ventes',
        entityId: venteId,
        details: 'Workflow de validation initialisé pour la vente #$venteId',
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'initialisation du workflow: $e');
    }
  }

  /// Valider l'étape de préparation (gestionnaire)
  Future<bool> validerPreparation({
    required int venteId,
    required int validePar,
    String? commentaire,
  }) async {
    try {
      return await _validerEtape(
        venteId: venteId,
        etape: 'preparation',
        validePar: validePar,
        commentaire: commentaire,
        prochaineEtape: 'validation_prix',
      );
    } catch (e) {
      throw Exception('Erreur lors de la validation de la préparation: $e');
    }
  }

  /// Valider l'étape de validation prix (superviseur)
  Future<bool> validerPrix({
    required int venteId,
    required int validePar,
    String? commentaire,
  }) async {
    try {
      return await _validerEtape(
        venteId: venteId,
        etape: 'validation_prix',
        validePar: validePar,
        commentaire: commentaire,
        prochaineEtape: 'confirmation_finale',
      );
    } catch (e) {
      throw Exception('Erreur lors de la validation du prix: $e');
    }
  }

  /// Valider l'étape de confirmation finale (admin)
  Future<bool> validerConfirmationFinale({
    required int venteId,
    required int validePar,
    String? commentaire,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Valider l'étape
      await _validerEtape(
        venteId: venteId,
        etape: 'confirmation_finale',
        validePar: validePar,
        commentaire: commentaire,
        prochaineEtape: null, // Dernière étape
      );

      // Marquer la vente comme validée
      await db.update(
        'ventes',
        {
          'workflow_etape': 'confirmation_finale',
          'workflow_statut': 'approuvee',
          'statut': 'valide',
        },
        where: 'id = ?',
        whereArgs: [venteId],
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors de la confirmation finale: $e');
    }
  }

  /// Valider une étape du workflow
  Future<bool> _validerEtape({
    required int venteId,
    required String etape,
    required int validePar,
    String? commentaire,
    String? prochaineEtape,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Marquer l'étape actuelle comme approuvée
      await db.update(
        'validations_vente',
        {
          'statut': 'approuvee',
          'valide_par': validePar,
          'commentaire': commentaire,
          'date_validation': DateTime.now().toIso8601String(),
        },
        where: 'vente_id = ? AND etape = ?',
        whereArgs: [venteId, etape],
      );

      // Si ce n'est pas la dernière étape, créer la prochaine étape
      if (prochaineEtape != null) {
        final prochaineValidation = ValidationVenteModel(
          venteId: venteId,
          etape: prochaineEtape,
          statut: 'en_attente',
          createdAt: DateTime.now(),
        );

        await db.insert('validations_vente', prochaineValidation.toMap());

        // Mettre à jour la vente avec la prochaine étape
        await db.update(
          'ventes',
          {
            'workflow_etape': prochaineEtape,
            'workflow_statut': 'en_attente',
          },
          where: 'id = ?',
          whereArgs: [venteId],
        );
      }

      await _auditService.logAction(
        userId: validePar,
        action: 'VALIDATE_${etape.toUpperCase()}',
        entityType: 'ventes',
        entityId: venteId,
        details: 'Étape $etape validée pour la vente #$venteId${commentaire != null ? ': $commentaire' : ''}',
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors de la validation de l\'étape: $e');
    }
  }

  /// Rejeter une étape du workflow
  Future<bool> rejeterEtape({
    required int venteId,
    required String etape,
    required int rejetePar,
    required String raison,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Marquer l'étape comme rejetée
      await db.update(
        'validations_vente',
        {
          'statut': 'rejetee',
          'valide_par': rejetePar,
          'commentaire': raison,
          'date_validation': DateTime.now().toIso8601String(),
        },
        where: 'vente_id = ? AND etape = ?',
        whereArgs: [venteId, etape],
      );

      // Mettre à jour la vente
      await db.update(
        'ventes',
        {
          'workflow_statut': 'rejetee',
        },
        where: 'id = ?',
        whereArgs: [venteId],
      );

      await _auditService.logAction(
        userId: rejetePar,
        action: 'REJECT_${etape.toUpperCase()}',
        entityType: 'ventes',
        entityId: venteId,
        details: 'Étape $etape rejetée pour la vente #$venteId: $raison',
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors du rejet de l\'étape: $e');
    }
  }

  /// Récupérer le workflow d'une vente
  Future<List<ValidationVenteModel>> getWorkflowVente(int venteId) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'validations_vente',
        where: 'vente_id = ?',
        whereArgs: [venteId],
        orderBy: 'created_at ASC',
      );

      return result.map((map) => ValidationVenteModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération du workflow: $e');
    }
  }

  /// Récupérer l'étape actuelle d'une vente
  Future<ValidationVenteModel?> getEtapeActuelle(int venteId) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'validations_vente',
        where: 'vente_id = ? AND statut = ?',
        whereArgs: [venteId, 'en_attente'],
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (result.isEmpty) return null;

      return ValidationVenteModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'étape actuelle: $e');
    }
  }

  /// Récupérer toutes les ventes en attente de validation
  Future<List<Map<String, dynamic>>> getVentesEnAttenteValidation({
    String? etape,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = "v.workflow_statut = 'en_attente'";
      List<dynamic> whereArgs = [];

      if (etape != null) {
        where += ' AND v.workflow_etape = ?';
        whereArgs.add(etape);
      }

      final result = await db.rawQuery('''
        SELECT 
          v.*,
          vv.etape,
          vv.statut as validation_statut,
          vv.valide_par,
          vv.commentaire
        FROM ventes v
        LEFT JOIN validations_vente vv ON v.id = vv.vente_id AND vv.statut = 'en_attente'
        WHERE $where
        ORDER BY v.created_at DESC
      ''', whereArgs.isEmpty ? null : whereArgs);

      return result;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des ventes en attente: $e');
    }
  }
}

