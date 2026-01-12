import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/routes.dart';
import '../../../data/models/vente_mensuelle_stats_model.dart';
import '../../../data/models/vente_top_client_stats_model.dart';
import '../../../services/dashboard/dashboard_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../widgets/common/loading_indicator.dart';

/// Tableau de bord "décision" (sans Scaffold).
///
/// Conçu pour être injecté dans `MainLayout` via `MainAppShell`.
class DecisionDashboardScreen extends StatefulWidget {
  const DecisionDashboardScreen({super.key});

  @override
  State<DecisionDashboardScreen> createState() =>
      _DecisionDashboardScreenState();
}

class _DecisionDashboardScreenState extends State<DecisionDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<DashboardViewModel>().refresh();

      final user = context.read<AuthViewModel>().currentUser;
      if (user != null && mounted) {
        await context.read<NotificationViewModel>().loadNotifications(
          user: user,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final snapshot = vm.snapshot;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            periodPreset: vm.periodPreset,
            onPresetChanged: vm.setPeriodPreset,
            onRefresh: vm.refresh,
          ),
          const SizedBox(height: 16),

          if (vm.isLoading && snapshot == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: LoadingIndicator(
                  message: 'Chargement du tableau de bord...',
                ),
              ),
            )
          else if (vm.errorMessage != null && snapshot == null)
            _ErrorBanner(
              title: 'Impossible de charger le tableau de bord',
              message: vm.errorMessage!,
              onRetry: vm.refresh,
            )
          else if (snapshot != null) ...[
            if (snapshot.issues.isNotEmpty) ...[
              _WarningBanner(
                title: 'Certaines données sont indisponibles',
                message:
                    '${snapshot.issues.length} source(s) ont échoué. Les valeurs manquantes sont remplacées par 0.',
                details: snapshot.issues
                    .map((i) => '${i.code}: ${i.message}')
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            _KpiGrid(snapshot: snapshot),
            const SizedBox(height: 16),

            _QuickActionsRow(),
            const SizedBox(height: 16),

            _Section(
              title: 'Ventes',
              subtitle: vm.currentPeriod.label,
              initiallyExpanded: true,
              child: _VentesSection(
                ventesParMois: snapshot.ventesParMois,
                topClients: snapshot.topClients,
                metric: vm.salesMetric,
                onMetricChanged: vm.setSalesMetric,
              ),
            ),
            _Section(
              title: 'Stock',
              subtitle: 'Qualité et couverture',
              child: _StockSection(snapshot: snapshot),
            ),
            _Section(
              title: 'Finances',
              subtitle: 'Journal comptable / trésorerie',
              child: _FinancesSection(snapshot: snapshot),
            ),
            _Section(
              title: 'Capital social',
              subtitle: 'Souscrit vs libéré',
              child: _CapitalSection(snapshot: snapshot),
            ),
            _Section(
              title: 'Crédits & créances',
              subtitle: 'Retards et exposition',
              child: _CreancesSection(snapshot: snapshot),
            ),
            _Section(
              title: 'Alertes & notifications',
              subtitle: 'À traiter',
              child: _NotificationsSection(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.periodPreset,
    required this.onPresetChanged,
    required this.onRefresh,
  });

  final DashboardPeriodPreset periodPreset;
  final ValueChanged<DashboardPeriodPreset> onPresetChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tableau de bord',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Décision rapide • vue consolidée',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<DashboardPeriodPreset>(
            value: periodPreset,
            decoration: const InputDecoration(
              labelText: 'Période',
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: DashboardPeriodPreset.last30Days,
                child: Text('30 derniers jours'),
              ),
              DropdownMenuItem(
                value: DashboardPeriodPreset.thisMonth,
                child: Text('Ce mois'),
              ),
              DropdownMenuItem(
                value: DashboardPeriodPreset.thisYear,
                child: Text('Cette année'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onPresetChanged(value);
            },
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Rafraîchir',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = <_QuickActionData>[
      _QuickActionData('Ventes', Icons.shopping_cart, AppRoutes.ventes),
      _QuickActionData('Stock', Icons.inventory, AppRoutes.stock),
      _QuickActionData('Recettes', Icons.attach_money, AppRoutes.recettes),
      _QuickActionData('Clients', Icons.storefront, AppRoutes.clients),
      _QuickActionData('Capital', Icons.pie_chart, AppRoutes.capital),
      _QuickActionData(
        'Notifications',
        Icons.notifications,
        AppRoutes.notifications,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions
          .map(
            (a) => ActionChip(
              label: Text(a.label),
              avatar: Icon(a.icon, size: 18),
              onPressed: () => Navigator.of(
                context,
                rootNavigator: false,
              ).pushNamed(a.route),
            ),
          )
          .toList(),
    );
  }
}

class _QuickActionData {
  final String label;
  final IconData icon;
  final String route;

  _QuickActionData(this.label, this.icon, this.route);
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final items = <_KpiItemData>[
      _KpiItemData(
        title: 'Ventes',
        value: '${snapshot.ventesCount}',
        subtitle: 'Transactions',
        icon: Icons.shopping_cart,
        color: Colors.purple,
      ),
      _KpiItemData(
        title: 'Montant',
        value: _formatCurrency(snapshot.ventesMontant),
        subtitle: snapshot.period.label,
        icon: Icons.payments,
        color: Colors.teal,
      ),
      _KpiItemData(
        title: 'Stock total',
        value: '${snapshot.stockTotalKg.toStringAsFixed(1)} kg',
        subtitle: '${snapshot.stockCritiqueCount} critique(s)',
        icon: Icons.inventory,
        color: Colors.orange,
      ),
      _KpiItemData(
        title: 'Champs',
        value: '${snapshot.champsCount}',
        subtitle:
            '${snapshot.champsSuperficieTotale.toStringAsFixed(1)} ha • ${snapshot.champsGeolocalisesCount} géoloc.',
        icon: Icons.agriculture,
        color: Colors.green,
      ),
      _KpiItemData(
        title: 'Créances en retard',
        value: '${snapshot.creancesEnRetardCount}',
        subtitle: _formatCurrency(snapshot.creancesEnRetardMontantRestant),
        icon: Icons.warning_amber,
        color: Colors.red,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1200
            ? 4
            : width >= 900
            ? 3
            : width >= 600
            ? 2
            : 1;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: items.map((i) => _KpiCard(item: i)).toList(),
        );
      },
    );
  }
}

class _KpiItemData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  _KpiItemData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});

  final _KpiItemData item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _VentesSection extends StatelessWidget {
  const _VentesSection({
    required this.ventesParMois,
    required this.topClients,
    required this.metric,
    required this.onMetricChanged,
  });

  final List<VenteMensuelleStatsModel> ventesParMois;
  final List<VenteTopClientStatsModel> topClients;
  final DashboardSalesMetric metric;
  final ValueChanged<DashboardSalesMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Montant'),
              selected: metric == DashboardSalesMetric.montant,
              onSelected: (_) => onMetricChanged(DashboardSalesMetric.montant),
            ),
            ChoiceChip(
              label: const Text('Quantité'),
              selected: metric == DashboardSalesMetric.quantite,
              onSelected: (_) => onMetricChanged(DashboardSalesMetric.quantite),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SalesBarChart(ventesParMois: ventesParMois, metric: metric),
        const SizedBox(height: 16),
        Text(
          'Top clients',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _TopClientsList(topClients: topClients, metric: metric),
      ],
    );
  }
}

