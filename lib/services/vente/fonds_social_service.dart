/// Service de Gestion du Fonds Social (V2)
/// 
/// Gestion de l'impact social avec pourcentage ou montant affecté au fonds social
/// Affichage sur facture et écriture comptable automatique

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/db_initializer.dart';
import '../../data/models/fonds_social_model.dart';
import '../../data/models/vente_model.dart';
import '../comptabilite/comptabilite_service.dart';
import '../auth/audit_service.dart';

class FondsSocialService {
  final ComptabiliteService _comptabiliteService = ComptabiliteService();
  final AuditService _auditService = AuditService();

  /// Créer une contribution au fonds social depuis une vente
  Future<FondsSocialModel> createContributionFromVente({
    required int venteId,
    required double montantVente,
    double? pourcentage,
    double? montantFixe,
    String? notes,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Calculer le montant de la contribution
      double montantContribution;
      if (montantFixe != null) {
        montantContribution = montantFixe;
        pourcentage = (montantContribution / montantVente) * 100;
      } else if (pourcentage != null) {
        montantContribution = montantVente * (pourcentage / 100);
      } else {
        throw Exception('Pourcentage ou montant fixe requis');
      }

      // Créer la contribution
      final contribution = FondsSocialModel(
        venteId: venteId,
        source: 'vente',
        montant: montantContribution,
        pourcentage: pourcentage,
        description: 'Contribution au fonds social depuis vente #$venteId',
        dateContribution: DateTime.now(),
        notes: notes,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final contributionId = await db.insert('fonds_social', contribution.toMap());

      // Créer l'écriture comptable automatique
      try {
        final ecriture = await _comptabiliteService.createEcritureFondsSocial(
          fondsSocialId: contributionId,
          montant: montantContribution,
          venteId: venteId,
          dateContribution: DateTime.now(),
          createdBy: createdBy,
        );

        // Mettre à jour la contribution avec l'ID de l'écriture
        await db.update(
          'fonds_social',
          {'ecriture_comptable_id': ecriture.id},
          where: 'id = ?',
          whereArgs: [contributionId],
        );

        return contribution.copyWith(
          id: contributionId,
          ecritureComptableId: ecriture.id,
        );
      } catch (e) {
        print('Erreur lors de la création de l\'écriture comptable: $e');
        // Ne pas faire échouer la création de la contribution
      }

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_FONDS_SOCIAL',
        entityType: 'fonds_social',
        entityId: contributionId,
        details: 'Contribution de ${montantContribution.toStringAsFixed(0)} FCFA au fonds social depuis vente #$venteId',
      );

      return contribution.copyWith(id: contributionId);
    } catch (e) {
      throw Exception('Erreur lors de la création de la contribution: $e');
    }
  }

  /// Créer une contribution manuelle (don, autre)
  Future<FondsSocialModel> createContributionManuelle({
    required String source,
    required double montant,
    required String description,
    String? notes,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      final contribution = FondsSocialModel(
        source: source,
        montant: montant,
        description: description,
        dateContribution: DateTime.now(),
        notes: notes,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final contributionId = await db.insert('fonds_social', contribution.toMap());

      // Créer l'écriture comptable automatique
      try {
        final ecriture = await _comptabiliteService.createEcritureFondsSocial(
          fondsSocialId: contributionId,
          montant: montant,
          dateContribution: DateTime.now(),
          createdBy: createdBy,
        );

        await db.update(
          'fonds_social',
          {'ecriture_comptable_id': ecriture.id},
          where: 'id = ?',
          whereArgs: [contributionId],
        );

        return contribution.copyWith(
          id: contributionId,
          ecritureComptableId: ecriture.id,
        );
      } catch (e) {
        print('Erreur lors de la création de l\'écriture comptable: $e');
      }

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_FONDS_SOCIAL_MANUAL',
        entityType: 'fonds_social',
        entityId: contributionId,
        details: 'Contribution manuelle de ${montant.toStringAsFixed(0)} FCFA au fonds social: $description',
      );

      return contribution.copyWith(id: contributionId);
    } catch (e) {
      throw Exception('Erreur lors de la création de la contribution: $e');
    }
  }

  /// Récupérer une contribution par ID
  Future<FondsSocialModel?> getContributionById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'fonds_social',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return FondsSocialModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la contribution: $e');
    }
  }

  /// Récupérer toutes les contributions d'une vente
  Future<List<FondsSocialModel>> getContributionsByVente(int venteId) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'fonds_social',
        where: 'vente_id = ?',
        whereArgs: [venteId],
        orderBy: 'date_contribution DESC',
      );

      return result.map((map) => FondsSocialModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des contributions: $e');
    }
  }

  /// Récupérer toutes les contributions
  Future<List<FondsSocialModel>> getAllContributions({
    String? source,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (source != null) {
        where += ' AND source = ?';
        whereArgs.add(source);
      }

      if (startDate != null) {
        where += ' AND date_contribution >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND date_contribution <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.query(
        'fonds_social',
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'date_contribution DESC',
      );

      return result.map((map) => FondsSocialModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des contributions: $e');
    }
  }

  /// Obtenir les statistiques du fonds social
  Future<Map<String, dynamic>> getStatistiquesFondsSocial({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (startDate != null) {
        where += ' AND date_contribution >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND date_contribution <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as nombre_contributions,
          SUM(montant) as montant_total,
          SUM(CASE WHEN source = 'vente' THEN montant ELSE 0 END) as montant_ventes,
          SUM(CASE WHEN source = 'don' THEN montant ELSE 0 END) as montant_dons,
          SUM(CASE WHEN source = 'autre' THEN montant ELSE 0 END) as montant_autre
        FROM fonds_social
        WHERE $where
      ''', whereArgs.isEmpty ? null : whereArgs);

      if (result.isEmpty) {
        return {
          'nombreContributions': 0,
          'montantTotal': 0.0,
          'montantVentes': 0.0,
          'montantDons': 0.0,
          'montantAutre': 0.0,
        };
      }

      final stats = result.first;
      return {
        'nombreContributions': stats['nombre_contributions'] as int? ?? 0,
        'montantTotal': (stats['montant_total'] as num?)?.toDouble() ?? 0.0,
        'montantVentes': (stats['montant_ventes'] as num?)?.toDouble() ?? 0.0,
        'montantDons': (stats['montant_dons'] as num?)?.toDouble() ?? 0.0,
        'montantAutre': (stats['montant_autre'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }
}

