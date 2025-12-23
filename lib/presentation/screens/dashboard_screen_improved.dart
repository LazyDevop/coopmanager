import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/adherent_viewmodel.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/vente_viewmodel.dart';
import '../viewmodels/recette_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../../config/routes/routes.dart';
import '../../config/theme/app_theme.dart';
import '../widgets/layout/main_layout.dart';
import '../widgets/dashboard/dashboard_stats.dart';
import '../widgets/dashboard/dashboard_charts.dart';
import '../widgets/common/stat_card.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/loading_indicator.dart';

/// Tableau de bord amélioré avec graphiques et statistiques
class DashboardScreenImproved extends StatefulWidget {
  const DashboardScreenImproved({super.key});

  @override
  State<DashboardScreenImproved> createState() => _DashboardScreenImprovedState();
}

class _DashboardScreenImprovedState extends State<DashboardScreenImproved> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final context = this.context;
    await Future.wait([
      context.read<AdherentViewModel>().loadAdherents(),
      context.read<StockViewModel>().loadStocksActuels(),
      context.read<VenteViewModel>().loadVentes(),
      context.read<RecetteViewModel>().loadRecettes(),
      context.read<NotificationViewModel>().loadNotifications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    if (user == null) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Chargement...'),
      );
    }

    return MainLayout(
      currentRoute: AppRoutes.dashboard,
      title: 'Tableau de bord',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec salutation
            _buildHeader(context, user),
            const SizedBox(height: 24),
            // Statistiques principales
            const DashboardStats(),
            const SizedBox(height: 24),
            // Alertes et notifications importantes
            _buildAlerts(context),
            const SizedBox(height: 24),
            // Graphiques
            _buildCharts(context),
            const SizedBox(height: 24),
            // Actions rapides
            _buildQuickActions(context, user),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Bonjour';
    } else if (hour < 18) {
      greeting = 'Bon après-midi';
    } else {
      greeting = 'Bonsoir';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, ${user.prenom}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bienvenue sur votre tableau de bord',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
        // Date actuelle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                DateTime.now().day.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                _getMonthName(DateTime.now().month),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlerts(BuildContext context) {
    return Consumer<StockViewModel>(
      builder: (context, stockVM, _) {
        final lowStockItems = stockVM.stocksActuels
            .where((stock) => stock.stockTotal <= 50.0)
            .toList();

        if (lowStockItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          color: AppTheme.warningColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.warningColor.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.warningColor,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alertes de stock',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lowStockItems.length} adhérent${lowStockItems.length > 1 ? 's' : ''} avec stock faible',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.stock);
                  },
                  child: const Text('Voir détails'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharts(BuildContext context) {
    return Consumer2<VenteViewModel, RecetteViewModel>(
      builder: (context, venteVM, recetteVM, _) {
        // Données pour les graphiques (exemple)
        final salesData = {
          'Lun': 150000.0,
          'Mar': 180000.0,
          'Mer': 200000.0,
          'Jeu': 170000.0,
          'Ven': 220000.0,
          'Sam': 190000.0,
          'Dim': 160000.0,
        };

        final stockDistribution = {
          'Premium': 45.0,
          'Standard': 35.0,
          'Bio': 20.0,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyses et tendances',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: SalesBarChart(
                    data: salesData,
                    title: 'Ventes de la semaine',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: PieChartWidget(
                    data: stockDistribution,
                    title: 'Répartition du stock',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.add_shopping_cart,
                title: 'Nouvelle vente',
                color: AppTheme.venteColor,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.venteIndividuelle);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.inventory_2,
                title: 'Dépôt de stock',
                color: AppTheme.stockColor,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.stockDepot);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.person_add,
                title: 'Nouvel adhérent',
                color: AppTheme.adherentColor,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.adherentAdd);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.receipt_long,
                title: 'Générer facture',
                color: AppTheme.factureColor,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.factures);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return months[month - 1];
  }
}
