import '../database/db_initializer.dart';
import '../../data/models/simulation_vente_model.dart';
import '../../data/models/historique_simulation_model.dart';
import '../../data/models/vente_model.dart';
import '../../data/models/parametres_cooperative_model.dart';
import '../parametres/parametres_service.dart';
import '../comptabilite/comptabilite_service.dart';

class SimulationVenteService {
  final ParametresService _parametresService = ParametresService();
  final ComptabiliteService _comptabiliteService = ComptabiliteService();

  /// Créer une simulation de vente
  Future<SimulationVenteModel> createSimulation({
    int? lotVenteId,
    int? clientId,
    int? campagneId,
    required double quantiteTotal,
    required double prixUnitairePropose,
    double? pourcentageFondsSocial,
    String? notes,
    int? createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      final normalizedCreatedBy = (createdBy != null && createdBy > 0)
          ? createdBy
          : null;

      // Calculer les montants
      final montantBrut = quantiteTotal * prixUnitairePropose;
      final parametres = await _parametresService.getParametres();
      final commissionRate = parametres.commissionRate;
      final montantCommission = montantBrut * commissionRate;
      final montantNet = montantBrut - montantCommission;

      // Calculer le montant du fonds social
      final montantFondsSocial = pourcentageFondsSocial != null
          ? montantBrut * (pourcentageFondsSocial / 100)
          : 0.0;

      // Obtenir les prix de comparaison
      final prixMoyenJour = await _getPrixMoyenJour();
      final prixMoyenPrecedent = await _getPrixMoyenPrecedent(
        campagneId: campagneId,
        clientId: clientId,
      );

      // Calculer la marge coopérative
      final margeCooperative = montantCommission;

      // Calculer les indicateurs
      final indicateurs = await _calculerIndicateurs(
        prixUnitairePropose: prixUnitairePropose,
        prixMoyenJour: prixMoyenJour,
        prixMoyenPrecedent: prixMoyenPrecedent,
        quantiteTotal: quantiteTotal,
        montantBrut: montantBrut,
        montantNet: montantNet,
        parametres: parametres,
      );

      // Créer la simulation
      final simulation = SimulationVenteModel(
        lotVenteId: lotVenteId,
        clientId: clientId,
        campagneId: campagneId,
        quantiteTotal: quantiteTotal,
        prixUnitairePropose: prixUnitairePropose,
        montantBrut: montantBrut,
        montantCommission: montantCommission,
        montantNet: montantNet,
        montantFondsSocial: montantFondsSocial,
        prixMoyenJour: prixMoyenJour,
        prixMoyenPrecedent: prixMoyenPrecedent,
        margeCooperative: margeCooperative,
        indicateurs: indicateurs,
        notes: notes,
        createdBy: normalizedCreatedBy,
        createdAt: DateTime.now(),
      );

      // Insérer dans la base de données
      final simulationId = await db.insert(
        'simulations_vente',
        simulation.toMap(),
      );

      // Enregistrer dans l'historique
      await _logHistorique(
        simulationId: simulationId,
        action: 'create',
        donneesAvant: {},
        donneesApres: simulation.toMap(),
        userId: normalizedCreatedBy,
      );

      return simulation.copyWith(id: simulationId);
    } catch (e) {
      throw Exception('Erreur lors de la création de la simulation: $e');
    }
  }

