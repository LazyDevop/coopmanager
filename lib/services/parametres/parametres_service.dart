import 'package:sqflite_common/sqlite_api.dart';
import '../database/db_initializer.dart';
import '../../data/models/parametres_cooperative_model.dart';
import '../auth/audit_service.dart';
import '../../data/models/audit_log_model.dart';
import '../../config/app_config.dart';

class ParametresService {
  final AuditService _auditService = AuditService();

  /// Obtenir les paramètres de la coopérative
  Future<ParametresCooperativeModel> getParametres() async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'coop_settings',
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return ParametresCooperativeModel.fromMap(result.first);
      }
      
      // Retourner les paramètres par défaut si aucun n'est trouvé
      return ParametresCooperativeModel(
        nomCooperative: 'Coopérative de Cacaoculteurs',
        commissionRate: AppConfig.defaultCommissionRate,
        periodeCampagneDays: AppConfig.defaultCampaignPeriod,
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paramètres: $e');
    }
  }

  /// Mettre à jour les paramètres de la coopérative
  Future<ParametresCooperativeModel> updateParametres({
    String? nomCooperative,
    String? logoPath,
    String? adresse,
    String? telephone,
    String? email,
    double? commissionRate,
    int? periodeCampagneDays,
    DateTime? dateDebutCampagne,
    DateTime? dateFinCampagne,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer les paramètres actuels
      final current = await getParametres();
      
      // Préparer les données à mettre à jour
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (nomCooperative != null) updateData['nom_cooperative'] = nomCooperative;
      if (logoPath != null) updateData['logo_path'] = logoPath;
      if (adresse != null) updateData['adresse'] = adresse;
      if (telephone != null) updateData['telephone'] = telephone;
      if (email != null) updateData['email'] = email;
      if (commissionRate != null) updateData['commission_rate'] = commissionRate;
      if (periodeCampagneDays != null) updateData['periode_campagne_days'] = periodeCampagneDays;
      if (dateDebutCampagne != null) updateData['date_debut_campagne'] = dateDebutCampagne.toIso8601String();
      if (dateFinCampagne != null) updateData['date_fin_campagne'] = dateFinCampagne.toIso8601String();
      
      // Mettre à jour ou insérer
      if (current.id != null) {
        await db.update(
          'coop_settings',
          updateData,
          where: 'id = ?',
          whereArgs: [current.id],
        );
      } else {
        // Insérer les paramètres par défaut si aucun n'existe
        final defaultData = <String, Object>{
          'nom_cooperative': nomCooperative ?? current.nomCooperative,
          'commission_rate': commissionRate ?? current.commissionRate,
          'periode_campagne_days': periodeCampagneDays ?? current.periodeCampagneDays,
          'updated_at': DateTime.now().toIso8601String(),
        };
        defaultData.addAll(updateData.map((key, value) => MapEntry(key, value as Object)));
        await db.insert('coop_settings', defaultData);
      }

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_PARAMETRES',
        entityType: 'coop_settings',
        entityId: current.id,
        details: 'Mise à jour des paramètres de la coopérative',
      );

      return await getParametres();
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Créer une campagne
  Future<CampagneModel> createCampagne({
    required String nom,
    required DateTime dateDebut,
    required DateTime dateFin,
    String? description,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Vérifier qu'il n'y a pas de chevauchement avec une campagne active
      final chevauchement = await db.query(
        'campagnes',
        where: '''
          is_active = 1 AND (
            (date_debut <= ? AND date_fin >= ?) OR
            (date_debut <= ? AND date_fin >= ?) OR
            (date_debut >= ? AND date_fin <= ?)
          )
        ''',
        whereArgs: [
          dateDebut.toIso8601String(),
          dateDebut.toIso8601String(),
          dateFin.toIso8601String(),
          dateFin.toIso8601String(),
          dateDebut.toIso8601String(),
          dateFin.toIso8601String(),
        ],
      );
      
      if (chevauchement.isNotEmpty) {
        throw Exception('Une campagne active existe déjà pour cette période');
      }
      
      final campagne = CampagneModel(
        nom: nom,
        dateDebut: dateDebut,
        dateFin: dateFin,
        description: description,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final id = await db.insert('campagnes', campagne.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_CAMPAGNE',
        entityType: 'campagnes',
        entityId: id,
        details: 'Création de la campagne: $nom',
      );

      return campagne.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création de la campagne: $e');
    }
  }

  /// Mettre à jour une campagne
  Future<CampagneModel> updateCampagne({
    required int id,
    String? nom,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? description,
    bool? isActive,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (nom != null) updateData['nom'] = nom;
      if (dateDebut != null) updateData['date_debut'] = dateDebut.toIso8601String();
      if (dateFin != null) updateData['date_fin'] = dateFin.toIso8601String();
      if (description != null) updateData['description'] = description;
      if (isActive != null) updateData['is_active'] = isActive ? 1 : 0;
      
      await db.update(
        'campagnes',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_CAMPAGNE',
        entityType: 'campagnes',
        entityId: id,
        details: 'Mise à jour de la campagne',
      );

      final result = await db.query(
        'campagnes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return CampagneModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Obtenir toutes les campagnes
  Future<List<CampagneModel>> getAllCampagnes({bool? isActive}) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String? where;
      List<dynamic>? whereArgs;
      
      if (isActive != null) {
        where = 'is_active = ?';
        whereArgs = [isActive ? 1 : 0];
      }
      
      final result = await db.query(
        'campagnes',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'date_debut DESC',
      );
      
      return result.map((map) => CampagneModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des campagnes: $e');
    }
  }

  /// Obtenir la campagne active
  Future<CampagneModel?> getCampagneActive() async {
    try {
      final campagnes = await getAllCampagnes(isActive: true);
      
      final now = DateTime.now();
      for (final campagne in campagnes) {
        if (campagne.isEnCours) {
          return campagne;
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la campagne active: $e');
    }
  }

  /// Supprimer une campagne
  Future<bool> deleteCampagne(int id, int deletedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      await db.delete(
        'campagnes',
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: deletedBy,
        action: 'DELETE_CAMPAGNE',
        entityType: 'campagnes',
        entityId: id,
        details: 'Suppression de la campagne',
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Créer ou mettre à jour un barème de qualité
  Future<BaremeQualiteModel> saveBaremeQualite({
    required String qualite,
    double? prixMin,
    double? prixMax,
    double? commissionRate,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Vérifier si le barème existe déjà
      final existing = await db.query(
        'baremes_qualite',
        where: 'qualite = ?',
        whereArgs: [qualite],
        limit: 1,
      );
      
      final bareme = BaremeQualiteModel(
        qualite: qualite,
        prixMin: prixMin,
        prixMax: prixMax,
        commissionRate: commissionRate,
      );
      
      if (existing.isNotEmpty) {
        // Mettre à jour
        await db.update(
          'baremes_qualite',
          {
            'prix_min': prixMin,
            'prix_max': prixMax,
            'commission_rate': commissionRate,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'qualite = ?',
          whereArgs: [qualite],
        );
      } else {
        // Créer
        await db.insert('baremes_qualite', {
          'qualite': qualite,
          'prix_min': prixMin,
          'prix_max': prixMax,
          'commission_rate': commissionRate,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      return bareme;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du barème: $e');
    }
  }

  /// Obtenir tous les barèmes de qualité
  Future<List<BaremeQualiteModel>> getAllBaremesQualite() async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'baremes_qualite',
        orderBy: 'qualite',
      );
      
      return result.map((map) => BaremeQualiteModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des barèmes: $e');
    }
  }

  /// Obtenir un barème par qualité
  Future<BaremeQualiteModel?> getBaremeByQualite(String qualite) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'baremes_qualite',
        where: 'qualite = ?',
        whereArgs: [qualite],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      return BaremeQualiteModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du barème: $e');
    }
  }

  /// Supprimer un barème
  Future<bool> deleteBaremeQualite(String qualite) async {
    try {
      final db = await DatabaseInitializer.database;
      
      await db.delete(
        'baremes_qualite',
        where: 'qualite = ?',
        whereArgs: [qualite],
      );
      
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression du barème: $e');
    }
  }
}

