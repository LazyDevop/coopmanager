import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/adherent_viewmodel.dart';
import 'presentation/viewmodels/stock_viewmodel.dart';
import 'presentation/viewmodels/recette_viewmodel.dart';
import 'presentation/viewmodels/parametres_viewmodel.dart';
import 'presentation/viewmodels/vente_viewmodel.dart';
import 'presentation/viewmodels/facture_viewmodel.dart';
import 'presentation/viewmodels/notification_viewmodel.dart';
import 'presentation/viewmodels/document_viewmodel.dart';
import 'presentation/viewmodels/client_viewmodel.dart';
import 'presentation/viewmodels/capital_viewmodel.dart';
import 'presentation/viewmodels/user_viewmodel.dart';
import 'presentation/viewmodels/commission_viewmodel.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/permission_provider.dart';
import 'presentation/widgets/auth_wrapper.dart';
import 'services/notification/notification_service.dart';
import 'config/routes/routes.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/adherents/adherents_list_screen.dart';
import 'presentation/screens/adherents/adherent_form_screen.dart';
import 'presentation/screens/adherents/adherent_detail_screen.dart';
import 'presentation/screens/stock_list_screen.dart';
import 'presentation/screens/stock_depot_form_screen.dart';
import 'presentation/screens/stock_movements_history_screen.dart';
import 'presentation/screens/stock_adjustment_screen.dart';
import 'presentation/screens/stock_export_screen.dart';
import 'presentation/screens/ventes/ventes_list_screen.dart';
import 'presentation/screens/ventes/vente_form_screen.dart';
import 'presentation/screens/ventes/vente_form_v1_screen.dart';
import 'presentation/screens/ventes/vente_detail_screen.dart';
import 'presentation/screens/recettes/recettes_list_screen.dart';
import 'presentation/screens/recettes/recette_detail_screen.dart';
import 'presentation/screens/recettes/recette_bordereau_screen.dart';
import 'presentation/screens/recettes/recette_export_screen.dart';
import 'presentation/screens/parametres/parametres_main_screen.dart';
import 'presentation/screens/parametres/campagne_form_screen.dart';
import 'presentation/screens/factures/factures_list_screen.dart';
import 'presentation/screens/factures/facture_detail_screen.dart';
import 'presentation/screens/notifications/notifications_history_screen.dart';
import 'data/models/adherent_model.dart';
import 'data/models/parametres_cooperative_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le service de notifications
  await NotificationService().initialize();
  
  runApp(const CoopManagerApp());
}

class CoopManagerApp extends StatelessWidget {
  const CoopManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final authViewModel = AuthViewModel();
          final permissionProvider = PermissionProvider();
          authViewModel.setPermissionProvider(permissionProvider);
          return authViewModel;
        }),
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
        ChangeNotifierProvider(create: (_) => AdherentViewModel()),
        ChangeNotifierProvider(create: (_) => StockViewModel()),
        ChangeNotifierProvider(create: (_) => RecetteViewModel()),
        ChangeNotifierProvider(create: (_) => ParametresViewModel()),
        ChangeNotifierProvider(create: (_) => VenteViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => FactureViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => DocumentViewModel()),
        ChangeNotifierProvider(create: (_) => ClientViewModel()),
        ChangeNotifierProvider(create: (_) => CapitalViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => CommissionViewModel()),
      ],
      child: MaterialApp(
        title: 'CoopManager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.brown,
            primary: Colors.brown.shade700,
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        // Utiliser le thème personnalisé
        // theme: AppTheme.lightTheme,
        // Seule la route login est gérée par MaterialApp
        // Toutes les autres routes sont gérées par le Navigator interne du MainAppShell
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
        },
        // Gérer les routes inconnues en redirigeant vers AuthWrapper
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
            settings: settings,
          );
        },
        // Routes non définies ici seront gérées par MainAppShell via AuthWrapper
        onGenerateRoute: (settings) {
          // Si ce n'est pas la route login, laisser AuthWrapper/MainAppShell gérer
          if (settings.name != AppRoutes.login) {
            return MaterialPageRoute(
              builder: (context) => const AuthWrapper(),
              settings: settings,
            );
          }
          return null;
        },
        home: const AuthWrapper(),
      ),
    );
  }
}
