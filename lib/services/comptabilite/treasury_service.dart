import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../data/models/tresorerie_model.dart';
import '../../data/models/journal_comptable_model.dart';
import '../database/db_initializer.dart';
import '../auth/audit_service.dart';

/// Service de gestion de la trésorerie
/// 
/// Suivi en temps réel de la trésorerie de la coopérative
class TreasuryService {
  final AuditService _auditService = AuditService();

  /// Obtenir le solde actuel de la trésorerie
  Future<double> getSoldeActuel() async {
    final db = await DatabaseInitializer.database;
    
    final result = await db.query(
      'tresorerie',
      orderBy: 'date_reference DESC',
      limit: 1,
    );
    
    if (result.isEmpty) {
      return 0.0;
    }
    
    return (result.first['solde_actuel'] as num).toDouble();
  }

  /// Obtenir le modèle de trésorerie actuel
  Future<TresorerieModel?> getTresorerieActuelle() async {
    final db = await DatabaseInitializer.database;
    
    final result = await db.query(
      'tresorerie',
      orderBy: 'date_reference DESC',
      limit: 1,
    );
    
    if (result.isEmpty) {
      return null;
    }
    
    return TresorerieModel.fromMap(result.first);
  }

  /// Mettre à jour la trésorerie après une opération
  Future<void> updateTresorerie({
    required double montant,
    required bool isEntree, // true = entrée, false = sortie
    required DateTime dateOperation,
    String? description,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      await db.execute('BEGIN TRANSACTION');
      
      // Récupérer la trésorerie actuelle
      final tresorerie = await getTresorerieActuelle();
      
      final soldeActuel = tresorerie?.soldeActuel ?? 0.0;
      final nouveauSolde = isEntree 
          ? soldeActuel + montant 
          : soldeActuel - montant;
      
      if (tresorerie == null) {
        // Créer une nouvelle entrée
        await db.insert('tresorerie', {
          'solde_initial': 0.0,
          'solde_actuel': nouveauSolde,
          'date_reference': dateOperation.toIso8601String(),
          'periode': 'Mois',
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Mettre à jour l'entrée existante
        await db.update(
          'tresorerie',
          {
            'solde_actuel': nouveauSolde,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [tresorerie.id],
        );
      }
      
      await db.execute('COMMIT');
    } catch (e) {
      await db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Obtenir l'historique de la trésorerie
  Future<List<TresorerieModel>> getHistoriqueTresorerie({
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final db = await DatabaseInitializer.database;
    
    String? where;
    List<Object?>? whereArgs = [];
    
    if (dateDebut != null) {
      where = 'date_reference >= ?';
      whereArgs.add(dateDebut.toIso8601String());
    }
    
    if (dateFin != null) {
      where = where != null 
          ? '$where AND date_reference <= ?'
          : 'date_reference <= ?';
      whereArgs.add(dateFin.toIso8601String());
    }
    
    final result = await db.query(
      'tresorerie',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date_reference DESC',
    );
    
    return result.map((map) => TresorerieModel.fromMap(map)).toList();
  }

  /// Vérifier si la trésorerie est basse (alerte)
  Future<bool> isTresorerieBasse({double? seuil}) async {
    final solde = await getSoldeActuel();
    final seuilMin = seuil ?? 100000.0; // 100 000 FCFA par défaut
    return solde < seuilMin;
  }

  /// Obtenir le flux de trésorerie par période
  Future<Map<String, double>> getFluxTresorerieParPeriode({
    required DateTime dateDebut,
    required DateTime dateFin,
    String periode = 'jour', // 'jour', 'semaine', 'mois'
  }) async {
    final db = await DatabaseInitializer.database;
    
    // Récupérer les écritures du journal qui impactent la trésorerie
    final journalEntries = await db.query(
      'journal_comptable',
      where: 'date_operation >= ? AND date_operation <= ? AND source_module IN (?, ?, ?)',
      whereArgs: [
        dateDebut.toIso8601String(),
        dateFin.toIso8601String(),
        'Paiement',
        'Vente',
        'Capital',
      ],
      orderBy: 'date_operation ASC',
    );
    
    final Map<String, double> flux = {};
    
    for (final entry in journalEntries) {
      final date = DateTime.parse(entry['date_operation'] as String);
      String key;
      
      switch (periode) {
        case 'jour':
          key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          break;
        case 'semaine':
          final semaine = date.difference(dateDebut).inDays ~/ 7;
          key = 'Semaine $semaine';
          break;
        case 'mois':
        default:
          key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          break;
      }
      
      final debit = (entry['debit'] as num).toDouble();
      final credit = (entry['credit'] as num).toDouble();
      final variation = credit - debit;
      
      flux[key] = (flux[key] ?? 0.0) + variation;
    }
    
    return flux;
  }

  /// Initialiser la trésorerie pour une nouvelle période
  Future<void> initialiserNouvellePeriode({
    required DateTime dateReference,
    String? periode,
  }) async {
    final db = await DatabaseInitializer.database;
    
    final soldeActuel = await getSoldeActuel();
    
    await db.insert('tresorerie', {
      'solde_initial': soldeActuel,
      'solde_actuel': soldeActuel,
      'date_reference': dateReference.toIso8601String(),
      'periode': periode ?? 'Mois',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}

