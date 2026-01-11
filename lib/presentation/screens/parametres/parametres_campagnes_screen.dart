import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/parametres_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/parametres_cooperative_model.dart';
import 'campagne_form_screen.dart';

class ParametresCampagnesScreen extends StatefulWidget {
  const ParametresCampagnesScreen({super.key});

  @override
  State<ParametresCampagnesScreen> createState() => _ParametresCampagnesScreenState();
}

class _ParametresCampagnesScreenState extends State<ParametresCampagnesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParametresViewModel>().loadCampagnes();
    });
  }

  Future<void> _toggleCampagneStatus(int id, bool isActive, int userId) async {
    final viewModel = context.read<ParametresViewModel>();
    final success = await viewModel.updateCampagne(
      id: id,
      isActive: !isActive,
      updatedBy: userId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statut de la campagne mis à jour'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteCampagne(int id, int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette campagne ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final viewModel = context.read<ParametresViewModel>();
      final success = await viewModel.deleteCampagne(id, userId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campagne supprimée'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Erreur lors de la suppression'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ParametresViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    return Column(
      children: [
        // Bouton ajouter campagne
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestion des campagnes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CampagneFormScreen(),
                    ),
                  ).then((_) {
                    viewModel.loadCampagnes();
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle campagne'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Liste des campagnes
        Expanded(
          child: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : viewModel.campagnes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune campagne enregistrée',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => viewModel.loadCampagnes(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: viewModel.campagnes.length,
                        itemBuilder: (context, index) {
                          final campagne = viewModel.campagnes[index];
                          return _buildCampagneCard(context, campagne, viewModel, currentUser);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCampagneCard(
    BuildContext context,
    CampagneModel campagne,
    ParametresViewModel viewModel,
    currentUser,
  ) {
    final isEnCours = campagne.isEnCours;
    final statusColor = campagne.isActive
        ? (isEnCours ? Colors.green : Colors.orange)
        : Colors.grey;

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
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.2),
            child: Icon(
              isEnCours ? Icons.play_circle : Icons.calendar_today,
              color: statusColor,
            ),
          ),
        ),
        title: Text(
          campagne.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Du ${DateFormat('dd/MM/yyyy').format(campagne.dateDebut)} au ${DateFormat('dd/MM/yyyy').format(campagne.dateFin)}',
            ),
            if (campagne.description != null) ...[
              const SizedBox(height: 4),
              Text(
                campagne.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    campagne.isActive
                        ? (isEnCours ? 'En cours' : 'Planifiée')
                        : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (currentUser == null) return;
            
            switch (value) {
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CampagneFormScreen(campagne: campagne),
                  ),
                ).then((_) {
                  viewModel.loadCampagnes();
                });
                break;
              case 'toggle':
                await _toggleCampagneStatus(campagne.id!, campagne.isActive, currentUser.id!);
                break;
              case 'delete':
                await _deleteCampagne(campagne.id!, currentUser.id!);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(campagne.isActive ? Icons.pause : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(campagne.isActive ? 'Désactiver' : 'Activer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

