import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../data/models/stock_model.dart';
import '../../config/routes/routes.dart';
import '../../services/auth/permission_service.dart';
import 'stock_depot_form_screen.dart';
import 'stock_movements_history_screen.dart';
import 'stock_adjustment_screen.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoaded) {
        _hasLoaded = true;
        context.read<StockViewModel>().loadStocks();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ne pas recharger ici pour éviter les clignotements
    // Le rechargement se fera via RefreshIndicator ou après navigation
  }

  @override
  Widget build(BuildContext context) {
    final stockViewModel = context.watch<StockViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

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
                'Gestion des Stocks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Historique',
                onPressed: () {
                  Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.stockHistory);
                },
              ),
              if (currentUser != null &&
                  (PermissionService.hasPermission(currentUser, 'manage_stock') ||
                      PermissionService.hasPermission(currentUser, 'manage_users')))
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Ajouter dépôt',
                  onPressed: () {
                    Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.stockDepot).then((_) {
                      stockViewModel.loadStocks();
                    });
                  },
                ),
            ],
          ),
        ),
        // Statistiques globales
        _buildStatisticsCard(stockViewModel),
        
        // Liste des stocks
        Expanded(
          child: stockViewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : stockViewModel.filteredStocks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun stock enregistré',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => stockViewModel.loadStocks(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: stockViewModel.filteredStocks.length,
                        itemBuilder: (context, index) {
                          final stock = stockViewModel.filteredStocks[index];
                          return _buildStockCard(context, stock, stockViewModel);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(StockViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Stock Total',
            '${viewModel.totalStockGlobal.toStringAsFixed(2)} kg',
            Icons.inventory,
            Colors.brown.shade700,
          ),
          _buildStatItem(
            'Adhérents',
            '${viewModel.nombreAdherentsAvecStock}',
            Icons.people,
            Colors.green.shade700,
          ),
          _buildStatItem(
            'Alertes',
            '${viewModel.nombreAdherentsStockCritique}',
            Icons.warning,
            Colors.orange.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStockCard(
    BuildContext context,
    StockActuelModel stock,
    StockViewModel viewModel,
  ) {
    final status = stock.status;
    final statusColor = Color(status.colorValue);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          viewModel.selectStock(stock);
          // Utiliser le Navigator interne pour garder la sidebar
          Navigator.of(context, rootNavigator: false).push(
            MaterialPageRoute(
              builder: (context) => StockDetailScreen(adherentId: stock.adherentId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicateur de statut
              Container(
                width: 8,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              
              // Informations adhérent
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          stock.adherentCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stock.adherentFullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.inventory, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${stock.stockTotal.toStringAsFixed(2)} kg',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    if (stock.dernierDepot != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Dernier dépôt: ${DateFormat('dd/MM/yyyy').format(stock.dernierDepot!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Badge de statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran de détail d'un stock
class StockDetailScreen extends StatefulWidget {
  final int adherentId;

  const StockDetailScreen({super.key, required this.adherentId});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<StockViewModel>();
      viewModel.loadDepotsByAdherent(widget.adherentId);
      viewModel.loadMouvements(adherentId: widget.adherentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stockViewModel = context.watch<StockViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du Stock'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (currentUser != null &&
              (PermissionService.hasPermission(currentUser, 'manage_stock') ||
                  PermissionService.hasPermission(currentUser, 'manage_users')))
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Ajuster stock',
              onPressed: () {
                Navigator.of(context, rootNavigator: false).pushNamed(
                  AppRoutes.stockAdjustment,
                  arguments: widget.adherentId,
                ).then((_) {
                  stockViewModel.loadStocks();
                  stockViewModel.loadMouvements(adherentId: widget.adherentId);
                });
              },
            ),
        ],
      ),
      body: stockViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Liste des dépôts
                  const Text(
                    'Dépôts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (stockViewModel.depots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucun dépôt enregistré'),
                    )
                  else
                    ...stockViewModel.depots.map((depot) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const SizedBox(
                              width: 24,
                              child: Icon(Icons.inventory_2, color: Colors.brown),
                            ),
                            title: Text(
                              '${depot.quantite.toStringAsFixed(2)} kg',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${DateFormat('dd/MM/yyyy').format(depot.dateDepot)}'),
                                if (depot.qualite != null)
                                  Text('Qualité: ${depot.qualite}'),
                                if (depot.observations != null)
                                  Text('Notes: ${depot.observations}'),
                              ],
                            ),
                          ),
                        )),
                  
                  const SizedBox(height: 24),
                  
                  // Historique des mouvements récents
                  const Text(
                    'Mouvements récents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (stockViewModel.mouvements.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucun mouvement enregistré'),
                    )
                  else
                    ...stockViewModel.mouvements.take(10).map((mouvement) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: SizedBox(
                              width: 24,
                              child: Icon(
                                mouvement.isDepot
                                    ? Icons.add_circle
                                    : mouvement.isVente
                                        ? Icons.remove_circle
                                        : Icons.tune,
                                color: mouvement.isDepot
                                    ? Colors.green
                                    : mouvement.isVente
                                      ? Colors.red
                                      : Colors.orange,
                              ),
                            ),
                            title: Text(
                              '${mouvement.typeLabel}: ${mouvement.quantite.abs().toStringAsFixed(2)} kg',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(mouvement.dateMouvement)}'),
                                if (mouvement.commentaire != null)
                                  Text('Note: ${mouvement.commentaire}'),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}

