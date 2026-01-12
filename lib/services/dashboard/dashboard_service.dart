import '../../data/models/stock_model.dart';
import '../../data/models/vente_mensuelle_stats_model.dart';
import '../../data/models/vente_top_client_stats_model.dart';
import '../adherent/champ_parcelle_service.dart';
import '../capital/capital_service.dart';
import '../comptabilite/financial_reporting_service.dart';
import '../stock/stock_service.dart';
import '../vente/creance_client_service.dart';
import '../vente/vente_service.dart';

class DashboardPeriod {
  final DateTime start;
  final DateTime end;
  final String label;

  const DashboardPeriod({
    required this.start,
    required this.end,
    required this.label,
  });

  String get cacheKey => '${start.toIso8601String()}__${end.toIso8601String()}';
}

class DashboardIssue {
  final String code;
  final String message;

  const DashboardIssue(this.code, this.message);
}

class DashboardSnapshot {
  final DashboardPeriod period;
  final DateTime generatedAt;
  final List<DashboardIssue> issues;

  // Ventes
  final int ventesCount;
  final double ventesQuantite;
  final double ventesMontant;
  final List<VenteMensuelleStatsModel> ventesParMois;
  final List<VenteTopClientStatsModel> topClients;

  // Stock
  final double stockTotalKg;
  final int adherentsAvecStock;
  final int stockCritiqueCount;

  // Champs / parcelles
  final int champsCount;
  final double champsSuperficieTotale;
  final int champsGeolocalisesCount;

  // Capital
  final double capitalSouscrit;
  final double capitalLibere;
  final double capitalRestant;
  final int nombreActionnaires;
  final double valeurPart;
  final double pourcentageLiberation;

  // Finances
  final MonthlyFinancialSummary? monthlyFinancialSummary;

  // Crédits / créances
  final int creancesEnRetardCount;
  final double creancesEnRetardMontantRestant;

  const DashboardSnapshot({
    required this.period,
    required this.generatedAt,
    required this.issues,
    required this.ventesCount,
    required this.ventesQuantite,
    required this.ventesMontant,
    required this.ventesParMois,
    required this.topClients,
    required this.stockTotalKg,
    required this.adherentsAvecStock,
    required this.stockCritiqueCount,
    required this.champsCount,
    required this.champsSuperficieTotale,
    required this.champsGeolocalisesCount,
    required this.capitalSouscrit,
    required this.capitalLibere,
    required this.capitalRestant,
    required this.nombreActionnaires,
    required this.valeurPart,
    required this.pourcentageLiberation,
    required this.monthlyFinancialSummary,
    required this.creancesEnRetardCount,
    required this.creancesEnRetardMontantRestant,
  });
}

class DashboardService {
  DashboardService({
    VenteService? venteService,
    StockService? stockService,
    ChampParcelleService? champParcelleService,
    CapitalService? capitalService,
    FinancialReportingService? financialReportingService,
    CreanceClientService? creanceClientService,
  }) : _venteService = venteService ?? VenteService(),
       _stockService = stockService ?? StockService(),
       _champParcelleService = champParcelleService ?? ChampParcelleService(),
       _capitalService = capitalService ?? CapitalService(),
       _financialReportingService =
           financialReportingService ?? FinancialReportingService(),
       _creanceClientService = creanceClientService ?? CreanceClientService();

  final VenteService _venteService;
  final StockService _stockService;
  final ChampParcelleService _champParcelleService;
  final CapitalService _capitalService;
  final FinancialReportingService _financialReportingService;
  final CreanceClientService _creanceClientService;

  static const Duration _cacheTtl = Duration(minutes: 2);
  final Map<String, _DashboardCacheEntry> _cache = {};

