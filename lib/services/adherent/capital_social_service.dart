import 'package:sqflite_common/sqlite_api.dart';
import '../database/db_initializer.dart';
import '../../data/models/adherent_expert/capital_social_model.dart';
import '../auth/audit_service.dart';

/// Service pour gérer le capital social des adhérents
class CapitalSocialService {
  final AuditService _auditService = AuditService();

  static const String _table = 'capital_social_expert';

  Future<void> _ensureCapitalSocialExpertSchema(Database db) async {
    try {
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_table'",
      );

      if (tableExists.isEmpty) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            adherent_id INTEGER NOT NULL,
            nombre_parts_souscrites INTEGER NOT NULL,
            nombre_parts_liberees INTEGER DEFAULT 0,
            nombre_parts_restantes INTEGER NOT NULL,
            valeur_part REAL NOT NULL,
            capital_total REAL NOT NULL,
            date_souscription TEXT NOT NULL,
            date_liberation TEXT,
            statut TEXT DEFAULT 'souscrit',
            notes TEXT,
            created_at TEXT NOT NULL,
            created_by INTEGER,
            FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
            FOREIGN KEY (created_by) REFERENCES users(id)
          )
        ''');
      }

      final tableInfo = await db.rawQuery('PRAGMA table_info($_table)');
      final columnNames = tableInfo.map((c) => c['name'] as String).toSet();

      Future<void> addColumnIfMissing(String name, String definition) async {
        if (!columnNames.contains(name)) {
          await db.execute('ALTER TABLE $_table ADD COLUMN $name $definition');
        }
      }

      await addColumnIfMissing('nombre_parts_liberees', 'INTEGER DEFAULT 0');
      await addColumnIfMissing('nombre_parts_restantes', 'INTEGER DEFAULT 0');
      await addColumnIfMissing('valeur_part', 'REAL DEFAULT 0');
      await addColumnIfMissing('capital_total', 'REAL DEFAULT 0');
      await addColumnIfMissing('date_liberation', 'TEXT');
      await addColumnIfMissing('statut', "TEXT DEFAULT 'souscrit'");
      await addColumnIfMissing('notes', 'TEXT');
      await addColumnIfMissing('created_at', 'TEXT');
      await addColumnIfMissing('created_by', 'INTEGER');

      // Recalculer les champs dérivés si besoin (ne casse pas si déjà correct)
      await db.execute('''
        UPDATE $_table
        SET nombre_parts_liberees = COALESCE(nombre_parts_liberees, 0)
      ''');

      await db.execute('''
        UPDATE $_table
        SET nombre_parts_restantes =
          CASE
            WHEN nombre_parts_souscrites IS NULL THEN COALESCE(nombre_parts_restantes, 0)
            ELSE MAX(nombre_parts_souscrites - COALESCE(nombre_parts_liberees, 0), 0)
          END
      ''');

      await db.execute('''
        UPDATE $_table
        SET capital_total =
          CASE
            WHEN nombre_parts_souscrites IS NULL THEN COALESCE(capital_total, 0)
            ELSE COALESCE(nombre_parts_souscrites, 0) * COALESCE(valeur_part, 0)
          END
      ''');

      // created_at: remplir si NULL
      await db.execute(
        '''
        UPDATE $_table
        SET created_at = COALESCE(created_at, ?)
      ''',
        [DateTime.now().toIso8601String()],
      );
    } catch (e) {
      // Ne pas faire échouer tout le module; laisser l'erreur remonter au besoin plus tard
      // via les requêtes précises.
      // ignore: avoid_print
      print('⚠️ Schéma capital_social_expert non assuré: $e');
    }
  }

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

      await _ensureCapitalSocialExpertSchema(db);

      if (nombrePartsSouscrites <= 0) {
        throw Exception('Le nombre de parts doit être supérieur à 0');
      }
      if (valeurPart <= 0) {
        throw Exception('La valeur de la part doit être supérieure à 0');
      }

      final capitalTotal = nombrePartsSouscrites * valeurPart;
      const statut = 'souscrit';

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

      final id = await db.insert(_table, souscription.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_CAPITAL_SOCIAL',
        entityType: _table,
        entityId: id,
        details:
            'Création souscription: $nombrePartsSouscrites parts pour adhérent $adherentId',
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

      await _ensureCapitalSocialExpertSchema(db);

      // Récupérer la souscription existante
      final existing = await getSouscriptionById(id);
      if (existing == null) {
        throw Exception('Souscription non trouvée');
      }

      if (nombrePartsALiberer <= 0) {
        throw Exception('Le nombre de parts à libérer doit être supérieur à 0');
      }

      final newNombrePartsLiberees =
          existing.nombrePartsLiberees + nombrePartsALiberer;

      if (newNombrePartsLiberees > existing.nombrePartsSouscrites) {
        throw Exception(
          'Le nombre de parts libérées ne peut pas dépasser le nombre de parts souscrites',
        );
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
        _table,
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'LIBERER_CAPITAL_SOCIAL',
        entityType: _table,
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

      await _ensureCapitalSocialExpertSchema(db);

      // Récupérer la souscription existante
      final existing = await getSouscriptionById(id);
      if (existing == null) {
        throw Exception('Souscription non trouvée');
      }

      final updatedNombrePartsSouscrites =
          nombrePartsSouscrites ?? existing.nombrePartsSouscrites;
      final updatedNombrePartsLiberees =
          nombrePartsLiberees ?? existing.nombrePartsLiberees;
      final updatedValeurPart = valeurPart ?? existing.valeurPart;

      if (updatedNombrePartsLiberees > updatedNombrePartsSouscrites) {
        throw Exception(
          'Le nombre de parts libérées ne peut pas dépasser le nombre de parts souscrites',
        );
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
        _table,
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_CAPITAL_SOCIAL',
        entityType: _table,
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

      await _ensureCapitalSocialExpertSchema(db);

      await db.update(
        _table,
        {'statut': 'annule', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: deletedBy,
        action: 'ANNULER_CAPITAL_SOCIAL',
        entityType: _table,
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

      await _ensureCapitalSocialExpertSchema(db);

      final result = await db.query(
        _table,
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
  Future<List<CapitalSocialModel>> getSouscriptionsByAdherent(
    int adherentId,
  ) async {
    try {
      final db = await DatabaseInitializer.database;

      await _ensureCapitalSocialExpertSchema(db);

      final result = await db.query(
        _table,
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

      await _ensureCapitalSocialExpertSchema(db);

      final result = await db.rawQuery(
        '''
        SELECT 
          COALESCE(SUM(capital_total), 0) as capital_souscrit_total,
          COALESCE(SUM(nombre_parts_liberees * valeur_part), 0) as capital_libere_total,
          COALESCE(SUM(nombre_parts_restantes * valeur_part), 0) as capital_restant_total
        FROM $_table
        WHERE adherent_id = ? AND statut != 'annule'
      ''',
        [adherentId],
      );

      if (result.isEmpty) {
        return {
          'capitalSocialSouscrit': 0.0,
          'capitalSocialLibere': 0.0,
          'capitalSocialRestant': 0.0,
        };
      }

      return {
        'capitalSocialSouscrit':
            (result.first['capital_souscrit_total'] as num?)?.toDouble() ?? 0.0,
        'capitalSocialLibere':
            (result.first['capital_libere_total'] as num?)?.toDouble() ?? 0.0,
        'capitalSocialRestant':
            (result.first['capital_restant_total'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }
}
