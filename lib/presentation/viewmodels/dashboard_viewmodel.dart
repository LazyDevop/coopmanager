import 'package:flutter/foundation.dart';

import '../../services/dashboard/dashboard_service.dart';

enum DashboardPeriodPreset {
  last30Days,
  thisMonth,
  thisYear,
}

enum DashboardSalesMetric {
  montant,
  quantite,
}

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({DashboardService? dashboardService})
      : _dashboardService = dashboardService ?? DashboardService();

  final DashboardService _dashboardService;

  DashboardPeriodPreset _periodPreset = DashboardPeriodPreset.last30Days;
  DashboardSalesMetric _salesMetric = DashboardSalesMetric.montant;

  bool _isLoading = false;
  String? _errorMessage;
  DashboardSnapshot? _snapshot;

  DashboardPeriodPreset get periodPreset => _periodPreset;
  DashboardSalesMetric get salesMetric => _salesMetric;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DashboardSnapshot? get snapshot => _snapshot;

  DashboardPeriod get currentPeriod {
    final now = DateTime.now();
    switch (_periodPreset) {
      case DashboardPeriodPreset.last30Days:
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final start = end.subtract(const Duration(days: 29));
        return DashboardPeriod(start: start, end: end, label: '30 derniers jours');
      case DashboardPeriodPreset.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DashboardPeriod(start: start, end: end, label: 'Ce mois');
      case DashboardPeriodPreset.thisYear:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return DashboardPeriod(start: start, end: end, label: 'Cette année');
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _snapshot = await _dashboardService.getSnapshot(period: currentPeriod);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPeriodPreset(DashboardPeriodPreset preset) {
    if (_periodPreset == preset) return;
    _periodPreset = preset;
    notifyListeners();
    refresh();
  }

  void setSalesMetric(DashboardSalesMetric metric) {
    if (_salesMetric == metric) return;
    _salesMetric = metric;
    notifyListeners();
  }
}
