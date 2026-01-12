import 'package:flutter/material.dart';

/// Contenu du Dashboard (sans Scaffold)
/// 
/// Cette page est injectée dans le MainLayout.
/// Elle ne contient PAS de Scaffold, AppBar ou menu.
/// 
/// Exemple d'utilisation :
/// ```dart
/// // Dans main_app_shell.dart
/// case AppRoutes.dashboard:
///   screen = const DashboardContent();
/// ```
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la page
          Text(
            'Tableau de bord',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700,
                ),
          ),
          const SizedBox(height: 24),
          // Contenu du dashboard
          Expanded(
            child: _buildDashboardContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    // Exemple de contenu avec cartes statistiques
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          title: 'Adhérents',
          value: '0',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildStatCard(
          context,
          title: 'Stock',
          value: '0 kg',
          icon: Icons.inventory,
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          title: 'Ventes',
          value: '0',
          icon: Icons.shopping_cart,
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          title: 'Recettes',
          value: '0 FCFA',
          icon: Icons.attach_money,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
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
      ),
    );
  }
}

