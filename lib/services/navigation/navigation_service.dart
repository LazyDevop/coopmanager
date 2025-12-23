import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../config/routes/routes.dart';
import '../../data/models/user_model.dart';
import '../../services/auth/permission_service.dart';

class NavigationItem {
  final String title;
  final IconData icon;
  final String route;
  final String module;
  final List<String> requiredPermissions;

  const NavigationItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.module,
    this.requiredPermissions = const [],
  });
}

class NavigationService {
  /// Obtenir les modules accessibles selon le rôle
  static List<NavigationItem> getAccessibleModules(UserModel user) {
    final allModules = _getAllModules();
    return allModules.where((module) {
      if (user.role == AppConfig.roleAdmin) {
        return true; // Admin a accès à tout
      }
      return PermissionService.canAccessModule(user, module.module);
    }).toList();
  }

  /// Obtenir tous les modules disponibles
  static List<NavigationItem> _getAllModules() {
    return [
      NavigationItem(
        title: 'Tableau de bord',
        icon: Icons.dashboard,
        route: AppRoutes.dashboard,
        module: 'dashboard',
      ),
      NavigationItem(
        title: 'Adhérents',
        icon: Icons.people,
        route: AppRoutes.adherents,
        module: 'adherents',
      ),
      NavigationItem(
        title: 'Stock',
        icon: Icons.inventory,
        route: AppRoutes.stock,
        module: 'stock',
      ),
      NavigationItem(
        title: 'Ventes',
        icon: Icons.shopping_cart,
        route: AppRoutes.ventes,
        module: 'ventes',
      ),
      NavigationItem(
        title: 'Recettes',
        icon: Icons.attach_money,
        route: AppRoutes.recettes,
        module: 'recettes',
      ),
      NavigationItem(
        title: 'Facturation',
        icon: Icons.receipt_long,
        route: AppRoutes.factures,
        module: 'factures',
      ),
      NavigationItem(
        title: 'Notifications',
        icon: Icons.notifications,
        route: AppRoutes.notifications,
        module: 'notifications',
      ),
      NavigationItem(
        title: 'Paramétrage',
        icon: Icons.settings,
        route: AppRoutes.settings,
        module: 'settings',
      ),
      // V2: Nouveaux modules
      NavigationItem(
        title: 'Clients',
        icon: Icons.business,
        route: AppRoutes.clients,
        module: 'clients',
      ),
      NavigationItem(
        title: 'Capital Social',
        icon: Icons.account_balance,
        route: AppRoutes.capital,
        module: 'capital',
      ),
      NavigationItem(
        title: 'Comptabilité',
        icon: Icons.calculate,
        route: AppRoutes.comptabilite,
        module: 'comptabilite',
      ),
      NavigationItem(
        title: 'Social',
        icon: Icons.favorite,
        route: AppRoutes.social,
        module: 'social',
      ),
    ];
  }

  /// Obtenir les modules pour le menu latéral selon le rôle
  static List<NavigationItem> getSidebarModules(UserModel user) {
    final accessibleModules = getAccessibleModules(user);
    
    // Filtrer selon les règles spécifiques par rôle
    switch (user.role) {
      case AppConfig.roleAdmin:
        return accessibleModules; // Tous les modules
      
      case AppConfig.roleCaissier:
        return accessibleModules.where((module) {
          return ['dashboard', 'ventes', 'recettes', 'factures', 'clients', 'notifications']
              .contains(module.module);
        }).toList();
      
      case AppConfig.roleGestionnaireStock:
        return accessibleModules.where((module) {
          return ['dashboard', 'adherents', 'stock', 'notifications']
              .contains(module.module);
        }).toList();
      
      case AppConfig.roleComptable:
        return accessibleModules.where((module) {
          return ['dashboard', 'ventes', 'recettes', 'factures', 'comptabilite', 'notifications']
              .contains(module.module);
        }).toList();
      
      case AppConfig.roleResponsableSocial:
        return accessibleModules.where((module) {
          return ['dashboard', 'adherents', 'social', 'notifications']
              .contains(module.module);
        }).toList();
      
      default:
        return accessibleModules;
    }
  }
}