  Future<DashboardSnapshot> getSnapshot({
    required DashboardPeriod period,
    int topClientsLimit = 8,
  }) async {
    final now = DateTime.now();
    final cached = _cache[period.cacheKey];
    if (cached != null && now.difference(cached.createdAt) < _cacheTtl) {
      return cached.snapshot;
    }

    final issues = <DashboardIssue>[];

    // --- Ventes
    int ventesCount = 0;
    double ventesQuantite = 0.0;
    double ventesMontant = 0.0;
    List<VenteMensuelleStatsModel> ventesParMois = const [];
    List<VenteTopClientStatsModel> topClients = const [];

    try {
      final stats = await _venteService.getStatistiques(
        startDate: period.start,
        endDate: period.end,
      );
      ventesCount = stats['nombreVentes'] as int? ?? 0;
      ventesQuantite = (stats['quantiteTotale'] as num?)?.toDouble() ?? 0.0;
      ventesMontant = (stats['montantTotal'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      issues.add(DashboardIssue('VENTES_STATS', e.toString()));
    }

    try {
      ventesParMois = await _venteService.getVentesParMois(
        startDate: period.start,
        endDate: period.end,
      );
    } catch (e) {
      issues.add(DashboardIssue('VENTES_MOIS', e.toString()));
    }

    try {
      topClients = await _venteService.getTopClients(
        startDate: period.start,
        endDate: period.end,
        limit: topClientsLimit,
        orderBy: 'montant_total',
      );
    } catch (e) {
      issues.add(DashboardIssue('TOP_CLIENTS', e.toString()));
    }

    // --- Stock
    double stockTotalKg = 0.0;
    int adherentsAvecStock = 0;
    int stockCritiqueCount = 0;

    try {
      final stocks = await _stockService.getAllStocksActuels();
      stockTotalKg = stocks.fold<double>(0.0, (sum, s) => sum + s.stockTotal);
      adherentsAvecStock = stocks.where((s) => s.stockTotal > 0).length;
      stockCritiqueCount = stocks
          .where((s) => s.status == StockStatus.critique)
          .length;
    } catch (e) {
      issues.add(DashboardIssue('STOCK', e.toString()));
    }

    // --- Champs / parcelles
    int champsCount = 0;
    double champsSuperficieTotale = 0.0;
    int champsGeolocalisesCount = 0;

    try {
      final stats = await _champParcelleService.getChampsGlobalStats();
      champsCount = stats['nombreChamps'] as int? ?? 0;
      champsSuperficieTotale =
          (stats['superficieTotale'] as num?)?.toDouble() ?? 0.0;
      champsGeolocalisesCount =
          (stats['champsGeolocalises'] as num?)?.toInt() ?? 0;
    } catch (e) {
      issues.add(DashboardIssue('CHAMPS', e.toString()));
    }

    // --- Capital
    double capitalSouscrit = 0.0;
    double capitalLibere = 0.0;
    double capitalRestant = 0.0;
    int nombreActionnaires = 0;
    double valeurPart = 0.0;
    double pourcentageLiberation = 0.0;

    try {
      final cap = await _capitalService.getStatistiquesCapital();
      capitalSouscrit = (cap['capital_souscrit'] as num?)?.toDouble() ?? 0.0;
      capitalLibere = (cap['capital_libere'] as num?)?.toDouble() ?? 0.0;
      capitalRestant = (cap['capital_restant'] as num?)?.toDouble() ?? 0.0;
      nombreActionnaires = cap['nombre_actionnaires'] as int? ?? 0;
      valeurPart = (cap['valeur_part'] as num?)?.toDouble() ?? 0.0;
      pourcentageLiberation =
          (cap['pourcentage_liberation'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      issues.add(DashboardIssue('CAPITAL', e.toString()));
    }

    // --- Finances (mois de la date de fin)
    MonthlyFinancialSummary? monthlyFinancialSummary;
    try {
      monthlyFinancialSummary = await _financialReportingService
          .getMonthlySummary(year: period.end.year, month: period.end.month);
    } catch (e) {
      issues.add(DashboardIssue('FINANCES', e.toString()));
    }

    // --- Créances
    int creancesEnRetardCount = 0;
    double creancesEnRetardMontantRestant = 0.0;
    try {
      final creances = await _creanceClientService.getCreancesEnRetard();
      creancesEnRetardCount = creances.length;
      creancesEnRetardMontantRestant = creances.fold<double>(
        0.0,
        (sum, c) => sum + c.montantRestant,
      );
    } catch (e) {
      issues.add(DashboardIssue('CREANCES', e.toString()));
    }

    final snapshot = DashboardSnapshot(
      period: period,
      generatedAt: now,
      issues: issues,
      ventesCount: ventesCount,
      ventesQuantite: ventesQuantite,
      ventesMontant: ventesMontant,
      ventesParMois: ventesParMois,
      topClients: topClients,
      stockTotalKg: stockTotalKg,
      adherentsAvecStock: adherentsAvecStock,
      stockCritiqueCount: stockCritiqueCount,
      champsCount: champsCount,
      champsSuperficieTotale: champsSuperficieTotale,
      champsGeolocalisesCount: champsGeolocalisesCount,
      capitalSouscrit: capitalSouscrit,
      capitalLibere: capitalLibere,
      capitalRestant: capitalRestant,
      nombreActionnaires: nombreActionnaires,
      valeurPart: valeurPart,
      pourcentageLiberation: pourcentageLiberation,
      monthlyFinancialSummary: monthlyFinancialSummary,
      creancesEnRetardCount: creancesEnRetardCount,
      creancesEnRetardMontantRestant: creancesEnRetardMontantRestant,
    );

    _cache[period.cacheKey] = _DashboardCacheEntry(snapshot: snapshot);
    return snapshot;
  }
}

class _DashboardCacheEntry {
  final DashboardSnapshot snapshot;
  final DateTime createdAt;

  _DashboardCacheEntry({required this.snapshot}) : createdAt = DateTime.now();
}
