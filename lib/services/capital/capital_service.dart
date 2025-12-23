import '../../data/models/part_sociale_model.dart';
import '../../services/database/db_initializer.dart';
import '../auth/audit_service.dart';

/// Service pour la gestion du capital social
class CapitalService {
  final AuditService _auditService = AuditService();

  /// Créer des parts sociales pour un adhérent
  Future<PartSocialeModel> createPartsSociales({
    required int adherentId,
    required int nombreParts,
    required double valeurUnitaire,
    required DateTime dateAcquisition,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    final partSociale = PartSocialeModel(
      adherentId: adherentId,
      nombreParts: nombreParts,
      valeurUnitaire: valeurUnitaire,
      dateAcquisition: dateAcquisition,
      statut: 'actif',
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    final id = await db.insert('parts_sociales', partSociale.toMap());
    
    // Audit
    await _auditService.logAction(
      userId: createdBy,
      action: 'create_parts_sociales',
      entityType: 'part_sociale',
      entityId: id,
      details: 'Création de $nombreParts parts pour adhérent ID: $adherentId',
    );

    return partSociale.copyWith(id: id);
  }

  /// Récupérer toutes les parts d'un adhérent
  Future<List<PartSocialeModel>> getPartsByAdherent(int adherentId) async {
    final db = await DatabaseInitializer.database;
    final result = await db.query(
      'parts_sociales',
      where: 'adherent_id = ?',
      whereArgs: [adherentId],
      orderBy: 'date_acquisition DESC',
    );
    
    return result.map((map) => PartSocialeModel.fromMap(map)).toList();
  }

  /// Récupérer les parts actives d'un adhérent
  Future<List<PartSocialeModel>> getActivePartsByAdherent(int adherentId) async {
    final db = await DatabaseInitializer.database;
    final result = await db.query(
      'parts_sociales',
      where: 'adherent_id = ? AND statut = ?',
      whereArgs: [adherentId, 'actif'],
      orderBy: 'date_acquisition DESC',
    );
    
    return result.map((map) => PartSocialeModel.fromMap(map)).toList();
  }

  /// Céder des parts sociales
  Future<PartSocialeModel> cederParts({
    required int partSocialeId,
    required DateTime dateCession,
    required int updatedBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    await db.update(
      'parts_sociales',
      {
        'statut': 'cede',
        'date_cession': dateCession.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [partSocialeId],
    );
    
    // Audit
    await _auditService.logAction(
      userId: updatedBy,
      action: 'cede_parts_sociales',
      entityType: 'part_sociale',
      entityId: partSocialeId,
      details: 'Cession de parts sociales ID: $partSocialeId',
    );
    
    final result = await db.query(
      'parts_sociales',
      where: 'id = ?',
      whereArgs: [partSocialeId],
      limit: 1,
    );
    
    return PartSocialeModel.fromMap(result.first);
  }

  /// Obtenir le résumé du capital social
  Future<CapitalSocialSummary> getCapitalSocialSummary() async {
    final db = await DatabaseInitializer.database;
    
    // Total des parts actives
    final partsResult = await db.rawQuery('''
      SELECT 
        SUM(nombre_parts) as total_parts,
        AVG(valeur_unitaire) as valeur_moyenne,
        COUNT(DISTINCT adherent_id) as nombre_actionnaires
      FROM parts_sociales
      WHERE statut = 'actif'
    ''');
    
    final totalParts = (partsResult.first['total_parts'] as num?)?.toInt() ?? 0;
    final valeurMoyenne = (partsResult.first['valeur_moyenne'] as num?)?.toDouble() ?? 0.0;
    final nombreActionnaires = partsResult.first['nombre_actionnaires'] as int? ?? 0;
    
    // Calculer le capital total
    final capitalResult = await db.rawQuery('''
      SELECT SUM(nombre_parts * valeur_unitaire) as capital_total
      FROM parts_sociales
      WHERE statut = 'actif'
    ''');
    
    final capitalTotal = (capitalResult.first['capital_total'] as num?)?.toDouble() ?? 0.0;
    
    // Nombre de parts actives
    final partsActivesResult = await db.rawQuery('''
      SELECT SUM(nombre_parts) as parts_actives
      FROM parts_sociales
      WHERE statut = 'actif'
    ''');
    
    final nombrePartsActives = (partsActivesResult.first['parts_actives'] as num?)?.toInt() ?? 0;
    
    return CapitalSocialSummary(
      totalParts: totalParts,
      valeurUnitaire: valeurMoyenne,
      capitalTotal: capitalTotal,
      nombreActionnaires: nombreActionnaires,
      nombrePartsActives: nombrePartsActives,
    );
  }

  /// Obtenir le nombre de parts d'un adhérent
  Future<int> getNombrePartsAdherent(int adherentId) async {
    final parts = await getActivePartsByAdherent(adherentId);
    return parts.fold<int>(0, (sum, part) => sum + part.nombreParts);
  }

  /// Obtenir la valeur totale des parts d'un adhérent
  Future<double> getValeurTotalePartsAdherent(int adherentId) async {
    final parts = await getActivePartsByAdherent(adherentId);
    return parts.fold<double>(0.0, (sum, part) => sum + part.valeurTotale);
  }
}

