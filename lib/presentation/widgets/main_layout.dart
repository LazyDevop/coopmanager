import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes/routes.dart';
import '../../data/models/user_model.dart';
import '../../services/auth/permission_service.dart';
import '../../services/navigation/navigation_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import 'common/toast_helper.dart';

/// Layout principal avec menu latéral et barre supérieure
class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
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
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Éviter d'accéder directement à notificationViewModel dans le build
    // Utiliser Consumer pour isoler les changements
    return Consumer<NotificationViewModel>(
      builder: (context, notificationViewModel, _) {
        final sidebarModules = NavigationService.getSidebarModules(user);
        return _buildScaffold(context, user, sidebarModules);
      },
    );
  }
  
  Widget _buildScaffold(
    BuildContext context,
    UserModel user,
    List<NavigationItem> sidebarModules,
  ) {
    return Scaffold(
      body: Row(
        children: [
          // Menu latéral
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSidebarExpanded ? 260 : 70,
            child: _buildSidebar(context, user, sidebarModules),
          ),
          // Contenu principal
          Expanded(
            child: Column(
              children: [
                // Barre supérieure
                _buildTopBar(context, user),
                // Contenu
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    UserModel user,
    List<NavigationItem> modules,
  ) {
    return Container(
      color: Colors.brown.shade800,
      child: Column(
        children: [
          // En-tête du menu
          Container(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
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
          ),
          const Divider(color: Colors.white24, height: 1),
          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                final isSelected = widget.currentRoute == module.route;
                return _buildMenuItem(context, module, isSelected);
              },
            ),
          ),
          // Bouton pour réduire/agrandir
          Padding(
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
            ),
          ),
        ],
      ),
    );
  }

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
          if (widget.currentRoute != module.route) {
            // Utiliser le Navigator le plus proche (celui dans MainAppShell)
            // Cela garantit que la sidebar reste visible
            Navigator.of(context, rootNavigator: false).pushReplacementNamed(module.route);
          }
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, UserModel user) {
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
          // Recherche globale
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Notifications
          _buildNotificationButton(context, user),
          const SizedBox(width: 16),
          // Profil utilisateur
          _buildUserProfile(context, user),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, UserModel user) {
    return Consumer<NotificationViewModel>(
      builder: (context, notificationViewModel, child) {
        final unreadCount = notificationViewModel.unreadCount;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 28),
              onPressed: () {
                // Utiliser le Navigator interne pour garder la sidebar
                Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.notifications);
              },
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
      },
    );
  }

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
                PermissionService.getRoleDisplayName(user.role),
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
          // TODO: Naviguer vers le profil
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

  Future<void> _handleLogout(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.logout();
    // Ne pas naviguer manuellement, AuthWrapper gère automatiquement la transition
    // via le Consumer qui écoute les changements d'état
  }
}
