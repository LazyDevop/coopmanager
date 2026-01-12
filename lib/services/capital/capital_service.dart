import '../database/db_initializer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../data/models/capital_social_model.dart';
import '../auth/audit_service.dart';

/// Service principal pour la gestion du capital social
class CapitalService {
  final AuditService _auditService = AuditService();

  static const String _partsValeursTable = 'parts_sociales_valeurs';

  /// Obtenir la valeur actuelle d'une part sociale
  Future<double> getValeurPartActuelle() async {
    final db = await DatabaseInitializer.database;

    List<Map<String, Object?>> result;
    try {
      result = await db.query(
        _partsValeursTable,
        where: 'active = 1',
        orderBy: 'date_effet DESC',
        limit: 1,
      );
    } catch (e) {
      // Base existante: la table peut être absente (ancienne version)
      if (e.toString().contains('no such table') &&
          e.toString().contains(_partsValeursTable)) {
        await _ensurePartsValeursTable(db);
        result = await db.query(
          _partsValeursTable,
          where: 'active = 1',
          orderBy: 'date_effet DESC',
          limit: 1,
        );
      } else {
        rethrow;
      }
    }

    if (result.isEmpty) {
      // Valeur par défaut si aucune part n'est définie
      return 5000.0;
    }

    return (result.first['valeur_part'] as num).toDouble();
  }

  Future<void> _ensurePartsValeursTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_partsValeursTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valeur_part REAL NOT NULL,
        devise TEXT NOT NULL DEFAULT 'FCFA',
        date_effet TEXT NOT NULL,
        active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        created_by INTEGER,
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');

    final activeRow = await db.query(
      _partsValeursTable,
      columns: ['id'],
      where: 'active = 1',
      limit: 1,
    );
    if (activeRow.isEmpty) {
      await db.insert(_partsValeursTable, {
        'valeur_part': 5000.0,
        'devise': 'FCFA',
        'date_effet': DateTime.now().toIso8601String(),
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
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
      await db.update(_partsValeursTable, {'active': 0}, where: 'active = 1');

      // Créer la nouvelle valeur
      final part = PartSocialeModel(
        valeurPart: valeurPart,
        devise: 'FCFA',
        dateEffet: dateEffet,
        active: true,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      final id = await db.insert(_partsValeursTable, part.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'DEFINE_PART_VALUE',
        entityType: _partsValeursTable,
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

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(montant_souscrit), 0) as total
      FROM souscriptions_capital
      WHERE statut != ?
    ''',
      [SouscriptionCapitalModel.statutAnnule],
    );

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

    final result = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT actionnaire_id) as total
      FROM souscriptions_capital
      WHERE statut != ?
    ''',
      [SouscriptionCapitalModel.statutAnnule],
    );

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
