/// Service pour la gestion des commissions
/// Implémente toutes les règles métier pour les commissions

import 'package:flutter/foundation.dart';
import '../database/db_initializer.dart';
import '../../data/models/commission_model.dart';
import '../auth/audit_service.dart';

class CommissionService {
  final AuditService _auditService = AuditService();

  /// Créer une nouvelle commission
  Future<CommissionModel> createCommission({
    required CommissionModel commission,
    required int userId,
    String? reason,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Vérifier que le code est unique
      final existing = await db.query(
        'commissions',
        where: 'code = ?',
        whereArgs: [commission.code],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw Exception('Une commission avec le code ${commission.code} existe déjà');
      }

      // Validation des dates
      if (commission.dateFin != null && commission.dateFin!.isBefore(commission.dateDebut)) {
        throw Exception('La date de fin doit être postérieure à la date de début');
      }

      // Validation du montant
      if (commission.montantFixe <= 0) {
        throw Exception('Le montant fixe doit être supérieur à 0');
      }

      // Insérer la commission
      final id = await db.insert(
        'commissions',
        commission.copyWith(
          createdBy: userId,
          createdAt: DateTime.now(),
        ).toMap(),
      );

      // Logger l'historique
      await _logHistory(
        commissionId: id,
        commissionCode: commission.code,
        action: 'CREATE',
        changedBy: userId,
        reason: reason,
        newMontantFixe: commission.montantFixe,
        newDateDebut: commission.dateDebut,
        newDateFin: commission.dateFin,
      );

      // Logger l'audit
      await _auditService.logAction(
        userId: userId,
        action: 'CREATE_COMMISSION',
        entityType: 'commission',
        entityId: id,
        details: 'Création commission: ${commission.code} - ${commission.libelle}',
      );

      return commission.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création de la commission: $e');
    }
  }

  /// Mettre à jour une commission
  Future<CommissionModel> updateCommission({
    required CommissionModel commission,
    required int userId,
    String? reason,
  }) async {
    try {
      if (commission.id == null) {
        throw Exception('L\'ID de la commission est requis pour la mise à jour');
      }

      final db = await DatabaseInitializer.database;

      // Récupérer l'ancienne version pour l'historique
      final oldCommission = await getCommissionById(commission.id!);
      if (oldCommission == null) {
        throw Exception('Commission introuvable');
      }

      // Vérifier que le code est unique (sauf pour cette commission)
      final existing = await db.query(
        'commissions',
        where: 'code = ? AND id != ?',
        whereArgs: [commission.code, commission.id],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw Exception('Une commission avec le code ${commission.code} existe déjà');
      }

      // Validation des dates
      if (commission.dateFin != null && commission.dateFin!.isBefore(commission.dateDebut)) {
        throw Exception('La date de fin doit être postérieure à la date de début');
      }

      // Validation du montant
      if (commission.montantFixe <= 0) {
        throw Exception('Le montant fixe doit être supérieur à 0');
      }

      // Mettre à jour
      await db.update(
        'commissions',
        commission.copyWith(
          updatedAt: DateTime.now(),
          updatedBy: userId,
        ).toMap(),
        where: 'id = ?',
        whereArgs: [commission.id],
      );

      // Logger l'historique
      await _logHistory(
        commissionId: commission.id!,
        commissionCode: commission.code,
        action: 'UPDATE',
        changedBy: userId,
        reason: reason,
        oldMontantFixe: oldCommission.montantFixe,
        newMontantFixe: commission.montantFixe,
        oldDateDebut: oldCommission.dateDebut,
        newDateDebut: commission.dateDebut,
        oldDateFin: oldCommission.dateFin,
        newDateFin: commission.dateFin,
      );

      // Logger l'audit
      await _auditService.logAction(
        userId: userId,
        action: 'UPDATE_COMMISSION',
        entityType: 'commission',
        entityId: commission.id,
        details: 'Mise à jour commission: ${commission.code}',
      );

      return commission;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la commission: $e');
    }
  }

