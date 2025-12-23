import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/local_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../../services/client/client_service.dart';
import '../../../data/models/client_model.dart';
import '../../../config/app_config.dart';
import '../../../config/routes/routes.dart';

/// Contenu de la liste des clients (sans Scaffold)
class ClientsListContent extends StatefulWidget {
  const ClientsListContent({super.key});

  @override
  State<ClientsListContent> createState() => _ClientsListContentState();
}

class _ClientsListContentState extends State<ClientsListContent> {
  final ClientService _clientService = ClientService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ClientModel> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clients = await _clientService.getAllClients(activeOnly: true);
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des clients: $e';
        _isLoading = false;
      });
    }
  }

  List<ClientModel> get _filteredClients {
    var filtered = _clients;
    
    if (_filterType != null) {
      filtered = filtered.where((c) => c.type == _filterType).toList();
    }
    
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((c) {
        return c.nom.toLowerCase().contains(query) ||
               c.code.toLowerCase().contains(query) ||
               (c.telephone?.toLowerCase().contains(query) ?? false) ||
               (c.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildHeader(context),
          const SizedBox(height: 16),
          // Filtres et recherche
          _buildFilters(context),
          const SizedBox(height: 16),
          // Liste
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion des Clients',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gérer les clients et acheteurs',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.clientAdd);
          },
          icon: const Icon(Icons.add),
          label: const Text('Nouveau Client'),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, code, téléphone, email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
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
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _filterType,
                  decoration: InputDecoration(
                    labelText: 'Type de client',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                    DropdownMenuItem<String>(
                      value: AppConfig.clientTypeEntreprise,
                      child: Text('Entreprise'),
                    ),
                    DropdownMenuItem<String>(
                      value: AppConfig.clientTypeParticulier,
                      child: Text('Particulier'),
                    ),
                    DropdownMenuItem<String>(
                      value: AppConfig.clientTypeCooperative,
                      child: Text('Coopérative'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterType = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.filter_alt_off),
                tooltip: 'Réinitialiser',
                onPressed: () {
                  setState(() {
                    _filterType = null;
                    _searchController.clear();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const LocalLoader(message: 'Chargement des clients...');
    }

    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadClients,
      );
    }

    if (_filteredClients.isEmpty) {
      return const EmptyState(
        icon: Icons.business_outlined,
        title: 'Aucun client trouvé',
        message: 'Ajoutez votre premier client',
      );
    }

    return ListView.builder(
      itemCount: _filteredClients.length,
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getTypeColor(client.type),
              child: Icon(
                _getTypeIcon(client.type),
                color: Colors.white,
              ),
            ),
            title: Text(
              client.nom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Code: ${client.code}'),
                if (client.telephone != null)
                  Text('Tél: ${client.telephone}'),
                if (client.ville != null)
                  Text('Ville: ${client.ville}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleMenuAction(context, value, client),
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
              ],
            ),
            onTap: () {
              Navigator.of(context, rootNavigator: false).pushNamed(
                AppRoutes.clientDetail,
                arguments: client.id,
              );
            },
          ),
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case AppConfig.clientTypeEntreprise:
        return Colors.blue;
      case AppConfig.clientTypeParticulier:
        return Colors.green;
      case AppConfig.clientTypeCooperative:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case AppConfig.clientTypeEntreprise:
        return Icons.business;
      case AppConfig.clientTypeParticulier:
        return Icons.person;
      case AppConfig.clientTypeCooperative:
        return Icons.group;
      default:
        return Icons.business;
    }
  }

  void _handleMenuAction(BuildContext context, String action, ClientModel client) {
    switch (action) {
      case 'view':
        Navigator.of(context, rootNavigator: false).pushNamed(
          AppRoutes.clientDetail,
          arguments: client.id,
        );
        break;
      case 'edit':
        Navigator.of(context, rootNavigator: false).pushNamed(
          AppRoutes.clientEdit,
          arguments: client,
        );
        break;
    }
  }
}

