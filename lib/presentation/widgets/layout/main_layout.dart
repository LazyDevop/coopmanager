import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/app_theme.dart';
import '../../../services/auth/permission_service.dart';
import '../../../data/models/user_model.dart';
import '../common/status_badge.dart';

/// Layout principal avec menu latéral et barre supérieure
class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final String title;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.title,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isMenuCollapsed = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Utiliser Consumer pour notificationViewModel pour éviter les rebuilds pendant le build
    return Consumer<NotificationViewModel>(
      builder: (context, notificationViewModel, _) {
        return _buildLayout(context, user, notificationViewModel);
      },
    );
  }
  
  Widget _buildLayout(
    BuildContext context,
    UserModel user,
    NotificationViewModel notificationViewModel,
  ) {
    return Scaffold(
          body: Row(
            children: [
              // Menu latéral
              _buildSidebar(context, user, notificationViewModel),
              // Contenu principal
              Expanded(
                child: Column(
                  children: [
                    // Barre supérieure
                    _buildTopBar(context, user, notificationViewModel),
                    // Contenu
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    UserModel user,
    NotificationViewModel notificationViewModel,
  ) {
    return Container(
      width: _isMenuCollapsed ? 80 : 260,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
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
          // Logo et titre
          Container(
            padding: const EdgeInsets.all(16),
            child: _isMenuCollapsed
                ? const Icon(Icons.eco, color: Colors.white, size: 32)
                : Column(
                    children: [
                      const Icon(Icons.eco, color: Colors.white, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'CoopManager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Gestion Coopérative',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
          const Divider(color: Colors.white24, height: 1),
          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard,
                  label: 'Tableau de bord',
                  route: AppRoutes.dashboard,
                  isActive: widget.currentRoute == AppRoutes.dashboard,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people,
                  label: 'Adhérents',
                  route: AppRoutes.adherents,
                  isActive: widget.currentRoute == AppRoutes.adherents ||
                      widget.currentRoute.startsWith('/adherent'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory,
                  label: 'Stock',
                  route: AppRoutes.stock,
                  isActive: widget.currentRoute == AppRoutes.stock ||
                      widget.currentRoute.startsWith('/stock'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.shopping_cart,
                  label: 'Ventes',
                  route: AppRoutes.ventes,
                  isActive: widget.currentRoute == AppRoutes.ventes ||
                      widget.currentRoute.startsWith('/vente'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.attach_money,
                  label: 'Recettes',
                  route: AppRoutes.recettes,
                  isActive: widget.currentRoute == AppRoutes.recettes ||
                      widget.currentRoute.startsWith('/recette'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.receipt,
                  label: 'Facturation',
                  route: AppRoutes.factures,
                  isActive: widget.currentRoute == AppRoutes.factures ||
                      widget.currentRoute.startsWith('/facture'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings,
                  label: 'Paramétrage',
                  route: AppRoutes.parametrage,
                  isActive: widget.currentRoute == AppRoutes.parametrage ||
                      widget.currentRoute.startsWith('/parametres'),
                  badge: PermissionService.hasPermission(user, 'manage_settings')
                      ? null
                      : Icons.lock,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.notifications,
                  label: 'Notifications',
                  route: AppRoutes.notifications,
                  isActive: widget.currentRoute == AppRoutes.notifications,
                  badge: notificationViewModel.unreadCount > 0
                      ? notificationViewModel.unreadCount.toString()
                      : null,
                ),
              ],
            ),
          ),
          // Bouton collapse/expand
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(
                _isMenuCollapsed ? Icons.chevron_right : Icons.chevron_left,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isMenuCollapsed = !_isMenuCollapsed;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    String? badge,
    IconData? badgeIcon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: SizedBox(
          width: 24,
          child: Icon(icon, color: Colors.white),
        ),
        title: _isMenuCollapsed
            ? null
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
        trailing: _isMenuCollapsed
            ? null
            : (badge != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : badgeIcon != null
                    ? Icon(badgeIcon, color: Colors.white70, size: 16)
                    : null),
        onTap: () {
          if (route != widget.currentRoute) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTopBar(
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Titre de la page
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
          // Recherche globale
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                // TODO: Implémenter la recherche globale
              },
            ),
          ),
          const SizedBox(width: 16),
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 28),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
              if (notificationViewModel.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notificationViewModel.unreadCount > 9
                          ? '9+'
                          : notificationViewModel.unreadCount.toString(),
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
          ),
          const SizedBox(width: 8),
          // Profil utilisateur
          PopupMenuButton<String>(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    user.prenom[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${user.prenom} ${user.nom}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      PermissionService.getRoleDisplayName(user.role),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
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
                        Text('${user.prenom} ${user.nom}'),
                        Text(
                          PermissionService.getRoleDisplayName(user.role),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
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
                    Icon(Icons.logout, color: AppTheme.errorColor, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Déconnexion',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
