import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../config/routes/routes.dart';
import '../../data/models/user_model.dart';
import '../../data/models/permissions/ui_view_model.dart';
import '../../presentation/providers/permission_provider.dart';

class NavigationItem {
  final String title;
  final IconData icon;
  final String route;
  final String module;
  final List<String> requiredPermissions;
  final String? uiViewCode; // Code de la vue UI associée

  const NavigationItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.module,
    this.requiredPermissions = const [],
    this.uiViewCode,
  });
}

class NavigationService {
  /// Obtenir les modules accessibles selon les permissions
  static Future<List<NavigationItem>> getAccessibleModules(PermissionProvider permissionProvider) async {
    final accessibleViews = permissionProvider.accessibleViews;
    
    // Si aucune vue n'est chargée, retourner les modules par défaut (fallback)
    if (accessibleViews.isEmpty) {
      return _getAllModules();
    }
    
    // Convertir les vues UI en NavigationItem
    final items = <NavigationItem>[];
    for (final view in accessibleViews) {
      items.add(NavigationItem(
        title: view.name,
        icon: _getIconFromString(view.icon ?? ''),
        route: view.route,
        module: view.code,
        uiViewCode: view.code,
      ));
    }
    
    // Trier par displayOrder
    items.sort((a, b) {
      final viewA = accessibleViews.firstWhere((v) => v.code == a.uiViewCode);
      final viewB = accessibleViews.firstWhere((v) => v.code == b.uiViewCode);
      return viewA.displayOrder.compareTo(viewB.displayOrder);
    });
    
    return items;
  }
  
  /// Obtenir l'icône depuis une chaîne
  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'dashboard': return Icons.dashboard;
      case 'people': return Icons.people;
      case 'inventory': return Icons.inventory;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'payments': return Icons.payments;
      case 'receipt': return Icons.receipt;
      case 'credit_card': return Icons.credit_card;
      case 'account_balance': return Icons.account_balance;
      case 'settings': return Icons.settings;
      case 'assessment': return Icons.assessment;
      case 'business': return Icons.business;
      case 'notifications': return Icons.notifications;
      default: return Icons.folder;
    }
  }
  
  /// Obtenir les modules accessibles selon le rôle (méthode legacy pour compatibilité)
  static List<NavigationItem> getAccessibleModulesLegacy(UserModel user) {
    final allModules = _getAllModules();
    return allModules.where((module) {
      // SuperAdmin et Admin ont accès à tout
      if (user.role == AppConfig.roleSuperAdmin || user.role == AppConfig.roleAdmin) {
        return true;
      }
      // Logique legacy simplifiée - sera filtré par les permissions réelles
      return true;
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
        route: AppRoutes.settingsMain,
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

  /// Obtenir les modules pour le menu latéral selon le rôle (méthode legacy pour compatibilité)
  /// Note: Cette méthode est dépréciée, utilisez getAccessibleModules avec PermissionProvider
  @Deprecated('Utilisez getAccessibleModules avec PermissionProvider')
  static Future<List<NavigationItem>> getSidebarModules(PermissionProvider permissionProvider) async {
    final accessibleModules = await getAccessibleModules(permissionProvider);
    
    // Le filtrage par rôle est maintenant géré par les permissions dans la base de données
    // Cette méthode retourne simplement les modules accessibles
    return accessibleModules;
  }
}
