import '../database/db_initializer.dart';
import '../../data/models/social/social_aide_type_model.dart';
import '../../data/models/social/social_aide_model.dart';
import '../../data/models/social/social_remboursement_model.dart';
import '../auth/audit_service.dart';
import '../database/migrations/social_module_migration.dart';

/// Service de gestion du module Social
class SocialService {
  final AuditService _auditService = AuditService();
  bool _tablesChecked = false;

  /// Vérifier et créer les tables si elles n'existent pas (fallback)
  Future<void> _ensureTablesExist() async {
    if (_tablesChecked) return;
    
    try {
      final db = await DatabaseInitializer.database;
      
      // Vérifier si la table existe
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='social_aide_types'",
      );
      
      if (result.isEmpty) {
        print('⚠️ Tables sociales introuvables, création en cours...');
        await SocialModuleMigration.createSocialTables(db);
        print('✅ Tables sociales créées avec succès (fallback)');
      }
      
      _tablesChecked = true;
    } catch (e) {
      print('⚠️ Erreur lors de la vérification des tables sociales: $e');
      // Ne pas bloquer les opérations, mais réessayer la prochaine fois
      _tablesChecked = false;
    }
  }

  // ==================== TYPES D'AIDES ====================

  /// Obtenir tous les types d'aides
  Future<List<SocialAideTypeModel>> getAllAideTypes({bool? actifsOnly}) async {
    try {
      // S'assurer que les tables existent
      await _ensureTablesExist();
      
      final db = await DatabaseInitializer.database;
      
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (actifsOnly == true) {
        whereClause = 'WHERE activation = ?';
        whereArgs = [1];
      }
      
      final result = await db.rawQuery(
        'SELECT * FROM social_aide_types $whereClause ORDER BY libelle',
        whereArgs.isEmpty ? null : whereArgs,
      );
      
      return result.map((map) => SocialAideTypeModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des types d\'aides: $e');
    }
  }

  /// Obtenir un type d'aide par ID
  Future<SocialAideTypeModel?> getAideTypeById(int id) async {
    try {
      await _ensureTablesExist();
      
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'social_aide_types',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      return SocialAideTypeModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du type d\'aide: $e');
    }
  }

  /// Obtenir un type d'aide par code
  Future<SocialAideTypeModel?> getAideTypeByCode(String code) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'social_aide_types',
        where: 'code = ?',
        whereArgs: [code],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      return SocialAideTypeModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du type d\'aide: $e');
    }
  }

  /// Créer un type d'aide
  Future<SocialAideTypeModel> createAideType({
    required String code,
    required String libelle,
    required String categorie,
    bool estRemboursable = false,
    double? plafondMontant,
    int? dureeMaxMois,
    String? modeRemboursement,
    bool activation = true,
    String? description,
    required int createdBy,
  }) async {
    try {
      await _ensureTablesExist();
      
      final db = await DatabaseInitializer.database;
      
      // Vérifier que le code n'existe pas déjà
      final existing = await getAideTypeByCode(code);
      if (existing != null) {
        throw Exception('Un type d\'aide avec le code "$code" existe déjà');
      }
      
      final aideType = SocialAideTypeModel(
        code: code,
        libelle: libelle,
        categorie: categorie,
        estRemboursable: estRemboursable,
        plafondMontant: plafondMontant,
        dureeMaxMois: dureeMaxMois,
        modeRemboursement: modeRemboursement,
        activation: activation,
        description: description,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );
      
      final id = await db.insert('social_aide_types', aideType.toMap());
      
      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_AIDE_TYPE',
        entityType: 'social_aide_types',
        entityId: id,
        details: 'Type d\'aide créé: $libelle ($code)',
      );
      
      return aideType.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création du type d\'aide: $e');
    }
  }

  /// Mettre à jour un type d'aide
  Future<SocialAideTypeModel> updateAideType({
    required int id,
    String? code,
    String? libelle,
    String? categorie,
    bool? estRemboursable,
    double? plafondMontant,
    int? dureeMaxMois,
    String? modeRemboursement,
    bool? activation,
    String? description,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final existing = await getAideTypeById(id);
      if (existing == null) {
        throw Exception('Type d\'aide introuvable');
      }
      
      // Vérifier l'unicité du code si modifié
      if (code != null && code != existing.code) {
        final codeExists = await getAideTypeByCode(code);
        if (codeExists != null) {
          throw Exception('Un type d\'aide avec le code "$code" existe déjà');
        }
      }
      
      final updated = existing.copyWith(
        code: code,
        libelle: libelle,
        categorie: categorie,
        estRemboursable: estRemboursable,
        plafondMontant: plafondMontant,
        dureeMaxMois: dureeMaxMois,
        modeRemboursement: modeRemboursement,
        activation: activation,
        description: description,
        updatedAt: DateTime.now(),
        updatedBy: updatedBy,
      );
      
      await db.update(
        'social_aide_types',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      
      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_AIDE_TYPE',
        entityType: 'social_aide_types',
        entityId: id,
        details: 'Type d\'aide modifié: ${updated.libelle}',
      );
      
      return updated;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du type d\'aide: $e');
    }
  }

  /// Activer/Désactiver un type d'aide
  Future<void> toggleAideTypeActivation({
    required int id,
    required bool activation,
    required int updatedBy,
  }) async {
    try {
      await updateAideType(
        id: id,
        activation: activation,
        updatedBy: updatedBy,
      );
    } catch (e) {
      throw Exception('Erreur lors de la modification de l\'activation: $e');
    }
  }

  // ==================== AIDES ACCORDÉES ====================

  /// Obtenir toutes les aides d'un adhérent
  Future<List<SocialAideModel>> getAidesByAdherent(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'social_aides',
        where: 'adherent_id = ?',
        whereArgs: [adherentId],
        orderBy: 'date_octroi DESC',
      );
      
      final aides = result.map((map) => SocialAideModel.fromMap(map)).toList();
      
      // Charger les types d'aides
      for (var aide in aides) {
        aide.aideType = await getAideTypeById(aide.aideTypeId);
      }
      
      return aides;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des aides: $e');
    }
  }

  /// Obtenir toutes les aides (avec filtres optionnels)
  Future<List<SocialAideModel>> getAllAides({
    int? adherentId,
    int? aideTypeId,
    String? statut,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      await _ensureTablesExist();
      
      final db = await DatabaseInitializer.database;
      
      List<String> whereClauses = [];
      List<dynamic> whereArgs = [];
      
      if (adherentId != null) {
        whereClauses.add('adherent_id = ?');
        whereArgs.add(adherentId);
      }
      
      if (aideTypeId != null) {
        whereClauses.add('aide_type_id = ?');
        whereArgs.add(aideTypeId);
      }
      
      if (statut != null) {
        whereClauses.add('statut = ?');
        whereArgs.add(statut);
      }
      
      if (dateDebut != null) {
        whereClauses.add('date_octroi >= ?');
        whereArgs.add(dateDebut.toIso8601String());
      }
      
      if (dateFin != null) {
        whereClauses.add('date_octroi <= ?');
        whereArgs.add(dateFin.toIso8601String());
      }
      
      final whereClause = whereClauses.isEmpty 
          ? null 
          : whereClauses.join(' AND ');
      
      final result = await db.query(
        'social_aides',
        where: whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'date_octroi DESC',
      );
      
      final aides = result.map((map) => SocialAideModel.fromMap(map)).toList();
      
      // Charger les types d'aides et infos adhérents
      for (var aide in aides) {
        aide.aideType = await getAideTypeById(aide.aideTypeId);
        // TODO: Charger les infos adhérent depuis AdherentService
      }
      
      return aides;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des aides: $e');
    }
  }

  /// Obtenir une aide par ID
  Future<SocialAideModel?> getAideById(int id) async {
    try {
      await _ensureTablesExist();
      
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'social_aides',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      final aide = SocialAideModel.fromMap(result.first);
      aide.aideType = await getAideTypeById(aide.aideTypeId);
      
      return aide;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'aide: $e');
    }
  }

  /// Accorder une aide à un adhérent
  Future<SocialAideModel> accorderAide({
    required int aideTypeId,
    required int adherentId,
    required double montant,
    required DateTime dateOctroi,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? observations,
    required int createdBy,
  }) async {
    try {
      await _ensureTablesExist();
      
      final db = await DatabaseInitializer.database;
      
      // Vérifier que le type d'aide existe et est actif
      final aideType = await getAideTypeById(aideTypeId);
      if (aideType == null) {
        throw Exception('Type d\'aide introuvable');
      }
      
      if (!aideType.activation) {
        throw Exception('Ce type d\'aide n\'est pas activé');
      }
      
      // Vérifier le plafond si défini
      if (aideType.plafondMontant != null && montant > aideType.plafondMontant!) {
        throw Exception(
          'Le montant dépasse le plafond autorisé de ${aideType.plafondMontant!.toStringAsFixed(0)} FCFA'
        );
      }
      
      // Déterminer le statut initial
      String statut = 'accordee';
      if (aideType.estRemboursable) {
        statut = 'en_cours';
      }
      
      final aide = SocialAideModel(
        aideTypeId: aideTypeId,
        adherentId: adherentId,
        montant: montant,
        dateOctroi: dateOctroi,
        dateDebut: dateDebut,
        dateFin: dateFin,
        statut: statut,
        observations: observations,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );
      
      final id = await db.insert('social_aides', aide.toMap());
      
      // Logger l'historique
      await _logAideHistory(
        aideId: id,
        action: 'CREATE',
        changedBy: createdBy,
        details: 'Aide accordée: ${aideType.libelle} - ${montant.toStringAsFixed(0)} FCFA',
      );
      
      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_AIDE',
        entityType: 'social_aides',
        entityId: id,
        details: 'Aide accordée à l\'adhérent $adherentId: ${aideType.libelle} - ${montant.toStringAsFixed(0)} FCFA',
      );
      
      return aide.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de l\'octroi de l\'aide: $e');
    }
  }

  /// Mettre à jour le statut d'une aide
  Future<void> updateAideStatut({
    required int id,
    required String newStatut,
    required int updatedBy,
    String? details,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final aide = await getAideById(id);
      if (aide == null) {
        throw Exception('Aide introuvable');
      }
      
      await db.update(
        'social_aides',
        {
          'statut': newStatut,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // Logger l'historique
      await _logAideHistory(
        aideId: id,
        action: 'STATUS_CHANGE',
        changedBy: updatedBy,
        oldStatut: aide.statut,
        newStatut: newStatut,
        details: details ?? 'Changement de statut: ${aide.statut} → $newStatut',
      );
      
      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_AIDE_STATUS',
        entityType: 'social_aides',
        entityId: id,
        details: 'Statut modifié: ${aide.statut} → $newStatut',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  /// Annuler une aide
  Future<void> annulerAide({
    required int id,
    required int updatedBy,
    String? raison,
  }) async {
    try {
      await updateAideStatut(
        id: id,
        newStatut: 'annulée',
        updatedBy: updatedBy,
        details: raison ?? 'Aide annulée',
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de l\'aide: $e');
    }
  }

  // ==================== REMBOURSEMENTS ====================

  /// Obtenir tous les remboursements d'une aide
  Future<List<SocialRemboursementModel>> getRemboursementsByAide(int aideId) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'social_remboursements',
        where: 'aide_id = ?',
        whereArgs: [aideId],
        orderBy: 'date_remboursement DESC',
      );
      
      return result.map((map) => SocialRemboursementModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des remboursements: $e');
    }
  }

  /// Calculer le solde restant d'une aide
  Future<double> getSoldeRestant(int aideId) async {
    try {
      final aide = await getAideById(aideId);
      if (aide == null) {
        throw Exception('Aide introuvable');
      }
      
      if (!aide.isRemboursable) {
        return 0.0; // Aide non remboursable
      }
      
      final remboursements = await getRemboursementsByAide(aideId);
      final totalRembourse = remboursements.fold<double>(
        0.0,
        (sum, r) => sum + r.montant,
      );
      
      return aide.montant - totalRembourse;
    } catch (e) {
      throw Exception('Erreur lors du calcul du solde restant: $e');
    }
  }

  /// Enregistrer un remboursement
  Future<SocialRemboursementModel> enregistrerRemboursement({
    required int aideId,
    required double montant,
    required DateTime dateRemboursement,
    required String source,
    int? recetteId,
    String? notes,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final aide = await getAideById(aideId);
      if (aide == null) {
        throw Exception('Aide introuvable');
      }
      
      if (!aide.isRemboursable) {
        throw Exception('Cette aide n\'est pas remboursable');
      }
      
      // Vérifier le solde restant
      final soldeRestant = await getSoldeRestant(aideId);
      if (montant > soldeRestant) {
        throw Exception(
          'Le montant dépasse le solde restant de ${soldeRestant.toStringAsFixed(0)} FCFA'
        );
      }
      
      final remboursement = SocialRemboursementModel(
        aideId: aideId,
        montant: montant,
        dateRemboursement: dateRemboursement,
        source: source,
        recetteId: recetteId,
        notes: notes,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );
      
      final id = await db.insert('social_remboursements', remboursement.toMap());
      
      // Vérifier si l'aide est complètement remboursée
      final nouveauSolde = await getSoldeRestant(aideId);
      if (nouveauSolde <= 0.01) { // Tolérance pour les arrondis
        await updateAideStatut(
          id: aideId,
          newStatut: 'remboursée',
          updatedBy: createdBy,
          details: 'Aide complètement remboursée',
        );
      } else {
        // S'assurer que le statut est "en_cours" si ce n'est pas déjà le cas
        if (aide.statut != 'en_cours') {
          await updateAideStatut(
            id: aideId,
            newStatut: 'en_cours',
            updatedBy: createdBy,
            details: 'Remboursement partiel enregistré',
          );
        }
      }
      
      // Logger l'historique
      await _logAideHistory(
        aideId: aideId,
        action: 'REMBURSEMENT',
        changedBy: createdBy,
        details: 'Remboursement de ${montant.toStringAsFixed(0)} FCFA via $source',
      );
      
      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_REMBURSEMENT',
        entityType: 'social_remboursements',
        entityId: id,
        details: 'Remboursement enregistré: ${montant.toStringAsFixed(0)} FCFA',
      );
      
      return remboursement.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement du remboursement: $e');
    }
  }

  // ==================== STATISTIQUES & RAPPORTS ====================

  /// Obtenir les statistiques des aides
  Future<Map<String, dynamic>> getStatistiques({
    DateTime? dateDebut,
    DateTime? dateFin,
    int? adherentId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      List<String> whereClauses = [];
      List<dynamic> whereArgs = [];
      
      if (dateDebut != null) {
        whereClauses.add('date_octroi >= ?');
        whereArgs.add(dateDebut.toIso8601String());
      }
      
      if (dateFin != null) {
        whereClauses.add('date_octroi <= ?');
        whereArgs.add(dateFin.toIso8601String());
      }
      
      if (adherentId != null) {
        whereClauses.add('adherent_id = ?');
        whereArgs.add(adherentId);
      }
      
      final whereClause = whereClauses.isEmpty 
          ? null 
          : whereClauses.join(' AND ');
      
      final result = await db.query(
        'social_aides',
        where: whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
      );
      
      final totalAides = result.length;
      final totalMontant = result.fold<double>(
        0.0,
        (sum, map) => sum + ((map['montant'] as num).toDouble()),
      );
      
      // Compter par statut
      final parStatut = <String, int>{};
      for (var map in result) {
        final statut = map['statut'] as String;
        parStatut[statut] = (parStatut[statut] ?? 0) + 1;
      }
      
      // Compter les remboursables
      final aidesRemboursables = result.where((map) {
        // TODO: Joindre avec social_aide_types pour vérifier est_remboursable
        return true; // Placeholder
      }).length;
      
      return {
        'total_aides': totalAides,
        'total_montant': totalMontant,
        'par_statut': parStatut,
        'aides_remboursables': aidesRemboursables,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  // ==================== HELPERS PRIVÉS ====================

  /// Logger l'historique d'une aide
  Future<void> _logAideHistory({
    required int aideId,
    required String action,
    required int changedBy,
    String? oldStatut,
    String? newStatut,
    double? oldMontant,
    double? newMontant,
    String? details,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.insert('social_aide_history', {
        'aide_id': aideId,
        'action': action,
        'old_statut': oldStatut,
        'new_statut': newStatut,
        'old_montant': oldMontant,
        'new_montant': newMontant,
        'details': details,
        'changed_by': changedBy,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erreur lors du logging de l\'historique: $e');
      // Ne pas faire échouer l'opération principale
    }
  }
}
