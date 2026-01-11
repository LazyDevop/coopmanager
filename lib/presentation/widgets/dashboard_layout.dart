import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes/routes.dart';
import '../../data/models/user_model.dart';
import '../../services/navigation/navigation_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../providers/permission_provider.dart';
import 'common/toast_helper.dart';
import '../../../config/app_config.dart';
import '../../../services/auth/permission_service.dart';

/// Layout principal de type Dashboard/Admin Panel
/// 
/// Caractéristiques :
/// - Header fixe en haut
/// - Sidebar fixe à gauche avec menu de navigation
/// - Zone de contenu dynamique à droite
/// - Compatible desktop et web Flutter
/// - Navigation sans recréer le layout complet
/// 
/// Usage :
/// ```dart
/// DashboardLayout(
///   currentRoute: AppRoutes.dashboard,
///   child: YourPageContent(),
/// )
/// ```
class DashboardLayout extends StatefulWidget {
  /// Contenu dynamique de la page (remplacé lors de la navigation)
  final Widget child;
  
  /// Route actuelle pour mettre en évidence l'élément de menu actif
  final String currentRoute;
  
  /// Callback optionnel appelé lors du changement de route
  final ValueChanged<String>? onRouteChanged;
  
  /// Fonction pour construire les écrans selon la route (optionnel)
  /// Si fournie, sera utilisée pour construire les écrans lors de la navigation
  final Widget Function(String route, Object? arguments)? routeBuilder;

  const DashboardLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    this.onRouteChanged,
    this.routeBuilder,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  bool _isSidebarExpanded = true;

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
    debugPrint('🔵 [DashboardLayout] build() appelé');
    debugPrint('🔵 [DashboardLayout] Route actuelle: ${widget.currentRoute}');
    
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    if (user == null) {
      debugPrint('🔵 [DashboardLayout] Utilisateur null, affichage loading');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Utiliser Consumer pour isoler les changements de NotificationViewModel et PermissionProvider
    return Consumer2<NotificationViewModel, PermissionProvider>(
      builder: (context, notificationViewModel, permissionProvider, _) {
        return FutureBuilder<List<NavigationItem>>(
          future: NavigationService.getAccessibleModules(permissionProvider),
          builder: (context, snapshot) {
            final sidebarModules = snapshot.data ?? [];
            debugPrint('🔵 [DashboardLayout] Modules sidebar: ${sidebarModules.length}');
            debugPrint('🔵 [DashboardLayout] Construction du scaffold');
            return _buildScaffold(context, user, sidebarModules, notificationViewModel);
          },
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    UserModel user,
    List<NavigationItem> sidebarModules,
    NotificationViewModel notificationViewModel,
  ) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar fixe à gauche
          _buildSidebar(context, user, sidebarModules),
          // Zone de contenu principale
          Expanded(
            child: Column(
              children: [
                // Header fixe en haut
                _buildHeader(context, user, notificationViewModel),
                // Contenu dynamique (remplacé lors de la navigation)
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la sidebar avec menu de navigation
  Widget _buildSidebar(
    BuildContext context,
    UserModel user,
    List<NavigationItem> modules,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarExpanded ? 260 : 70,
      decoration: BoxDecoration(
        color: Colors.brown.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête du menu (Logo + Titre)
          _buildSidebarHeader(context, user),
          const Divider(color: Colors.white24, height: 1),
          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                final isSelected = widget.currentRoute == module.route ||
                    widget.currentRoute.startsWith('${module.route}/');
                return _buildMenuItem(context, module, isSelected);
              },
            ),
          ),
          // Bouton pour réduire/agrandir la sidebar
          _buildSidebarToggle(),
        ],
      ),
    );
  }

  /// En-tête de la sidebar avec logo et informations utilisateur
  Widget _buildSidebarHeader(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _isSidebarExpanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CoopManager',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  PermissionService.getRoleDisplayName(user.role),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            )
          : const Icon(
              Icons.store,
              color: Colors.white,
              size: 32,
            ),
    );
  }

