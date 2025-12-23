import 'package:sqflite_common/sqlite_api.dart';
import '../database/db_initializer.dart';
import '../../data/models/adherent_expert/capital_social_model.dart';
import '../auth/audit_service.dart';

/// Service pour gérer le capital social des adhérents
class CapitalSocialService {
  final AuditService _auditService = AuditService();

  /// Créer une souscription au capital social
  Future<CapitalSocialModel> createSouscription({
    required int adherentId,
    required int nombrePartsSouscrites,
    required double valeurPart,
    required DateTime dateSouscription,
    String? notes,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      if (nombrePartsSouscrites <= 0) {
        throw Exception('Le nombre de parts doit être supérieur à 0');
      }
      if (valeurPart <= 0) {
        throw Exception('La valeur de la part doit être supérieure à 0');
      }
      
      final capitalTotal = nombrePartsSouscrites * valeurPart;
      final statut = 'souscrit';
      
      final souscription = CapitalSocialModel(
        adherentId: adherentId,
        nombrePartsSouscrites: nombrePartsSouscrites,
        nombrePartsLiberees: 0,
        valeurPart: valeurPart,
        capitalTotal: capitalTotal,
        dateSouscription: dateSouscription,
        statut: statut,
        notes: notes,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      final id = await db.insert('capital_social_expert', souscription.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_CAPITAL_SOCIAL',
        entityType: 'capital_social_expert',
        entityId: id,
        details: 'Création souscription: $nombrePartsSouscrites parts pour adhérent $adherentId',
      );

      return souscription.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création de la souscription: $e');
    }
  }

  /// Libérer des parts du capital social
  Future<CapitalSocialModel> libererParts({
    required int id,
    required int nombrePartsALiberer,
    DateTime? dateLiberation,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer la souscription existante
      final existing = await getSouscriptionById(id);
      if (existing == null) {
        throw Exception('Souscription non trouvée');
      }

      if (nombrePartsALiberer <= 0) {
        throw Exception('Le nombre de parts à libérer doit être supérieur à 0');
      }

      final newNombrePartsLiberees = existing.nombrePartsLiberees + nombrePartsALiberer;
      
      if (newNombrePartsLiberees > existing.nombrePartsSouscrites) {
        throw Exception('Le nombre de parts libérées ne peut pas dépasser le nombre de parts souscrites');
      }

      final newStatut = newNombrePartsLiberees == existing.nombrePartsSouscrites
          ? 'libere'
          : 'partiellement_libere';

      final updated = existing.copyWith(
        nombrePartsLiberees: newNombrePartsLiberees,
        dateLiberation: dateLiberation ?? DateTime.now(),
        statut: newStatut,
      );

      await db.update(
        'capital_social_expert',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'LIBERER_CAPITAL_SOCIAL',
        entityType: 'capital_social_expert',
        entityId: id,
        details: 'Libération de $nombrePartsALiberer parts',
      );

      return updated;
    } catch (e) {
      throw Exception('Erreur lors de la libération des parts: $e');
    }
  }

  /// Mettre à jour une souscription
  Future<CapitalSocialModel> updateSouscription({
    required int id,
    int? nombrePartsSouscrites,
    int? nombrePartsLiberees,
    double? valeurPart,
    DateTime? dateSouscription,
    DateTime? dateLiberation,
    String? statut,
    String? notes,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer la souscription existante
      final existing = await getSouscriptionById(id);
      if (existing == null) {
        throw Exception('Souscription non trouvée');
      }

      final updatedNombrePartsSouscrites = nombrePartsSouscrites ?? existing.nombrePartsSouscrites;
      final updatedNombrePartsLiberees = nombrePartsLiberees ?? existing.nombrePartsLiberees;
      final updatedValeurPart = valeurPart ?? existing.valeurPart;
      
      if (updatedNombrePartsLiberees > updatedNombrePartsSouscrites) {
        throw Exception('Le nombre de parts libérées ne peut pas dépasser le nombre de parts souscrites');
      }

      final updatedStatut = statut ?? existing.calculateStatut();

      final updated = existing.copyWith(
        nombrePartsSouscrites: nombrePartsSouscrites,
        nombrePartsLiberees: nombrePartsLiberees,
        valeurPart: valeurPart,
        capitalTotal: updatedNombrePartsSouscrites * updatedValeurPart,
        dateSouscription: dateSouscription,
        dateLiberation: dateLiberation,
        statut: updatedStatut,
        notes: notes,
      );

      await db.update(
        'capital_social_expert',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_CAPITAL_SOCIAL',
        entityType: 'capital_social_expert',
        entityId: id,
        details: 'Modification souscription',
      );

      return updated;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la souscription: $e');
    }
  }

  /// Annuler une souscription
  Future<void> annulerSouscription(int id, int deletedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      await db.update(
        'capital_social_expert',
        {
          'statut': 'annule',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: deletedBy,
        action: 'ANNULER_CAPITAL_SOCIAL',
        entityType: 'capital_social_expert',
        entityId: id,
        details: 'Annulation souscription $id',
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la souscription: $e');
    }
  }

  /// Récupérer une souscription par ID
  Future<CapitalSocialModel?> getSouscriptionById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'capital_social_expert',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return CapitalSocialModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la souscription: $e');
    }
  }

  /// Récupérer toutes les souscriptions d'un adhérent
  Future<List<CapitalSocialModel>> getSouscriptionsByAdherent(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'capital_social_expert',
        where: 'adherent_id = ? AND statut != ?',
        whereArgs: [adherentId, 'annule'],
        orderBy: 'date_souscription DESC',
      );

      return result.map((map) => CapitalSocialModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des souscriptions: $e');
    }
  }

  /// Calculer les statistiques du capital social pour un adhérent
  Future<Map<String, double>> getCapitalSocialStats(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(capital_total), 0) as capital_souscrit_total,
          COALESCE(SUM(nombre_parts_liberees * valeur_part), 0) as capital_libere_total,
          COALESCE(SUM(nombre_parts_restantes * valeur_part), 0) as capital_restant_total
        FROM capital_social_expert
        WHERE adherent_id = ? AND statut != 'annule'
      ''', [adherentId]);

      if (result.isEmpty) {
        return {
          'capitalSocialSouscrit': 0.0,
          'capitalSocialLibere': 0.0,
          'capitalSocialRestant': 0.0,
        };
      }

      return {
        'capitalSocialSouscrit': (result.first['capital_souscrit_total'] as num?)?.toDouble() ?? 0.0,
        'capitalSocialLibere': (result.first['capital_libere_total'] as num?)?.toDouble() ?? 0.0,
        'capitalSocialRestant': (result.first['capital_restant_total'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }
}

