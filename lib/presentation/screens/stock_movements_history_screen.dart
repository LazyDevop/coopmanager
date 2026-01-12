import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../../data/models/stock_movement_model.dart';
import 'stock_export_screen.dart';

class StockMovementsHistoryScreen extends StatefulWidget {
  const StockMovementsHistoryScreen({super.key});

  @override
  State<StockMovementsHistoryScreen> createState() => _StockMovementsHistoryScreenState();
}

class _StockMovementsHistoryScreenState extends State<StockMovementsHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockViewModel>().loadMouvements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stockViewModel = context.watch<StockViewModel>();

    // Le DashboardLayout fournit déjà le Scaffold, donc on retourne directement le contenu
    return Column(
      children: [
        // Barre de titre avec actions (remplace l'AppBar)
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
                'Historique des Mouvements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filtres',
                onPressed: () => _showFiltersDialog(context, stockViewModel),
              ),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exporter',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StockExportScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Contenu principal
        Expanded(
          child: Column(
        children: [
          // Filtres actifs
          if (stockViewModel.filterTypeMouvement != null ||
              stockViewModel.filterStartDate != null ||
              stockViewModel.filterEndDate != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.brown.shade50,
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getActiveFiltersText(stockViewModel),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      stockViewModel.resetFilters();
                      stockViewModel.loadMouvements();
                    },
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),

          // Liste des mouvements
          Expanded(
            child: stockViewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : stockViewModel.filteredMouvements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun mouvement enregistré',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => stockViewModel.loadMouvements(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: stockViewModel.filteredMouvements.length,
                          itemBuilder: (context, index) {
                            final mouvement = stockViewModel.filteredMouvements[index];
                            return _buildMovementCard(mouvement);
                          },
                        ),
                      ),
          ),
          ],
        ),
        ),
      ],
    );
  }

  Widget _buildMovementCard(StockMovementModel mouvement) {
    final isPositive = mouvement.quantite > 0;
    final color = mouvement.isDepot
        ? Colors.green
        : mouvement.isVente
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(
              mouvement.isDepot
                  ? Icons.add
                  : mouvement.isVente
                      ? Icons.remove
                      : Icons.tune,
              color: color,
            ),
          ),
        ),
        title: Text(
          mouvement.typeLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quantité: ${mouvement.quantite.abs().toStringAsFixed(2)} kg',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(mouvement.dateMouvement)}',
            ),
            if (mouvement.commentaire != null)
              Text('Note: ${mouvement.commentaire}'),
          ],
        ),
        trailing: Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
        ),
      ),
    );
  }

  String _getActiveFiltersText(StockViewModel viewModel) {
    final filters = <String>[];
    if (viewModel.filterTypeMouvement != null) {
      filters.add('Type: ${viewModel.filterTypeMouvement}');
    }
    if (viewModel.filterStartDate != null) {
      filters.add('Début: ${DateFormat('dd/MM/yyyy').format(viewModel.filterStartDate!)}');
    }
    if (viewModel.filterEndDate != null) {
      filters.add('Fin: ${DateFormat('dd/MM/yyyy').format(viewModel.filterEndDate!)}');
    }
    return filters.join(' • ');
  }

  void _showFiltersDialog(BuildContext context, StockViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: viewModel.filterTypeMouvement,
                decoration: const InputDecoration(
                  labelText: 'Type de mouvement',
                ),
                items: const [
                  DropdownMenuItem(value: 'depot', child: Text('Dépôt')),
                  DropdownMenuItem(value: 'vente', child: Text('Vente')),
                  DropdownMenuItem(value: 'ajustement', child: Text('Ajustement')),
                ],
                onChanged: (value) {
                  viewModel.setFilterTypeMouvement(value);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date de début'),
                subtitle: Text(
                  viewModel.filterStartDate != null
                      ? DateFormat('dd/MM/yyyy').format(viewModel.filterStartDate!)
                      : 'Non définie',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: viewModel.filterStartDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    viewModel.setFilterDates(
                      picked,
                      viewModel.filterEndDate,
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Date de fin'),
                subtitle: Text(
                  viewModel.filterEndDate != null
                      ? DateFormat('dd/MM/yyyy').format(viewModel.filterEndDate!)
                      : 'Non définie',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: viewModel.filterEndDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    viewModel.setFilterDates(
                      viewModel.filterStartDate,
                      picked,
                    );
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              viewModel.resetFilters();
              Navigator.pop(context);
              viewModel.loadMouvements();
            },
            child: const Text('Réinitialiser'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.loadMouvements();
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }
}

