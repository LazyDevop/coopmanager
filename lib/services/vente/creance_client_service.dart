/// Service de Gestion des Créances Clients (V2)
/// 
/// Gestion du paiement différé et suivi des créances clients
/// Blocage automatique si retard

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/db_initializer.dart';
import '../../data/models/creance_client_model.dart';
import '../../data/models/client_model.dart';
import '../client/client_service.dart';

class CreanceClientService {
  final ClientService _clientService = ClientService();

  /// Créer une créance pour une vente avec paiement différé
  Future<CreanceClientModel> createCreance({
    required int venteId,
    required int clientId,
    required double montantTotal,
    required DateTime dateEcheance,
    String? notes,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      final creance = CreanceClientModel(
        venteId: venteId,
        clientId: clientId,
        montantTotal: montantTotal,
        montantRestant: montantTotal,
        dateVente: DateTime.now(),
        dateEcheance: dateEcheance,
        statut: 'en_attente',
        notes: notes,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final creanceId = await db.insert('creances_clients', creance.toMap());

      return creance.copyWith(id: creanceId);
    } catch (e) {
      throw Exception('Erreur lors de la création de la créance: $e');
    }
  }

  /// Enregistrer un paiement partiel ou total
  Future<bool> enregistrerPaiement({
    required int creanceId,
    required double montantPaye,
    required int userId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Récupérer la créance
      final creance = await getCreanceById(creanceId);
      if (creance == null) {
        throw Exception('Créance non trouvée');
      }

      final nouveauMontantPaye = creance.montantPaye + montantPaye;
      double nouveauMontantRestant = creance.montantTotal - nouveauMontantPaye;

      String nouveauStatut;
      DateTime? datePaiement;

      if (nouveauMontantRestant <= 0) {
        // Paiement complet
        nouveauStatut = 'payee';
        datePaiement = DateTime.now();
        nouveauMontantRestant = 0.0;
      } else if (nouveauMontantPaye > 0) {
        // Paiement partiel
        nouveauStatut = 'partiellement_payee';
      } else {
        nouveauStatut = creance.statut;
      }

      // Mettre à jour la créance
      await db.update(
        'creances_clients',
        {
          'montant_paye': nouveauMontantPaye,
          'montant_restant': nouveauMontantRestant,
          'statut': nouveauStatut,
          'date_paiement': datePaiement?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [creanceId],
      );

      // Vérifier et mettre à jour le blocage du client
      await _verifierBlocageClient(creance.clientId);

      return true;
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement du paiement: $e');
    }
  }

  /// Vérifier et mettre à jour le blocage automatique du client
  Future<void> _verifierBlocageClient(int clientId) async {
    try {
      final db = await DatabaseInitializer.database;
      final maintenant = DateTime.now();

      // Récupérer toutes les créances en retard
      final creancesEnRetard = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM creances_clients
        WHERE client_id = ?
          AND statut != 'payee'
          AND date_echeance < ?
          AND is_client_bloque = 0
      ''', [clientId, maintenant.toIso8601String()]);

      final countEnRetard = creancesEnRetard.first['count'] as int? ?? 0;

      if (countEnRetard > 0) {
        // Bloquer le client
        await db.update(
          'creances_clients',
          {
            'statut': 'en_retard',
            'is_client_bloque': 1,
            'jours_retard': _calculerJoursRetard(maintenant),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'client_id = ? AND statut != ? AND date_echeance < ?',
          whereArgs: [clientId, 'payee', maintenant.toIso8601String()],
        );

        // TODO: Notifier le client du blocage
      }
    } catch (e) {
      print('Erreur lors de la vérification du blocage: $e');
    }
  }

  /// Calculer les jours de retard
  int _calculerJoursRetard(DateTime dateEcheance) {
    final maintenant = DateTime.now();
    if (maintenant.isBefore(dateEcheance)) return 0;
    return maintenant.difference(dateEcheance).inDays;
  }

  /// Récupérer une créance par ID
  Future<CreanceClientModel?> getCreanceById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'creances_clients',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return CreanceClientModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la créance: $e');
    }
  }

  /// Récupérer toutes les créances d'un client
  Future<List<CreanceClientModel>> getCreancesByClient(int clientId) async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query(
        'creances_clients',
        where: 'client_id = ?',
        whereArgs: [clientId],
        orderBy: 'date_echeance ASC',
      );

      return result.map((map) => CreanceClientModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des créances: $e');
    }
  }

  /// Récupérer toutes les créances en retard
  Future<List<CreanceClientModel>> getCreancesEnRetard() async {
    try {
      final db = await DatabaseInitializer.database;
      final maintenant = DateTime.now();

      final result = await db.query(
        'creances_clients',
        where: 'statut != ? AND date_echeance < ?',
        whereArgs: ['payee', maintenant.toIso8601String()],
        orderBy: 'date_echeance ASC',
      );

      return result.map((map) => CreanceClientModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des créances en retard: $e');
    }
  }

  /// Récupérer toutes les créances
  Future<List<CreanceClientModel>> getAllCreances({
    int? clientId,
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

      if (statut != null) {
        where += ' AND statut = ?';
        whereArgs.add(statut);
      }

      final result = await db.query(
        'creances_clients',
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'date_echeance ASC',
      );

      return result.map((map) => CreanceClientModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des créances: $e');
    }
  }

  /// Débloquer un client
  Future<bool> debloquerClient(int clientId) async {
    try {
      final db = await DatabaseInitializer.database;

      await db.update(
        'creances_clients',
        {
          'is_client_bloque': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'client_id = ?',
        whereArgs: [clientId],
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors du déblocage du client: $e');
    }
  }

  /// Obtenir les statistiques des créances
  Future<Map<String, dynamic>> getStatistiquesCreances() async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as nombre_creances,
          SUM(montant_total) as montant_total,
          SUM(montant_paye) as montant_paye,
          SUM(montant_restant) as montant_restant,
          COUNT(CASE WHEN statut = 'en_retard' THEN 1 END) as nombre_en_retard,
          SUM(CASE WHEN statut = 'en_retard' THEN montant_restant ELSE 0 END) as montant_en_retard
        FROM creances_clients
        WHERE statut != 'payee'
      ''');

      if (result.isEmpty) {
        return {
          'nombreCreances': 0,
          'montantTotal': 0.0,
          'montantPaye': 0.0,
          'montantRestant': 0.0,
          'nombreEnRetard': 0,
          'montantEnRetard': 0.0,
        };
      }

      final stats = result.first;
      return {
        'nombreCreances': stats['nombre_creances'] as int? ?? 0,
        'montantTotal': (stats['montant_total'] as num?)?.toDouble() ?? 0.0,
        'montantPaye': (stats['montant_paye'] as num?)?.toDouble() ?? 0.0,
        'montantRestant': (stats['montant_restant'] as num?)?.toDouble() ?? 0.0,
        'nombreEnRetard': stats['nombre_en_retard'] as int? ?? 0,
        'montantEnRetard': (stats['montant_en_retard'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }
}

