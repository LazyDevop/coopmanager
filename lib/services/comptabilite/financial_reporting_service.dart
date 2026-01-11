import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../data/models/journal_comptable_model.dart';
import '../../data/models/compte_comptable_model.dart';
import '../database/db_initializer.dart';
import 'treasury_service.dart';
import 'capital_accounting_service.dart';

/// Service de reporting financier
/// 
/// Génère les rapports financiers et indicateurs clés
class FinancialReportingService {
  final TreasuryService _treasuryService = TreasuryService();
  final CapitalAccountingService _capitalAccountingService = CapitalAccountingService();

  /// Obtenir le résumé financier mensuel
  Future<MonthlyFinancialSummary> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    final db = await DatabaseInitializer.database;
    
    final dateDebut = DateTime(year, month, 1);
    final dateFin = DateTime(year, month + 1, 0, 23, 59, 59);
    
    // Récupérer les écritures du mois
    final journalEntries = await db.query(
      'journal_comptable',
      where: 'date_operation >= ? AND date_operation <= ?',
      whereArgs: [dateDebut.toIso8601String(), dateFin.toIso8601String()],
    );
    
    // Calculer les totaux par type
    double totalVentes = 0.0;
    double totalPaiements = 0.0;
    double totalCapital = 0.0;
    double totalCharges = 0.0;
    
    for (final entry in journalEntries) {
      final type = entry['type_journal'] as String;
      final debit = (entry['debit'] as num).toDouble();
      final credit = (entry['credit'] as num).toDouble();
      
      switch (type) {
        case 'Vente':
          totalVentes += credit;
          break;
        case 'Paiement':
          totalPaiements += debit;
          break;
        case 'Capital':
          totalCapital += credit;
          break;
        case 'Charge':
          totalCharges += debit;
          break;
      }
    }
    
    // Trésorerie
    final tresorerie = await _treasuryService.getTresorerieActuelle();
    
    // Capital
    final capitalSummary = await _capitalAccountingService.getCapitalFinancialSummary();
    
