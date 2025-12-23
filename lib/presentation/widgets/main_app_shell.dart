import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes/routes.dart';
import '../../data/models/user_model.dart';
import '../../services/navigation/navigation_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../layout/main_layout.dart';
import '../screens/dashboard_screen.dart';
import '../screens/adherents/adherents_list_screen.dart';
import '../screens/adherents/adherent_form_screen.dart';
import '../screens/adherents/adherent_detail_screen.dart';
import '../screens/adherents_expert/adherent_expert_detail_screen.dart';
import '../screens/stock_list_screen.dart';
import '../screens/stock_depot_form_screen.dart';
import '../screens/stock_movements_history_screen.dart';
import '../screens/stock_adjustment_screen.dart';
import '../screens/stock_export_screen.dart';
import '../screens/ventes/ventes_list_screen.dart';
import '../screens/ventes/vente_form_screen.dart';
import '../screens/ventes/vente_detail_screen.dart';
import '../screens/recettes/recettes_list_screen.dart';
import '../screens/recettes/recette_detail_screen.dart';
import '../screens/recettes/recette_bordereau_screen.dart';
import '../screens/recettes/recette_export_screen.dart';
import '../screens/parametres/parametres_main_screen.dart';
import '../screens/parametres/campagne_form_screen.dart';
import '../screens/factures/factures_list_screen.dart';
import '../screens/factures/facture_detail_screen.dart';
import '../screens/notifications/notifications_history_screen.dart';
// V2: Nouveaux imports
import '../screens/clients/clients_list_content.dart';
import '../screens/capital/capital_content.dart';
import '../screens/comptabilite/comptabilite_content.dart';
import '../screens/social/social_content.dart';
import '../../../data/models/adherent_model.dart';
import '../../../data/models/parametres_cooperative_model.dart';
import '../../../data/models/client_model.dart';

