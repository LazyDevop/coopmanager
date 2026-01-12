/// Service de Gestion des Lots de Vente (V2)
/// 
/// Permet de constituer automatiquement des lots par :
/// - Campagne
/// - Qualité
/// - Catégorie producteur
/// Avec possibilité d'exclusion manuelle

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/db_initializer.dart';
import '../../data/models/lot_vente_model.dart';
import '../../data/models/lot_vente_detail_model.dart';
import '../../data/models/adherent_model.dart';
import '../../data/models/stock_model.dart';
import '../stock/stock_service.dart';
import '../adherent/adherent_service.dart';
import 'dart:math';

class LotVenteService {
  final StockService _stockService = StockService();
  final AdherentService _adherentService = AdherentService();

  /// Créer un lot automatiquement par campagne
  Future<LotVenteModel> createLotParCampagne({
    required int campagneId,
    required double prixUnitairePropose,
    int? clientId,
    String? notes,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Récupérer tous les adhérents avec stock disponible pour cette campagne
      final adherentsAvecStock = await _getAdherentsAvecStockParCampagne(campagneId);

      if (adherentsAvecStock.isEmpty) {
        throw Exception('Aucun adhérent avec stock disponible pour cette campagne');
      }

      // Calculer la quantité totale
      final quantiteTotal = adherentsAvecStock.fold<double>(
        0.0,
        (sum, item) => sum + (item['quantite_disponible'] as double),
      );

      // Générer un code de lot unique
      final codeLot = _genererCodeLot(campagneId);

      // Créer le lot
      final lot = LotVenteModel(
        codeLot: codeLot,
        campagneId: campagneId,
        quantiteTotal: quantiteTotal,
        prixUnitairePropose: prixUnitairePropose,
        clientId: clientId,
        statut: 'preparation',
        notes: notes,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final lotId = await db.insert('lots_vente', lot.toMap());

      // Créer les détails du lot
      for (final item in adherentsAvecStock) {
        final adherentId = item['adherent_id'] as int;
        final quantite = item['quantite_disponible'] as double;

        final detail = LotVenteDetailModel(
          lotVenteId: lotId,
          adherentId: adherentId,
          quantite: quantite,
          isExclu: false,
          createdAt: DateTime.now(),
        );

        await db.insert('lot_vente_details', detail.toMap());
      }

      return lot.copyWith(id: lotId);
    } catch (e) {
      throw Exception('Erreur lors de la création du lot par campagne: $e');
    }
  }

  /// Créer un lot automatiquement par qualité
  Future<LotVenteModel> createLotParQualite({
    required String qualite,
    int? campagneId,
    required double prixUnitairePropose,
    int? clientId,
    String? notes,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Récupérer tous les adhérents avec stock de cette qualité
      final adherentsAvecStock = await _getAdherentsAvecStockParQualite(
        qualite: qualite,
        campagneId: campagneId,
      );

      if (adherentsAvecStock.isEmpty) {
        throw Exception('Aucun adhérent avec stock de qualité "$qualite" disponible');
      }

      // Calculer la quantité totale
      final quantiteTotal = adherentsAvecStock.fold<double>(
        0.0,
        (sum, item) => sum + (item['quantite_disponible'] as double),
      );

      // Générer un code de lot unique
      final codeLot = _genererCodeLot(null, qualite: qualite);

      // Créer le lot
      final lot = LotVenteModel(
        codeLot: codeLot,
        campagneId: campagneId,
        qualite: qualite,
        quantiteTotal: quantiteTotal,
        prixUnitairePropose: prixUnitairePropose,
        clientId: clientId,
        statut: 'preparation',
        notes: notes,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final lotId = await db.insert('lots_vente', lot.toMap());

      // Créer les détails du lot
      for (final item in adherentsAvecStock) {
        final adherentId = item['adherent_id'] as int;
        final quantite = item['quantite_disponible'] as double;

        final detail = LotVenteDetailModel(
          lotVenteId: lotId,
          adherentId: adherentId,
          quantite: quantite,
          isExclu: false,
          createdAt: DateTime.now(),
        );

        await db.insert('lot_vente_details', detail.toMap());
      }

      return lot.copyWith(id: lotId);
    } catch (e) {
      throw Exception('Erreur lors de la création du lot par qualité: $e');
    }
  }

  /// Créer un lot automatiquement par catégorie producteur
  Future<LotVenteModel> createLotParCategorie({
    required String categorieProducteur,
    int? campagneId,
    required double prixUnitairePropose,
    int? clientId,
    String? notes,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Récupérer tous les adhérents de cette catégorie avec stock disponible
      final adherentsAvecStock = await _getAdherentsAvecStockParCategorie(
        categorieProducteur: categorieProducteur,
        campagneId: campagneId,
      );

      if (adherentsAvecStock.isEmpty) {
        throw Exception('Aucun adhérent de catégorie "$categorieProducteur" avec stock disponible');
      }

      // Calculer la quantité totale
      final quantiteTotal = adherentsAvecStock.fold<double>(
        0.0,
        (sum, item) => sum + (item['quantite_disponible'] as double),
      );

      // Générer un code de lot unique
      final codeLot = _genererCodeLot(campagneId, categorieProducteur: categorieProducteur);

      // Créer le lot
      final lot = LotVenteModel(
        codeLot: codeLot,
        campagneId: campagneId,
        categorieProducteur: categorieProducteur,
        quantiteTotal: quantiteTotal,
        prixUnitairePropose: prixUnitairePropose,
        clientId: clientId,
        statut: 'preparation',
        notes: notes,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final lotId = await db.insert('lots_vente', lot.toMap());

      // Créer les détails du lot
      for (final item in adherentsAvecStock) {
        final adherentId = item['adherent_id'] as int;
        final quantite = item['quantite_disponible'] as double;

        final detail = LotVenteDetailModel(
          lotVenteId: lotId,
          adherentId: adherentId,
          quantite: quantite,
          isExclu: false,
          createdAt: DateTime.now(),
        );

        await db.insert('lot_vente_details', detail.toMap());
      }

      return lot.copyWith(id: lotId);
    } catch (e) {
      throw Exception('Erreur lors de la création du lot par catégorie: $e');
    }
  }

  /// Exclure un adhérent d'un lot
  Future<bool> exclureAdherentDuLot({
    required int lotId,
    required int adherentId,
    required String raison,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Mettre à jour le détail
      await db.update(
        'lot_vente_details',
        {
          'is_exclu': 1,
          'raison_exclusion': raison,
        },
        where: 'lot_vente_id = ? AND adherent_id = ?',
        whereArgs: [lotId, adherentId],
      );

      // Recalculer la quantité totale du lot
      await _recalculerQuantiteTotaleLot(lotId);

      return true;
    } catch (e) {
      throw Exception('Erreur lors de l\'exclusion de l\'adhérent: $e');
    }
  }

  /// Réintégrer un adhérent dans un lot
  Future<bool> reintegrerAdherentDansLot({
    required int lotId,
    required int adherentId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Mettre à jour le détail
      await db.update(
        'lot_vente_details',
        {
          'is_exclu': 0,
          'raison_exclusion': null,
        },
        where: 'lot_vente_id = ? AND adherent_id = ?',
        whereArgs: [lotId, adherentId],
      );

      // Recalculer la quantité totale du lot
      await _recalculerQuantiteTotaleLot(lotId);

      return true;
    } catch (e) {
      throw Exception('Erreur lors de la réintégration de l\'adhérent: $e');
    }
  }

  /// Recalculer la quantité totale d'un lot
  Future<void> _recalculerQuantiteTotaleLot(int lotId) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.rawQuery('''
        SELECT SUM(quantite) as quantite_totale
        FROM lot_vente_details
        WHERE lot_vente_id = ? AND is_exclu = 0
      ''', [lotId]);

      final quantiteTotale = result.isNotEmpty && result.first['quantite_totale'] != null
          ? (result.first['quantite_totale'] as num).toDouble()
          : 0.0;

      await db.update(
        'lots_vente',
        {'quantite_total': quantiteTotale},
        where: 'id = ?',
        whereArgs: [lotId],
      );
    } catch (e) {
      print('Erreur lors du recalcul de la quantité totale: $e');
    }
  }

  /// Récupérer les adhérents avec stock par campagne
  Future<List<Map<String, dynamic>>> _getAdherentsAvecStockParCampagne(int campagneId) async {
    try {
      final db = await DatabaseInitializer.database;

      // Récupérer les dépôts de stock pour cette campagne
      final result = await db.rawQuery('''
        SELECT 
          sd.adherent_id,
          SUM(sd.quantite) as quantite_disponible
        FROM stock_depots sd
        INNER JOIN adherents a ON sd.adherent_id = a.id
        WHERE a.is_active = 1
          AND sd.quantite > 0
        GROUP BY sd.adherent_id
        HAVING quantite_disponible > 0
      ''');

      return result.map((row) => {
        'adherent_id': row['adherent_id'] as int,
        'quantite_disponible': (row['quantite_disponible'] as num).toDouble(),
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des adhérents: $e');
    }
  }

  /// Récupérer les adhérents avec stock par qualité
  Future<List<Map<String, dynamic>>> _getAdherentsAvecStockParQualite({
    required String qualite,
    int? campagneId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = "sd.qualite = ? AND a.is_active = 1 AND sd.quantite > 0";
      List<dynamic> whereArgs = [qualite];

      final result = await db.rawQuery('''
        SELECT 
          sd.adherent_id,
          SUM(sd.quantite) as quantite_disponible
        FROM stock_depots sd
        INNER JOIN adherents a ON sd.adherent_id = a.id
        WHERE $where
        GROUP BY sd.adherent_id
        HAVING quantite_disponible > 0
      ''', whereArgs);

      return result.map((row) => {
        'adherent_id': row['adherent_id'] as int,
        'quantite_disponible': (row['quantite_disponible'] as num).toDouble(),
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des adhérents: $e');
    }
  }

  /// Récupérer les adhérents avec stock par catégorie
  Future<List<Map<String, dynamic>>> _getAdherentsAvecStockParCategorie({
    required String categorieProducteur,
    int? campagneId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = "a.categorie = ? AND a.is_active = 1 AND sd.quantite > 0";
      List<dynamic> whereArgs = [categorieProducteur];

      final result = await db.rawQuery('''
        SELECT 
          sd.adherent_id,
          SUM(sd.quantite) as quantite_disponible
        FROM stock_depots sd
        INNER JOIN adherents a ON sd.adherent_id = a.id
        WHERE $where
        GROUP BY sd.adherent_id
        HAVING quantite_disponible > 0
      ''', whereArgs);

      return result.map((row) => {
        'adherent_id': row['adherent_id'] as int,
        'quantite_disponible': (row['quantite_disponible'] as num).toDouble(),
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des adhérents: $e');
    }
  }

  /// Générer un code de lot unique
  String _genererCodeLot(int? campagneId, {String? qualite, String? categorieProducteur}) {
    final now = DateTime.now();
    const prefix = 'LOT';
    final annee = now.year.toString().substring(2);
    final mois = now.month.toString().padLeft(2, '0');
    final jour = now.day.toString().padLeft(2, '0');
    final random = Random().nextInt(9999).toString().padLeft(4, '0');

    String suffix = '';
    if (qualite != null) {
      suffix = '-${qualite.toUpperCase().substring(0, qualite.length > 3 ? 3 : qualite.length)}';
    } else if (categorieProducteur != null) {
      suffix = '-${categorieProducteur.toUpperCase().substring(0, categorieProducteur.length > 3 ? 3 : categorieProducteur.length)}';
    }

    return '$prefix$annee$mois$jour$suffix$random';
  }

  /// Récupérer un lot par ID
  Future<LotVenteModel?> getLotById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'lots_vente',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return LotVenteModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du lot: $e');
    }
  }

  /// Récupérer les détails d'un lot
  Future<List<LotVenteDetailModel>> getLotDetails(int lotId) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'lot_vente_details',
        where: 'lot_vente_id = ?',
        whereArgs: [lotId],
      );

      return result.map((map) => LotVenteDetailModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des détails: $e');
    }
  }

  /// Valider un lot
  Future<bool> validerLot({
    required int lotId,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      await db.update(
        'lots_vente',
        {
          'statut': 'valide',
          'date_validation': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [lotId],
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors de la validation du lot: $e');
    }
  }

  /// Récupérer tous les lots
  Future<List<LotVenteModel>> getAllLots({
    int? campagneId,
    String? statut,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (campagneId != null) {
        where += ' AND campagne_id = ?';
        whereArgs.add(campagneId);
      }

      if (statut != null) {
        where += ' AND statut = ?';
        whereArgs.add(statut);
      }

      final result = await db.query(
        'lots_vente',
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'created_at DESC',
      );

      return result.map((map) => LotVenteModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des lots: $e');
    }
  }
}