  /// Obtenir le prix moyen du jour
  Future<double> _getPrixMoyenJour() async {
    try {
      final db = await DatabaseInitializer.database;
      final aujourdhui = DateTime.now();
      final debutJour = DateTime(
        aujourdhui.year,
        aujourdhui.month,
        aujourdhui.day,
      );

      final result = await db.rawQuery(
        '''
        SELECT AVG(prix_unitaire) as prix_moyen
        FROM ventes
        WHERE date_vente >= ? 
          AND statut = 'valide'
      ''',
        [debutJour.toIso8601String()],
      );

      if (result.isEmpty || result.first['prix_moyen'] == null) {
        return 0.0;
      }

      return (result.first['prix_moyen'] as num).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  /// Obtenir le prix moyen des ventes précédentes
  Future<double> _getPrixMoyenPrecedent({
    int? campagneId,
    int? clientId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = "statut = 'valide'";
      List<dynamic> whereArgs = [];

      if (campagneId != null) {
        where += ' AND campagne_id = ?';
        whereArgs.add(campagneId);
      }

      if (clientId != null) {
        where += ' AND client_id = ?';
        whereArgs.add(clientId);
      }

      final result = await db.rawQuery('''
        SELECT AVG(prix_unitaire) as prix_moyen
        FROM ventes
        WHERE $where
        ORDER BY date_vente DESC
        LIMIT 100
      ''', whereArgs.isEmpty ? null : whereArgs);

      if (result.isEmpty || result.first['prix_moyen'] == null) {
        return 0.0;
      }

      return (result.first['prix_moyen'] as num).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculer les indicateurs de simulation
  Future<Map<String, dynamic>> _calculerIndicateurs({
    required double prixUnitairePropose,
    required double prixMoyenJour,
    required double prixMoyenPrecedent,
    required double quantiteTotal,
    required double montantBrut,
    required double montantNet,
    required ParametresCooperativeModel parametres,
  }) async {
    final indicateurs = <String, dynamic>{};

    // Seuils de prix (depuis barèmes de qualité)
    try {
      final db = await DatabaseInitializer.database;
      final baremes = await db.query('baremes_qualite');

      if (baremes.isNotEmpty) {
        double? prixMinGlobal;
        double? prixMaxGlobal;

        for (final bareme in baremes) {
          final prixMin = bareme['prix_min'] as num?;
          final prixMax = bareme['prix_max'] as num?;

          if (prixMin != null &&
              (prixMinGlobal == null || prixMin < prixMinGlobal)) {
            prixMinGlobal = prixMin.toDouble();
          }
          if (prixMax != null &&
              (prixMaxGlobal == null || prixMax > prixMaxGlobal)) {
            prixMaxGlobal = prixMax.toDouble();
          }
        }

        indicateurs['prix_min'] = prixMinGlobal;
        indicateurs['prix_max'] = prixMaxGlobal;
        indicateurs['prix_hors_seuil'] =
            (prixMinGlobal != null && prixUnitairePropose < prixMinGlobal) ||
            (prixMaxGlobal != null && prixUnitairePropose > prixMaxGlobal);
      }
    } catch (e) {
      print('Erreur lors de la récupération des barèmes: $e');
    }

    // Comparaisons de prix
    indicateurs['ecart_prix_jour'] = prixUnitairePropose - prixMoyenJour;
    indicateurs['ecart_prix_precedent'] =
        prixUnitairePropose - prixMoyenPrecedent;
    indicateurs['pourcentage_ecart_jour'] = prixMoyenJour > 0
        ? ((prixUnitairePropose - prixMoyenJour) / prixMoyenJour) * 100
        : 0.0;
    indicateurs['pourcentage_ecart_precedent'] = prixMoyenPrecedent > 0
        ? ((prixUnitairePropose - prixMoyenPrecedent) / prixMoyenPrecedent) *
              100
        : 0.0;

    // Indicateurs financiers
    indicateurs['marge_cooperative'] = montantBrut - montantNet;
    indicateurs['taux_marge'] = montantBrut > 0
        ? ((montantBrut - montantNet) / montantBrut) * 100
        : 0.0;
    indicateurs['montant_par_kg'] = quantiteTotal > 0
        ? montantNet / quantiteTotal
        : 0.0;

    // Niveaux de risque
    final risques = <String>[];
    if (indicateurs['prix_hors_seuil'] == true) {
      risques.add('prix_hors_seuil');
    }
    if (prixUnitairePropose < prixMoyenPrecedent * 0.9) {
      risques.add('prix_trop_bas');
    }
    if (prixUnitairePropose > prixMoyenPrecedent * 1.2) {
      risques.add('prix_trop_eleve');
    }
    indicateurs['risques'] = risques;
    indicateurs['niveau_risque'] = risques.isEmpty
        ? 'faible'
        : risques.length == 1
        ? 'moyen'
        : 'eleve';

    return indicateurs;
  }

  /// Récupérer une simulation par ID
  Future<SimulationVenteModel?> getSimulationById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'simulations_vente',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return SimulationVenteModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la simulation: $e');
    }
  }

  /// Valider une simulation (convertir en vente)
  Future<VenteModel> validerSimulation({
    required int simulationId,
    required int createdBy,
  }) async {
    try {
      final simulation = await getSimulationById(simulationId);
      if (simulation == null) {
        throw Exception('Simulation non trouvée');
      }

      if (simulation.isValidee) {
        throw Exception('Cette simulation est déjà validée');
      }

      // TODO: Créer la vente à partir de la simulation
      // Cette méthode devrait appeler VenteService.createVenteV2()
      // Pour l'instant, on marque juste la simulation comme validée

      final db = await DatabaseInitializer.database;
      await db.update(
        'simulations_vente',
        {
          'statut': 'validee',
          'date_validation': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [simulationId],
      );

      // Enregistrer dans l'historique
      await _logHistorique(
        simulationId: simulationId,
        action: 'validate',
        donneesAvant: simulation.toMap(),
        donneesApres: {...simulation.toMap(), 'statut': 'validee'},
        userId: createdBy,
      );

      // TODO: Retourner la vente créée
      throw Exception(
        'Validation de simulation non implémentée - à compléter avec création de vente',
      );
    } catch (e) {
      throw Exception('Erreur lors de la validation de la simulation: $e');
    }
  }

  /// Rejeter une simulation
  Future<bool> rejeterSimulation({
    required int simulationId,
    required String raison,
    required int userId,
  }) async {
    try {
      final simulation = await getSimulationById(simulationId);
      if (simulation == null) {
        throw Exception('Simulation non trouvée');
      }

      final db = await DatabaseInitializer.database;
      await db.update(
        'simulations_vente',
        {'statut': 'rejetee', 'notes': raison},
        where: 'id = ?',
        whereArgs: [simulationId],
      );

      // Enregistrer dans l'historique
      await _logHistorique(
        simulationId: simulationId,
        action: 'reject',
        donneesAvant: simulation.toMap(),
        donneesApres: {
          ...simulation.toMap(),
          'statut': 'rejetee',
          'notes': raison,
        },
        userId: userId,
        commentaire: raison,
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors du rejet de la simulation: $e');
    }
  }

  /// Enregistrer dans l'historique
  Future<void> _logHistorique({
    required int simulationId,
    required String action,
    required Map<String, dynamic> donneesAvant,
    required Map<String, dynamic> donneesApres,
    int? userId,
    String? commentaire,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      final historique = HistoriqueSimulationModel(
        simulationId: simulationId,
        action: action,
        donneesAvant: donneesAvant,
        donneesApres: donneesApres,
        commentaire: commentaire,
        userId: (userId != null && userId > 0) ? userId : null,
        createdAt: DateTime.now(),
      );

      await db.insert('historiques_simulation', historique.toMap());
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'historique: $e');
    }
  }

  /// Récupérer toutes les simulations
  Future<List<SimulationVenteModel>> getAllSimulations({
    int? clientId,
    int? campagneId,
    String? statut,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (clientId != null) {
        where += ' AND client_id = ?';
        whereArgs.add(clientId);
      }

      if (campagneId != null) {
        where += ' AND campagne_id = ?';
        whereArgs.add(campagneId);
      }

      if (statut != null) {
        where += ' AND statut = ?';
        whereArgs.add(statut);
      }

      final result = await db.query(
        'simulations_vente',
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'created_at DESC',
      );

      return result.map((map) => SimulationVenteModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des simulations: $e');
    }
  }
}
