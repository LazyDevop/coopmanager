/// Service backend pour la gestion des coopératives avec règles métier
import '../../../data/models/backend/cooperative_model.dart';
import '../repositories/cooperative_repository.dart';
import '../../auth/audit_service.dart';

class CooperativeService {
  final ICooperativeRepository _repository;
  final AuditService _auditService;

  CooperativeService({
    ICooperativeRepository? repository,
    AuditService? auditService,
  })  : _repository = repository ?? CooperativeRepository(),
        _auditService = auditService ?? AuditService();

  /// Obtenir la coopérative active
  Future<CooperativeModel?> getCurrent() async {
    return await _repository.getCurrent();
  }

  /// Obtenir une coopérative par ID
  Future<CooperativeModel?> getById(String id) async {
    return await _repository.getById(id);
  }

  /// Obtenir toutes les coopératives
  Future<List<CooperativeModel>> getAll({CooperativeStatut? statut}) async {
    return await _repository.getAll(statut: statut);
  }

  /// Créer une nouvelle coopérative
  Future<CooperativeModel> create({
    required CooperativeModel cooperative,
    required int userId,
  }) async {
    // Règles métier : Une seule coopérative active à la fois
    if (cooperative.statut == CooperativeStatut.active) {
      final current = await _repository.getCurrent();
      if (current != null) {
        throw Exception('Une coopérative active existe déjà. Désactivez-la d\'abord.');
      }
    }
    
    // Validation des champs obligatoires
    if (cooperative.raisonSociale.isEmpty) {
      throw Exception('La raison sociale est obligatoire');
    }
    
    final created = await _repository.create(cooperative);
    
    await _auditService.logAction(
      userId: userId,
      action: 'CREATE_COOPERATIVE',
      entityType: 'cooperatives',
      entityId: created.id,
      details: 'Création de la coopérative: ${created.raisonSociale}',
    );
    
    return created;
  }

  /// Mettre à jour une coopérative
  Future<CooperativeModel> update({
    required CooperativeModel cooperative,
    required int userId,
  }) async {
    final existing = await _repository.getById(cooperative.id);
    if (existing == null) {
      throw Exception('Coopérative introuvable');
    }
    
    // Règles métier : Une seule coopérative active à la fois
    if (cooperative.statut == CooperativeStatut.active && 
        existing.statut != CooperativeStatut.active) {
      final current = await _repository.getCurrent();
      if (current != null && current.id != cooperative.id) {
        throw Exception('Une coopérative active existe déjà. Désactivez-la d\'abord.');
      }
    }
    
    // Validation
    if (cooperative.raisonSociale.isEmpty) {
      throw Exception('La raison sociale est obligatoire');
    }
    
    final updated = await _repository.update(cooperative);
    
    await _auditService.logAction(
      userId: userId,
      action: 'UPDATE_COOPERATIVE',
      entityType: 'cooperatives',
      entityId: updated.id,
      details: 'Mise à jour de la coopérative: ${updated.raisonSociale}',
    );
    
    return updated;
  }

  /// Supprimer une coopérative
  Future<bool> delete({
    required String id,
    required int userId,
  }) async {
    final cooperative = await _repository.getById(id);
    if (cooperative == null) {
      throw Exception('Coopérative introuvable');
    }
    
    // Règles métier : Ne pas supprimer la coopérative active
    if (cooperative.statut == CooperativeStatut.active) {
      throw Exception('Impossible de supprimer la coopérative active');
    }
    
    final deleted = await _repository.delete(id);
    
    if (deleted) {
      await _auditService.logAction(
        userId: userId,
        action: 'DELETE_COOPERATIVE',
        entityType: 'cooperatives',
        entityId: id,
        details: 'Suppression de la coopérative: ${cooperative.raisonSociale}',
      );
    }
    
    return deleted;
  }

  /// Changer la coopérative active
  Future<bool> setCurrent({
    required String id,
    required int userId,
  }) async {
    final cooperative = await _repository.getById(id);
    if (cooperative == null) {
      throw Exception('Coopérative introuvable');
    }
    
    if (cooperative.statut == CooperativeStatut.suspended) {
      throw Exception('Impossible d\'activer une coopérative suspendue');
    }
    
    final success = await _repository.setCurrent(id);
    
    if (success) {
      await _auditService.logAction(
        userId: userId,
        action: 'SET_CURRENT_COOPERATIVE',
        entityType: 'cooperatives',
        entityId: id,
        details: 'Changement de coopérative active: ${cooperative.raisonSociale}',
      );
    }
    
    return success;
  }

  /// Vérifier si les paramètres obligatoires sont configurés
  Future<bool> validateRequiredSettings(String cooperativeId) async {
    // Vérifier les paramètres obligatoires avant activation d'un module
    // Cette méthode sera utilisée par les autres modules
    // À implémenter selon les besoins spécifiques
    return true;
  }
}

