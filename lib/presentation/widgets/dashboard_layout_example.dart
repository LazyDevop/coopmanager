import 'package:flutter/material.dart';
import '../../config/routes/routes.dart';
import 'dashboard_layout.dart';
import '../screens/enhanced_dashboard_screen.dart';

/// Exemple d'utilisation du DashboardLayout
/// 
/// Ce fichier montre comment utiliser le DashboardLayout dans une page.
/// Le DashboardLayout gère automatiquement :
/// - La sidebar avec navigation
/// - Le header fixe
/// - La mise en évidence de la route active
/// 
/// Les pages n'ont plus besoin de gérer leur propre Scaffold/AppBar,
/// elles retournent simplement leur contenu.
class DashboardLayoutExample extends StatelessWidget {
  const DashboardLayoutExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Le DashboardLayout gère tout le layout (sidebar + header)
    // La page retourne uniquement son contenu
    return const DashboardLayout(
      currentRoute: AppRoutes.dashboard,
      child: EnhancedDashboardScreen(),
    );
  }
}

/// Exemple de page simple utilisant DashboardLayout
class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: AppRoutes.adherents,
      onRouteChanged: (route) {
        // Callback optionnel appelé lors du changement de route
        debugPrint('Route changée vers: $route');
      },
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.brown),
            SizedBox(height: 16),
            Text(
              'Page Exemple',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cette page utilise DashboardLayout',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
