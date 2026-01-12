import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes/routes.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import 'main_layout.dart';

/// Wrapper principal qui gère la sidebar fixe et la navigation pour toutes les pages
class MainAppWrapper extends StatefulWidget {
  const MainAppWrapper({super.key});

  @override
  State<MainAppWrapper> createState() => _MainAppWrapperState();
}

class _MainAppWrapperState extends State<MainAppWrapper> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _currentRoute = AppRoutes.dashboard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final authViewModel = context.read<AuthViewModel>();
    final user = authViewModel.currentUser;
    if (user != null) {
      await context.read<NotificationViewModel>().loadNotifications(user: user);
    }
  }

  void _onRouteChanged(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MainLayout(
      currentRoute: _currentRoute,
      child: Navigator(
        key: _navigatorKey,
        initialRoute: _currentRoute,
        onGenerateRoute: (settings) {
          // Mettre à jour la route courante
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onRouteChanged(settings.name ?? AppRoutes.dashboard);
          });

          // Retourner la route depuis le générateur de routes global
          return MaterialPageRoute(
            builder: (context) => _buildRoute(settings.name ?? AppRoutes.dashboard, settings.arguments),
            settings: settings,
          );
        },
      ),
    );
  }

  Widget _buildRoute(String route, Object? arguments) {
    // Cette méthode sera remplacée par le système de routes dans main.dart
    // Pour l'instant, on retourne un placeholder
    return const SizedBox();
  }
}
