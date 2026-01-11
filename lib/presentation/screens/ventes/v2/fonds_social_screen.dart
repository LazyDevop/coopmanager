/// Écran de Gestion du Fonds Social V2
/// 
/// Gestion des contributions au fonds social

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/vente_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../data/models/fonds_social_model.dart';
import '../../../../config/routes/routes.dart';
import 'package:intl/intl.dart';

class FondsSocialScreen extends StatefulWidget {
  const FondsSocialScreen({super.key});

  @override
  State<FondsSocialScreen> createState() => _FondsSocialScreenState();
}

class _FondsSocialScreenState extends State<FondsSocialScreen> {
  String _filterSource = 'tous';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadContributionsFondsSocial();
      viewModel.loadVentes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VenteViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            // En-tête avec statistiques
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
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context, rootNavigator: false).pushReplacementNamed(AppRoutes.ventes),
                        tooltip: 'Retour',
                      ),
                      const Icon(Icons.favorite, color: AppTheme.errorColor, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Fonds Social',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorColor,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateContributionDialog(context, viewModel),
                        icon: const Icon(Icons.add),
                        label: const Text('Nouvelle Contribution'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Statistiques
                  _buildStatsBar(viewModel),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Liste des contributions
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContributionsList(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsBar(VenteViewModel viewModel) {
    final contributions = viewModel.contributionsFondsSocial;
    final total = contributions.fold<double>(0.0, (sum, c) => sum + c.montant);
    final fromVentes = contributions.where((c) => c.isFromVente).fold<double>(0.0, (sum, c) => sum + c.montant);
    final fromDons = contributions.where((c) => c.isFromDon).fold<double>(0.0, (sum, c) => sum + c.montant);

    return Row(
      children: [
        Expanded(
          child: _buildStatItem('Total', total, AppTheme.errorColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem('Depuis ventes', fromVentes, AppTheme.venteColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem('Dons', fromDons, AppTheme.successColor),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat('#,##0').format(value),
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionsList(BuildContext context, VenteViewModel viewModel) {
    var contributions = viewModel.contributionsFondsSocial;

    if (_filterSource != 'tous') {
      contributions = contributions.where((c) => c.source == _filterSource).toList();
    }

    if (contributions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune contribution',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showCreateContributionDialog(context, viewModel),
              icon: const Icon(Icons.add),
              label: const Text('Créer une contribution'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filtres
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[50],
          child: Row(
            children: [
              DropdownButton<String>(
                value: _filterSource,
                items: const [
                  DropdownMenuItem(value: 'tous', child: Text('Toutes les sources')),
                  DropdownMenuItem(value: 'vente', child: Text('Depuis ventes')),
                  DropdownMenuItem(value: 'don', child: Text('Dons')),
                  DropdownMenuItem(value: 'autre', child: Text('Autre')),
                ],
                onChanged: (value) {
                  setState(() => _filterSource = value!);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contributions.length,
            itemBuilder: (context, index) {
              final contribution = contributions[index];
              return _buildContributionCard(context, viewModel, contribution);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContributionCard(
    BuildContext context,
    VenteViewModel viewModel,
    FondsSocialModel contribution,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                    color: _getSourceColor(contribution.source).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contribution.source.toUpperCase(),
                    style: TextStyle(
                      color: _getSourceColor(contribution.source),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${NumberFormat('#,##0').format(contribution.montant)} FCFA',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              contribution.description,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (contribution.pourcentage != null) ...[
              const SizedBox(height: 4),
              Text(
                'Pourcentage: ${contribution.pourcentage!.toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(contribution.dateContribution),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (contribution.venteId != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Vente #${contribution.venteId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'vente':
        return AppTheme.venteColor;
      case 'don':
        return AppTheme.successColor;
      case 'autre':
        return AppTheme.infoColor;
      default:
        return Colors.grey;
    }
  }

  void _showCreateContributionDialog(BuildContext context, VenteViewModel viewModel) {
    final montantController = TextEditingController();
    final descriptionController = TextEditingController();
    final pourcentageController = TextEditingController();
    String selectedSource = 'vente';
    int? selectedVenteId;
    bool usePourcentage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouvelle Contribution'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSource,
                  decoration: const InputDecoration(
                    labelText: 'Source',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'vente', child: Text('Depuis une vente')),
                    DropdownMenuItem(value: 'don', child: Text('Don')),
                    DropdownMenuItem(value: 'autre', child: Text('Autre')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedSource = value!);
                  },
                ),
                if (selectedSource == 'vente') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: selectedVenteId,
                    decoration: const InputDecoration(
                      labelText: 'Vente',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Sélectionner')),
                      ...viewModel.ventes.map((v) => DropdownMenuItem<int?>(
                        value: v.id,
                        child: Text('Vente #${v.id} - ${NumberFormat('#,##0').format(v.montantTotal)} FCFA'),
                      )),
                    ],
                    onChanged: (value) => setState(() => selectedVenteId = value),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: usePourcentage,
                      onChanged: (value) => setState(() => usePourcentage = value ?? false),
                    ),
                    const Text('Calculer en pourcentage'),
                  ],
                ),
                if (usePourcentage && selectedSource == 'vente' && selectedVenteId != null)
                  TextField(
                    controller: pourcentageController,
                    decoration: const InputDecoration(
                      labelText: 'Pourcentage (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  )
                else
                  TextField(
                    controller: montantController,
                    decoration: const InputDecoration(
                      labelText: 'Montant (FCFA)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Description requise'),
                      backgroundColor: AppTheme.errorColor,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                final authViewModel = context.read<AuthViewModel>();
                final userId = authViewModel.currentUser?.id ?? 0;

                bool success = false;

                if (selectedSource == 'vente' && selectedVenteId != null) {
                  final vente = viewModel.ventes.firstWhere((v) => v.id == selectedVenteId);
                  if (usePourcentage && pourcentageController.text.isNotEmpty) {
                    success = await viewModel.createContributionFondsSocialFromVente(
                      venteId: selectedVenteId!,
                      montantVente: vente.montantTotal,
                      pourcentage: double.parse(pourcentageController.text),
                      createdBy: userId,
                    );
                  } else if (montantController.text.isNotEmpty) {
                    success = await viewModel.createContributionFondsSocialFromVente(
                      venteId: selectedVenteId!,
                      montantVente: vente.montantTotal,
                      montantFixe: double.parse(montantController.text),
                      createdBy: userId,
                    );
                  }
                } else {
                  // Contribution manuelle
                  if (montantController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Montant requis'),
                        backgroundColor: AppTheme.errorColor,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                  // TODO: Implémenter création contribution manuelle dans ViewModel
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Contribution manuelle à implémenter'),
                      backgroundColor: AppTheme.infoColor,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Contribution créée avec succès'),
                        backgroundColor: AppTheme.successColor,
                        duration: const Duration(seconds: 3),
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
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