class _SalesBarChart extends StatelessWidget {
  const _SalesBarChart({required this.ventesParMois, required this.metric});

  final List<VenteMensuelleStatsModel> ventesParMois;
  final DashboardSalesMetric metric;

  @override
  Widget build(BuildContext context) {
    if (ventesParMois.isEmpty) {
      return _EmptyState(message: 'Aucune vente sur la période.');
    }

    double maxY = 0.0;
    for (final row in ventesParMois) {
      final v = metric == DashboardSalesMetric.montant
          ? row.montantTotal
          : row.quantiteTotale;
      if (v > maxY) maxY = v;
    }
    if (maxY <= 0) maxY = 1.0;
    final interval = maxY / 4;

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.1,
          gridData: FlGridData(show: true),
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
                interval: interval <= 0 ? 1.0 : interval,
                reservedSize: 44,
                getTitlesWidget: (value, meta) => Text(
                  metric == DashboardSalesMetric.montant
                      ? _shortCurrency(value)
                      : value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= ventesParMois.length)
                    return const SizedBox.shrink();
                  final m = ventesParMois[i].mois;
                  final label =
                      '${m.month.toString().padLeft(2, '0')}/${m.year.toString().substring(2)}';
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(ventesParMois.length, (i) {
            final row = ventesParMois[i];
            final y = metric == DashboardSalesMetric.montant
                ? row.montantTotal
                : row.quantiteTotale;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: y,
                  color: Colors.brown.shade600,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _TopClientsList extends StatelessWidget {
  const _TopClientsList({required this.topClients, required this.metric});

  final List<VenteTopClientStatsModel> topClients;
  final DashboardSalesMetric metric;

  @override
  Widget build(BuildContext context) {
    if (topClients.isEmpty) {
      return _EmptyState(message: 'Aucun client sur la période.');
    }

    final maxValue = topClients
        .map<double>(
          (c) => metric == DashboardSalesMetric.montant
              ? c.montantTotal
              : c.quantiteTotale,
        )
        .fold<double>(0.0, (a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Column(
      children: List.generate(topClients.length, (index) {
        final c = topClients[index];
        final value = metric == DashboardSalesMetric.montant
            ? c.montantTotal
            : c.quantiteTotale;
        final ratio = (value / safeMax).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.clientNom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          metric == DashboardSalesMetric.montant
                              ? _formatCurrency(value)
                              : '${value.toStringAsFixed(1)} kg',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.brown.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.nombreVentes} vente(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StockSection extends StatelessWidget {
  const _StockSection({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total: ${snapshot.stockTotalKg.toStringAsFixed(1)} kg • ${snapshot.adherentsAvecStock} adhérent(s) avec stock • ${snapshot.stockCritiqueCount} critique(s)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _HintCard(
          icon: Icons.info_outline,
          title: 'Astuce',
          message:
              'Pour voir le détail par adhérent et par qualité, utilisez le module Stock.',
          actionLabel: 'Ouvrir Stock',
          onAction: () => Navigator.of(
            context,
            rootNavigator: false,
          ).pushNamed(AppRoutes.stock),
        ),
      ],
    );
  }
}

class _FinancesSection extends StatelessWidget {
  const _FinancesSection({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final monthly = snapshot.monthlyFinancialSummary;
    if (monthly == null) {
      return _EmptyState(message: 'Aucune donnée comptable disponible.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MiniStat(
              label: 'Ventes (mois)',
              value: _formatCurrency(monthly.totalVentes),
            ),
            _MiniStat(
              label: 'Paiements',
              value: _formatCurrency(monthly.totalPaiements),
            ),
            _MiniStat(
              label: 'Charges',
              value: _formatCurrency(monthly.totalCharges),
            ),
            _MiniStat(
              label: 'Trésorerie',
              value: _formatCurrency(monthly.soldeTresorerie),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HintCard(
          icon: Icons.analytics_outlined,
          title: 'Reporting',
          message:
              'Le détail du journal et du bilan se trouve dans Comptabilité.',
          actionLabel: 'Ouvrir Comptabilité',
          onAction: () => Navigator.of(
            context,
            rootNavigator: false,
          ).pushNamed(AppRoutes.comptabilite),
        ),
      ],
    );
  }
}

class _CapitalSection extends StatelessWidget {
  const _CapitalSection({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final progress = (snapshot.pourcentageLiberation / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Souscrit: ${_formatCurrency(snapshot.capitalSouscrit)} • Libéré: ${_formatCurrency(snapshot.capitalLibere)} • Restant: ${_formatCurrency(snapshot.capitalRestant)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: progress,
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
          color: Colors.green.shade600,
          backgroundColor: Colors.grey.shade200,
        ),
        const SizedBox(height: 8),
        Text(
          'Libération: ${snapshot.pourcentageLiberation.toStringAsFixed(1)}% • Actionnaires: ${snapshot.nombreActionnaires} • Valeur part: ${_formatCurrency(snapshot.valeurPart)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.of(
              context,
              rootNavigator: false,
            ).pushNamed(AppRoutes.capital),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir module Capital'),
          ),
        ),
      ],
    );
  }
}

class _CreancesSection extends StatelessWidget {
  const _CreancesSection({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Créances en retard: ${snapshot.creancesEnRetardCount} • Montant restant: ${_formatCurrency(snapshot.creancesEnRetardMontantRestant)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _HintCard(
          icon: Icons.person_search,
          title: 'Actions rapides',
          message:
              'Ouvrez la liste des clients pour identifier les impayés et débloquer les cas réglés.',
          actionLabel: 'Ouvrir Clients',
          onAction: () => Navigator.of(
            context,
            rootNavigator: false,
          ).pushNamed(AppRoutes.clients),
        ),
      ],
    );
  }
}

class _NotificationsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final items = vm.notifications.take(5).toList();

    if (vm.isLoading && vm.notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LoadingIndicator(message: 'Chargement des notifications...'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Non lues: ${vm.unreadCount}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const _EmptyState(message: 'Aucune notification récente.')
        else
          ...items.map(
            (n) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                n.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
              ),
              title: Text(
                n.titre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                n.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: TextButton(
                onPressed: () => Navigator.of(
                  context,
                  rootNavigator: false,
                ).pushNamed(AppRoutes.notifications),
                child: const Text('Voir'),
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: Colors.brown.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(message, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.grey.shade700)),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(message, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.title,
    required this.message,
    required this.details,
  });

  final String title;
  final String message;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(message, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Détails techniques'),
            children: details
                .take(10)
                .map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $d',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(num value) {
  // Format simple (évite dépendance intl). Ajustable ensuite.
  final v = value.toDouble();
  return '${v.toStringAsFixed(0)} FCFA';
}

String _shortCurrency(num value) {
  final v = value.toDouble();
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}
