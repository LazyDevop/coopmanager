import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/social/social_service.dart';
import '../../../data/models/social/social_aide_type_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'social_aide_type_form_screen.dart';

/// Écran de gestion des types d'aides sociales (paramétrage)
class SocialAideTypesScreen extends StatefulWidget {
  const SocialAideTypesScreen({super.key});

  @override
  State<SocialAideTypesScreen> createState() => _SocialAideTypesScreenState();
}

class _SocialAideTypesScreenState extends State<SocialAideTypesScreen> {
  final SocialService _socialService = SocialService();
  List<SocialAideTypeModel> _aideTypes = [];
  bool _isLoading = true;
  bool _showActifsOnly = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAideTypes();
  }

  Future<void> _loadAideTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final types = await _socialService.getAllAideTypes(
        actifsOnly: _showActifsOnly,
      );
      setState(() {
        _aideTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleActivation(SocialAideTypeModel type) async {
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser == null) return;

    try {
      await _socialService.toggleAideTypeActivation(
        id: type.id!,
        activation: !type.activation,
        updatedBy: currentUser.id!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type.activation 
                ? 'Type d\'aide désactivé' 
                : 'Type d\'aide activé',
            ),
          ),
        );
        _loadAideTypes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteType(SocialAideTypeModel type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le type d\'aide "${type.libelle}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // TODO: Implémenter la suppression dans le service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suppression non implémentée')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Types d\'aides sociales'),
        actions: [
          IconButton(
            icon: Icon(_showActifsOnly ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() => _showActifsOnly = !_showActifsOnly);
              _loadAideTypes();
            },
            tooltip: _showActifsOnly 
              ? 'Afficher tous les types' 
              : 'Afficher uniquement les actifs',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push<SocialAideTypeModel?>(
                MaterialPageRoute(
                  builder: (context) => const SocialAideTypeFormScreen(),
                ),
              );
              if (result != null && mounted) {
                _loadAideTypes();
              }
            },
            tooltip: 'Ajouter un type d\'aide',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAideTypes,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _aideTypes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun type d\'aide configuré',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.of(context).push<SocialAideTypeModel?>(
                                MaterialPageRoute(
                                  builder: (context) => const SocialAideTypeFormScreen(),
                                ),
                              );
                              if (result != null && mounted) {
                                _loadAideTypes();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Créer le premier type'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAideTypes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _aideTypes.length,
                        itemBuilder: (context, index) {
                          final type = _aideTypes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: type.activation
                                    ? Colors.green.shade100
                                    : Colors.grey.shade300,
                                child: Icon(
                                  _getCategoryIcon(type.categorie),
                                  color: type.activation
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      type.libelle,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: type.activation
                                            ? null
                                            : TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                  if (!type.activation)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'INACTIF',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Code: ${type.code}'),
                                  Text('Catégorie: ${type.categorie}'),
                                  if (type.plafondMontant != null)
                                    Text(
                                      'Plafond: ${type.plafondMontant!.toStringAsFixed(0)} FCFA',
                                    ),
                                  if (type.estRemboursable) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.rotate_left,
                                          size: 14,
                                          color: Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Remboursable',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (type.modeRemboursement == 'RETENUE_RECETTE') ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.autorenew,
                                            size: 14,
                                            color: Colors.blue.shade700,
                                          ),
                                          Text(
                                            'Retenue auto',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      type.activation
                                          ? Icons.toggle_on
                                          : Icons.toggle_off,
                                      ),
                                    color: type.activation
                                        ? Colors.green
                                        : Colors.grey,
                                    onPressed: () => _toggleActivation(type),
                                    tooltip: type.activation
                                        ? 'Désactiver'
                                        : 'Activer',
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        Navigator.of(context).push<SocialAideTypeModel?>(
                                          MaterialPageRoute(
                                            builder: (context) => SocialAideTypeFormScreen(
                                              aideType: type,
                                            ),
                                          ),
                                        ).then((result) {
                                          if (result != null) {
                                            _loadAideTypes();
                                          }
                                        });
                                      } else if (value == 'delete') {
                                        _deleteType(type);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Modifier'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  IconData _getCategoryIcon(String categorie) {
    switch (categorie) {
      case 'FINANCIERE':
        return Icons.attach_money;
      case 'MATERIELLE':
        return Icons.inventory;
      case 'SOCIALE':
        return Icons.people;
      case 'TECHNIQUE':
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }
}

