import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../config/routes/routes.dart';
import '../../config/app_config.dart';
import '../../services/auth/permission_service.dart';
import '../../data/models/user_model.dart';
import 'enhanced_dashboard_screen.dart';

/// Écran Dashboard - Contenu injecté dans MainLayout
/// 
/// Cette page ne contient PAS de Scaffold.
/// Le MainLayout fournit le Header et le Sidebar.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Le MainAppShell gère déjà le MainLayout, donc on retourne directement le contenu
    // EnhancedDashboardScreen ne doit pas contenir de Scaffold
    return const EnhancedDashboardScreen();
  }

  Widget _buildDashboardContent(BuildContext context, UserModel user) {
    // Redirection selon le rôle vers le tableau de bord spécifique
    switch (user.role) {
      case AppConfig.roleAdmin:
        return _buildAdminDashboard(context, user);
      case AppConfig.roleGestionnaireStock:
        return _buildStockManagerDashboard(context, user);
      case AppConfig.roleCaissier:
        return _buildCashierDashboard(context, user);
      case AppConfig.roleConsultation:
        return _buildSupervisorDashboard(context, user);
      default:
        return _buildAdminDashboard(context, user);
    }
  }

  Widget _buildAdminDashboard(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tableau de bord - Administrateur',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade700,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildDashboardCard(
                context,
                title: 'Utilisateurs',
                icon: Icons.people,
                color: Colors.blue,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.users),
              ),
              _buildDashboardCard(
                context,
                title: 'Adhérents',
                icon: Icons.person_add,
                color: Colors.green,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.adherents),
              ),
              _buildDashboardCard(
                context,
                title: 'Stock',
                icon: Icons.inventory,
                color: Colors.orange,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.stock),
              ),
              _buildDashboardCard(
                context,
                title: 'Ventes',
                icon: Icons.shopping_cart,
                color: Colors.purple,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.ventes),
              ),
              _buildDashboardCard(
                context,
                title: 'Recettes',
                icon: Icons.attach_money,
                color: Colors.teal,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.recettes),
              ),
              _buildDashboardCard(
                context,
                title: 'Factures',
                icon: Icons.receipt,
                color: Colors.indigo,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.factures),
              ),
              _buildDashboardCard(
                context,
                title: 'Notifications',
                icon: Icons.notifications,
                color: Colors.amber,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.notifications),
              ),
              _buildDashboardCard(
                context,
                title: 'Paramètres',
                icon: Icons.settings,
                color: Colors.grey,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockManagerDashboard(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tableau de bord - Gestionnaire Stock',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade700,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildDashboardCard(
                context,
                title: 'Adhérents',
                icon: Icons.person_add,
                color: Colors.green,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.adherents),
              ),
              _buildDashboardCard(
                context,
                title: 'Dépôt Stock',
                icon: Icons.inventory,
                color: Colors.orange,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.stockDepot),
              ),
              _buildDashboardCard(
                context,
                title: 'Mouvements',
                icon: Icons.swap_horiz,
                color: Colors.blue,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.stockMouvements),
              ),
              _buildDashboardCard(
                context,
                title: 'Ventes',
                icon: Icons.shopping_cart,
                color: Colors.purple,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.ventes),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashierDashboard(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tableau de bord - Caissier / Comptable',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade700,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildDashboardCard(
                context,
                title: 'Nouvelle Vente',
                icon: Icons.add_shopping_cart,
                color: Colors.green,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.venteIndividuelle),
              ),
              _buildDashboardCard(
                context,
                title: 'Ventes',
                icon: Icons.shopping_cart,
                color: Colors.purple,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.ventes),
              ),
              _buildDashboardCard(
                context,
                title: 'Recettes',
                icon: Icons.attach_money,
                color: Colors.teal,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.recettes),
              ),
              _buildDashboardCard(
                context,
                title: 'Factures',
                icon: Icons.receipt,
                color: Colors.indigo,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.factures),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorDashboard(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tableau de bord - Superviseur',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Mode consultation - Accès en lecture seule',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildDashboardCard(
                context,
                title: 'Adhérents',
                icon: Icons.person_add,
                color: Colors.green,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.adherents),
              ),
              _buildDashboardCard(
                context,
                title: 'Stock',
                icon: Icons.inventory,
                color: Colors.orange,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.stock),
              ),
              _buildDashboardCard(
                context,
                title: 'Ventes',
                icon: Icons.shopping_cart,
                color: Colors.purple,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.ventes),
              ),
              _buildDashboardCard(
                context,
                title: 'Recettes',
                icon: Icons.attach_money,
                color: Colors.teal,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.recettes),
              ),
              _buildDashboardCard(
                context,
                title: 'Factures',
                icon: Icons.receipt,
                color: Colors.indigo,
                onTap: () => Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.factures),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.logout();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }
}