  /// Obtenir une commission par ID
  Future<CommissionModel?> getCommissionById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'commissions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return CommissionModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la commission: $e');
    }
  }

  /// Obtenir une commission par code
  Future<CommissionModel?> getCommissionByCode(String code) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'commissions',
        where: 'code = ?',
        whereArgs: [code],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return CommissionModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la commission: $e');
    }
  }

  /// Obtenir toutes les commissions actives à une date donnée
  Future<List<CommissionModel>> getCommissionsActives({DateTime? date}) async {
    try {
      final db = await DatabaseInitializer.database;
      final targetDate = date ?? DateTime.now();
      final dateStr = targetDate.toIso8601String().split('T')[0];

      final result = await db.rawQuery('''
        SELECT * FROM commissions
        WHERE statut = 'active'
        AND date_debut <= ?
        AND (date_fin IS NULL OR date_fin >= ?)
        ORDER BY code
      ''', [dateStr, dateStr]);

      return result.map((map) => CommissionModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des commissions actives: $e');
    }
  }

  /// Obtenir toutes les commissions
  Future<List<CommissionModel>> getAllCommissions() async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'commissions',
        orderBy: 'code',
      );

      return result.map((map) => CommissionModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des commissions: $e');
    }
  }

  /// Activer une commission
  Future<void> activateCommission(int id, int userId, {String? reason}) async {
    try {
      final commission = await getCommissionById(id);
      if (commission == null) {
        throw Exception('Commission introuvable');
      }

      await updateCommission(
        commission: commission.copyWith(statut: CommissionStatut.active),
        userId: userId,
        reason: reason,
      );

      await _logHistory(
        commissionId: id,
        commissionCode: commission.code,
        action: 'ACTIVATE',
        changedBy: userId,
        reason: reason,
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'activation de la commission: $e');
    }
  }

  /// Désactiver une commission
  Future<void> deactivateCommission(int id, int userId, {String? reason}) async {
    try {
      final commission = await getCommissionById(id);
      if (commission == null) {
        throw Exception('Commission introuvable');
      }

      await updateCommission(
        commission: commission.copyWith(statut: CommissionStatut.inactive),
        userId: userId,
        reason: reason,
      );

      await _logHistory(
        commissionId: id,
        commissionCode: commission.code,
        action: 'DEACTIVATE',
        changedBy: userId,
        reason: reason,
      );
    } catch (e) {
      throw Exception('Erreur lors de la désactivation de la commission: $e');
    }
  }

  /// Reconduire automatiquement les commissions expirées
  Future<List<CommissionModel>> reconduireCommissionsExpirees({
    required int userId,
    String? reason,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final aujourdhui = DateTime.now();
      final aujourdhuiStr = aujourdhui.toIso8601String().split('T')[0];

      // Récupérer les commissions à reconduire
      final result = await db.rawQuery('''
        SELECT * FROM commissions
        WHERE statut = 'active'
        AND reconductible = 1
        AND date_fin IS NOT NULL
        AND date_fin < ?
      ''', [aujourdhuiStr]);

      final commissionsAReconduire = result
          .map((map) => CommissionModel.fromMap(map))
          .where((c) => c.shouldBeReconduced(aujourdhui))
          .toList();

      final nouvellesCommissions = <CommissionModel>[];

      for (final commission in commissionsAReconduire) {
        try {
          final nouvelleCommission = commission.reconduire();
          final created = await createCommission(
            commission: nouvelleCommission,
            userId: userId,
            reason: reason ?? 'Reconduction automatique',
          );

          // Logger la reconduction
          await _logHistory(
            commissionId: commission.id!,
            commissionCode: commission.code,
            action: 'RECONDUCTION',
            changedBy: userId,
            reason: reason ?? 'Reconduction automatique',
            oldDateFin: commission.dateFin,
            newDateDebut: nouvelleCommission.dateDebut,
            newDateFin: nouvelleCommission.dateFin,
          );

          nouvellesCommissions.add(created);
        } catch (e) {
          debugPrint('⚠️ Erreur lors de la reconduction de ${commission.code}: $e');
        }
      }

      return nouvellesCommissions;
    } catch (e) {
      throw Exception('Erreur lors de la reconduction des commissions: $e');
    }
  }

  /// Logger l'historique d'une commission
  Future<void> _logHistory({
    required int commissionId,
    required String commissionCode,
    required String action,
    required int changedBy,
    String? reason,
    double? oldMontantFixe,
    double? newMontantFixe,
    DateTime? oldDateDebut,
    DateTime? newDateDebut,
    DateTime? oldDateFin,
    DateTime? newDateFin,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.insert('commission_history', {
        'commission_id': commissionId,
        'commission_code': commissionCode,
        'action': action,
        'old_montant_fixe': oldMontantFixe,
        'new_montant_fixe': newMontantFixe,
        'old_date_debut': oldDateDebut?.toIso8601String(),
        'new_date_debut': newDateDebut?.toIso8601String(),
        'old_date_fin': oldDateFin?.toIso8601String(),
        'new_date_fin': newDateFin?.toIso8601String(),
        'changed_by': changedBy,
        'change_reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('⚠️ Erreur lors du logging de l\'historique: $e');
    }
  }
}

