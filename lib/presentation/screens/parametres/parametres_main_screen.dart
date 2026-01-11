import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/parametres_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../services/auth/permission_service.dart';
import 'parametres_info_screen.dart';
import 'parametres_finances_screen.dart';
import 'parametres_campagnes_screen.dart';
import 'parametres_overview_screen.dart';

class ParametresMainScreen extends StatefulWidget {
  const ParametresMainScreen({super.key});

  @override
  State<ParametresMainScreen> createState() => _ParametresMainScreenState();
}

class _ParametresMainScreenState extends State<ParametresMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Debug: vérifier que le TabController a bien 4 onglets
    debugPrint('TabController créé avec ${_tabController.length} onglets');
    
    // Écouter les changements d'onglet pour mettre à jour l'état et recharger les données
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final newIndex = _tabController.index;
        setState(() {
          _currentIndex = newIndex;
        });
        
        // Recharger les données quand on change d'onglet
        final viewModel = context.read<ParametresViewModel>();
        switch (newIndex) {
          case 0: // Vue d'ensemble
            viewModel.loadParametres();
            viewModel.loadCampagnes();
            viewModel.loadBaremes();
            break;
          case 1: // Informations
            viewModel.loadParametres();
            break;
          case 2: // Finances
            viewModel.loadParametres();
            viewModel.loadBaremes();
            break;
          case 3: // Campagnes
            viewModel.loadCampagnes();
            break;
        }
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ParametresViewModel>();
      // Charger toutes les données au démarrage pour la vue d'ensemble
      viewModel.loadParametres();
      viewModel.loadCampagnes();
      viewModel.loadBaremes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramétrage Coopérative'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Permet de faire défiler les onglets si nécessaire
          tabAlignment: TabAlignment.start, // Aligne les onglets à gauche
          indicator: BoxDecoration(
            color: Colors.brown.shade900,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          indicatorColor: Colors.white,
          indicatorWeight: 4.0,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          dividerColor: Colors.transparent,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            debugPrint('Onglet sélectionné: $index');
          },
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard, size: 18),
              text: 'Vue d\'ensemble',
            ),
            Tab(
              icon: Icon(Icons.business, size: 18),
              text: 'Informations',
            ),
            Tab(
              icon: Icon(Icons.attach_money, size: 18),
              text: 'Finances',
            ),
            Tab(
              icon: Icon(Icons.calendar_today, size: 18),
              text: 'Campagnes',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ParametresOverviewScreen(
            onNavigateToTab: (index) {
              _tabController.animateTo(index);
            },
          ),
          ParametresInfoScreen(
            key: ValueKey('info$_currentIndex'),
          ),
          ParametresFinancesScreen(
            key: ValueKey('finances$_currentIndex'),
          ),
          ParametresCampagnesScreen(
            key: ValueKey('campagnes$_currentIndex'),
          ),
        ],
      ),
    );
  }
}

