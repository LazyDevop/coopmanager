/// Repository pour la gestion des coopératives (Clean Architecture)
import 'package:sqflite_common/sqlite_api.dart';
import '../../../data/models/backend/cooperative_model.dart';
import '../../database/db_initializer.dart';

abstract class ICooperativeRepository {
  Future<CooperativeModel?> getById(String id);
  Future<CooperativeModel?> getCurrent();
  Future<List<CooperativeModel>> getAll({CooperativeStatut? statut});
  Future<CooperativeModel> create(CooperativeModel cooperative);
  Future<CooperativeModel> update(CooperativeModel cooperative);
  Future<bool> delete(String id);
  Future<bool> setCurrent(String id);
}

class CooperativeRepository implements ICooperativeRepository {
  @override
  Future<CooperativeModel?> getById(String id) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'cooperatives',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return CooperativeModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la coopérative: $e');
    }
  }

  @override
  Future<CooperativeModel?> getCurrent() async {
    try {
      // Récupérer la coopérative active (statut = ACTIVE)
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'cooperatives',
        where: 'statut = ?',
        whereArgs: ['ACTIVE'],
        limit: 1,
        orderBy: 'created_at DESC',
      );
      if (result.isEmpty) return null;
      return CooperativeModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la coopérative active: $e');
    }
  }

  @override
  Future<List<CooperativeModel>> getAll({CooperativeStatut? statut}) async {
    try {
      final db = await DatabaseInitializer.database;
      String? where;
      List<dynamic>? whereArgs;
      
      if (statut != null) {
        where = 'statut = ?';
        whereArgs = [statut.name.toUpperCase()];
      }
      
      final result = await db.query(
        'cooperatives',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );
      
      return result.map((map) => CooperativeModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des coopératives: $e');
    }
  }

  @override
  Future<CooperativeModel> create(CooperativeModel cooperative) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Vérifier qu'il n'y a pas déjà une coopérative active si celle-ci est active
      if (cooperative.statut == CooperativeStatut.active) {
        final active = await getCurrent();
        if (active != null && active.id != cooperative.id) {
          throw Exception('Une coopérative active existe déjà. Désactivez-la d\'abord.');
        }
      }
      
      await db.insert('cooperatives', cooperative.toMap());
      return (await getById(cooperative.id))!;
    } catch (e) {
      throw Exception('Erreur lors de la création de la coopérative: $e');
    }
  }

  @override
  Future<CooperativeModel> update(CooperativeModel cooperative) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Si on active cette coopérative, désactiver les autres
      if (cooperative.statut == CooperativeStatut.active) {
        final active = await getCurrent();
        if (active != null && active.id != cooperative.id) {
          await db.update(
            'cooperatives',
            {'statut': 'INACTIVE', 'updated_at': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [active.id],
          );
        }
      }
      
      await db.update(
        'cooperatives',
        cooperative.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [cooperative.id],
      );
      
      return (await getById(cooperative.id))!;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la coopérative: $e');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Vérifier qu'il reste au moins une coopérative
      final all = await getAll();
      if (all.length <= 1) {
        throw Exception('Impossible de supprimer la dernière coopérative');
      }
      
      // Vérifier qu'elle n'est pas active
      final coop = await getById(id);
      if (coop?.statut == CooperativeStatut.active) {
        throw Exception('Impossible de supprimer la coopérative active');
      }
      
      await db.delete('cooperatives', where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la coopérative: $e');
    }
  }

  @override
  Future<bool> setCurrent(String id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Désactiver toutes les coopératives
      await db.update(
        'cooperatives',
        {'statut': 'INACTIVE', 'updated_at': DateTime.now().toIso8601String()},
      );
      
      // Activer celle demandée
      await db.update(
        'cooperatives',
        {'statut': 'ACTIVE', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return true;
    } catch (e) {
      throw Exception('Erreur lors du changement de coopérative active: $e');
    }
  }
}

