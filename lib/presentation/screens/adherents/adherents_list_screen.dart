import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/adherent_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../config/routes/routes.dart';
import '../../../data/models/adherent_model.dart';
import 'package:intl/intl.dart';

class AdherentsListScreen extends StatefulWidget {
  const AdherentsListScreen({super.key});

  @override
  State<AdherentsListScreen> createState() {
    debugPrint('📱 [AdherentsListScreen] createState() appelé');
    return _AdherentsListScreenState();
  }
}

class _AdherentsListScreenState extends State<AdherentsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    debugPrint('📱 [AdherentsListScreen] initState() appelé');
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📱 [AdherentsListScreen] build() appelé');
    // Le MainAppShell gère déjà le layout, donc on retourne seulement le contenu
    return Consumer<AdherentViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.adherents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.loadAdherents(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildFiltersAndSearch(context, viewModel),
              Expanded(
                child: viewModel.filteredAdherents.isEmpty
                    ? _buildEmptyState(context)
                    : _buildAdherentsList(context, viewModel),
              ),
            ],
          );
        },
    );
  }

  Widget _buildFiltersAndSearch(BuildContext context, AdherentViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête avec titre et bouton Ajouter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestion des Adhérents',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.adherentAdd);
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par code, nom, prénom, téléphone...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.searchAdherents('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              viewModel.searchAdherents(value);
            },
          ),
          const SizedBox(height: 12),
          // Filtres
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<bool?>(
                  value: viewModel.filterActive,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem<bool?>(value: null, child: Text('Tous')),
                    DropdownMenuItem<bool?>(value: true, child: Text('Actifs')),
                    DropdownMenuItem<bool?>(value: false, child: Text('Inactifs')),
                  ],
                  onChanged: (value) {
                    viewModel.setFilterActive(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: viewModel.filterVillage,
                  decoration: InputDecoration(
                    labelText: 'Village',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Tous les villages')),
                    ...viewModel.villages.map((village) => DropdownMenuItem<String?>(
                      value: village,
                      child: Text(village),
                    )),
                  ],
                  onChanged: (value) {
                    viewModel.setFilterVillage(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.filter_alt_off),
                tooltip: 'Réinitialiser les filtres',
                onPressed: () {
                  viewModel.resetFilters();
                  _searchController.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucun adhérent trouvé',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier adhérent',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.adherentAdd);
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Ajouter un adhérent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherentsList(BuildContext context, AdherentViewModel viewModel) {
    final adherents = viewModel.filteredAdherents;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: adherents.length,
      itemBuilder: (context, index) {
        final adherent = adherents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: SizedBox(
              width: 40,
              child: CircleAvatar(
                backgroundColor: adherent.isActive
                    ? Colors.green.shade100
                    : Colors.grey.shade300,
                child: Icon(
                  Icons.person,
                  color: adherent.isActive
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ),
            title: Text(
              adherent.fullName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: adherent.isActive ? null : Colors.grey.shade600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.badge, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Code: ${adherent.code}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                if (adherent.village != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        adherent.village!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
                if (adherent.telephone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        adherent.telephone!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Adhésion: ${dateFormat.format(adherent.dateAdhesion)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!adherent.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Inactif',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleMenuAction(context, value, adherent, viewModel),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text('Consulter'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: adherent.isActive ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            adherent.isActive ? Icons.block : Icons.check_circle,
                            size: 18,
                            color: adherent.isActive ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            adherent.isActive ? 'Désactiver' : 'Réactiver',
                            style: TextStyle(
                              color: adherent.isActive ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context, rootNavigator: false).pushNamed(
                AppRoutes.adherentDetail,
                arguments: adherent.id,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    String action,
    AdherentModel adherent,
    AdherentViewModel viewModel,
  ) async {
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    
    if (currentUser == null) return;

    switch (action) {
      case 'view':
        Navigator.pushNamed(
          context,
          AppRoutes.adherentDetail,
          arguments: adherent.id,
        );
        break;
      case 'edit':
        Navigator.pushNamed(
          context,
          AppRoutes.adherentEdit,
          arguments: adherent,
        );
        break;
      case 'activate':
      case 'deactivate':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              action == 'activate' ? 'Réactiver l\'adhérent' : 'Désactiver l\'adhérent',
            ),
            content: Text(
              action == 'activate'
                  ? 'Voulez-vous réactiver ${adherent.fullName} ?'
                  : 'Voulez-vous désactiver ${adherent.fullName} ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: action == 'activate' ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final success = await viewModel.toggleAdherentStatus(
            adherent.id!,
            action == 'activate',
            currentUser.id!,
          );

          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(action == 'activate'
                    ? 'Adhérent réactivé avec succès'
                    : 'Adhérent désactivé avec succès'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
        break;
    }
  }
}
