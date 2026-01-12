import 'package:flutter/material.dart';

import 'dashboard/decision_dashboard_screen.dart';

/// Écran Dashboard - Contenu injecté dans MainLayout
///
/// Cette page ne contient PAS de Scaffold.
/// Le MainLayout fournit le Header et le Sidebar.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecisionDashboardScreen();
  }
}
