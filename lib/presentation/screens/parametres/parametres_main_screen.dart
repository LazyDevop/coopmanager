import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/parametres_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../services/auth/permission_service.dart';
import 'parametres_info_screen.dart';
import 'parametres_finances_screen.dart';
import 'parametres_campagnes_screen.dart';

class ParametresMainScreen extends StatefulWidget {
  const ParametresMainScreen({super.key});

  @override
  State<ParametresMainScreen> createState() => _ParametresMainScreenState();
}

class _ParametresMainScreenState extends State<ParametresMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParametresViewModel>().loadParametres();
      context.read<ParametresViewModel>().loadCampagnes();
      context.read<ParametresViewModel>().loadBaremes();
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
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.business),
              text: 'Informations',
            ),
            Tab(
              icon: Icon(Icons.attach_money),
              text: 'Finances',
            ),
            Tab(
              icon: Icon(Icons.calendar_today),
              text: 'Campagnes',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ParametresInfoScreen(),
          ParametresFinancesScreen(),
          ParametresCampagnesScreen(),
        ],
      ),
    );
  }
}

