import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/local_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/stat_card.dart';

/// Exemple complet d'une page utilisant le nouveau système de layout
/// 
/// Cette page démontre :
/// - Structure sans Scaffold
/// - Gestion des états (loading, empty, error)
/// - Utilisation des widgets communs
/// - Layout professionnel
class ExamplePageContent extends StatefulWidget {
  const ExamplePageContent({super.key});

  @override
  State<ExamplePageContent> createState() => _ExamplePageContentState();
}

class _ExamplePageContentState extends State<ExamplePageContent> {
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simuler un chargement
      await Future.delayed(const Duration(seconds: 1));
      
      // Simuler des données
      setState(() {
        _items = ['Item 1', 'Item 2', 'Item 3'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la page
          _buildHeader(context),
          const SizedBox(height: 24),
          // Contenu principal
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  /// En-tête de la page
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exemple de Page',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Exemple d\'utilisation du nouveau système de layout',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
        ),
      ],
    );
  }

  /// Contenu principal avec gestion des états
  Widget _buildContent(BuildContext context) {
    // État de chargement
    if (_isLoading) {
      return const LocalLoader(message: 'Chargement des données...');
    }

    // État d'erreur
    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadData,
      );
    }

    // État vide
    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox,
        title: 'Aucun élément',
        message: 'Ajoutez votre premier élément',
        action: null, // Vous pouvez ajouter un bouton ici
      );
    }

    // Contenu normal
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistiques
        _buildStats(context),
        const SizedBox(height: 24),
        // Liste
        Expanded(
          child: _buildList(context),
        ),
      ],
    );
  }

  /// Cartes de statistiques
  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Total',
            value: '${_items.length}',
            icon: Icons.list,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Actifs',
            value: '${_items.length}',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'En attente',
            value: '0',
            icon: Icons.pending,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  /// Liste des éléments
  Widget _buildList(BuildContext context) {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.brown.shade100,
              child: Icon(Icons.item, color: Colors.brown.shade700),
            ),
            title: Text(
              item,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Description de $item'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Action
              },
            ),
            onTap: () {
              // Navigation ou action
            },
          ),
        );
      },
    );
  }
}

