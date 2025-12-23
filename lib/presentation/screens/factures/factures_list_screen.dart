import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../viewmodels/facture_viewmodel.dart';
import '../../viewmodels/adherent_viewmodel.dart';
import '../../../data/models/facture_model.dart';
import '../../../config/routes/routes.dart';

class FacturesListScreen extends StatefulWidget {
  const FacturesListScreen({super.key});

  @override
  State<FacturesListScreen> createState() => _FacturesListScreenState();
}

class _FacturesListScreenState extends State<FacturesListScreen> {
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
                'Gestion des Factures',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.print),
                tooltip: 'Exporter',
                onPressed: () {
                  // TODO: Implémenter l'export batch
                },
              ),
            ],
          ),
        ),
        // Contenu
        Expanded(
          child: Consumer<FactureViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.factures.isEmpty) {
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
                    onPressed: () => viewModel.loadFactures(),
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
                child: viewModel.filteredFactures.isEmpty
                    ? _buildEmptyState(context)
                    : _buildFacturesList(context, viewModel),
              ),
            ],
          );
          },
        ),
      ),
    ],
    );
  }

  Widget _buildFiltersAndSearch(BuildContext context, FactureViewModel viewModel) {
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
              hintText: 'Rechercher par numéro, notes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.searchFactures('');
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
              viewModel.searchFactures(value);
            },
          ),
          const SizedBox(height: 12),
          // Filtres
          Row(
            children: [
              Expanded(
                child: Consumer<AdherentViewModel>(
                  builder: (context, adherentViewModel, child) {
                    return DropdownButtonFormField<int?>(
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
                        ...adherentViewModel.adherents.map((adherent) => DropdownMenuItem<int?>(
                          value: adherent.id,
                          child: Text('${adherent.code} - ${adherent.fullName}'),
                        )),
                      ],
                      onChanged: (value) {
                        viewModel.setFilterAdherent(value);
                      },
                    );
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
                    DropdownMenuItem<String?>(value: 'vente', child: Text('Vente')),
                    DropdownMenuItem<String?>(value: 'recette', child: Text('Recette')),
                    DropdownMenuItem<String?>(value: 'bordereau', child: Text('Bordereau')),
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
                    DropdownMenuItem<String?>(value: 'validee', child: Text('Validée')),
                    DropdownMenuItem<String?>(value: 'payee', child: Text('Payée')),
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
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucune facture trouvée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les factures seront générées automatiquement lors des ventes et recettes',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFacturesList(BuildContext context, FactureViewModel viewModel) {
    final factures = viewModel.filteredFactures;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: factures.length,
      itemBuilder: (context, index) {
        final facture = factures[index];
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
                backgroundColor: _getStatutColor(facture.statut),
                child: Icon(
                  _getTypeIcon(facture.type),
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              facture.numero,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: facture.isAnnulee ? Colors.grey.shade600 : null,
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
                      dateFormat.format(facture.dateFacture),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getTypeLabel(facture.type),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${numberFormat.format(facture.montantTotal)} FCFA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: facture.isPayee
                        ? Colors.green.shade700
                        : facture.isAnnulee
                            ? Colors.grey.shade600
                            : Colors.brown.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatutColor(facture.statut).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatutLabel(facture.statut),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatutColor(facture.statut),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context, rootNavigator: false).pushNamed(
                AppRoutes.factureDetail,
                arguments: facture.id,
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'payee':
        return Colors.green;
      case 'annulee':
        return Colors.red;
      case 'validee':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'payee':
        return 'Payée';
      case 'annulee':
        return 'Annulée';
      case 'validee':
        return 'Validée';
      case 'brouillon':
        return 'Brouillon';
      default:
        return statut;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'vente':
        return Icons.shopping_cart;
      case 'recette':
        return Icons.attach_money;
      case 'bordereau':
        return Icons.receipt_long;
      default:
        return Icons.receipt;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'vente':
        return 'Facture de vente';
      case 'recette':
        return 'Facture de recette';
      case 'bordereau':
        return 'Bordereau de recettes';
      default:
        return type;
    }
  }
}
