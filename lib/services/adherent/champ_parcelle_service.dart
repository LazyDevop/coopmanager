import 'package:sqflite_common/sqlite_api.dart';
import '../database/db_initializer.dart';
import '../../data/models/adherent_expert/champ_parcelle_model.dart';
import '../auth/audit_service.dart';

/// Service pour gérer les champs/parcelles des adhérents
class ChampParcelleService {
  final AuditService _auditService = AuditService();

  /// Générer un code unique pour un champ
  Future<String> generateCodeChamp(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;

      // Récupérer le code de l'adhérent
      final adherentResult = await db.query(
        'adherents',
        where: 'id = ?',
        whereArgs: [adherentId],
        limit: 1,
      );

      if (adherentResult.isEmpty) {
        throw Exception('Adhérent non trouvé');
      }

      final adherentCode = adherentResult.first['code'] as String;

      // Compter les champs existants pour cet adhérent
      final countResult = await db.rawQuery(
        '''
        SELECT COUNT(*) as count
        FROM champs_parcelles
        WHERE adherent_id = ? AND is_deleted = 0
      ''',
        [adherentId],
      );

      final count = (countResult.first['count'] as int) ?? 0;
      final nextNumber = count + 1;

      // Format: CH-{CODE_ADHERENT}-{NUMERO}
      return 'CH-$adherentCode-${nextNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      throw Exception('Erreur lors de la génération du code champ: $e');
    }
  }

  /// Créer un champ
  Future<ChampParcelleModel> createChamp({
    required int adherentId,
    String? codeChamp,
    String? nomChamp,
    String? localisation,
    double? latitude,
    double? longitude,
    required double superficie,
    String? typeSol,
    int? anneeMiseEnCulture,
    String etatChamp = 'actif',
    double rendementEstime = 0.0,
    String? campagneAgricole,
    String? varieteCacao,
    int? nombreArbres,
    int? ageMoyenArbres,
    double? densiteArbresAssocies,
    String? systemeIrrigation,
    String? notes,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // S'assurer que toutes les colonnes nécessaires existent
      await _ensureChampsParcellesColumns(db);

      // Générer le code si non fourni
      final finalCodeChamp = codeChamp ?? await generateCodeChamp(adherentId);

      final champ = ChampParcelleModel(
        adherentId: adherentId,
        codeChamp: finalCodeChamp,
        nomChamp: nomChamp,
        localisation: localisation,
        latitude: latitude,
        longitude: longitude,
        superficie: superficie,
        typeSol: typeSol,
        anneeMiseEnCulture: anneeMiseEnCulture,
        etatChamp: etatChamp,
        rendementEstime: rendementEstime,
        campagneAgricole: campagneAgricole,
        varieteCacao: varieteCacao,
        nombreArbres: nombreArbres,
        ageMoyenArbres: ageMoyenArbres,
        systemeIrrigation: systemeIrrigation,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final dataToInsert = champ.toMap();
      print(
        '🔍 Création champ - Paramètres reçus: latitude=$latitude, longitude=$longitude',
      );
      print(
        '🔍 Création champ - Données à insérer: latitude=${dataToInsert['latitude']}, longitude=${dataToInsert['longitude']}',
      );
      print(
        '🔍 Création champ - Modèle: latitude=${champ.latitude}, longitude=${champ.longitude}',
      );

      final id = await db.insert('champs_parcelles', dataToInsert);

      // Vérifier que les données ont bien été sauvegardées
      final verification = await db.query(
        'champs_parcelles',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (verification.isNotEmpty) {
        print('✅ Champ créé avec ID: $id');
        print(
          '🔍 Vérification DB - latitude=${verification.first['latitude']}, longitude=${verification.first['longitude']}',
        );
      }

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_CHAMP',
        entityType: 'champs_parcelles',
        entityId: id,
        details: 'Création champ: $finalCodeChamp pour adhérent $adherentId',
      );

      return champ.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création du champ: $e');
    }
  }

  /// Mettre à jour un champ
  Future<ChampParcelleModel> updateChamp({
    required int id,
    String? nomChamp,
    String? localisation,
    double? latitude,
    double? longitude,
    double? superficie,
    String? typeSol,
    int? anneeMiseEnCulture,
    String? etatChamp,
    double? rendementEstime,
    String? campagneAgricole,
    String? varieteCacao,
    int? nombreArbres,
    int? ageMoyenArbres,
    double? densiteArbresAssocies,
    String? systemeIrrigation,
    String? notes,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // S'assurer que toutes les colonnes nécessaires existent
      await _ensureChampsParcellesColumns(db);

      // Récupérer le champ existant
      final existing = await getChampById(id);
      if (existing == null) {
        throw Exception('Champ non trouvé');
      }

      // Construire directement le Map de mise à jour pour éviter le problème avec copyWith et null
      final dataToUpdate = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        // Toujours inclure latitude et longitude pour s'assurer qu'elles sont mises à jour
        'latitude': latitude,
        'longitude': longitude,
      };

      // Ajouter seulement les champs qui sont fournis (non null)
      if (nomChamp != null) dataToUpdate['nom_champ'] = nomChamp;
      if (localisation != null) dataToUpdate['localisation'] = localisation;
      if (superficie != null) dataToUpdate['superficie'] = superficie;
      if (typeSol != null) dataToUpdate['type_sol'] = typeSol;
      if (anneeMiseEnCulture != null)
        dataToUpdate['annee_mise_en_culture'] = anneeMiseEnCulture;
      if (etatChamp != null) dataToUpdate['etat_champ'] = etatChamp;
      if (rendementEstime != null)
        dataToUpdate['rendement_estime'] = rendementEstime;
      if (campagneAgricole != null)
        dataToUpdate['campagne_agricole'] = campagneAgricole;
      if (varieteCacao != null) dataToUpdate['variete_cacao'] = varieteCacao;
      if (nombreArbres != null) dataToUpdate['nombre_arbres'] = nombreArbres;
      if (ageMoyenArbres != null)
        dataToUpdate['age_moyen_arbres'] = ageMoyenArbres;
      if (densiteArbresAssocies != null)
        dataToUpdate['densite_arbres_associes'] = densiteArbresAssocies;
      if (systemeIrrigation != null)
        dataToUpdate['systeme_irrigation'] = systemeIrrigation;
      if (notes != null) dataToUpdate['notes'] = notes;

      print(
        '🔍 Mise à jour champ ID $id - Paramètres reçus: latitude=$latitude, longitude=$longitude',
      );
      print(
        '🔍 Mise à jour champ - Données à mettre à jour: latitude=${dataToUpdate['latitude']}, longitude=${dataToUpdate['longitude']}',
      );
      print('🔍 Mise à jour champ - Toutes les données: $dataToUpdate');

      print(
        '🔍 Avant db.update - latitude=$latitude (type: ${latitude.runtimeType}), longitude=$longitude (type: ${longitude.runtimeType})',
      );
      print(
        '🔍 dataToUpdate contient: latitude=${dataToUpdate['latitude']}, longitude=${dataToUpdate['longitude']}',
      );

      // Mettre à jour tous les champs, y compris latitude et longitude
      final rowsAffected = await db.update(
        'champs_parcelles',
        dataToUpdate,
        where: 'id = ?',
        whereArgs: [id],
      );

      print('🔍 Mise à jour effectuée - $rowsAffected ligne(s) affectée(s)');

      // Vérifier immédiatement après la mise à jour
      final checkAfterUpdate = await db.rawQuery(
        'SELECT latitude, longitude FROM champs_parcelles WHERE id = ?',
        [id],
      );
      if (checkAfterUpdate.isNotEmpty) {
        print(
          '🔍 Vérification immédiate après update - latitude=${checkAfterUpdate.first['latitude']}, longitude=${checkAfterUpdate.first['longitude']}',
        );
      }

      // Récupérer le champ mis à jour depuis la base de données
      final updated = await getChampById(id);
      if (updated == null) {
        throw Exception('Erreur: champ non trouvé après mise à jour');
      }

      // Vérifier que les données ont bien été mises à jour
      print('✅ Champ mis à jour avec ID: $id');
      print(
        '🔍 Vérification DB - latitude=${updated.latitude}, longitude=${updated.longitude}',
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_CHAMP',
        entityType: 'champs_parcelles',
        entityId: id,
        details: 'Modification champ: ${updated.codeChamp}',
      );

      return updated;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du champ: $e');
    }
  }

  /// Supprimer un champ (suppression logique)
  Future<void> deleteChamp(int id, int deletedBy) async {
    try {
      final db = await DatabaseInitializer.database;

      await db.update(
        'champs_parcelles',
        {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: deletedBy,
        action: 'DELETE_CHAMP',
        entityType: 'champs_parcelles',
        entityId: id,
        details: 'Suppression champ $id',
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression du champ: $e');
    }
  }

  /// Récupérer un champ par ID
  Future<ChampParcelleModel?> getChampById(int id) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.query(
        'champs_parcelles',
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return ChampParcelleModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du champ: $e');
    }
  }

  /// Récupérer tous les champs d'un adhérent
  Future<List<ChampParcelleModel>> getChampsByAdherent(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;

      // S'assurer que toutes les colonnes nécessaires existent
      await _ensureChampsParcellesColumns(db);

      // Récupérer explicitement toutes les colonnes, y compris latitude et longitude
      final result = await db.query(
        'champs_parcelles',
        columns: [
          'id',
          'adherent_id',
          'code_champ',
          'nom_champ',
          'localisation',
          'latitude',
          'longitude',
          'superficie',
          'type_sol',
          'annee_mise_en_culture',
          'etat_champ',
          'rendement_estime',
          'campagne_agricole',
          'variete_cacao',
          'nombre_arbres',
          'age_moyen_arbres',
          'densite_arbres_associes',
          'systeme_irrigation',
          'notes',
          'created_at',
          'updated_at',
          'is_deleted',
        ],
        where: 'adherent_id = ? AND is_deleted = 0',
        whereArgs: [adherentId],
        orderBy: 'code_champ ASC',
      );

      // Debug: vérifier les données brutes de la base
      for (final row in result) {
        print(
          '🔍 getChampsByAdherent - Données brutes DB pour ${row['code_champ']}: lat=${row['latitude']}, lng=${row['longitude']}',
        );
      }

      final champs = result.map((map) {
        final champ = ChampParcelleModel.fromMap(map);
        print(
          '🔍 getChampsByAdherent - Après fromMap pour ${champ.codeChamp}: lat=${champ.latitude}, lng=${champ.longitude}',
        );
        return champ;
      }).toList();

      return champs;
    } catch (e) {
      print('❌ Erreur getChampsByAdherent: $e');
      throw Exception('Erreur lors de la récupération des champs: $e');
    }
  }

  /// Récupérer tous les champs avec coordonnées GPS
  Future<List<ChampParcelleModel>> getAllChampsWithCoordinates() async {
    try {
      final db = await DatabaseInitializer.database;

      // Récupérer tous les champs non supprimés
      final result = await db.query(
        'champs_parcelles',
        where: 'is_deleted = 0',
        orderBy: 'code_champ ASC',
      );

      // Filtrer dans le code pour ceux avec coordonnées GPS valides
      final champs = result
          .map((map) => ChampParcelleModel.fromMap(map))
          .toList();
      final champsWithCoords = champs
          .where(
            (c) =>
                c.latitude != null &&
                c.longitude != null &&
                c.latitude != 0.0 &&
                c.longitude != 0.0 &&
                c.latitude! >= -90 &&
                c.latitude! <= 90 &&
                c.longitude! >= -180 &&
                c.longitude! <= 180,
          )
          .toList();

      print(
        '🔍 getAllChampsWithCoordinates: ${champs.length} champs totaux, ${champsWithCoords.length} avec coordonnées',
      );

      return champsWithCoords;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des champs: $e');
    }
  }

  /// Calculer les statistiques des champs pour un adhérent
  Future<Map<String, dynamic>> getChampsStats(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as nombre_champs,
          COALESCE(SUM(superficie), 0) as superficie_totale,
          COALESCE(AVG(rendement_estime), 0) as rendement_moyen
        FROM champs_parcelles
        WHERE adherent_id = ? AND is_deleted = 0
      ''',
        [adherentId],
      );

      if (result.isEmpty) {
        return {
          'nombreChamps': 0,
          'superficieTotale': 0.0,
          'rendementMoyen': 0.0,
        };
      }

      return {
        'nombreChamps': result.first['nombre_champs'] as int? ?? 0,
        'superficieTotale':
            (result.first['superficie_totale'] as num?)?.toDouble() ?? 0.0,
        'rendementMoyen':
            (result.first['rendement_moyen'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  /// Calculer les statistiques globales des champs (tous adhérents)
  Future<Map<String, dynamic>> getChampsGlobalStats() async {
    try {
      final db = await DatabaseInitializer.database;

      // S'assurer que toutes les colonnes nécessaires existent
      await _ensureChampsParcellesColumns(db);

      final result = await db.rawQuery('''
        SELECT
          COUNT(*) as nombre_champs,
          COALESCE(SUM(superficie), 0) as superficie_totale,
          SUM(
            CASE
              WHEN latitude IS NOT NULL
               AND longitude IS NOT NULL
               AND latitude != 0
               AND longitude != 0
               AND latitude >= -90 AND latitude <= 90
               AND longitude >= -180 AND longitude <= 180
              THEN 1
              ELSE 0
            END
          ) as champs_geolocalises
        FROM champs_parcelles
        WHERE is_deleted = 0
      ''');

      if (result.isEmpty) {
        return {
          'nombreChamps': 0,
          'superficieTotale': 0.0,
          'champsGeolocalises': 0,
        };
      }

      return {
        'nombreChamps': result.first['nombre_champs'] as int? ?? 0,
        'superficieTotale':
            (result.first['superficie_totale'] as num?)?.toDouble() ?? 0.0,
        'champsGeolocalises':
            (result.first['champs_geolocalises'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques globales: $e');
    }
  }

  /// S'assurer que toutes les colonnes nécessaires existent dans la table champs_parcelles
  /// Cette méthode est appelée avant chaque insertion pour garantir la compatibilité
  Future<void> _ensureChampsParcellesColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(champs_parcelles)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      final requiredColumns = {
        'latitude': 'ALTER TABLE champs_parcelles ADD COLUMN latitude REAL',
        'longitude': 'ALTER TABLE champs_parcelles ADD COLUMN longitude REAL',
        'densite_arbres_associes':
            'ALTER TABLE champs_parcelles ADD COLUMN densite_arbres_associes REAL',
      };

      for (final entry in requiredColumns.entries) {
        if (!columnNames.contains(entry.key)) {
          try {
            await db.execute(entry.value);
            print(
              '✅ Colonne ${entry.key} ajoutée à champs_parcelles (vérification runtime)',
            );
          } catch (e) {
            if (!e.toString().contains('duplicate column') &&
                !e.toString().contains('already exists')) {
              print('⚠️ Erreur lors de l\'ajout de ${entry.key}: $e');
            }
          }
        }
      }
    } catch (e) {
      print(
        '⚠️ Erreur lors de la vérification des colonnes champs_parcelles: $e',
      );
    }
  }
}
