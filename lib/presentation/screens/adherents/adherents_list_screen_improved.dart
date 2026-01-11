import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/adherent_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/app_theme.dart';
import '../../../data/models/adherent_model.dart';
import '../../widgets/layout/main_layout.dart';
import '../../widgets/common/data_table_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/loading_button.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/toast_helper.dart';

/// Écran amélioré de liste des adhérents avec le nouveau design
class AdherentsListScreenImproved extends StatefulWidget {
  const AdherentsListScreenImproved({super.key});

  @override
  State<AdherentsListScreenImproved> createState() => _AdherentsListScreenImprovedState();
}

class _AdherentsListScreenImprovedState extends State<AdherentsListScreenImproved> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdherentViewModel>().loadAdherents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: AppRoutes.adherents,
      title: 'Gestion des Adhérents',
      child: Consumer<AdherentViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading && viewModel.adherents.isEmpty) {
            return const LoadingIndicator(message: 'Chargement des adhérents...');
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: TextStyle(color: AppTheme.errorColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => viewModel.loadAdherents(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec actions
                _buildHeader(context, viewModel),
                const SizedBox(height: 24),
                // Tableau des adhérents
                Expanded(
                  child: DataTableWidget<AdherentModel>(
                    data: viewModel.filteredAdherents,
                    isLoading: viewModel.isLoading,
                    searchHint: 'Rechercher un adhérent...',
                    searchFilter: (adherent) =>
                        '${adherent.nom} ${adherent.prenom} ${adherent.code} ${adherent.telephone}',
                    actions: [
                      LoadingButton(
                        text: 'Ajouter',
                        icon: Icons.person_add,
                        isLoading: false,
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.adherentAdd);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Actualiser',
                        onPressed: () => viewModel.loadAdherents(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download),
                        tooltip: 'Exporter',
                        onPressed: () {
                          // TODO: Implémenter l'export
                          ToastHelper.showInfo('Export en cours...');
                        },
                      ),
                    ],
                    columns: const [
                      DataColumn(label: Text('Code')),
                      DataColumn(label: Text('Nom complet')),
                      DataColumn(label: Text('Téléphone')),
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Date adhésion')),
                      DataColumn(label: Text('Actions')),
                    ],
                    buildRow: (adherent, index) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              adherent.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          DataCell(
                            Text('${adherent.prenom} ${adherent.nom}'),
                          ),
                          DataCell(Text(adherent.telephone ?? '-')),
                          DataCell(
                            adherent.isActive
                                ? StatusBadges.success('Actif', isSmall: true)
                                : StatusBadges.error('Inactif', isSmall: true),
                          ),
                          DataCell(
                            Text(
                              DateFormat('dd/MM/yyyy').format(adherent.dateAdhesion),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 20),
                                  tooltip: 'Voir détails',
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.adherentDetail,
                                      arguments: adherent.id,
                                    );
                                  },
                                  color: AppTheme.infoColor,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: 'Modifier',
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.adherentEdit,
                                      arguments: adherent,
                                    );
                                  },
                                  color: AppTheme.primaryColor,
                                ),
                                IconButton(
                                  icon: Icon(
                                    adherent.isActive
                                        ? Icons.block
                                        : Icons.check_circle,
                                    size: 20,
                                  ),
                                  tooltip: adherent.isActive
                                      ? 'Désactiver'
                                      : 'Activer',
                                  onPressed: () => _toggleAdherentStatus(
                                    context,
                                    adherent,
                                    viewModel,
                                  ),
                                  color: adherent.isActive
                                      ? AppTheme.errorColor
                                      : AppTheme.successColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    emptyMessage: 'Aucun adhérent trouvé',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AdherentViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Liste des Adhérents',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${viewModel.adherents.length} adhérent${viewModel.adherents.length > 1 ? 's' : ''} au total',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
        // Statistiques rapides
        Row(
          children: [
            _buildStatChip(
              context,
              label: 'Actifs',
              value: '${viewModel.adherents.where((a) => a.isActive).length}',
              color: AppTheme.successColor,
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              context,
              label: 'Inactifs',
              value: '${viewModel.adherents.where((a) => !a.isActive).length}',
              color: AppTheme.errorColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAdherentStatus(
    BuildContext context,
    AdherentModel adherent,
    AdherentViewModel viewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          adherent.isActive ? 'Désactiver l\'adhérent' : 'Activer l\'adhérent',
        ),
        content: Text(
          adherent.isActive
              ? 'Êtes-vous sûr de vouloir désactiver ${adherent.prenom} ${adherent.nom} ?'
              : 'Êtes-vous sûr de vouloir activer ${adherent.prenom} ${adherent.nom} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: adherent.isActive
                  ? AppTheme.errorColor
                  : AppTheme.successColor,
            ),
            child: Text(adherent.isActive ? 'Désactiver' : 'Activer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final authViewModel = context.read<AuthViewModel>();
        final currentUser = authViewModel.currentUser;
        
        if (currentUser == null) {
          ToastHelper.showError('Erreur: utilisateur non connecté');
          return;
        }
        
        final success = await viewModel.toggleAdherentStatus(
          adherent.id!,
          !adherent.isActive,
          currentUser.id!,
        );
        
        if (success && context.mounted) {
          ToastHelper.showSuccess(
            adherent.isActive
                ? 'Adhérent désactivé avec succès'
                : 'Adhérent activé avec succès',
          );
        } else if (context.mounted) {
          ToastHelper.showError('Erreur lors de la modification du statut');
        }
      } catch (e) {
        if (context.mounted) {
          ToastHelper.showError('Erreur: ${e.toString()}');
        }
      }
    }
  }
}
