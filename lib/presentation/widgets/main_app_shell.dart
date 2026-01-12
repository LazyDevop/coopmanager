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
import '../screens/adherents_expert/champs_map_screen.dart';
import '../screens/stock_list_screen.dart';
import '../screens/stock_depot_form_screen.dart';
import '../screens/stock_movements_history_screen.dart';
import '../screens/stock_adjustment_screen.dart';
import '../screens/stock_export_screen.dart';
import '../screens/ventes/ventes_list_screen.dart';
import '../screens/ventes/vente_form_screen.dart';
import '../screens/ventes/vente_detail_screen.dart';
import '../screens/ventes/ventes_statistiques_screen.dart';
import '../screens/ventes/v2/simulation_vente_screen.dart';
import '../screens/ventes/v2/lots_vente_screen.dart';
import '../screens/ventes/v2/creances_clients_screen.dart';
import '../screens/ventes/v2/validation_workflow_screen.dart';
import '../screens/ventes/v2/fonds_social_screen.dart';
import '../screens/recettes/recettes_list_screen.dart';
import '../screens/recettes/recette_detail_screen.dart';
import '../screens/recettes/recette_bordereau_screen.dart';
import '../screens/recettes/recette_export_screen.dart';
import '../screens/recettes/compte_financier_adherent_screen.dart';
import '../screens/recettes/paiement_form_screen.dart';
import '../screens/commissions/commissions_list_screen.dart';
import '../screens/commissions/commission_form_screen.dart';
import '../screens/documents/documents_list_screen.dart';
import '../screens/clients/clients_list_screen.dart';
import '../screens/clients/client_form_screen.dart';
import '../screens/clients/client_detail_screen.dart';
import '../screens/clients/clients_impayes_screen.dart';
import '../screens/capital/actionnaires_list_screen.dart';
import '../screens/capital/part_sociale_form_screen.dart';
import '../screens/capital/souscription_form_screen.dart';
import '../screens/capital/capital_etat_screen.dart';
import '../screens/parametres/parametres_main_screen.dart';
import '../screens/parametres/campagne_form_screen.dart';
import '../screens/settings/settings_main_screen.dart';
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
import '../../../data/models/commission_model.dart';

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
  Page<dynamic>?
  _cachedPage; // Cache la page complète pour éviter les reconstructions

  // Exposer le Navigator pour qu'il soit accessible depuis les écrans enfants
  NavigatorState? get navigator => _navigatorKey.currentState;

  @override
  void initState() {
    super.initState();
    // Créer la GlobalKey une seule fois lors de l'initialisation
    _navigatorKey = GlobalKey<NavigatorState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Mémoriser la page complète avec une clé stable pour éviter les reconstructions
    final pageKey = ValueKey('page_$_currentRoute');
    if (_cachedPage == null || _cachedPage!.key != pageKey) {
      final pageWidget = _buildRoute(_currentRoute, null);
      _cachedPage = MaterialPage<dynamic>(
        key: pageKey,
        name: _currentRoute,
        child: RepaintBoundary(
          key: ValueKey('repaint_$_currentRoute'),
          child: pageWidget,
        ),
      );
    }

    return MainLayout(
      key: ValueKey('layout_$_currentRoute'),
      currentRoute: _currentRoute,
      onRouteChanged: (route) {
        if (!mounted || _currentRoute == route) {
          return;
        }
        // Invalider le cache et mettre à jour la route
        _cachedPage = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentRoute = route;
            });
          }
        });
      },
      child: Navigator(
        key: _navigatorKey,
        pages: [_cachedPage!],
        onPopPage: (route, result) {
          return false;
        },
        onGenerateRoute: (settings) {
          // Handle pushNamed calls dynamically
          final routeWidget = _buildRoute(
            settings.name ?? '',
            settings.arguments,
          );
          return MaterialPageRoute<dynamic>(
            builder: (context) => routeWidget,
            settings: settings,
          );
        },
      ),
    );
  }

  Widget _buildRoute(String route, Object? arguments) {
    Widget screen;
    switch (route) {
      case AppRoutes.dashboard:
        screen = const DashboardScreen();
        break;
      case AppRoutes.adherents:
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
      case AppRoutes.champsMap:
        screen = ChampsMapScreen(adherentId: arguments as int?);
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
      case AppRoutes.ventesStatistiques:
        screen = const VentesStatistiquesScreen();
        break;
      case AppRoutes.simulationVente:
        screen = const SimulationVenteScreen();
        break;
      case AppRoutes.lotsVente:
        screen = const LotsVenteScreen();
        break;
      case AppRoutes.creancesClients:
        screen = const CreancesClientsScreen();
        break;
      case AppRoutes.validationWorkflow:
        screen = const ValidationWorkflowScreen();
        break;
      case AppRoutes.fondsSocial:
        screen = const FondsSocialScreen();
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
      case AppRoutes.compteFinancierAdherent:
        screen = CompteFinancierAdherentScreen(adherentId: arguments as int);
        break;
      case AppRoutes.paiementForm:
        final args = arguments as Map<String, dynamic>;
        screen = PaiementFormScreen(
          adherentId: args['adherentId'] as int,
          soldeDisponible: args['soldeDisponible'] as double,
        );
        break;
      case AppRoutes.commissions:
        screen = const CommissionsListScreen();
        break;
      case AppRoutes.commissionForm:
        screen = CommissionFormScreen(
          commission: arguments as CommissionModel?,
        );
        break;
      case AppRoutes.settingsMain:
        screen = const SettingsMainScreen();
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
        screen = const ClientsListScreen();
        break;
      case AppRoutes.clientDetail:
        screen = ClientDetailScreen(clientId: arguments as int);
        break;
      case AppRoutes.clientAdd:
        screen = const ClientFormScreen();
        break;
      case AppRoutes.clientEdit:
        screen = ClientFormScreen(clientId: arguments as int);
        break;
      case AppRoutes.clientsImpayes:
        screen = const ClientsImpayesScreen();
        break;
      // Module Capital Social
      case AppRoutes.capital:
        screen = const ActionnairesListScreen();
        break;
      case AppRoutes.capitalActionnaireDetail:
        screen =
            const ActionnairesListScreen(); // TODO: Créer ActionnaireDetailScreen
        break;
      case AppRoutes.capitalSouscription:
        screen = const SouscriptionFormScreen();
        break;
      case AppRoutes.capitalLiberation:
        screen =
            const ActionnairesListScreen(); // TODO: Créer LiberationFormScreen
        break;
      case AppRoutes.capitalEtat:
        screen = const CapitalSocialEtatScreen();
        break;
      case AppRoutes.partSocialeAdd:
        screen = const PartSocialeFormScreen();
        break;
      case AppRoutes.comptabilite:
        screen = const ComptabiliteContent();
        break;
      case AppRoutes.grandLivre:
        screen = const ComptabiliteContent(); // TODO: Créer GrandLivreContent
        break;
      case AppRoutes.etatsFinanciers:
        screen =
            const ComptabiliteContent(); // TODO: Créer EtatsFinanciersContent
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
        screen = const DashboardScreen();
    }

    // Envelopper chaque écran dans Material pour garantir un contexte Material
    // (nécessaire pour TextField et autres widgets Material)
    // Le DashboardLayout fournit déjà le Scaffold, donc les écrans ne doivent pas en avoir
    return Material(child: screen);
  }
}
