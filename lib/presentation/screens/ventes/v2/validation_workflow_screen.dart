/// Écran de Workflow de Validation V2
/// 
/// Gestion du workflow multi-niveaux de validation des ventes

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/vente_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../data/models/validation_vente_model.dart';
import '../../../../data/models/vente_model.dart';
import '../../../../config/routes/routes.dart';
import 'package:intl/intl.dart';

class ValidationWorkflowScreen extends StatefulWidget {
  const ValidationWorkflowScreen({super.key});

  @override
  State<ValidationWorkflowScreen> createState() => _ValidationWorkflowScreenState();
}

class _ValidationWorkflowScreenState extends State<ValidationWorkflowScreen> {
  String _filterEtape = 'tous';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadVentes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VenteViewModel>(
      builder: (context, viewModel, child) {
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context, rootNavigator: false).pushReplacementNamed(AppRoutes.ventes),
                    tooltip: 'Retour',
                  ),
                  const Icon(Icons.verified_user, color: AppTheme.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Workflow de Validation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _filterEtape,
                    items: const [
                      DropdownMenuItem(value: 'tous', child: Text('Toutes les étapes')),
                      DropdownMenuItem(value: 'preparation', child: Text('Préparation')),
                      DropdownMenuItem(value: 'validation_prix', child: Text('Validation Prix')),
                      DropdownMenuItem(value: 'confirmation_finale', child: Text('Confirmation Finale')),
                    ],
                    onChanged: (value) {
                      setState(() => _filterEtape = value!);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Liste des ventes en attente
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildVentesEnAttente(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVentesEnAttente(BuildContext context, VenteViewModel viewModel) {
    // Filtrer les ventes qui ont besoin de validation
    final ventesEnAttente = viewModel.ventes.where((v) => v.statut == 'valide').toList();

    if (ventesEnAttente.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune vente en attente de validation',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ventesEnAttente.length,
      itemBuilder: (context, index) {
        final vente = ventesEnAttente[index];
        return _buildVenteCard(context, viewModel, vente);
      },
    );
  }

  Widget _buildVenteCard(BuildContext context, VenteViewModel viewModel, VenteModel vente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showWorkflowDetail(context, viewModel, vente),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'EN ATTENTE',
                      style: TextStyle(
                        color: AppTheme.infoColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Vente #${vente.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Quantité',
                      '${vente.quantiteTotal.toStringAsFixed(2)} kg',
                      Icons.scale,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Prix unitaire',
                      '${NumberFormat('#,##0').format(vente.prixUnitaire)} FCFA/kg',
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Montant total',
                      '${NumberFormat('#,##0').format(vente.montantTotal)} FCFA',
                      Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Workflow steps
              _buildWorkflowSteps(context, viewModel, vente),
              const SizedBox(height: 12),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showWorkflowDetail(context, viewModel, vente),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Voir workflow'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showValidationDialog(context, viewModel, vente),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowSteps(BuildContext context, VenteViewModel viewModel, VenteModel vente) {
    return FutureBuilder<List<ValidationVenteModel>>(
      future: viewModel.getWorkflowVente(vente.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()));
        }

        final validations = snapshot.data ?? [];
        final etapes = ['preparation', 'validation_prix', 'confirmation_finale'];

        return Row(
          children: etapes.map((etape) {
            final validation = validations.firstWhere(
              (v) => v.etape == etape,
              orElse: () => ValidationVenteModel(
                venteId: vente.id!,
                etape: etape,
                createdAt: DateTime.now(),
              ),
            );

            final isActive = validation.isEnAttente;
            final isCompleted = validation.isApprouvee;
            final isRejected = validation.isRejetee;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.successColor
                          : isRejected
                              ? AppTheme.errorColor
                              : isActive
                                  ? AppTheme.infoColor
                                  : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check
                          : isRejected
                              ? Icons.close
                              : Icons.radio_button_unchecked,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getEtapeLabel(etape),
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? AppTheme.infoColor : Colors.grey[600],
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _getEtapeLabel(String etape) {
    switch (etape) {
      case 'preparation':
        return 'Préparation';
      case 'validation_prix':
        return 'Validation Prix';
      case 'confirmation_finale':
        return 'Confirmation';
      default:
        return etape;
    }
  }

  void _showWorkflowDetail(BuildContext context, VenteViewModel viewModel, VenteModel vente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Workflow - Vente #${vente.id}'),
        content: FutureBuilder<List<ValidationVenteModel>>(
          future: viewModel.getWorkflowVente(vente.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final validations = snapshot.data ?? [];

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: validations.map((validation) {
                  return ListTile(
                    leading: Icon(
                      validation.isApprouvee
                          ? Icons.check_circle
                          : validation.isRejetee
                              ? Icons.cancel
                              : Icons.pending,
                      color: validation.isApprouvee
                          ? AppTheme.successColor
                          : validation.isRejetee
                              ? AppTheme.errorColor
                              : AppTheme.infoColor,
                    ),
                    title: Text(_getEtapeLabel(validation.etape)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Statut: ${validation.statut}'),
                        if (validation.commentaire != null)
                          Text('Commentaire: ${validation.commentaire}'),
                        if (validation.dateValidation != null)
                          Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(validation.dateValidation!)}'),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showValidationDialog(BuildContext context, VenteViewModel viewModel, VenteModel vente) {
    final commentaireController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider la vente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vente #${vente.id}'),
            const SizedBox(height: 16),
            TextField(
              controller: commentaireController,
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authViewModel = context.read<AuthViewModel>();
              final userId = authViewModel.currentUser?.id ?? 0;

              // TODO: Implémenter la validation selon l'étape actuelle
              final success = await viewModel.initialiserWorkflow(
                venteId: vente.id!,
                createdBy: userId,
              );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workflow initialisé'),
                      backgroundColor: AppTheme.successColor,
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(viewModel.errorMessage ?? 'Erreur'),
                      backgroundColor: AppTheme.errorColor,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}

