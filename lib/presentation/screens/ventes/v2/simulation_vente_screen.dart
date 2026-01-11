/// Écran de Simulation de Vente V2
/// 
/// Permet de simuler une vente avant validation avec comparaisons et indicateurs

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/vente_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../data/models/simulation_vente_model.dart';
import '../../../../config/routes/routes.dart';
import 'package:intl/intl.dart';

class SimulationVenteScreen extends StatefulWidget {
  const SimulationVenteScreen({super.key});

  @override
  State<SimulationVenteScreen> createState() => _SimulationVenteScreenState();
}

class _SimulationVenteScreenState extends State<SimulationVenteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteController = TextEditingController();
  final _prixController = TextEditingController();
  final _fondsSocialController = TextEditingController();

  int? _selectedClientId;
  int? _selectedCampagneId;
  int? _selectedLotId;
  bool _usePourcentage = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadClients();
      viewModel.loadCampagnes();
      viewModel.loadLotsVente();
      viewModel.loadSimulations();
    });
  }

  @override
  void dispose() {
    _quantiteController.dispose();
    _prixController.dispose();
    _fondsSocialController.dispose();
    super.dispose();
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
                  const Icon(Icons.calculate, color: AppTheme.infoColor, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Simulation de Vente',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.infoColor,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateSimulationDialog(context, viewModel),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle Simulation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.infoColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Contenu
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSimulationsList(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSimulationsList(BuildContext context, VenteViewModel viewModel) {
    if (viewModel.simulations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune simulation',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showCreateSimulationDialog(context, viewModel),
              icon: const Icon(Icons.add),
              label: const Text('Créer une simulation'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.simulations.length,
      itemBuilder: (context, index) {
        final simulation = viewModel.simulations[index];
        return _buildSimulationCard(context, viewModel, simulation);
      },
    );
  }

  Widget _buildSimulationCard(
    BuildContext context,
    VenteViewModel viewModel,
    SimulationVenteModel simulation,
  ) {
    final isRisque = simulation.isPrixHorsSeuil || simulation.isPrixInferieurMoyenne;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showSimulationDetail(context, viewModel, simulation),
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
                      color: _getStatusColor(simulation.statut).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      simulation.statut.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(simulation.statut),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isRisque) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 16, color: AppTheme.warningColor),
                          const SizedBox(width: 4),
                          Text(
                            'RISQUE',
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(simulation.createdAt),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
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
                      '${simulation.quantiteTotal.toStringAsFixed(2)} kg',
                      Icons.scale,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Prix unitaire',
                      '${NumberFormat('#,##0').format(simulation.prixUnitairePropose)} FCFA/kg',
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Montant brut',
                      '${NumberFormat('#,##0').format(simulation.montantBrut)} FCFA',
                      Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Comparaisons
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildComparisonItem(
                        'Prix du jour',
                        simulation.prixMoyenJour,
                        simulation.prixUnitairePropose,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildComparisonItem(
                        'Prix moyen',
                        simulation.prixMoyenPrecedent,
                        simulation.prixUnitairePropose,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showSimulationDetail(context, viewModel, simulation),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Détails'),
                  ),
                  if (simulation.isSimulee) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _validerSimulation(context, viewModel, simulation.id!),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Valider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
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

  Widget _buildComparisonItem(String label, double prixReference, double prixPropose) {
    final ecart = prixPropose - prixReference;
    final pourcentage = prixReference > 0 ? (ecart / prixReference) * 100 : 0.0;
    final isPositif = ecart >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '${NumberFormat('#,##0').format(prixReference)}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(
              isPositif ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: isPositif ? AppTheme.successColor : AppTheme.errorColor,
            ),
            Text(
              '${pourcentage.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: isPositif ? AppTheme.successColor : AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'simulee':
        return AppTheme.infoColor;
      case 'validee':
        return AppTheme.successColor;
      case 'rejetee':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  void _showCreateSimulationDialog(BuildContext context, VenteViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Simulation'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  value: _selectedClientId,
                  decoration: const InputDecoration(
                    labelText: 'Client',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Sélectionner un client')),
                    ...viewModel.clients.map((client) => DropdownMenuItem<int?>(
                      value: client.id,
                      child: Text(client.raisonSociale),
                    )),
                  ],
                  onChanged: (value) => setState(() => _selectedClientId = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: _selectedCampagneId,
                  decoration: const InputDecoration(
                    labelText: 'Campagne',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Sélectionner une campagne')),
                    ...viewModel.campagnes.map((campagne) => DropdownMenuItem<int?>(
                      value: campagne.id,
                      child: Text(campagne.nom),
                    )),
                  ],
                  onChanged: (value) => setState(() => _selectedCampagneId = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantiteController,
                  decoration: const InputDecoration(
                    labelText: 'Quantité (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Quantité requise';
                    if (double.tryParse(value) == null) return 'Valeur invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _prixController,
                  decoration: const InputDecoration(
                    labelText: 'Prix unitaire (FCFA/kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Prix requis';
                    if (double.tryParse(value) == null) return 'Valeur invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _usePourcentage,
                      onChanged: (value) => setState(() => _usePourcentage = value ?? true),
                    ),
                    const Text('Pourcentage'),
                  ],
                ),
                if (_usePourcentage)
                  TextFormField(
                    controller: _fondsSocialController,
                    decoration: const InputDecoration(
                      labelText: 'Pourcentage fonds social (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  )
                else
                  TextFormField(
                    controller: _fondsSocialController,
                    decoration: const InputDecoration(
                      labelText: 'Montant fonds social (FCFA)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _createSimulation(context, viewModel),
            child: const Text('Simuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSimulation(BuildContext context, VenteViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();
    final userId = authViewModel.currentUser?.id ?? 0;

    final success = await viewModel.createSimulation(
      clientId: _selectedClientId,
      campagneId: _selectedCampagneId,
      quantiteTotal: double.parse(_quantiteController.text),
      prixUnitairePropose: double.parse(_prixController.text),
      pourcentageFondsSocial: _usePourcentage && _fondsSocialController.text.isNotEmpty
          ? double.parse(_fondsSocialController.text)
          : null,
      createdBy: userId,
    );

    if (context.mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Simulation créée avec succès'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Erreur lors de la création'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showSimulationDetail(
    BuildContext context,
    VenteViewModel viewModel,
    SimulationVenteModel simulation,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de la Simulation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Quantité', '${simulation.quantiteTotal.toStringAsFixed(2)} kg'),
              _buildDetailRow('Prix unitaire', '${NumberFormat('#,##0').format(simulation.prixUnitairePropose)} FCFA/kg'),
              _buildDetailRow('Montant brut', '${NumberFormat('#,##0').format(simulation.montantBrut)} FCFA'),
              _buildDetailRow('Commission', '${NumberFormat('#,##0').format(simulation.montantCommission)} FCFA'),
              _buildDetailRow('Montant net', '${NumberFormat('#,##0').format(simulation.montantNet)} FCFA'),
              _buildDetailRow('Fonds social', '${NumberFormat('#,##0').format(simulation.montantFondsSocial)} FCFA'),
              const Divider(),
              _buildDetailRow('Prix moyen du jour', '${NumberFormat('#,##0').format(simulation.prixMoyenJour)} FCFA/kg'),
              _buildDetailRow('Prix moyen précédent', '${NumberFormat('#,##0').format(simulation.prixMoyenPrecedent)} FCFA/kg'),
              _buildDetailRow('Marge coopérative', '${NumberFormat('#,##0').format(simulation.margeCooperative)} FCFA'),
              if (simulation.isPrixHorsSeuil)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: AppTheme.warningColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Prix hors des seuils configurés',
                          style: TextStyle(color: AppTheme.warningColor),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _validerSimulation(BuildContext context, VenteViewModel viewModel, int simulationId) async {
    // TODO: Implémenter la validation de simulation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Validation de simulation à implémenter'),
        backgroundColor: AppTheme.infoColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

