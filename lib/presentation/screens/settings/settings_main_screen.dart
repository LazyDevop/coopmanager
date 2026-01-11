import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/parametres_viewmodel.dart';
import '../../../services/auth/permission_service.dart';
import '../parametres/parametres_overview_screen.dart';
import 'cooperative_settings_screen.dart';
import 'general_settings_screen.dart';
import 'capital_settings_screen.dart';
import 'accounting_settings_screen.dart';
import 'sales_settings_screen.dart';
import 'document_settings_screen.dart';
import 'social_settings_screen.dart';
import 'users_roles_settings_screen.dart';
import 'module_settings_screen.dart';
import '../commissions/commissions_list_screen.dart';

/// Écran principal de navigation pour le module de paramétrage
class SettingsMainScreen extends StatefulWidget {
  const SettingsMainScreen({super.key});

  @override
  State<SettingsMainScreen> createState() => _SettingsMainScreenState();
}

class _SettingsMainScreenState extends State<SettingsMainScreen> {
  int _selectedIndex = 0;
  
  // Méthode pour changer l'index depuis un enfant
  void _changeSelectedIndex(int index) {
    if (index >= 0 && index < _menuItems.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  final List<SettingsMenuItem> _menuItems = [
    SettingsMenuItem(
      title: 'Vue d\'ensemble',
      icon: Icons.dashboard,
      screen: ParametresOverviewScreen(
        onNavigateToTab: null, // Pas de TabController ici
      ),
      category: 'overview',
    ),
    SettingsMenuItem(
      title: 'Coopérative',
      icon: Icons.business,
      screen: const CooperativeSettingsScreen(),
      category: 'cooperative',
    ),
    SettingsMenuItem(
      title: 'Général',
      icon: Icons.settings,
      screen: const GeneralSettingsScreen(),
      category: 'general',
    ),
    SettingsMenuItem(
      title: 'Capital Social',
      icon: Icons.account_balance,
      screen: const CapitalSettingsScreen(),
      category: 'capital',
    ),
    SettingsMenuItem(
      title: 'Comptabilité',
      icon: Icons.calculate,
      screen: const AccountingSettingsScreen(),
      category: 'accounting',
    ),
    SettingsMenuItem(
      title: 'Ventes & Prix',
      icon: Icons.shopping_cart,
      screen: const SalesSettingsScreen(),
      category: 'sales',
    ),
    SettingsMenuItem(
      title: 'Gestion des Commissions',
      icon: Icons.account_balance_wallet,
      screen: const CommissionsListScreen(),
      category: 'commissions',
    ),
    SettingsMenuItem(
      title: 'Documents & QR Code',
      icon: Icons.description,
      screen: const DocumentSettingsScreen(),
      category: 'document',
    ),
    SettingsMenuItem(
      title: 'Social',
      icon: Icons.people,
      screen: const SocialSettingsScreen(),
      category: 'social',
    ),
    SettingsMenuItem(
      title: 'Utilisateurs & Rôles',
      icon: Icons.person,
      screen: const UsersRolesSettingsScreen(),
      category: 'users',
    ),
    SettingsMenuItem(
      title: 'Modules & Sécurité',
      icon: Icons.security,
      screen: const ModuleSettingsScreen(),
      category: 'module',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final currentUser = authViewModel.currentUser;
      if (currentUser != null) {
        final settingsProvider = context.read<SettingsProvider>();
        settingsProvider.initialize(currentUser.id.toString());
        
        // Charger TOUTES les données pour la vue d'ensemble
        settingsProvider.loadAllSettings();
        
        // Charger les données de l'ancien système aussi
        final parametresViewModel = context.read<ParametresViewModel>();
        parametresViewModel.loadParametres();
        parametresViewModel.loadCampagnes();
        parametresViewModel.loadBaremes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    // Vérifier les permissions
    if (currentUser == null ||
        !PermissionService.hasPermission(currentUser, 'manage_settings')) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Paramétrage'),
          backgroundColor: Colors.brown.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Vous n\'avez pas les permissions nécessaires pour accéder à cette section.',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramétrage'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: isWideScreen
          ? Row(
              children: [
                // Menu latéral pour écrans larges
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    border: Border(
                      right: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: _buildMenuList(context),
                ),
                // Contenu
                Expanded(
                  child: _selectedIndex == 0
                      ? ParametresOverviewScreen(
                          onNavigateToTab: (index) {
                            // Mapper les index de ParametresMainScreen vers SettingsMainScreen
                            // 1 -> Coopérative (index 1), 2 -> Ventes & Prix (index 5), etc.
                            switch (index) {
                              case 1: // Informations -> Coopérative
                                _changeSelectedIndex(1);
                                break;
                              case 2: // Finances -> Ventes & Prix
                                _changeSelectedIndex(5);
                                break;
                              case 3: // Campagnes -> Général (ou autre)
                                _changeSelectedIndex(2);
                                break;
                            }
                          },
                        )
                      : _menuItems[_selectedIndex].screen,
                ),
              ],
            )
          : _selectedIndex == 0
              ? ParametresOverviewScreen(
                  onNavigateToTab: (index) {
                    switch (index) {
                      case 1:
                        _changeSelectedIndex(1);
                        break;
                      case 2:
                        _changeSelectedIndex(5);
                        break;
                      case 3:
                        _changeSelectedIndex(2);
                        break;
                    }
                  },
                )
              : _menuItems[_selectedIndex].screen,
      drawer: isWideScreen
          ? null
          : Drawer(
              child: _buildMenuList(context),
            ),
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                Navigator.of(context).pop(); // Fermer le drawer
              },
              destinations: _menuItems.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.title,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
          ),
          child: Text(
            'Paramétrage',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        ...List.generate(_menuItems.length, (index) {
          final item = _menuItems[index];
          final isSelected = _selectedIndex == index;

          return ListTile(
            leading: Icon(
              item.icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(item.title),
            selected: isSelected,
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
              if (MediaQuery.of(context).size.width <= 800) {
                Navigator.of(context).pop();
              }
            },
            tileColor: isSelected
                ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                : null,
          );
        }),
      ],
    );
  }
}

class SettingsMenuItem {
  final String title;
  final IconData icon;
  final Widget screen;
  final String category;

  SettingsMenuItem({
    required this.title,
    required this.icon,
    required this.screen,
    required this.category,
  });
}

