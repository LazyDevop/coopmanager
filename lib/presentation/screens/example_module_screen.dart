import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/screen_wrapper.dart';
import '../widgets/common/conditional_actions.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/toast_helper.dart';
import '../widgets/common/status_indicators.dart';
import '../../services/auth/permission_service.dart';

/// Exemple d'écran de module avec actions conditionnelles selon le rôle
class ExampleModuleScreen extends StatefulWidget {
  final String moduleName;
  final String route;

  const ExampleModuleScreen({
    super.key,
    required this.moduleName,
    required this.route,
  });

  @override
  State<ExampleModuleScreen> createState() => _ExampleModuleScreenState();
}

class _ExampleModuleScreenState extends State<ExampleModuleScreen> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Simuler un chargement
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      // Données de démonstration
      _items.addAll([
        {
          'id': 1,
          'name': 'Item 1',
          'status': 'validated',
          'stock': 150.0,
          'isLow': false,
        },
        {
          'id': 2,
          'name': 'Item 2',
          'status': 'pending',
          'stock': 5.0,
          'isLow': true,
        },
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      currentRoute: widget.route,
      child: Scaffold(
        body: _isLoading
            ? const LoadingIndicator(message: 'Chargement...')
            : Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: _items.isEmpty
                        ? _buildEmptyState(context)
                        : _buildItemsList(context),
                  ),
                ],
              ),
        floatingActionButton: _buildFAB(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser!;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.moduleName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          ConditionalActions(
            user: user,
            entity: widget.moduleName.toLowerCase(),
            onAdd: () => _handleAdd(context),
            onEdit: () => _handleEdit(context),
            onDelete: () => _handleDelete(context),
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
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun élément',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser!;

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: SizedBox(
              width: 40,
              child: CircleAvatar(
                backgroundColor: Colors.brown.shade100,
                child: Text('${item['id']}'),
              ),
            ),
            title: Text(item['name']),
            subtitle: Row(
              children: [
                if (item['isLow'] == true) StatusIndicators.stockLow(),
                if (item['status'] == 'validated') StatusIndicators.venteValidee(),
                if (item['status'] == 'pending') StatusIndicators.depotEnAttente(),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (PermissionService.canUpdate(user, widget.moduleName.toLowerCase()))
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _handleEditItem(context, item),
                  ),
                if (PermissionService.canDelete(user, widget.moduleName.toLowerCase()))
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _handleDeleteItem(context, item),
                  ),
              ],
            ),
            onTap: () => _handleViewItem(context, item),
          ),
        );
      },
    );
  }

  Widget _buildFAB(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser!;

    return ConditionalFAB(
      user: user,
      entity: widget.moduleName.toLowerCase(),
      onPressed: () => _handleAdd(context),
      tooltip: 'Ajouter',
    );
  }

  void _handleAdd(BuildContext context) {
    ToastHelper.showInfo('Ajouter un élément');
    // TODO: Naviguer vers le formulaire d'ajout
  }

  void _handleEdit(BuildContext context) {
    ToastHelper.showInfo('Modifier un élément');
    // TODO: Naviguer vers le formulaire d'édition
  }

  void _handleDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet élément ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ToastHelper.showSuccessSnackBar(context, 'Élément supprimé');
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleViewItem(BuildContext context, Map<String, dynamic> item) {
    ToastHelper.showInfo('Voir les détails de ${item['name']}');
    // TODO: Naviguer vers la page de détails
  }

  void _handleEditItem(BuildContext context, Map<String, dynamic> item) {
    ToastHelper.showInfo('Modifier ${item['name']}');
    // TODO: Naviguer vers le formulaire d'édition
  }

  void _handleDeleteItem(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${item['name']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _items.remove(item);
              });
              ToastHelper.showSuccessSnackBar(context, 'Élément supprimé');
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
