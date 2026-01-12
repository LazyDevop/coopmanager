import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/client_model.dart';
import '../../viewmodels/client_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../config/routes/routes.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;
  String? _selectedStatut;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientViewModel>().loadClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.all(16),
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
                'Gestion des Clients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.account_balance_wallet),
                tooltip: 'Clients impayés',
                onPressed: () {
                  Navigator.of(
                    context,
                    rootNavigator: false,
                  ).pushNamed(AppRoutes.clientsImpayes);
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Nouveau client',
                onPressed: () {
                  Navigator.of(
                    context,
                    rootNavigator: false,
                  ).pushNamed(AppRoutes.clientAdd);
                },
              ),
            ],
          ),
        ),
        // Filtres et recherche
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            children: [
              // Barre de recherche
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText:
                      'Rechercher par code, raison sociale, responsable...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<ClientViewModel>().searchClients('');
                            setState(() {});
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
                  setState(() {});
                  context.read<ClientViewModel>().searchClients(value);
                },
              ),
              const SizedBox(height: 12),
              // Filtres
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Type de client',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tous')),
                        DropdownMenuItem(
                          value: ClientModel.typeLocal,
                          child: Text('Acheteur local'),
                        ),
                        DropdownMenuItem(
                          value: ClientModel.typeGrossiste,
                          child: Text('Grossiste'),
                        ),
                        DropdownMenuItem(
                          value: ClientModel.typeExportateur,
                          child: Text('Exportateur'),
                        ),
                        DropdownMenuItem(
                          value: ClientModel.typeIndustriel,
                          child: Text('Industriel'),
                        ),
                        DropdownMenuItem(
                          value: ClientModel.typeOccasionnel,
                          child: Text('Occasionnel'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                        context.read<ClientViewModel>().setFilterType(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedStatut,
                      decoration: InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tous')),
                        DropdownMenuItem(
                          value: ClientModel.statutActif,
                          child: Text('Actif'),
                        ),
                        DropdownMenuItem(
                          value: ClientModel.statutSuspendu,
                          child: Text('Suspendu'),
                        ),
                        DropdownMenuItem(
                          value: ClientModel.statutBloque,
                          child: Text('Bloqué'),
                        ),
                        DropdownMenuItem(
                          value: ClientModel.statutArchive,
                          child: Text('Archivé'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatut = value;
                        });
                        context.read<ClientViewModel>().setFilterStatut(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedType = null;
                        _selectedStatut = null;
                        _searchController.clear();
                      });
                      context.read<ClientViewModel>().resetFilters();
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
        ),
        // Liste des clients
        Expanded(
          child: Consumer<ClientViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading && viewModel.clients.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(viewModel.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => viewModel.loadClients(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }

              if (viewModel.filteredClients.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun client trouvé',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(
                            context,
                            rootNavigator: false,
                          ).pushNamed(AppRoutes.clientAdd);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Créer le premier client'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => viewModel.loadClients(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = viewModel.filteredClients[index];
                    return _buildClientCard(context, client);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClientCard(BuildContext context, ClientModel client) {
    final numberFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Couleur selon le statut et le risque
    Color cardColor = Colors.white;
    if (client.statut == ClientModel.statutBloque) {
      cardColor = Colors.red.shade50;
    } else if (client.estARisque) {
      cardColor = Colors.orange.shade50;
    } else if (client.soldeClient > 0) {
      cardColor = Colors.yellow.shade50;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          final id = client.id;
          if (id == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Client invalide (id manquant)')),
            );
            return;
          }
          Navigator.of(
            context,
            rootNavigator: false,
          ).pushNamed(AppRoutes.clientDetail, arguments: id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône type
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getTypeColor(client.typeClient).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(client.typeClient),
                  color: _getTypeColor(client.typeClient),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            client.raisonSociale,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatutBadge(client.statut),
                        if (client.estARisque)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'RISQUE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${client.codeClient} • ${client.typeClientLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (client.nomResponsable != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Contact: ${client.nomResponsable}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (client.telephone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            client.telephone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Solde et crédit
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${numberFormat.format(client.soldeClient)} FCFA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: client.soldeClient > 0
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (client.plafondCredit != null) ...[
                    Text(
                      'Plafond: ${numberFormat.format(client.plafondCredit!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (client.pourcentageCreditUtilise / 100)
                            .clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: client.estARisque
                                ? Colors.orange
                                : Colors.green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatutBadge(String statut) {
    Color color;
    String label;

    switch (statut) {
      case ClientModel.statutActif:
        color = Colors.green;
        label = 'Actif';
        break;
      case ClientModel.statutSuspendu:
        color = Colors.orange;
        label = 'Suspendu';
        break;
      case ClientModel.statutBloque:
        color = Colors.red;
        label = 'Bloqué';
        break;
      case ClientModel.statutArchive:
        color = Colors.grey;
        label = 'Archivé';
        break;
      default:
        color = Colors.grey;
        label = statut;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color.fromRGBO(
            (color.red * 0.7).round(),
            (color.green * 0.7).round(),
            (color.blue * 0.7).round(),
            1.0,
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case ClientModel.typeLocal:
        return Icons.store;
      case ClientModel.typeGrossiste:
        return Icons.shopping_bag;
      case ClientModel.typeExportateur:
        return Icons.flight_takeoff;
      case ClientModel.typeIndustriel:
        return Icons.factory;
      case ClientModel.typeOccasionnel:
        return Icons.person;
      default:
        return Icons.business;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case ClientModel.typeLocal:
        return Colors.blue;
      case ClientModel.typeGrossiste:
        return Colors.green;
      case ClientModel.typeExportateur:
        return Colors.purple;
      case ClientModel.typeIndustriel:
        return Colors.orange;
      case ClientModel.typeOccasionnel:
        return Colors.grey;
      default:
        return Colors.brown;
    }
  }
}
