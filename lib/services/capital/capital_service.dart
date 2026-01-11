import '../database/db_initializer.dart';
import '../../data/models/capital_social_model.dart';
import '../auth/audit_service.dart';

/// Service principal pour la gestion du capital social
class CapitalService {
  final AuditService _auditService = AuditService();

  /// Obtenir la valeur actuelle d'une part sociale
  Future<double> getValeurPartActuelle() async {
    final db = await DatabaseInitializer.database;
    
    final result = await db.query(
      'parts_sociales',
      where: 'active = 1',
      orderBy: 'date_effet DESC',
      limit: 1,
    );
    
    if (result.isEmpty) {
      // Valeur par défaut si aucune part n'est définie
      return 5000.0;
    }
    
    return (result.first['valeur_part'] as num).toDouble();
  }

  /// Définir une nouvelle valeur de part
  Future<PartSocialeModel> definirValeurPart({
    required double valeurPart,
    required DateTime dateEffet,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      // Désactiver toutes les parts précédentes
      await db.update(
        'parts_sociales',
        {'active': 0},
        where: 'active = 1',
      );
      
      // Créer la nouvelle valeur
      final part = PartSocialeModel(
        valeurPart: valeurPart,
        devise: 'FCFA',
        dateEffet: dateEffet,
        active: true,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );
      
      final id = await db.insert('parts_sociales', part.toMap());
      
      await _auditService.logAction(
        userId: createdBy,
        action: 'DEFINE_PART_VALUE',
        entityType: 'parts_sociales',
        entityId: id,
        details: 'Nouvelle valeur de part définie: $valeurPart FCFA',
      );
      
      return part.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la définition de la valeur: $e');
    }
  }

  /// Calculer le capital social total (souscrit)
  Future<double> getCapitalSocialTotal() async {
    final db = await DatabaseInitializer.database;
    
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(montant_souscrit), 0) as total
      FROM souscriptions_capital
      WHERE statut != ?
    ''', [SouscriptionCapitalModel.statutAnnule]);
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Calculer le capital libéré total
  Future<double> getCapitalLibereTotal() async {
    final db = await DatabaseInitializer.database;
    
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(montant_libere), 0) as total
      FROM liberations_capital
    ''');
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Calculer le capital restant à libérer
  Future<double> getCapitalRestantTotal() async {
    final capitalSouscrit = await getCapitalSocialTotal();
    final capitalLibere = await getCapitalLibereTotal();
    return capitalSouscrit - capitalLibere;
  }

  /// Obtenir le nombre total d'actionnaires actifs
  Future<int> getNombreActionnaires() async {
    final db = await DatabaseInitializer.database;
    
    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT actionnaire_id) as total
      FROM souscriptions_capital
      WHERE statut != ?
    ''', [SouscriptionCapitalModel.statutAnnule]);
    
    return result.first['total'] as int? ?? 0;
  }

  /// Obtenir les statistiques complètes du capital social
  Future<Map<String, dynamic>> getStatistiquesCapital() async {
    final capitalSouscrit = await getCapitalSocialTotal();
    final capitalLibere = await getCapitalLibereTotal();
    final capitalRestant = capitalSouscrit - capitalLibere;
    final nombreActionnaires = await getNombreActionnaires();
    final valeurPart = await getValeurPartActuelle();
    
    double pourcentageLiberation = 0.0;
    if (capitalSouscrit > 0) {
      pourcentageLiberation = (capitalLibere / capitalSouscrit) * 100;
    }
    
    return {
      'capital_souscrit': capitalSouscrit,
      'capital_libere': capitalLibere,
      'capital_restant': capitalRestant,
      'nombre_actionnaires': nombreActionnaires,
      'valeur_part': valeurPart,
      'pourcentage_liberation': pourcentageLiberation,
    };
  }
}
