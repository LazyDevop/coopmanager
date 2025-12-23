import 'package:flutter/material.dart';
import '../../../services/navigation/navigation_service.dart';
import '../../../services/auth/permission_service.dart';
import '../../../data/models/user_model.dart';

/// Sidebar fixe de l'application Admin Dashboard
/// 
/// Caractéristiques :
/// - Menu de navigation dynamique selon les rôles
/// - Réduction/expansion animée
/// - Mise en évidence de la route active
/// - Gestion des permissions d'accès
class AppSidebar extends StatelessWidget {
  final bool isExpanded;
  final String currentRoute;
  final List<NavigationItem> modules;
  final UserModel user;
  final VoidCallback onToggle;
  final ValueChanged<String> onNavigate;

  const AppSidebar({
    super.key,
    required this.isExpanded,
    required this.currentRoute,
    required this.modules,
    required this.user,
    required this.onToggle,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? 260 : 70,
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
          _buildSidebarHeader(context),
          const Divider(color: Colors.white24, height: 1),
          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                final isSelected = _isRouteActive(module.route);
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
  Widget _buildSidebarHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: isExpanded
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
    final menuItem = Container(
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
        title: isExpanded
            ? Text(
                module.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              )
            : null,
        selected: isSelected,
        onTap: () => onNavigate(module.route),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    // Wrap with Tooltip when collapsed to show title on hover
    if (!isExpanded) {
      return Tooltip(
        message: module.title,
        child: menuItem,
      );
    }

    return menuItem;
  }

  /// Bouton pour réduire/agrandir la sidebar
  Widget _buildSidebarToggle() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        icon: Icon(
          isExpanded ? Icons.chevron_left : Icons.chevron_right,
          color: Colors.white,
        ),
        onPressed: onToggle,
        tooltip: isExpanded ? 'Réduire le menu' : 'Agrandir le menu',
      ),
    );
  }

  /// Vérifie si une route est active (inclut les sous-routes)
  bool _isRouteActive(String route) {
    return currentRoute == route || currentRoute.startsWith('$route/');
  }
}

