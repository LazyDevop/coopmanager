import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/vente_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../config/routes/routes.dart';
import '../../../data/models/vente_model.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class VentesListScreen extends StatefulWidget {
  const VentesListScreen({super.key});

  @override
  State<VentesListScreen> createState() => _VentesListScreenState();
}

class _VentesListScreenState extends State<VentesListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le MainAppShell gère déjà le layout avec sidebar, donc on retourne seulement le contenu
    return Column(
      children: [
        // Barre d'actions en haut (remplace l'AppBar)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text(
                'Gestion des Ventes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.add),
                tooltip: 'Ajouter une vente',
                onSelected: (value) {
                  if (value == 'individuelle') {
                    Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.venteIndividuelle);
                  } else if (value == 'groupee') {
                    Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.venteGroupee);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'individuelle',
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Vente individuelle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'groupee',
                    child: Row(
                      children: [
                        Icon(Icons.people),
                        SizedBox(width: 8),
                        Text('Vente groupée'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Contenu
        Expanded(
          child: Consumer<VenteViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading && viewModel.ventes.isEmpty) {
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
                        onPressed: () => viewModel.loadVentes(),
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
                    child: viewModel.filteredVentes.isEmpty
                        ? _buildEmptyState(context)
                        : _buildVentesList(context, viewModel),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersAndSearch(BuildContext context, VenteViewModel viewModel) {
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
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par acheteur, notes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.searchVentes('');
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
              viewModel.searchVentes(value);
            },
          ),
          const SizedBox(height: 12),
          // Filtres
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: viewModel.filterAdherentId,
                  decoration: InputDecoration(
                    labelText: 'Adhérent',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Tous')),
                    ...viewModel.adherents.map((adherent) => DropdownMenuItem<int?>(
                      value: adherent.id,
                      child: Text('${adherent.code} - ${adherent.fullName}'),
                    )),
                  ],
                  onChanged: (value) {
                    viewModel.setFilterAdherent(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: viewModel.filterType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                    DropdownMenuItem<String?>(value: 'individuelle', child: Text('Individuelle')),
                    DropdownMenuItem<String?>(value: 'groupee', child: Text('Groupée')),
                  ],
                  onChanged: (value) {
                    viewModel.setFilterType(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: viewModel.filterStatut,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                    DropdownMenuItem<String?>(value: 'valide', child: Text('Valide')),
                    DropdownMenuItem<String?>(value: 'annulee', child: Text('Annulée')),
                  ],
                  onChanged: (value) {
                    viewModel.setFilterStatut(value);
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
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucune vente trouvée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première vente',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildVentesList(BuildContext context, VenteViewModel viewModel) {
    final ventes = viewModel.filteredVentes;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: ventes.length,
      itemBuilder: (context, index) {
        final vente = ventes[index];
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
                backgroundColor: vente.isValide
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                child: Icon(
                  vente.isIndividuelle ? Icons.person : Icons.people,
                  color: vente.isValide
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ),
            title: Text(
              vente.isIndividuelle
                  ? 'Vente individuelle'
                  : 'Vente groupée',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: vente.isValide ? null : Colors.grey.shade600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(vente.dateVente),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.scale, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${numberFormat.format(vente.quantiteTotal)} kg',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                if (vente.acheteur != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        vente.acheteur!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${numberFormat.format(vente.montantTotal)} FCFA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: vente.isValide ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                ),
                if (!vente.isValide)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Annulée',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.of(context, rootNavigator: false).pushNamed(
                AppRoutes.venteDetail,
                arguments: vente.id,
              );
            },
          ),
        );
      },
    );
  }
}
