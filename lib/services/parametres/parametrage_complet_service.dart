/// Service complet de paramétrage pour toutes les entités
import 'package:sqflite_common/sqlite_api.dart';
import '../database/db_initializer.dart';
import '../auth/audit_service.dart';
import '../../data/models/parametrage_models.dart';

class ParametrageCompletService {
  final AuditService _auditService = AuditService();

  // ============================================
  // 1. PARAMÉTRAGE DE L'ENTITÉ (COOPÉRATIVE)
  // ============================================

  /// Obtenir l'entité coopérative
  Future<CooperativeEntityModel?> getCooperativeEntity() async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query('cooperative_entity', limit: 1);
      if (result.isEmpty) return null;
      return CooperativeEntityModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'entité: $e');
    }
  }

  /// Créer ou mettre à jour l'entité coopérative
  Future<CooperativeEntityModel> saveCooperativeEntity({
    required CooperativeEntityModel entity,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final existing = await getCooperativeEntity();

      if (existing != null) {
        await db.update(
          'cooperative_entity',
          entity.copyWith(updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        await _auditService.logAction(
          userId: userId,
          action: 'UPDATE_COOPERATIVE_ENTITY',
          entityType: 'cooperative_entity',
          entityId: existing.id,
          details: 'Mise à jour de l\'entité coopérative',
        );
        return (await getCooperativeEntity())!;
      } else {
        final id = await db.insert('cooperative_entity', entity.toMap());
        await _auditService.logAction(
          userId: userId,
          action: 'CREATE_COOPERATIVE_ENTITY',
          entityType: 'cooperative_entity',
          entityId: id,
          details: 'Création de l\'entité coopérative',
        );
        return entity.copyWith(id: id);
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  // ============================================
  // 2. PARAMÉTRAGE ORGANISATIONNEL
  // ============================================

  /// Sections
  Future<List<SectionModel>> getAllSections({bool? isActive}) async {
    try {
      final db = await DatabaseInitializer.database;
      String? where;
      List<dynamic>? whereArgs;
      if (isActive != null) {
        where = 'is_active = ?';
        whereArgs = [isActive ? 1 : 0];
      }
      final result = await db.query('sections', where: where, whereArgs: whereArgs, orderBy: 'nom');
      return result.map((m) => SectionModel.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des sections: $e');
    }
  }

  Future<SectionModel> createSection({
    required SectionModel section,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final id = await db.insert('sections', section.toMap());
      await _auditService.logAction(
        userId: userId,
        action: 'CREATE_SECTION',
        entityType: 'sections',
        entityId: id,
        details: 'Création de la section: ${section.nom}',
      );
      return section.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  Future<SectionModel> updateSection({
    required int id,
    required SectionModel section,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.update(
        'sections',
        section.copyWith(id: id, updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await _auditService.logAction(
        userId: userId,
        action: 'UPDATE_SECTION',
        entityType: 'sections',
        entityId: id,
        details: 'Mise à jour de la section',
      );
      final result = await db.query('sections', where: 'id = ?', whereArgs: [id], limit: 1);
      return SectionModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<bool> deleteSection(int id, int userId) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.delete('sections', where: 'id = ?', whereArgs: [id]);
      await _auditService.logAction(
        userId: userId,
        action: 'DELETE_SECTION',
        entityType: 'sections',
        entityId: id,
        details: 'Suppression de la section',
      );
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Sites
  Future<List<SiteModel>> getAllSites({int? sectionId, bool? isActive}) async {
    try {
      final db = await DatabaseInitializer.database;
      String? where;
      List<dynamic>? whereArgs = [];
      if (sectionId != null) {
        where = 'section_id = ?';
        whereArgs.add(sectionId);
      }
      if (isActive != null) {
        where = where != null ? '$where AND is_active = ?' : 'is_active = ?';
        whereArgs.add(isActive ? 1 : 0);
      }
      final result = await db.query('sites', where: where, whereArgs: whereArgs.isEmpty ? null : whereArgs, orderBy: 'nom');
      return result.map((m) => SiteModel.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des sites: $e');
    }
  }

  Future<SiteModel> createSite({
    required SiteModel site,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final id = await db.insert('sites', site.toMap());
      await _auditService.logAction(
        userId: userId,
        action: 'CREATE_SITE',
        entityType: 'sites',
        entityId: id,
        details: 'Création du site: ${site.nom}',
      );
      return site.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  Future<SiteModel> updateSite({
    required int id,
    required SiteModel site,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.update(
        'sites',
        site.copyWith(id: id, updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await _auditService.logAction(
        userId: userId,
        action: 'UPDATE_SITE',
        entityType: 'sites',
        entityId: id,
        details: 'Mise à jour du site',
      );
      final result = await db.query('sites', where: 'id = ?', whereArgs: [id], limit: 1);
      return SiteModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<bool> deleteSite(int id, int userId) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.delete('sites', where: 'id = ?', whereArgs: [id]);
      await _auditService.logAction(
        userId: userId,
        action: 'DELETE_SITE',
        entityType: 'sites',
        entityId: id,
        details: 'Suppression du site',
      );
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Magasins
  Future<List<MagasinModel>> getAllMagasins({int? siteId, bool? isActive}) async {
    try {
      final db = await DatabaseInitializer.database;
      String? where;
      List<dynamic>? whereArgs = [];
      if (siteId != null) {
        where = 'site_id = ?';
        whereArgs.add(siteId);
      }
      if (isActive != null) {
        where = where != null ? '$where AND is_active = ?' : 'is_active = ?';
        whereArgs.add(isActive ? 1 : 0);
      }
      final result = await db.query('magasins', where: where, whereArgs: whereArgs.isEmpty ? null : whereArgs, orderBy: 'nom');
      return result.map((m) => MagasinModel.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des magasins: $e');
    }
  }

  Future<MagasinModel> createMagasin({
    required MagasinModel magasin,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final id = await db.insert('magasins', magasin.toMap());
      await _auditService.logAction(
        userId: userId,
        action: 'CREATE_MAGASIN',
        entityType: 'magasins',
        entityId: id,
        details: 'Création du magasin: ${magasin.nom}',
      );
      return magasin.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  Future<MagasinModel> updateMagasin({
    required int id,
    required MagasinModel magasin,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.update(
        'magasins',
        magasin.copyWith(id: id, updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await _auditService.logAction(
        userId: userId,
        action: 'UPDATE_MAGASIN',
        entityType: 'magasins',
        entityId: id,
        details: 'Mise à jour du magasin',
      );
      final result = await db.query('magasins', where: 'id = ?', whereArgs: [id], limit: 1);
      return MagasinModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<bool> deleteMagasin(int id, int userId) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.delete('magasins', where: 'id = ?', whereArgs: [id]);
      await _auditService.logAction(
        userId: userId,
        action: 'DELETE_MAGASIN',
        entityType: 'magasins',
        entityId: id,
        details: 'Suppression du magasin',
      );
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Comités
  Future<List<ComiteModel>> getAllComites({bool? isActive}) async {
    try {
      final db = await DatabaseInitializer.database;
      String? where;
      List<dynamic>? whereArgs;
      if (isActive != null) {
        where = 'is_active = ?';
        whereArgs = [isActive ? 1 : 0];
      }
      final result = await db.query('comites', where: where, whereArgs: whereArgs, orderBy: 'nom');
      return result.map((m) => ComiteModel.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des comités: $e');
    }
  }

  Future<ComiteModel> createComite({
    required ComiteModel comite,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final id = await db.insert('comites', comite.toMap());
      await _auditService.logAction(
        userId: userId,
        action: 'CREATE_COMITE',
        entityType: 'comites',
        entityId: id,
        details: 'Création du comité: ${comite.nom}',
      );
      return comite.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  Future<ComiteModel> updateComite({
    required int id,
    required ComiteModel comite,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.update(
        'comites',
        comite.copyWith(id: id, updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await _auditService.logAction(
        userId: userId,
        action: 'UPDATE_COMITE',
        entityType: 'comites',
        entityId: id,
        details: 'Mise à jour du comité',
      );
      final result = await db.query('comites', where: 'id = ?', whereArgs: [id], limit: 1);
      return ComiteModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<bool> deleteComite(int id, int userId) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.delete('comites', where: 'id = ?', whereArgs: [id]);
      await _auditService.logAction(
        userId: userId,
        action: 'DELETE_COMITE',
        entityType: 'comites',
        entityId: id,
        details: 'Suppression du comité',
      );
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // ============================================
  // 3. PARAMÉTRAGE MÉTIER
  // ============================================

  /// Produits
  Future<List<ProduitModel>> getAllProduits({bool? isActive}) async {
    try {
      final db = await DatabaseInitializer.database;
      String? where;
      List<dynamic>? whereArgs;
      if (isActive != null) {
        where = 'is_active = ?';
        whereArgs = [isActive ? 1 : 0];
      }
      final result = await db.query('produits', where: where, whereArgs: whereArgs, orderBy: 'nom_produit');
      return result.map((m) => ProduitModel.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des produits: $e');
    }
  }

  Future<ProduitModel> createProduit({
    required ProduitModel produit,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final id = await db.insert('produits', produit.toMap());
      await _auditService.logAction(
        userId: userId,
        action: 'CREATE_PRODUIT',
        entityType: 'produits',
        entityId: id,
        details: 'Création du produit: ${produit.nomProduit}',
      );
      return produit.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  Future<ProduitModel> updateProduit({
    required int id,
    required ProduitModel produit,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.update(
        'produits',
        produit.copyWith(id: id, updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await _auditService.logAction(
        userId: userId,
        action: 'UPDATE_PRODUIT',
        entityType: 'produits',
        entityId: id,
        details: 'Mise à jour du produit',
      );
      final result = await db.query('produits', where: 'id = ?', whereArgs: [id], limit: 1);
      return ProduitModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<bool> deleteProduit(int id, int userId) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.delete('produits', where: 'id = ?', whereArgs: [id]);
      await _auditService.logAction(
        userId: userId,
        action: 'DELETE_PRODUIT',
        entityType: 'produits',
        entityId: id,
        details: 'Suppression du produit',
      );
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Prix Marché
  Future<List<PrixMarcheModel>> getAllPrixMarche({int? produitId, bool? isActive}) async {
    try {
      final db = await DatabaseInitializer.database;
      String? where;
      List<dynamic>? whereArgs = [];
      if (produitId != null) {
        where = 'produit_id = ?';
        whereArgs.add(produitId);
      }
      if (isActive != null) {
        where = where != null ? '$where AND is_active = ?' : 'is_active = ?';
        whereArgs.add(isActive ? 1 : 0);
      }
      final result = await db.query('prix_marche', where: where, whereArgs: whereArgs.isEmpty ? null : whereArgs, orderBy: 'created_at DESC');
      return result.map((m) => PrixMarcheModel.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des prix: $e');
    }
  }

  Future<PrixMarcheModel> createPrixMarche({
    required PrixMarcheModel prix,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final id = await db.insert('prix_marche', prix.toMap());
      await _auditService.logAction(
        userId: userId,
        action: 'CREATE_PRIX_MARCHE',
        entityType: 'prix_marche',
        entityId: id,
        details: 'Création d\'un prix marché',
      );
      return prix.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  Future<PrixMarcheModel> updatePrixMarche({
    required int id,
    required PrixMarcheModel prix,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.update(
        'prix_marche',
        prix.copyWith(id: id, updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await _auditService.logAction(
        userId: userId,
        action: 'UPDATE_PRIX_MARCHE',
        entityType: 'prix_marche',
        entityId: id,
        details: 'Mise à jour du prix marché',
      );
      final result = await db.query('prix_marche', where: 'id = ?', whereArgs: [id], limit: 1);
      return PrixMarcheModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<bool> deletePrixMarche(int id, int userId) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.delete('prix_marche', where: 'id = ?', whereArgs: [id]);
      await _auditService.logAction(
        userId: userId,
        action: 'DELETE_PRIX_MARCHE',
        entityType: 'prix_marche',
        entityId: id,
        details: 'Suppression du prix marché',
      );
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // ============================================
  // 4. PARAMÉTRAGE FINANCIER & COMPTABLE
  // ============================================

  /// Capital Social
  Future<CapitalSocialModel?> getCapitalSocial() async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query('capital_social', limit: 1);
      if (result.isEmpty) return null;
      return CapitalSocialModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  Future<CapitalSocialModel> saveCapitalSocial({
    required CapitalSocialModel capital,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final existing = await getCapitalSocial();
      if (existing != null) {
        await db.update(
          'capital_social',
          capital.copyWith(id: existing.id, updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        await _auditService.logAction(
          userId: userId,
          action: 'UPDATE_CAPITAL_SOCIAL',
          entityType: 'capital_social',
          entityId: existing.id,
          details: 'Mise à jour du capital social',
        );
        return (await getCapitalSocial())!;
      } else {
        final id = await db.insert('capital_social', capital.toMap());
        await _auditService.logAction(
          userId: userId,
          action: 'CREATE_CAPITAL_SOCIAL',
          entityType: 'capital_social',
          entityId: id,
          details: 'Création du capital social',
        );
        return capital.copyWith(id: id);
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Paramètres Comptables
  Future<ParametresComptablesModel?> getParametresComptables() async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query('parametres_comptables', limit: 1);
      if (result.isEmpty) return null;
      return ParametresComptablesModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  Future<ParametresComptablesModel> saveParametresComptables({
    required ParametresComptablesModel parametres,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final existing = await getParametresComptables();
      if (existing != null) {
        await db.update(
          'parametres_comptables',
          parametres.copyWith(id: existing.id, updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        await _auditService.logAction(
          userId: userId,
          action: 'UPDATE_PARAMETRES_COMPTABLES',
          entityType: 'parametres_comptables',
          entityId: existing.id,
          details: 'Mise à jour des paramètres comptables',
        );
        return (await getParametresComptables())!;
      } else {
        final id = await db.insert('parametres_comptables', parametres.toMap());
        await _auditService.logAction(
          userId: userId,
          action: 'CREATE_PARAMETRES_COMPTABLES',
          entityType: 'parametres_comptables',
          entityId: id,
          details: 'Création des paramètres comptables',
        );
        return parametres.copyWith(id: id);
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Retenues
  Future<List<RetenueModel>> getAllRetenues({bool? isActive}) async {
    try {
      final db = await DatabaseInitializer.database;
      String? where;
      List<dynamic>? whereArgs;
      if (isActive != null) {
        where = 'is_active = ?';
        whereArgs = [isActive ? 1 : 0];
      }
      final result = await db.query('retenues', where: where, whereArgs: whereArgs, orderBy: 'type_retenue');
      return result.map((m) => RetenueModel.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des retenues: $e');
    }
  }

  Future<RetenueModel> createRetenue({
    required RetenueModel retenue,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final id = await db.insert('retenues', retenue.toMap());
      await _auditService.logAction(
        userId: userId,
        action: 'CREATE_RETENUE',
        entityType: 'retenues',
        entityId: id,
        details: 'Création de la retenue: ${retenue.typeRetenue}',
      );
      return retenue.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  Future<RetenueModel> updateRetenue({
    required int id,
    required RetenueModel retenue,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.update(
        'retenues',
        retenue.copyWith(id: id, updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      await _auditService.logAction(
        userId: userId,
        action: 'UPDATE_RETENUE',
        entityType: 'retenues',
        entityId: id,
        details: 'Mise à jour de la retenue',
      );
      final result = await db.query('retenues', where: 'id = ?', whereArgs: [id], limit: 1);
      return RetenueModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  Future<bool> deleteRetenue(int id, int userId) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.delete('retenues', where: 'id = ?', whereArgs: [id]);
      await _auditService.logAction(
        userId: userId,
        action: 'DELETE_RETENUE',
        entityType: 'retenues',
        entityId: id,
        details: 'Suppression de la retenue',
      );
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // ============================================
  // 5. PARAMÉTRAGE COMMERCIAL
  // ============================================

  /// Paramètres Documents
  Future<ParametresDocumentsModel?> getParametresDocuments() async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query('parametres_documents', limit: 1);
      if (result.isEmpty) return null;
      return ParametresDocumentsModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  Future<ParametresDocumentsModel> saveParametresDocuments({
    required ParametresDocumentsModel parametres,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final existing = await getParametresDocuments();
      if (existing != null) {
        await db.update(
          'parametres_documents',
          parametres.copyWith(id: existing.id, updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        await _auditService.logAction(
          userId: userId,
          action: 'UPDATE_PARAMETRES_DOCUMENTS',
          entityType: 'parametres_documents',
          entityId: existing.id,
          details: 'Mise à jour des paramètres documents',
        );
        return (await getParametresDocuments())!;
      } else {
        final id = await db.insert('parametres_documents', parametres.toMap());
        await _auditService.logAction(
          userId: userId,
          action: 'CREATE_PARAMETRES_DOCUMENTS',
          entityType: 'parametres_documents',
          entityId: id,
          details: 'Création des paramètres documents',
        );
        return parametres.copyWith(id: id);
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  // ============================================
  // 6. PARAMÉTRAGE SÉCURITÉ
  // ============================================

  /// Paramètres Sécurité
  Future<ParametresSecuriteModel?> getParametresSecurite() async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query('parametres_securite', limit: 1);
      if (result.isEmpty) return null;
      return ParametresSecuriteModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  Future<ParametresSecuriteModel> saveParametresSecurite({
    required ParametresSecuriteModel parametres,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final existing = await getParametresSecurite();
      if (existing != null) {
        await db.update(
          'parametres_securite',
          parametres.copyWith(id: existing.id, updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        await _auditService.logAction(
          userId: userId,
          action: 'UPDATE_PARAMETRES_SECURITE',
          entityType: 'parametres_securite',
          entityId: existing.id,
          details: 'Mise à jour des paramètres sécurité',
        );
        return (await getParametresSecurite())!;
      } else {
        final id = await db.insert('parametres_securite', parametres.toMap());
        await _auditService.logAction(
          userId: userId,
          action: 'CREATE_PARAMETRES_SECURITE',
          entityType: 'parametres_securite',
          entityId: id,
          details: 'Création des paramètres sécurité',
        );
        return parametres.copyWith(id: id);
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  // ============================================
  // 7. PARAMÉTRAGE IA & ANALYTIQUE
  // ============================================

  /// Paramètres IA
  Future<ParametresIAModel?> getParametresIA() async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query('parametres_ia', limit: 1);
      if (result.isEmpty) return null;
      return ParametresIAModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  Future<ParametresIAModel> saveParametresIA({
    required ParametresIAModel parametres,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final existing = await getParametresIA();
      if (existing != null) {
        await db.update(
          'parametres_ia',
          parametres.copyWith(id: existing.id, updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        await _auditService.logAction(
          userId: userId,
          action: 'UPDATE_PARAMETRES_IA',
          entityType: 'parametres_ia',
          entityId: existing.id,
          details: 'Mise à jour des paramètres IA',
        );
        return (await getParametresIA())!;
      } else {
        final id = await db.insert('parametres_ia', parametres.toMap());
        await _auditService.logAction(
          userId: userId,
          action: 'CREATE_PARAMETRES_IA',
          entityType: 'parametres_ia',
          entityId: id,
          details: 'Création des paramètres IA',
        );
        return parametres.copyWith(id: id);
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  // ============================================
  // 8. TABLE DE PARAMÉTRAGE GÉNÉRIQUE (SETTINGS)
  // ============================================

  /// Obtenir un setting par catégorie et clé
  Future<SettingModel?> getSetting(String category, String key) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'settings',
        where: 'category = ? AND key = ?',
        whereArgs: [category, key],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return SettingModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Obtenir tous les settings d'une catégorie
  Future<List<SettingModel>> getSettingsByCategory(String category) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'settings',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'key',
      );
      return result.map((m) => SettingModel.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Créer ou mettre à jour un setting
  Future<SettingModel> saveSetting({
    required SettingModel setting,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final existing = await getSetting(setting.category, setting.key);
      
      if (existing != null) {
        if (!existing.editable) {
          throw Exception('Ce paramètre n\'est pas modifiable');
        }
        await db.update(
          'settings',
          setting.copyWith(id: existing.id, updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        await _auditService.logAction(
          userId: userId,
          action: 'UPDATE_SETTING',
          entityType: 'settings',
          entityId: existing.id,
          details: 'Mise à jour du setting: ${setting.category}.${setting.key}',
        );
        return (await getSetting(setting.category, setting.key))!;
      } else {
        final id = await db.insert('settings', setting.toMap());
        await _auditService.logAction(
          userId: userId,
          action: 'CREATE_SETTING',
          entityType: 'settings',
          entityId: id,
          details: 'Création du setting: ${setting.category}.${setting.key}',
        );
        return setting.copyWith(id: id);
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Supprimer un setting
  Future<bool> deleteSetting(String category, String key, int userId) async {
    try {
      final db = await DatabaseInitializer.database;
      final setting = await getSetting(category, key);
      if (setting == null) return false;
      if (!setting.editable) {
        throw Exception('Ce paramètre ne peut pas être supprimé');
      }
      await db.delete(
        'settings',
        where: 'category = ? AND key = ?',
        whereArgs: [category, key],
      );
      await _auditService.logAction(
        userId: userId,
        action: 'DELETE_SETTING',
        entityType: 'settings',
        entityId: setting.id,
        details: 'Suppression du setting: $category.$key',
      );
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}

