import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_config.dart';
import '../../data/models/user_model.dart';
import '../../services/auth/permission_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/adherent_viewmodel.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/vente_viewmodel.dart';
import '../viewmodels/recette_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../widgets/common/stat_card.dart';
import '../widgets/common/loading_indicator.dart';

/// Dashboard amélioré avec graphiques et statistiques par rôle
class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({super.key});

  @override
  State<EnhancedDashboardScreen> createState() {
    debugPrint('📱 [EnhancedDashboardScreen] createState() appelé');
    return _EnhancedDashboardScreenState();
  }
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Différer le chargement pour éviter notifyListeners() pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    // Charger les données nécessaires selon le rôle
    final authViewModel = context.read<AuthViewModel>();
    final user = authViewModel.currentUser;

    if (user == null || !mounted) return;

    // Charger les données communes
    if (!mounted) return;
    await context.read<NotificationViewModel>().loadNotifications(user: user);

    if (!mounted) return;

    // Charger les données selon le rôle
    switch (user.role) {
      case AppConfig.roleAdmin:
        await _loadAdminData();
        break;
      case AppConfig.roleCaissier:
        await _loadCaissierData();
        break;
      case AppConfig.roleGestionnaireStock:
        await _loadMagasinierData();
        break;
    }
  }

  Future<void> _loadAdminData() async {
    if (!mounted) return;
    await Future.wait<void>([
      if (mounted) context.read<AdherentViewModel>().loadAdherents(),
      if (mounted) context.read<StockViewModel>().loadStock(),
      if (mounted) context.read<VenteViewModel>().loadVentes(),
      if (mounted) context.read<RecetteViewModel>().loadRecettes(),
    ]);
  }

  Future<void> _loadCaissierData() async {
    if (!mounted) return;
    await Future.wait<void>([
      if (mounted) context.read<VenteViewModel>().loadVentes(),
      if (mounted) context.read<RecetteViewModel>().loadRecettes(),
    ]);
  }

  Future<void> _loadMagasinierData() async {
    if (!mounted) return;
    await Future.wait<void>([
      if (mounted) context.read<AdherentViewModel>().loadAdherents(),
      if (mounted) context.read<StockViewModel>().loadStock(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📱 [EnhancedDashboardScreen] build() appelé');
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    if (user == null) {
      // Ne pas utiliser Scaffold ici car DashboardLayout fournit déjà le Scaffold
      return const Center(child: LoadingIndicator(message: 'Chargement...'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, user),
          const SizedBox(height: 24),
          _buildStatsCards(context, user),
          const SizedBox(height: 24),
          _buildCharts(context, user),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
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
              PermissionService.getRoleDisplayName(user.role),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
        Text(
          _getGreeting(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  Widget _buildStatsCards(BuildContext context, UserModel user) {
    switch (user.role) {
      case AppConfig.roleAdmin:
        return _buildAdminStatsCards(context);
      case AppConfig.roleCaissier:
        return _buildCaissierStatsCards(context);
      case AppConfig.roleGestionnaireStock:
        return _buildMagasinierStatsCards(context);
      default:
        return _buildAdminStatsCards(context);
    }
  }

  Widget _buildAdminStatsCards(BuildContext context) {
    final adherentViewModel = context.watch<AdherentViewModel>();
    final stockViewModel = context.watch<StockViewModel>();
    final venteViewModel = context.watch<VenteViewModel>();
    final recetteViewModel = context.watch<RecetteViewModel>();
    final notificationViewModel = context.watch<NotificationViewModel>();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        StatCard(
          title: 'Adhérents',
          value: '${adherentViewModel.adherents.length}',
          icon: Icons.people,
          color: Colors.blue,
        ),
        StatCard(
          title: 'Stock total',
          value: '${_formatStock(stockViewModel.totalStock)} kg',
          icon: Icons.inventory,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Ventes',
          value: '${venteViewModel.ventes.length}',
          icon: Icons.shopping_cart,
          color: Colors.purple,
        ),
        StatCard(
          title: 'Recettes',
          value: _formatCurrency(recetteViewModel.totalRecettes),
          icon: Icons.attach_money,
          color: Colors.teal,
        ),
        StatCard(
          title: 'Paiements',
          value: _formatCurrency(_calculateTotalPaiements(venteViewModel)),
          icon: Icons.payment,
          color: Colors.green,
        ),
        StatCard(
          title: 'Alertes',
          value: '${notificationViewModel.unreadCount}',
          icon: Icons.notifications_active,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildCaissierStatsCards(BuildContext context) {
    final venteViewModel = context.watch<VenteViewModel>();
    final recetteViewModel = context.watch<RecetteViewModel>();
    final notificationViewModel = context.watch<NotificationViewModel>();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        StatCard(
          title: 'Ventes',
          value: '${venteViewModel.ventes.length}',
          icon: Icons.shopping_cart,
          color: Colors.purple,
        ),
        StatCard(
          title: 'Recettes nettes',
          value: _formatCurrency(recetteViewModel.totalRecettes),
          icon: Icons.attach_money,
          color: Colors.teal,
        ),
        StatCard(
          title: 'Paiements en attente',
          value: '${_countPendingPayments(venteViewModel)}',
          icon: Icons.pending,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMagasinierStatsCards(BuildContext context) {
    final stockViewModel = context.watch<StockViewModel>();
    final notificationViewModel = context.watch<NotificationViewModel>();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        StatCard(
          title: 'Stock total',
          value: '${_formatStock(stockViewModel.totalStock)} kg',
          icon: Icons.inventory,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Dépôts récents',
          value: '${_countRecentDepots(stockViewModel)}',
          icon: Icons.add_box,
          color: Colors.green,
        ),
        StatCard(
          title: 'Stocks faibles',
          value: '${_countLowStocks(stockViewModel)}',
          icon: Icons.warning,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildCharts(BuildContext context, UserModel user) {
    switch (user.role) {
      case AppConfig.roleAdmin:
        return _buildAdminCharts(context);
      case AppConfig.roleCaissier:
        return _buildCaissierCharts(context);
      case AppConfig.roleGestionnaireStock:
        return _buildMagasinierCharts(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAdminCharts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Graphiques',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildVentesChart(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStockChart(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCaissierCharts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Graphiques',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildVentesChart(context),
      ],
    );
  }

  Widget _buildMagasinierCharts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Graphiques',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildStockChart(context),
      ],
    );
  }

  Widget _buildVentesChart(BuildContext context) {
    final venteViewModel = context.watch<VenteViewModel>();
    
    // Générer des données de démonstration (à remplacer par de vraies données)
    final chartData = _generateVentesChartData(venteViewModel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution des ventes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.purple.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockChart(BuildContext context) {
    final stockViewModel = context.watch<StockViewModel>();
    
    // Générer des données de démonstration
    final chartData = _generateStockChartData(stockViewModel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution du stock',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: chartData,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateVentesChartData(VenteViewModel viewModel) {
    // Générer des données de démonstration (7 derniers jours)
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return FlSpot(
        index.toDouble(),
        (viewModel.ventes.length * (0.5 + (index % 3) * 0.2)).toDouble(),
      );
    });
  }

  List<BarChartGroupData> _generateStockChartData(StockViewModel viewModel) {
    // Générer des données de démonstration (7 derniers jours)
    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (viewModel.totalStock * (0.7 + (index % 3) * 0.1)),
            color: Colors.orange,
            width: 16,
          ),
        ],
      );
    });
  }

  // Méthodes utilitaires
  String _formatStock(double stock) {
    return stock.toStringAsFixed(2);
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} FCFA';
  }

  double _calculateTotalPaiements(VenteViewModel viewModel) {
    // Calculer le total des paiements (à adapter selon votre modèle)
    return viewModel.ventes.length * 50000.0; // Exemple
  }

  int _countPendingPayments(VenteViewModel viewModel) {
    // Compter les paiements en attente (à adapter selon votre modèle)
    return viewModel.ventes.length ~/ 3; // Exemple
  }

  int _countRecentDepots(StockViewModel viewModel) {
    // Compter les dépôts récents (à adapter selon votre modèle)
    return 5; // Exemple
  }

  int _countLowStocks(StockViewModel viewModel) {
    // Compter les stocks faibles (à adapter selon votre modèle)
    return 3; // Exemple
  }
}