/// Shell principal de l'application avec sidebar fixe
/// Ce widget maintient la sidebar visible sur toutes les pages
class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  // Créer la GlobalKey une seule fois dans initState pour éviter les problèmes de duplication
  late final GlobalKey<NavigatorState> _navigatorKey;
  String _currentRoute = AppRoutes.dashboard;
  bool _isNavigatorInitialized = false;
  
  // Exposer le Navigator pour qu'il soit accessible depuis les écrans enfants
  NavigatorState? get navigator => _navigatorKey.currentState;
  
  @override
  void initState() {
    super.initState();
    debugPrint('🟢 [MainAppShell] initState() appelé');
    debugPrint('🟢 [MainAppShell] Route initiale: $_currentRoute');
    
    // Créer la GlobalKey une seule fois lors de l'initialisation
    _navigatorKey = GlobalKey<NavigatorState>();
    debugPrint('🟢 [MainAppShell] NavigatorKey créée');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🟢 [MainAppShell] PostFrameCallback initState');
      _loadNotifications();
    });
  }
  
  @override
  void dispose() {
    // Nettoyer si nécessaire
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final authViewModel = context.read<AuthViewModel>();
    final user = authViewModel.currentUser;
    if (user != null) {
      await context.read<NotificationViewModel>().loadNotifications(user: user);
    }
  }

  void _onRouteChanged(String route) {
    debugPrint('🟣 [MainAppShell] _onRouteChanged appelé avec route: $route');
    debugPrint('🟣 [MainAppShell] Route actuelle: $_currentRoute');
    debugPrint('🟣 [MainAppShell] Widget mounted: $mounted');
    
    if (mounted && _currentRoute != route) {
      debugPrint('🟢 [MainAppShell] Mise à jour de la route: $_currentRoute -> $route');
      setState(() {
        _currentRoute = route;
      });
      debugPrint('✅ [MainAppShell] Route mise à jour: $_currentRoute');
    } else {
      debugPrint('🟡 [MainAppShell] Pas de changement de route nécessaire');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🟡 [MainAppShell] build() appelé');
    debugPrint('🟡 [MainAppShell] Route actuelle: $_currentRoute');
    
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    if (user == null) {
      debugPrint('🟡 [MainAppShell] Utilisateur null, affichage loading');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    debugPrint('🟡 [MainAppShell] Construction MainLayout avec route: $_currentRoute');
    return MainLayout(
      currentRoute: _currentRoute,
      onRouteChanged: (route) {
        debugPrint('🟡 [MainAppShell] onRouteChanged callback appelé avec: $route');
        // Vérifier que le widget est toujours monté avant de mettre à jour
        if (!mounted) {
          debugPrint('🟡 [MainAppShell] Widget non monté, ignore la mise à jour de route');
          return;
        }
        // Naviguer vers la nouvelle route seulement si elle est différente
        if (_currentRoute != route && _navigatorKey.currentState != null) {
          debugPrint('🟡 [MainAppShell] Navigation vers: $route');
          // Mettre à jour la route d'abord pour synchroniser le menu
          setState(() {
            _currentRoute = route;
          });
          // Construire la route directement plutôt que d'utiliser pushReplacementNamed
          final screen = _buildRoute(route, null);
          final newRoute = MaterialPageRoute(
            builder: (context) => screen,
            settings: RouteSettings(name: route),
          );
          _navigatorKey.currentState!.pushReplacement(newRoute);
        }
      },
      child: Navigator(
        key: _navigatorKey,
        initialRoute: _isNavigatorInitialized ? null : _currentRoute,
        onGenerateRoute: (settings) {
          debugPrint('🔴 [MainAppShell] onGenerateRoute appelé');
          debugPrint('🔴 [MainAppShell] settings.name: ${settings.name}');
          debugPrint('🔴 [MainAppShell] settings.arguments: ${settings.arguments}');
          debugPrint('🔴 [MainAppShell] _currentRoute dans onGenerateRoute: $_currentRoute');
          debugPrint('🔴 [MainAppShell] _isNavigatorInitialized: $_isNavigatorInitialized');
          
          // Marquer le Navigator comme initialisé après le premier appel
          if (!_isNavigatorInitialized) {
            _isNavigatorInitialized = true;
            debugPrint('🔴 [MainAppShell] Navigator marqué comme initialisé');
          }
          
          // Utiliser la route depuis settings.name, pas _currentRoute
          // Si settings.name est null ou '/', utiliser _currentRoute ou dashboard
          final routeName = settings.name != null && settings.name != '/' && settings.name!.isNotEmpty
              ? settings.name! 
              : (_currentRoute.isNotEmpty ? _currentRoute : AppRoutes.dashboard);
          
          debugPrint('🔴 [MainAppShell] Route générée: $routeName (settings.name était: ${settings.name})');
          
          // Mettre à jour la route courante silencieusement (sans déclencher de navigation)
          // pour synchroniser l'état avec la route générée
          if (_currentRoute != routeName) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentRoute = routeName;
                });
              }
            });
          }

          // Générer la route avec les écrans appropriés
          final screen = _buildRoute(routeName, settings.arguments);
          debugPrint('🔴 [MainAppShell] Écran construit: ${screen.runtimeType} pour route: $routeName');
          
          return MaterialPageRoute(
            builder: (context) {
              debugPrint('🔴 [MainAppShell] MaterialPageRoute builder appelé pour: $routeName');
              return screen;
            },
            settings: RouteSettings(name: routeName, arguments: settings.arguments),
          );
        },
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }
          // Mettre à jour la route courante lors du retour (sans déclencher de navigation)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _navigatorKey.currentState != null && _navigatorKey.currentContext != null) {
              final currentRoute = ModalRoute.of(_navigatorKey.currentContext!)?.settings.name;
              final newRoute = currentRoute ?? AppRoutes.dashboard;
              if (_currentRoute != newRoute) {
                setState(() {
                  _currentRoute = newRoute;
                });
              }
            }
          });
          return true;
        },
        // Ajouter une route par défaut pour éviter les problèmes
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => _buildRoute(AppRoutes.dashboard, null),
            settings: settings,
          );
        },
      ),
    );
  }

  Widget _buildRoute(String route, Object? arguments) {
    debugPrint('🟠 [MainAppShell] _buildRoute appelé');
    debugPrint('🟠 [MainAppShell] Route: $route');
    debugPrint('🟠 [MainAppShell] Arguments: $arguments');
    
    Widget screen;
    switch (route) {
      case AppRoutes.dashboard:
        debugPrint('🟠 [MainAppShell] Construction DashboardScreen');
        screen = const DashboardScreen();
        break;
      case AppRoutes.adherents:
        debugPrint('🟠 [MainAppShell] Construction AdherentsListScreen');
        screen = const AdherentsListScreen();
        break;
      case AppRoutes.adherentAdd:
        screen = const AdherentFormScreen();
        break;
      case AppRoutes.adherentEdit:
        screen = AdherentFormScreen(adherent: arguments as AdherentModel);
        break;
      case AppRoutes.adherentDetail:
        screen = AdherentDetailScreen(adherentId: arguments as int);
        break;
      case AppRoutes.adherentExpertDetail:
        screen = AdherentExpertDetailScreen(adherentId: arguments as int);
        break;
      case AppRoutes.stock:
        screen = const StockListScreen();
        break;
      case AppRoutes.stockDepot:
        screen = const StockDepotFormScreen();
        break;
      case AppRoutes.stockHistory:
        screen = const StockMovementsHistoryScreen();
        break;
      case AppRoutes.stockExport:
        screen = const StockExportScreen();
        break;
      case AppRoutes.stockAdjustment:
        screen = StockAdjustmentScreen(adherentId: arguments as int);
        break;
      case AppRoutes.ventes:
        screen = const VentesListScreen();
        break;
      case AppRoutes.venteIndividuelle:
        screen = const VenteFormScreen(type: 'individuelle');
        break;
      case AppRoutes.venteGroupee:
        screen = const VenteFormScreen(type: 'groupee');
        break;
      case AppRoutes.venteDetail:
        screen = VenteDetailScreen(venteId: arguments as int);
        break;
      case AppRoutes.recettes:
        screen = const RecettesListScreen();
        break;
      case AppRoutes.recetteDetail:
        screen = RecetteDetailScreen(adherentId: arguments as int);
        break;
      case AppRoutes.recetteBordereau:
        final args = arguments as Map<String, dynamic>;
        screen = RecetteBordereauScreen(
          adherentId: args['adherentId'] as int,
          startDate: args['startDate'] as DateTime?,
          endDate: args['endDate'] as DateTime?,
        );
        break;
      case AppRoutes.recetteExport:
        screen = const RecetteExportScreen();
        break;
      case AppRoutes.settings:
      case AppRoutes.parametrage:
        screen = const ParametresMainScreen();
        break;
      case AppRoutes.campagneForm:
        screen = CampagneFormScreen(campagne: arguments as CampagneModel?);
        break;
      case AppRoutes.factures:
        screen = const FacturesListScreen();
        break;
      case AppRoutes.factureDetail:
        screen = FactureDetailScreen(factureId: arguments as int);
        break;
      case AppRoutes.notifications:
        screen = const NotificationsHistoryScreen();
        break;
      // V2: Nouvelles routes
      case AppRoutes.clients:
        screen = const ClientsListContent();
        break;
      case AppRoutes.clientDetail:
        screen = const ClientsListContent(); // TODO: Créer ClientDetailContent
        break;
      case AppRoutes.clientAdd:
        screen = const ClientsListContent(); // TODO: Créer ClientFormContent
        break;
      case AppRoutes.clientEdit:
        screen = const ClientsListContent(); // TODO: Créer ClientFormContent
        break;
      case AppRoutes.capital:
      case AppRoutes.partsSociales:
        screen = const CapitalContent();
        break;
      case AppRoutes.partSocialeAdd:
        screen = const CapitalContent(); // TODO: Créer PartSocialeFormContent
        break;
      case AppRoutes.comptabilite:
        screen = const ComptabiliteContent();
        break;
      case AppRoutes.grandLivre:
        screen = const ComptabiliteContent(); // TODO: Créer GrandLivreContent
        break;
      case AppRoutes.etatsFinanciers:
        screen = const ComptabiliteContent(); // TODO: Créer EtatsFinanciersContent
        break;
      case AppRoutes.social:
      case AppRoutes.aidesSociales:
        screen = const SocialContent();
        break;
      case AppRoutes.aideSocialeAdd:
        screen = const SocialContent(); // TODO: Créer AideSocialeFormContent
        break;
      case AppRoutes.aideSocialeDetail:
        screen = const SocialContent(); // TODO: Créer AideSocialeDetailContent
        break;
      default:
        debugPrint('🟠 [MainAppShell] Route inconnue, retour au DashboardScreen');
        screen = const DashboardScreen();
    }
    
    // Envelopper chaque écran dans Material pour garantir un contexte Material
    // (nécessaire pour TextField et autres widgets Material)
    // Le DashboardLayout fournit déjà le Scaffold, donc les écrans ne doivent pas en avoir
    return Material(
      child: screen,
    );
  }
}
