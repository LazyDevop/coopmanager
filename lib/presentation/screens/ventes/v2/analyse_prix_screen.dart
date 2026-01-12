/// Écran d'Analyse Prix/Marge V2
///
/// Analyse des prix et marges avec graphiques et indicateurs

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/vente_viewmodel.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/routes/routes.dart';
import 'package:intl/intl.dart';

enum _PrixGrouping { auto, day, week, month }

class AnalysePrixScreen extends StatefulWidget {
  const AnalysePrixScreen({super.key});

  @override
  State<AnalysePrixScreen> createState() => _AnalysePrixScreenState();
}

class _AnalysePrixScreenState extends State<AnalysePrixScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedCampagneId;

  int _quickRangeDays = 30;
  _PrixGrouping _grouping = _PrixGrouping.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadVentes();
      viewModel.loadCampagnes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VenteViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      final navigator = Navigator.of(
                        context,
                        rootNavigator: false,
                      );
                      if (navigator.canPop()) {
                        navigator.pop();
                      } else {
                        navigator.pushNamed(AppRoutes.ventes);
                      }
                    },
                    tooltip: 'Retour',
                  ),
                  const Icon(
                    Icons.trending_up,
                    color: AppTheme.venteColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Analyse Prix / Marge',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.venteColor,
                    ),
                  ),
                  const Spacer(),
                  // Filtres
                  ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _startDate == null
                          ? 'Date début'
                          : DateFormat('dd/MM/yyyy').format(_startDate!),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _endDate == null
                          ? 'Date fin'
                          : DateFormat('dd/MM/yyyy').format(_endDate!),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Contenu d'analyse
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAnalyseContent(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyseContent(BuildContext context, VenteViewModel viewModel) {
    final ventes = viewModel.ventes.where((v) {
      if (_startDate != null && v.dateVente.isBefore(_startDate!)) return false;
      if (_endDate != null && v.dateVente.isAfter(_endDate!)) return false;
      if (_selectedCampagneId != null && v.campagneId != _selectedCampagneId)
        return false;
      return true;
    }).toList();

    if (ventes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée à analyser',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Calculs
    final prixMoyen = ventes.isEmpty
        ? 0.0
        : ventes.fold<double>(0.0, (sum, v) => sum + v.prixUnitaire) /
              ventes.length;

    final prixMin = ventes.isEmpty
        ? 0.0
        : ventes.map((v) => v.prixUnitaire).reduce((a, b) => a < b ? a : b);

    final prixMax = ventes.isEmpty
        ? 0.0
        : ventes.map((v) => v.prixUnitaire).reduce((a, b) => a > b ? a : b);

    final margeTotale = ventes.fold<double>(
      0.0,
      (sum, v) => sum + (v.montantCommission),
    );

    final margeMoyenne = ventes.isEmpty ? 0.0 : margeTotale / ventes.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicateurs clés
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Prix Moyen',
                  '${NumberFormat('#,##0').format(prixMoyen)} FCFA/kg',
                  Icons.attach_money,
                  AppTheme.venteColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Prix Min',
                  '${NumberFormat('#,##0').format(prixMin)} FCFA/kg',
                  Icons.trending_down,
                  AppTheme.infoColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Prix Max',
                  '${NumberFormat('#,##0').format(prixMax)} FCFA/kg',
                  Icons.trending_up,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Marge Totale',
                  '${NumberFormat('#,##0').format(margeTotale)} FCFA',
                  Icons.account_balance,
                  AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Marge Moyenne',
                  '${NumberFormat('#,##0').format(margeMoyenne)} FCFA',
                  Icons.analytics,
                  AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Évolution des prix
          _buildEvolutionPrix(context, ventes),
          const SizedBox(height: 24),
          // Top ventes
          _buildTopVentes(context, ventes),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionPrix(BuildContext context, List ventes) {
    final currency = NumberFormat('#,##0');

    // Si l'utilisateur choisit une période rapide, on applique aussi le filtre dates.
    DateTime? effectiveStart = _startDate;
    DateTime? effectiveEnd = _endDate;
    if (effectiveStart == null && effectiveEnd == null) {
      final now = DateTime.now();
      effectiveEnd = now;
      effectiveStart = now.subtract(Duration(days: _quickRangeDays));
    }

    // Filtrer sur la période effective (si définie)
    final filtered = ventes.where((v) {
      final DateTime dt = v.dateVente as DateTime;
      if (effectiveStart != null && dt.isBefore(effectiveStart)) return false;
      if (effectiveEnd != null && dt.isAfter(effectiveEnd)) return false;
      return true;
    }).toList();

    final grouping = _resolveGrouping(filtered, _grouping);
    final points = _aggregatePrixPoints(filtered, grouping);
    final spots = <FlSpot>[
      for (int i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].avg),
    ];

    final minY = spots.isEmpty
        ? 0.0
        : spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.isEmpty
        ? 0.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final avgY = spots.isEmpty
        ? 0.0
        : spots.fold<double>(0.0, (s, p) => s + p.y) / spots.length;

    final last = points.isNotEmpty ? points.last : null;
    final prev = points.length >= 2 ? points[points.length - 2] : null;
    final delta = (last != null && prev != null) ? (last.avg - prev.avg) : null;
    final deltaPct = (delta != null && prev!.avg != 0)
        ? (delta / prev.avg) * 100
        : null;
    final deltaUp = (delta ?? 0) >= 0;
    final deltaColor = delta == null
        ? Colors.grey
        : (deltaUp ? Colors.green : Colors.red);

    String formatBottom(DateTime start, DateTime end) {
      switch (grouping) {
        case _PrixGrouping.day:
          return DateFormat('dd/MM').format(start);
        case _PrixGrouping.week:
          return 'S${_isoWeekNumber(start)}';
        case _PrixGrouping.month:
          return DateFormat('MM/yy').format(start);
        case _PrixGrouping.auto:
          return DateFormat('dd/MM').format(start);
      }
    }

    String formatTooltip(_PrixPoint p) {
      final value = '${currency.format(p.avg)} FCFA/kg';
      switch (grouping) {
        case _PrixGrouping.day:
          return '${DateFormat('dd/MM/yyyy').format(p.start)}\n$value\n(${p.count} vente(s))';
        case _PrixGrouping.week:
          return 'Semaine ${_isoWeekNumber(p.start)} (${DateFormat('dd/MM').format(p.start)} → ${DateFormat('dd/MM').format(p.end)})\n$value\n(${p.count} vente(s))';
        case _PrixGrouping.month:
          return '${DateFormat('MMMM yyyy', 'fr_FR').format(p.start)}\n$value\n(${p.count} vente(s))';
        case _PrixGrouping.auto:
          return '${DateFormat('dd/MM/yyyy').format(p.start)}\n$value\n(${p.count} vente(s))';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Évolution des Prix',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildRangeChip('7j', 7),
                  _buildRangeChip('30j', 30),
                  _buildRangeChip('90j', 90),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                    child: const Text('Tout'),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<_PrixGrouping>(
                      value: _grouping,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: _PrixGrouping.auto,
                          child: Text('Auto'),
                        ),
                        DropdownMenuItem(
                          value: _PrixGrouping.day,
                          child: Text('Jour'),
                        ),
                        DropdownMenuItem(
                          value: _PrixGrouping.week,
                          child: Text('Semaine'),
                        ),
                        DropdownMenuItem(
                          value: _PrixGrouping.month,
                          child: Text('Mois'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _grouping = v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMiniStat(
                label: 'Min',
                value: spots.isEmpty ? '-' : '${currency.format(minY)}',
              ),
              const SizedBox(width: 16),
              _buildMiniStat(
                label: 'Moy',
                value: spots.isEmpty ? '-' : '${currency.format(avgY)}',
              ),
              const SizedBox(width: 16),
              _buildMiniStat(
                label: 'Max',
                value: spots.isEmpty ? '-' : '${currency.format(maxY)}',
              ),
              const Spacer(),
              if (last != null)
                Row(
                  children: [
                    Icon(
                      delta == null
                          ? Icons.remove
                          : (deltaUp ? Icons.trending_up : Icons.trending_down),
                      color: deltaColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      delta == null
                          ? '—'
                          : '${currency.format(delta!.abs())} (${deltaPct == null ? '—' : '${deltaPct.abs().toStringAsFixed(1)}%'})',
                      style: TextStyle(
                        color: deltaColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'Pas de données de prix sur la période',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: minY - ((maxY - minY).abs() * 0.08),
                      maxY: maxY + ((maxY - minY).abs() * 0.08),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: ((maxY - minY) / 4).abs() > 0
                            ? ((maxY - minY) / 4).abs()
                            : 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 58,
                            interval: ((maxY - minY) / 4).abs() > 0
                                ? ((maxY - minY) / 4).abs()
                                : 1,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  _formatCompact(currency, value),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: points.length <= 7
                                ? 1
                                : (points.length / 6).ceilToDouble(),
                            getTitlesWidget: (value, meta) {
                              final idx = value.round();
                              if (idx < 0 || idx >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  formatBottom(
                                    points[idx].start,
                                    points[idx].end,
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: avgY,
                            color: Colors.grey.withOpacity(0.35),
                            strokeWidth: 1,
                            dashArray: [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              padding: const EdgeInsets.only(
                                right: 6,
                                bottom: 2,
                              ),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                              labelResolver: (_) => 'Moy.',
                            ),
                          ),
                        ],
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 3,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.venteColor.withOpacity(0.6),
                              AppTheme.venteColor,
                            ],
                          ),
                          dotData: FlDotData(
                            show: true,
                            checkToShowDot: (spot, barData) {
                              return spot.x == spots.last.x;
                            },
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppTheme.venteColor,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.venteColor.withOpacity(0.20),
                                AppTheme.venteColor.withOpacity(0.02),
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.black.withOpacity(0.78),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((ts) {
                              final i = ts.x.round();
                              final p = points[i];
                              return LineTooltipItem(
                                formatTooltip(p),
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, int days) {
    final selected =
        _startDate == null && _endDate == null && _quickRangeDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.venteColor.withOpacity(0.18),
      labelStyle: TextStyle(
        color: selected ? AppTheme.venteColor : Colors.black87,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (_) {
        setState(() {
          _quickRangeDays = days;
          // On repasse en mode "période rapide" (dates null)
          _startDate = null;
          _endDate = null;
        });
      },
    );
  }

  Widget _buildMiniStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  static String _formatCompact(NumberFormat base, double value) {
    final abs = value.abs();
    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return base.format(value);
  }

  static _PrixGrouping _resolveGrouping(List ventes, _PrixGrouping selected) {
    if (selected != _PrixGrouping.auto) return selected;
    if (ventes.isEmpty) return _PrixGrouping.day;

    DateTime min = ventes.first.dateVente as DateTime;
    DateTime max = ventes.first.dateVente as DateTime;
    for (final v in ventes) {
      final dt = v.dateVente as DateTime;
      if (dt.isBefore(min)) min = dt;
      if (dt.isAfter(max)) max = dt;
    }
    final spanDays = max.difference(min).inDays.abs();
    if (spanDays >= 180) return _PrixGrouping.month;
    if (spanDays >= 60) return _PrixGrouping.week;
    return _PrixGrouping.day;
  }

  static List<_PrixPoint> _aggregatePrixPoints(
    List ventes,
    _PrixGrouping grouping,
  ) {
    final Map<DateTime, _MutableBucket> buckets = {};

    for (final v in ventes) {
      final DateTime dtRaw = v.dateVente as DateTime;
      final dt = DateTime(dtRaw.year, dtRaw.month, dtRaw.day);
      final double price = (v.prixUnitaire as num).toDouble();

      DateTime start;
      DateTime end;
      switch (grouping) {
        case _PrixGrouping.day:
          start = dt;
          end = dt;
          break;
        case _PrixGrouping.week:
          start = dt.subtract(Duration(days: dt.weekday - DateTime.monday));
          end = start.add(const Duration(days: 6));
          break;
        case _PrixGrouping.month:
          start = DateTime(dt.year, dt.month, 1);
          end = DateTime(dt.year, dt.month + 1, 0);
          break;
        case _PrixGrouping.auto:
          start = dt;
          end = dt;
          break;
      }

      final bucket = buckets.putIfAbsent(
        start,
        () => _MutableBucket(start: start, end: end),
      );
      bucket.end = end;
      bucket.sum += price;
      bucket.count += 1;
    }

    final keys = buckets.keys.toList()..sort();
    return [
      for (final k in keys)
        _PrixPoint(
          start: buckets[k]!.start,
          end: buckets[k]!.end,
          avg: buckets[k]!.count == 0 ? 0 : buckets[k]!.sum / buckets[k]!.count,
          count: buckets[k]!.count,
        ),
    ];
  }

  static int _isoWeekNumber(DateTime date) {
    // ISO week date weeks start on Monday
    final thursday = date.add(
      Duration(days: 4 - (date.weekday == 7 ? 7 : date.weekday)),
    );
    final firstThursday = DateTime(thursday.year, 1, 4);
    final diff = thursday.difference(firstThursday);
    return 1 + (diff.inDays / 7).floor();
  }

  Widget _buildTopVentes(BuildContext context, List ventes) {
    final topVentes = ventes.toList()
      ..sort((a, b) => b.montantTotal.compareTo(a.montantTotal));
    final top5 = topVentes.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 Ventes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (top5.isEmpty)
            Center(
              child: Text(
                'Aucune vente',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
          else
            ...top5.asMap().entries.map((entry) {
              final index = entry.key;
              final vente = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.venteColor.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.venteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text('Vente #${vente.id}'),
                subtitle: Text(
                  '${vente.quantiteTotal.toStringAsFixed(2)} kg - ${DateFormat('dd/MM/yyyy').format(vente.dateVente)}',
                ),
                trailing: Text(
                  '${NumberFormat('#,##0').format(vente.montantTotal)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.venteColor,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PrixPoint {
  final DateTime start;
  final DateTime end;
  final double avg;
  final int count;

  const _PrixPoint({
    required this.start,
    required this.end,
    required this.avg,
    required this.count,
  });
}

class _MutableBucket {
  final DateTime start;
  DateTime end;
  double sum = 0;
  int count = 0;

  _MutableBucket({required this.start, required this.end});
}
