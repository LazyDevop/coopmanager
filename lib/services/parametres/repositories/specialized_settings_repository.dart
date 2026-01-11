/// Repository pour les paramètres spécialisés (Clean Architecture)
import 'package:sqflite_common/sqlite_api.dart';
import '../../../data/models/backend/specialized_settings_models.dart';
import '../../database/db_initializer.dart';

abstract class ICapitalSettingsRepository {
  Future<CapitalSettingsModel?> getByCooperative(String cooperativeId);
  Future<CapitalSettingsModel> save(CapitalSettingsModel settings);
}

abstract class IAccountingSettingsRepository {
  Future<AccountingSettingsModel?> getByCooperative(String cooperativeId);
  Future<AccountingSettingsModel> save(AccountingSettingsModel settings);
  Future<bool> hasActiveExercise(String cooperativeId, int exercice);
}

abstract class IDocumentSettingsRepository {
  Future<DocumentSettingsModel?> getByType(String cooperativeId, DocumentType type);
  Future<List<DocumentSettingsModel>> getAllByCooperative(String cooperativeId);
  Future<DocumentSettingsModel> save(DocumentSettingsModel settings);
}

class CapitalSettingsRepository implements ICapitalSettingsRepository {
  @override
  Future<CapitalSettingsModel?> getByCooperative(String cooperativeId) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'capital_settings',
        where: 'cooperative_id = ?',
        whereArgs: [cooperativeId],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return CapitalSettingsModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paramètres capital: $e');
    }
  }

  @override
  Future<CapitalSettingsModel> save(CapitalSettingsModel settings) async {
    try {
      final db = await DatabaseInitializer.database;
      final existing = await getByCooperative(settings.cooperativeId);
      
      if (existing != null) {
        await db.update(
          'capital_settings',
          {
            'valeur_part': settings.valeurPart,
            'parts_min': settings.partsMin,
            'parts_max': settings.partsMax,
            'liberation_obligatoire': settings.liberationObligatoire ? 1 : 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        return (await getByCooperative(settings.cooperativeId))!;
      } else {
        await db.insert('capital_settings', settings.toMap());
        return (await getByCooperative(settings.cooperativeId))!;
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde des paramètres capital: $e');
    }
  }
}

class AccountingSettingsRepository implements IAccountingSettingsRepository {
  @override
  Future<AccountingSettingsModel?> getByCooperative(String cooperativeId) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'accounting_settings',
        where: 'cooperative_id = ?',
        whereArgs: [cooperativeId],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return AccountingSettingsModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paramètres comptables: $e');
    }
  }

  @override
  Future<AccountingSettingsModel> save(AccountingSettingsModel settings) async {
    try {
      final db = await DatabaseInitializer.database;
      final existing = await getByCooperative(settings.cooperativeId);
      
      if (existing != null) {
        await db.update(
          'accounting_settings',
          {
            'exercice_actif': settings.exerciceActif,
            'plan_comptable': settings.planComptable,
            'taux_reserve': settings.tauxReserve,
            'taux_frais_gestion': settings.tauxFraisGestion,
            'compte_caisse': settings.compteCaisse,
            'compte_banque': settings.compteBanque,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        return (await getByCooperative(settings.cooperativeId))!;
      } else {
        await db.insert('accounting_settings', settings.toMap());
        return (await getByCooperative(settings.cooperativeId))!;
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde des paramètres comptables: $e');
    }
  }

  @override
  Future<bool> hasActiveExercise(String cooperativeId, int exercice) async {
    try {
      final settings = await getByCooperative(cooperativeId);
      return settings?.exerciceActif == exercice;
    } catch (e) {
      return false;
    }
  }
}

class DocumentSettingsRepository implements IDocumentSettingsRepository {
  @override
  Future<DocumentSettingsModel?> getByType(String cooperativeId, DocumentType type) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'document_settings',
        where: 'cooperative_id = ? AND type_document = ?',
        whereArgs: [cooperativeId, type.name],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return DocumentSettingsModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paramètres document: $e');
    }
  }

  @override
  Future<List<DocumentSettingsModel>> getAllByCooperative(String cooperativeId) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'document_settings',
        where: 'cooperative_id = ?',
        whereArgs: [cooperativeId],
        orderBy: 'type_document',
      );
      return result.map((map) => DocumentSettingsModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paramètres documents: $e');
    }
  }

  @override
  Future<DocumentSettingsModel> save(DocumentSettingsModel settings) async {
    try {
      final db = await DatabaseInitializer.database;
      final existing = await getByType(settings.cooperativeId, settings.typeDocument);
      
      if (existing != null) {
        await db.update(
          'document_settings',
          {
            'prefix': settings.prefix,
            'format_numero': settings.formatNumero,
            'pied_page': settings.piedPage,
            'signature_auto': settings.signatureAuto ? 1 : 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        return (await getByType(settings.cooperativeId, settings.typeDocument))!;
      } else {
        await db.insert('document_settings', settings.toMap());
        return (await getByType(settings.cooperativeId, settings.typeDocument))!;
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde des paramètres document: $e');
    }
  }
}

