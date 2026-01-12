import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/vente_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../config/routes/routes.dart';
import '../../../data/models/vente_model.dart';
import 'package:intl/intl.dart';
// Import des écrans de fonctionnalités
import 'ventes_statistiques_screen.dart';
import 'v2/simulation_vente_screen.dart';
import 'v2/lots_vente_screen.dart';
import 'v2/creances_clients_screen.dart';
import 'v2/validation_workflow_screen.dart';
import 'v2/fonds_social_screen.dart';
import 'v2/analyse_prix_screen.dart';

class VentesListScreen extends StatefulWidget {
  const VentesListScreen({super.key});

  @override
  State<VentesListScreen> createState() => _VentesListScreenState();
}

class _VentesListScreenState extends State<VentesListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadVentes();
      viewModel.loadAdherents();
      viewModel.loadClients();
      viewModel.loadCampagnes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
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
              // Indicateur de chargement en temps réel
              Consumer<VenteViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading && viewModel.ventes.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.brown.shade700),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
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
                  PopupMenuItem(
                    value: 'individuelle',
                    enabled: false,
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 20, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vente individuelle',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'groupee',
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 20),
                        SizedBox(width: 8),
                        Expanded(child: Text('Vente groupée')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Onglets pour toutes les fonctionnalités
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.brown.shade700,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.brown.shade700,
            tabs: const [
              Tab(icon: Icon(Icons.list), text: 'Liste'),
              Tab(icon: Icon(Icons.analytics), text: 'Statistiques'),
              Tab(icon: Icon(Icons.calculate), text: 'Simulation'),
              Tab(icon: Icon(Icons.inventory_2), text: 'Lots'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Créances'),
              Tab(icon: Icon(Icons.verified_user), text: 'Workflow'),
              Tab(icon: Icon(Icons.favorite), text: 'Fonds Social'),
              Tab(icon: Icon(Icons.trending_up), text: 'Analyse Prix'),
            ],
          ),
        ),
        // Contenu des onglets
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Onglet 1: Liste des ventes
              Consumer<VenteViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading && viewModel.ventes.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Chargement des ventes...'),
                        ],
                      ),
                    );
                  }

                  if (viewModel.errorMessage != null && viewModel.ventes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
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
                            ElevatedButton.icon(
                              onPressed: () {
                                viewModel.loadVentes();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown.shade700,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      _buildFiltersAndSearch(context, viewModel),
                      Expanded(
                        child: viewModel.filteredVentes.isEmpty
                            ? _buildEmptyState(context)
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await viewModel.loadVentes();
                                },
                                child: _buildVentesList(context, viewModel),
                              ),
                      ),
                    ],
                  );
                },
              ),
              // Onglet 2: Statistiques
              const VentesStatistiquesScreen(),
              // Onglet 3: Simulation
              const SimulationVenteScreen(),
              // Onglet 4: Lots
              const LotsVenteScreen(),
              // Onglet 5: Créances
              const CreancesClientsScreen(),
              // Onglet 6: Workflow
              const ValidationWorkflowScreen(),
              // Onglet 7: Fonds Social
              const FondsSocialScreen(),
              // Onglet 8: Analyse Prix
              const AnalysePrixScreen(),
            ],
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
          // Filtres V1
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Filtre Client (V1)
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int?>(
                  initialValue: viewModel.filterClientId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Client',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Tous')),
                    ...viewModel.clients.map((client) => DropdownMenuItem<int?>(
                      value: client.id,
                      child: Text(client.raisonSociale, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  selectedItemBuilder: (BuildContext context) {
                    return [
                      const Text('Tous', overflow: TextOverflow.ellipsis),
                      ...viewModel.clients.map((client) => Text(
                        client.raisonSociale,
                        overflow: TextOverflow.ellipsis,
                      )),
                    ];
                  },
                  onChanged: (value) {
                    viewModel.setFilterClient(value);
                  },
                ),
              ),
              // Filtre Campagne (V1)
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int?>(
                  initialValue: viewModel.filterCampagneId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Campagne',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Toutes')),
                    ...viewModel.campagnes.map((campagne) => DropdownMenuItem<int?>(
                      value: campagne.id,
                      child: Text(campagne.nom, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  selectedItemBuilder: (BuildContext context) {
                    return [
                      const Text('Toutes', overflow: TextOverflow.ellipsis),
                      ...viewModel.campagnes.map((campagne) => Text(
                        campagne.nom,
                        overflow: TextOverflow.ellipsis,
                      )),
                    ];
                  },
                  onChanged: (value) {
                    viewModel.setFilterCampagne(value);
                  },
                ),
              ),
              // Filtre Statut Paiement (V1)
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String?>(
                  initialValue: viewModel.filterStatutPaiement,
                  decoration: InputDecoration(
                    labelText: 'Paiement',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                    DropdownMenuItem<String?>(value: 'payee', child: Text('Payée')),
                    DropdownMenuItem<String?>(value: 'non_payee', child: Text('Non payée')),
                    DropdownMenuItem<String?>(value: 'partiellement_payee', child: Text('Partielle')),
                  ],
                  onChanged: (value) {
                    viewModel.setFilterStatutPaiement(value);
                  },
                ),
              ),
              // Filtre Adhérent (ancien)
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int?>(
                  initialValue: viewModel.filterAdherentId,
                  isExpanded: true,
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
                      child: Text('${adherent.code} - ${adherent.fullName}', overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  selectedItemBuilder: (BuildContext context) {
                    return [
                      const Text('Tous', overflow: TextOverflow.ellipsis),
                      ...viewModel.adherents.map((adherent) => Text(
                        '${adherent.code} - ${adherent.fullName}',
                        overflow: TextOverflow.ellipsis,
                      )),
                    ];
                  },
                  onChanged: (value) {
                    viewModel.setFilterAdherent(value);
                  },
                ),
              ),
              // Filtre Type
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String?>(
                  initialValue: viewModel.filterType,
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
              // Filtre Statut
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String?>(
                  initialValue: viewModel.filterStatut,
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
              // Bouton Réinitialiser filtres
              ElevatedButton.icon(
                onPressed: () {
                  viewModel.resetFilters();
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Réinitialiser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade800,
                ),
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: null, // Désactivé - utiliser le menu déroulant pour les ventes groupées
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle vente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentesList(BuildContext context, VenteViewModel viewModel) {
    final ventes = viewModel.filteredVentes;
    final clients = viewModel.clients;
    final campagnes = viewModel.campagnes;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    // Helper pour obtenir le nom du client
    String? getClientName(int? clientId) {
      if (clientId == null) return null;
      try {
        final client = clients.firstWhere((c) => c.id == clientId);
        return client.raisonSociale;
      } catch (e) {
        return 'Client #$clientId';
      }
    }

    // Helper pour obtenir le nom de la campagne
    String? getCampagneName(int? campagneId) {
      if (campagneId == null) return null;
      try {
        final campagne = campagnes.firstWhere((c) => c.id == campagneId);
        return campagne.nom;
      } catch (e) {
        return 'Campagne #$campagneId';
      }
    }

    // Helper pour obtenir le badge de statut paiement
    Widget getStatutPaiementBadge(String statut) {
      MaterialColor color;
      String label;
      switch (statut) {
        case 'payee':
          color = Colors.green;
          label = 'Payée';
          break;
        case 'partiellement_payee':
          color = Colors.orange;
          label = 'Partielle';
          break;
        default:
          color = Colors.red;
          label = 'Non payée';
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: ventes.length,
      physics: const AlwaysScrollableScrollPhysics(), // Permet le scroll même si peu d'éléments
      itemBuilder: (context, index) {
        final vente = ventes[index];
        final isV1 = vente.clientId != null && vente.clientId! > 0 && 
                     vente.campagneId != null && vente.campagneId! > 0;
        
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
                    ? (isV1 ? Colors.blue.shade100 : Colors.green.shade100)
                    : Colors.red.shade100,
                child: Icon(
                  isV1 
                      ? Icons.shopping_cart
                      : (vente.isIndividuelle ? Icons.person : Icons.people),
                  color: vente.isValide
                      ? (isV1 ? Colors.blue.shade700 : Colors.green.shade700)
                      : Colors.red.shade700,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    isV1 
                        ? 'Vente V1'
                        : (vente.isIndividuelle ? 'Vente individuelle' : 'Vente groupée'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: vente.isValide ? null : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (isV1) getStatutPaiementBadge(vente.statutPaiement),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // Client (V1)
                if (isV1 && vente.clientId != null) ...[
                  Row(
                    children: [
                      Icon(Icons.business, size: 14, color: Colors.blue.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Client: ${getClientName(vente.clientId) ?? 'N/A'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Campagne (V1)
                  if (vente.campagneId != null)
                    Row(
                      children: [
                        Icon(Icons.agriculture, size: 14, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Campagne: ${getCampagneName(vente.campagneId) ?? 'N/A'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                ],
                // Date
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
                // Quantité
                Row(
                  children: [
                    Icon(Icons.scale, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${numberFormat.format(vente.quantiteTotal)} kg',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (isV1 && vente.montantCommission > 0) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.percent, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Comm: ${numberFormat.format(vente.montantCommission)} FCFA',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
                // Acheteur (ancien format)
                if (!isV1 && vente.acheteur != null) ...[
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
                if (isV1 && vente.montantNet > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Net: ${numberFormat.format(vente.montantNet)} FCFA',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
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
