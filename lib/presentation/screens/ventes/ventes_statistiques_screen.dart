/// Écran de Statistiques Ventes V1
///
/// Affiche les statistiques et analyses des ventes

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/vente_viewmodel.dart';
import '../../../config/routes/routes.dart';
import 'package:intl/intl.dart';
import '../../../config/theme/app_theme.dart';

enum _VentesChartMetric { montant, quantite }

enum _TopClientsMetric { montant, quantite }

class VentesStatistiquesScreen extends StatefulWidget {
  const VentesStatistiquesScreen({super.key});

  @override
  State<VentesStatistiquesScreen> createState() =>
      _VentesStatistiquesScreenState();
}

class _VentesStatistiquesScreenState extends State<VentesStatistiquesScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedAdherentId;

  _VentesChartMetric _metric = _VentesChartMetric.montant;
  _TopClientsMetric _topClientsMetric = _TopClientsMetric.montant;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadVentes();
      viewModel.loadAdherents();
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
                    onPressed: () => Navigator.of(
                      context,
                      rootNavigator: false,
                    ).pushReplacementNamed(AppRoutes.ventes),
                    tooltip: 'Retour',
                  ),
                  const Icon(
                    Icons.analytics,
                    color: AppTheme.venteColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Statistiques des Ventes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.venteColor,
                    ),
                  ),
                  const Spacer(),
                  // Filtres
                  Row(
                    children: [
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
                            _loadStats(viewModel);
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
                            _loadStats(viewModel);
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Statistiques
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStatsContent(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadStats(VenteViewModel viewModel) async {
    await viewModel.getStatistiques(
      startDate: _startDate,
      endDate: _endDate,
      adherentId: _selectedAdherentId,
    );
  }

  Widget _buildStatsContent(BuildContext context, VenteViewModel viewModel) {
    return FutureBuilder<Map<String, dynamic>>(
      future: viewModel.getStatistiques(
        startDate: _startDate,
        endDate: _endDate,
        adherentId: _selectedAdherentId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final stats =
            snapshot.data ??
            {'nombreVentes': 0, 'quantiteTotale': 0.0, 'montantTotal': 0.0};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cartes de statistiques
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Nombre de Ventes',
                      '${stats['nombreVentes']}',
                      Icons.shopping_cart,
                      AppTheme.venteColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Quantité Totale',
                      '${(stats['quantiteTotale'] as num).toStringAsFixed(2)} kg',
                      Icons.scale,
                      AppTheme.stockColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Montant Total',
                      '${NumberFormat('#,##0').format(stats['montantTotal'])} FCFA',
                      Icons.attach_money,
                      AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Graphiques et analyses
              _buildVentesParMois(context, viewModel),
              const SizedBox(height: 24),
              _buildTopClients(context, viewModel),
            ],
          ),
        );
      },
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentesParMois(BuildContext context, VenteViewModel viewModel) {
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
            'Ventes par Mois',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Montant'),
                selected: _metric == _VentesChartMetric.montant,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() => _metric = _VentesChartMetric.montant);
                },
              ),
              ChoiceChip(
                label: const Text('Quantité'),
                selected: _metric == _VentesChartMetric.quantite,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() => _metric = _VentesChartMetric.quantite);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder(
            future: viewModel.getVentesParMois(
              startDate: _startDate,
              endDate: _endDate,
              adherentId: _selectedAdherentId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'Erreur: ${snapshot.error}',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                );
              }

              final allData = snapshot.data ?? const [];
              if (allData.isEmpty) {
                return SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'Aucune donnée sur la période',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
                );
              }

              // Par défaut, on garde une fenêtre lisible (12 mois), tout en permettant le scroll si besoin.
              final data = allData.length > 12
                  ? allData.sublist(allData.length - 12)
                  : allData;

              double maxValue = 0;
              for (final d in data) {
                final v = _metric == _VentesChartMetric.montant
                    ? d.montantTotal
                    : d.quantiteTotale;
                maxValue = math.max(maxValue, v);
              }

              final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.15;
              final interval = _computeNiceInterval(maxY);

              final groups = <BarChartGroupData>[];
              for (var i = 0; i < data.length; i++) {
                final v = _metric == _VentesChartMetric.montant
                    ? data[i].montantTotal
                    : data[i].quantiteTotale;
                groups.add(
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: v,
                        color: AppTheme.venteColor,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }

              final chartWidth = math.max(600.0, data.length * 56.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _metric == _VentesChartMetric.montant
                        ? 'Montant total (FCFA)'
                        : 'Quantité totale (kg)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 240,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        child: BarChart(
                          BarChartData(
                            maxY: maxY,
                            barGroups: groups,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: interval,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.withOpacity(0.15),
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
                                  reservedSize: 56,
                                  interval: interval,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      _metric == _VentesChartMetric.montant
                                          ? _formatCompactNumber(value)
                                          : _formatCompactKg(value),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 34,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= data.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final label = DateFormat(
                                      'MMM yy',
                                    ).format(data[i].mois);
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 8,
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 11,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.black87,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                      final i = group.x.toInt();
                                      if (i < 0 || i >= data.length) {
                                        return null;
                                      }
                                      final monthLabel = DateFormat(
                                        'MMMM yyyy',
                                      ).format(data[i].mois);
                                      final amount = NumberFormat(
                                        '#,##0',
                                      ).format(data[i].montantTotal);
                                      final qty = data[i].quantiteTotale
                                          .toStringAsFixed(2);

                                      final primary =
                                          _metric == _VentesChartMetric.montant
                                          ? '$amount FCFA'
                                          : '$qty kg';
                                      final secondary =
                                          _metric == _VentesChartMetric.montant
                                          ? '$qty kg'
                                          : '$amount FCFA';
                                      return BarTooltipItem(
                                        '$monthLabel\n$primary\n$secondary',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static double _computeNiceInterval(double maxY) {
    if (maxY <= 0) return 1;
    final rough = maxY / 4;
    final pow10 = math
        .pow(10, (math.log(rough) / math.ln10).floor())
        .toDouble();
    final normalized = rough / pow10;

    double step;
    if (normalized <= 1) {
      step = 1;
    } else if (normalized <= 2) {
      step = 2;
    } else if (normalized <= 5) {
      step = 5;
    } else {
      step = 10;
    }
    return step * pow10;
  }

  static String _formatCompactNumber(double value) {
    final abs = value.abs();
    if (abs >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  static String _formatCompactKg(double value) {
    final abs = value.abs();
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}t';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildTopClients(BuildContext context, VenteViewModel viewModel) {
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
            'Top Clients',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Montant'),
                selected: _topClientsMetric == _TopClientsMetric.montant,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() => _topClientsMetric = _TopClientsMetric.montant);
                },
              ),
              ChoiceChip(
                label: const Text('Quantité'),
                selected: _topClientsMetric == _TopClientsMetric.quantite,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(
                    () => _topClientsMetric = _TopClientsMetric.quantite,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder(
            future: viewModel.getTopClients(
              startDate: _startDate,
              endDate: _endDate,
              adherentId: _selectedAdherentId,
              limit: 8,
              orderBy: _topClientsMetric == _TopClientsMetric.montant
                  ? 'montant_total'
                  : 'quantite_totale',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'Erreur: ${snapshot.error}',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                );
              }

              final clients = snapshot.data ?? const [];
              if (clients.isEmpty) {
                return SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      'Aucune donnée client sur la période',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
                );
              }

              double maxValue = 0;
              for (final c in clients) {
                final v = _topClientsMetric == _TopClientsMetric.montant
                    ? c.montantTotal
                    : c.quantiteTotale;
                maxValue = math.max(maxValue, v);
              }
              if (maxValue <= 0) maxValue = 1;

              return Column(
                children: [
                  for (var i = 0; i < clients.length; i++) ...[
                    _buildTopClientRow(
                      rank: i + 1,
                      name: clients[i].clientNom,
                      nombreVentes: clients[i].nombreVentes,
                      montantTotal: clients[i].montantTotal,
                      quantiteTotale: clients[i].quantiteTotale,
                      ratio:
                          (_topClientsMetric == _TopClientsMetric.montant
                              ? clients[i].montantTotal
                              : clients[i].quantiteTotale) /
                          maxValue,
                      metric: _topClientsMetric,
                    ),
                    if (i != clients.length - 1) const Divider(height: 18),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopClientRow({
    required int rank,
    required String name,
    required int nombreVentes,
    required double montantTotal,
    required double quantiteTotale,
    required double ratio,
    required _TopClientsMetric metric,
  }) {
    final displayName = name.trim().isEmpty ? 'Inconnu' : name.trim();
    final primary = metric == _TopClientsMetric.montant
        ? '${NumberFormat('#,##0').format(montantTotal)} FCFA'
        : '${quantiteTotale.toStringAsFixed(2)} kg';
    final secondary = metric == _TopClientsMetric.montant
        ? '${quantiteTotale.toStringAsFixed(2)} kg'
        : '${NumberFormat('#,##0').format(montantTotal)} FCFA';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$rank',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: ratio.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.venteColor),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      primary,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '$nombreVentes vente(s)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                secondary,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