  /// Construit un élément de menu
  Widget _buildMenuItem(
    BuildContext context,
    NavigationItem module,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.brown.shade600 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: SizedBox(
          width: 24,
          child: Icon(
            module.icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: _isSidebarExpanded
            ? Text(
                module.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              )
            : null,
        selected: isSelected,
        onTap: () {
          debugPrint('🔵 [DashboardLayout] Clic sur menu item: ${module.title} (route: ${module.route})');
          debugPrint('🔵 [DashboardLayout] Route actuelle: ${widget.currentRoute}');
          
          if (widget.currentRoute != module.route) {
            debugPrint('🟢 [DashboardLayout] Navigation vers: ${module.route}');
            
            // Utiliser le Navigator interne pour garder la sidebar visible
            final navigator = Navigator.of(context, rootNavigator: false);
            debugPrint('🟢 [DashboardLayout] Navigator trouvé: ${navigator != null}');
            debugPrint('🟢 [DashboardLayout] Tentative de navigation vers: ${module.route}');
            
            // Si routeBuilder est fourni, construire l'écran directement
            if (widget.routeBuilder != null) {
              debugPrint('🟢 [DashboardLayout] Utilisation de routeBuilder pour construire l\'écran');
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) {
                    debugPrint('🟢 [DashboardLayout] MaterialPageRoute builder appelé pour: ${module.route}');
                    return widget.routeBuilder!(module.route, null);
                  },
                  settings: RouteSettings(name: module.route),
                ),
              ).then((_) {
                debugPrint('✅ [DashboardLayout] Navigation terminée vers: ${module.route}');
                // Vérifier que le widget est toujours monté avant d'appeler le callback
                if (mounted) {
                  widget.onRouteChanged?.call(module.route);
                } else {
                  debugPrint('🟡 [DashboardLayout] Widget non monté, ignore le callback onRouteChanged');
                }
              }).catchError((error) {
                debugPrint('❌ [DashboardLayout] Erreur navigation: $error');
              });
            } else {
              // Sinon, utiliser pushReplacementNamed
              debugPrint('🟢 [DashboardLayout] Appel de pushReplacementNamed avec route: ${module.route}');
              navigator.pushReplacementNamed(module.route).then((_) {
                debugPrint('✅ [DashboardLayout] Navigation terminée vers: ${module.route}');
                // Vérifier que le widget est toujours monté avant d'appeler le callback
                if (mounted) {
                  widget.onRouteChanged?.call(module.route);
                } else {
                  debugPrint('🟡 [DashboardLayout] Widget non monté, ignore le callback onRouteChanged');
                }
              }).catchError((error) {
                debugPrint('❌ [DashboardLayout] Erreur navigation: $error');
                debugPrint('❌ [DashboardLayout] Stack trace: ${StackTrace.current}');
              });
            }
            
            debugPrint('🟢 [DashboardLayout] Navigation déclenchée vers: ${module.route}');
          } else {
            debugPrint('🟡 [DashboardLayout] Route déjà active, pas de navigation');
          }
        },
      ),
    );
  }

  /// Bouton pour réduire/agrandir la sidebar
  Widget _buildSidebarToggle() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        icon: Icon(
          _isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
          color: Colors.white,
        ),
        onPressed: () {
          setState(() {
            _isSidebarExpanded = !_isSidebarExpanded;
          });
        },
        tooltip: _isSidebarExpanded ? 'Réduire le menu' : 'Agrandir le menu',
      ),
    );
  }

  /// Construit le header fixe en haut
  Widget _buildHeader(
    BuildContext context,
    UserModel user,
    NotificationViewModel notificationViewModel,
  ) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Barre de recherche globale
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Bouton notifications
          _buildNotificationButton(context, notificationViewModel),
          const SizedBox(width: 16),
          // Profil utilisateur
          _buildUserProfile(context, user),
        ],
      ),
    );
  }

  /// Bouton de notifications avec badge
  Widget _buildNotificationButton(
    BuildContext context,
    NotificationViewModel notificationViewModel,
  ) {
    final unreadCount = notificationViewModel.unreadCount;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 28),
          onPressed: () {
            Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.notifications);
          },
          tooltip: 'Notifications',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Profil utilisateur avec menu déroulant
  Widget _buildUserProfile(BuildContext context, UserModel user) {
    return PopupMenuButton<String>(
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.brown.shade700,
            child: Text(
              user.prenom[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                PermissionProvider.getRoleDisplayName(user.role),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
      onSelected: (value) {
        if (value == 'logout') {
          _handleLogout(context);
        } else if (value == 'profile') {
          ToastHelper.showInfo('Profil utilisateur (à venir)');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email ?? 'Aucun email',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Déconnexion', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  /// Gère la déconnexion
  Future<void> _handleLogout(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.logout();
    // Ne pas naviguer manuellement, AuthWrapper gère automatiquement la transition
    // via le Consumer qui écoute les changements d'état
  }
}
