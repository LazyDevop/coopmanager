import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes/routes.dart';
import '../../data/models/user_model.dart';
import '../../services/navigation/navigation_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../providers/permission_provider.dart';
import 'header/app_header.dart';
import 'sidebar/app_sidebar.dart';
import '../widgets/common/loading_overlay.dart';

/// Layout principal global de l'application Admin Dashboard
/// 
/// Ce widget est le seul layout global de l'application. Il contient :
/// - Un Header fixe en haut
/// - Un Sidebar fixe à gauche
/// - Une zone de contenu dynamique au centre
/// 
/// Toutes les pages métiers doivent être injectées dans ce layout
/// et ne doivent PAS contenir de Scaffold.
/// 
/// Usage :
/// ```dart
/// MainLayout(
///   currentRoute: AppRoutes.dashboard,
///   child: DashboardContent(),
/// )
/// ```
class MainLayout extends StatefulWidget {
  /// Contenu dynamique de la page (remplacé lors de la navigation)
  final Widget child;
  
  /// Route actuelle pour mettre en évidence l'élément de menu actif
  final String currentRoute;
  
  /// Callback optionnel appelé lors du changement de route
  final ValueChanged<String>? onRouteChanged;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    this.onRouteChanged,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isSidebarExpanded = true;
  Future<List<NavigationItem>>? _cachedModulesFuture;
  PermissionProvider? _cachedPermissionProvider;

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

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final permissionProvider = context.watch<PermissionProvider>();
    
    // Mémoriser le Future pour éviter les reconstructions inutiles
    if (_cachedModulesFuture == null || _cachedPermissionProvider != permissionProvider) {
      _cachedModulesFuture = NavigationService.getSidebarModules(permissionProvider);
      _cachedPermissionProvider = permissionProvider;
    }
    
    return FutureBuilder<List<NavigationItem>>(
      key: ValueKey(_cachedPermissionProvider),
      future: _cachedModulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Erreur: ${snapshot.error}'),
            ),
          );
        }
        
        final sidebarModules = snapshot.data ?? [];
        // Utiliser Selector uniquement pour NotificationViewModel dans _buildLayout
        return Selector<NotificationViewModel, NotificationViewModel>(
          selector: (_, vm) => vm,
          shouldRebuild: (prev, next) => false, // Ne pas reconstruire à cause de NotificationViewModel
          builder: (context, notificationViewModel, _) {
            return _buildLayout(context, user, sidebarModules, notificationViewModel);
          },
        );
      },
    );
  }

  Widget _buildLayout(
    BuildContext context,
    UserModel user,
    List<NavigationItem> sidebarModules,
    NotificationViewModel notificationViewModel,
  ) {
    return Scaffold(
      body: Stack(
        children: [
          // Layout principal
          Row(
            children: [
              // Sidebar fixe à gauche
              AppSidebar(
                isExpanded: _isSidebarExpanded,
                currentRoute: widget.currentRoute,
                modules: sidebarModules,
                user: user,
                onToggle: () {
                  setState(() {
                    _isSidebarExpanded = !_isSidebarExpanded;
                  });
                },
                onNavigate: (route) {
                  // La navigation est gérée par MainAppShell via le callback
                  if (widget.currentRoute != route) {
                    widget.onRouteChanged?.call(route);
                  }
                },
              ),
              // Zone de contenu principale
              Expanded(
                child: Column(
                  children: [
                    // Header fixe en haut
                    AppHeader(
                      user: user,
                      notificationViewModel: notificationViewModel,
                    ),
                    // Contenu dynamique (remplacé lors de la navigation)
                    Expanded(
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Overlay de chargement global
          const LoadingOverlay(),
        ],
      ),
    );
  }
}