    return MonthlyFinancialSummary(
      year: year,
      month: month,
      totalVentes: totalVentes,
      totalPaiements: totalPaiements,
      totalCapital: totalCapital,
      totalCharges: totalCharges,
      soldeTresorerie: tresorerie?.soldeActuel ?? 0.0,
      capitalSouscrit: capitalSummary.capitalSouscrit,
      capitalLibere: capitalSummary.capitalLibere,
      capitalRestant: capitalSummary.capitalRestant,
      nombreActionnaires: capitalSummary.nombreActionnaires,
    );
  }

  /// Obtenir le flux financier par module
  Future<Map<String, double>> getFluxParModule({
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final db = await DatabaseInitializer.database;
    
    String? where;
    List<Object?>? whereArgs = [];
    
    if (dateDebut != null) {
      where = 'date_operation >= ?';
      whereArgs.add(dateDebut.toIso8601String());
    }
    
    if (dateFin != null) {
      where = where != null 
          ? '$where AND date_operation <= ?'
          : 'date_operation <= ?';
      whereArgs.add(dateFin.toIso8601String());
    }
    
    final journalEntries = await db.query(
      'journal_comptable',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );
    
    final Map<String, double> flux = {};
    
    for (final entry in journalEntries) {
      final module = entry['source_module'] as String;
      final debit = (entry['debit'] as num).toDouble();
      final credit = (entry['credit'] as num).toDouble();
      final variation = credit - debit;
      
      flux[module] = (flux[module] ?? 0.0) + variation;
    }
    
    return flux;
  }

  /// Obtenir la contribution des actionnaires
  Future<List<ActionnaireContribution>> getContributionsActionnaires() async {
    final db = await DatabaseInitializer.database;
    
    final result = await db.rawQuery('''
      SELECT 
        actionnaire_id,
        SUM(CASE WHEN type_operation = 'Souscription' THEN montant ELSE 0 END) as total_souscrit,
        SUM(CASE WHEN type_operation = 'Liberation' THEN montant ELSE 0 END) as total_libere
      FROM ecritures_capital
      GROUP BY actionnaire_id
      ORDER BY total_souscrit DESC
    ''');
    
    return result.map((row) {
      return ActionnaireContribution(
        actionnaireId: row['actionnaire_id'] as int,
        capitalSouscrit: (row['total_souscrit'] as num?)?.toDouble() ?? 0.0,
        capitalLibere: (row['total_libere'] as num?)?.toDouble() ?? 0.0,
        capitalRestant: ((row['total_souscrit'] as num?)?.toDouble() ?? 0.0) - 
                       ((row['total_libere'] as num?)?.toDouble() ?? 0.0),
      );
    }).toList();
  }

  /// Obtenir le bilan simplifié
  Future<BilanSimplifie> getBilanSimplifie({DateTime? dateLimite}) async {
    final db = await DatabaseInitializer.database;
    
    final dateRef = dateLimite ?? DateTime.now();
    
    // Actifs
    final caisse = await _getSoldeCompte('530', dateRef);
    final banque = await _getSoldeCompte('512', dateRef);
    final clients = await _getSoldeCompte('411', dateRef);
    final adherents = await _getSoldeCompte('412', dateRef);
    final stock = await _getSoldeCompte('310', dateRef);
    
    final totalActifs = caisse + banque + clients + adherents + stock;
    
    // Passifs
    final capitalSouscrit = await _getSoldeCompte('1011', dateRef);
    final capitalLibere = await _getSoldeCompte('1012', dateRef);
    final reserves = await _getSoldeCompte('106', dateRef);
    final fondsSocial = await _getSoldeCompte('107', dateRef);
    
    final totalPassifs = capitalSouscrit + capitalLibere + reserves + fondsSocial;
    
    return BilanSimplifie(
      dateReference: dateRef,
      actifs: ActifsBilan(
        caisse: caisse,
        banque: banque,
        clients: clients,
        adherents: adherents,
        stock: stock,
        total: totalActifs,
      ),
      passifs: PassifsBilan(
        capitalSouscrit: capitalSouscrit,
        capitalLibere: capitalLibere,
        reserves: reserves,
        fondsSocial: fondsSocial,
        total: totalPassifs,
      ),
    );
  }

  /// Obtenir le solde d'un compte à une date donnée
  Future<double> _getSoldeCompte(String codeCompte, DateTime dateLimite) async {
    final db = await DatabaseInitializer.database;
    
    // Récupérer le compte
    final compteResult = await db.query(
      'comptes_comptables',
      where: 'code_compte = ?',
      whereArgs: [codeCompte],
      limit: 1,
    );
    
    if (compteResult.isEmpty) {
      return 0.0;
    }
    
    // Pour simplifier, on retourne le solde actuel
    // En production, il faudrait calculer depuis le journal jusqu'à la date limite
    return (compteResult.first['solde'] as num?)?.toDouble() ?? 0.0;
  }
}

/// Résumé financier mensuel
class MonthlyFinancialSummary {
  final int year;
  final int month;
  final double totalVentes;
  final double totalPaiements;
  final double totalCapital;
  final double totalCharges;
  final double soldeTresorerie;
  final double capitalSouscrit;
  final double capitalLibere;
  final double capitalRestant;
  final int nombreActionnaires;

  MonthlyFinancialSummary({
    required this.year,
    required this.month,
    required this.totalVentes,
    required this.totalPaiements,
    required this.totalCapital,
    required this.totalCharges,
    required this.soldeTresorerie,
    required this.capitalSouscrit,
    required this.capitalLibere,
    required this.capitalRestant,
    required this.nombreActionnaires,
  });
}

/// Contribution d'un actionnaire
class ActionnaireContribution {
  final int actionnaireId;
  final double capitalSouscrit;
  final double capitalLibere;
  final double capitalRestant;

  ActionnaireContribution({
    required this.actionnaireId,
    required this.capitalSouscrit,
    required this.capitalLibere,
    required this.capitalRestant,
  });
}

/// Bilan simplifié
class BilanSimplifie {
  final DateTime dateReference;
  final ActifsBilan actifs;
  final PassifsBilan passifs;

  BilanSimplifie({
    required this.dateReference,
    required this.actifs,
    required this.passifs,
  });
}

class ActifsBilan {
  final double caisse;
  final double banque;
  final double clients;
  final double adherents;
  final double stock;
  final double total;

  ActifsBilan({
    required this.caisse,
    required this.banque,
    required this.clients,
    required this.adherents,
    required this.stock,
    required this.total,
  });
}

class PassifsBilan {
  final double capitalSouscrit;
  final double capitalLibere;
  final double reserves;
  final double fondsSocial;
  final double total;

  PassifsBilan({
    required this.capitalSouscrit,
    required this.capitalLibere,
    required this.reserves,
    required this.fondsSocial,
    required this.total,
  });
}

