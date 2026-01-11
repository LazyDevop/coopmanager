/// Écran de Gestion des Créances Clients V2
/// 
/// Suivi des créances et paiements différés

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/vente_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../data/models/creance_client_model.dart';
import '../../../../config/routes/routes.dart';
import 'package:intl/intl.dart';

class CreancesClientsScreen extends StatefulWidget {
  const CreancesClientsScreen({super.key});

  @override
  State<CreancesClientsScreen> createState() => _CreancesClientsScreenState();
}

class _CreancesClientsScreenState extends State<CreancesClientsScreen> {
  String _filterStatut = 'tous';
  int? _selectedClientId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadCreances();
      viewModel.loadClients();
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
                      const Icon(Icons.account_balance_wallet, color: AppTheme.warningColor, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Créances Clients',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const Spacer(),
                      // Filtres
                      DropdownButton<int?>(
                        value: _selectedClientId,
                        hint: const Text('Tous les clients'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Tous les clients')),
                          ...viewModel.clients.map((c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.raisonSociale),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedClientId = value);
                          viewModel.loadCreances(clientId: value);
                        },
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _filterStatut,
                        items: const [
                          DropdownMenuItem(value: 'tous', child: Text('Tous')),
                          DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                          DropdownMenuItem(value: 'partiellement_payee', child: Text('Partiellement payée')),
                          DropdownMenuItem(value: 'en_retard', child: Text('En retard')),
                          DropdownMenuItem(value: 'payee', child: Text('Payée')),
                        ],
                        onChanged: (value) {
                          setState(() => _filterStatut = value!);
                          viewModel.loadCreances(
                            clientId: _selectedClientId,
                            statut: value == 'tous' ? null : value,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Statistiques rapides
                  _buildStatsBar(viewModel),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Liste des créances
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCreancesList(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsBar(VenteViewModel viewModel) {
    final creances = viewModel.creances;
    final totalCreances = creances.fold<double>(0.0, (sum, c) => sum + c.montantTotal);
    final totalPaye = creances.fold<double>(0.0, (sum, c) => sum + c.montantPaye);
    final totalRestant = creances.fold<double>(0.0, (sum, c) => sum + c.montantRestant);
    final enRetard = creances.where((c) => c.isEnRetard).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem('Total créances', totalCreances, AppTheme.infoColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem('Payé', totalPaye, AppTheme.successColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem('Restant', totalRestant, AppTheme.warningColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem('En retard', enRetard.toDouble(), AppTheme.errorColor, isCount: true),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, double value, Color color, {bool isCount = false}) {
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
            isCount ? value.toInt().toString() : NumberFormat('#,##0').format(value),
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

  Widget _buildCreancesList(BuildContext context, VenteViewModel viewModel) {
    final creances = _filterStatut == 'tous'
        ? viewModel.creances
        : viewModel.creances.where((c) => c.statut == _filterStatut).toList();

    if (creances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune créance',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: creances.length,
      itemBuilder: (context, index) {
        final creance = creances[index];
        return _buildCreanceCard(context, viewModel, creance);
      },
    );
  }

  Widget _buildCreanceCard(BuildContext context, VenteViewModel viewModel, CreanceClientModel creance) {
    final isRetard = creance.isEnRetard;
    final pourcentagePaye = creance.pourcentagePaye;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isRetard ? AppTheme.errorColor.withOpacity(0.05) : null,
      child: InkWell(
        onTap: () => _showCreanceDetail(context, viewModel, creance),
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
                      color: _getStatutColor(creance.statut).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      creance.statut.toUpperCase(),
                      style: TextStyle(
                        color: _getStatutColor(creance.statut),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isRetard) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 16, color: AppTheme.errorColor),
                          const SizedBox(width: 4),
                          Text(
                            '${creance.joursRetard ?? 0} jours',
                            style: TextStyle(
                              color: AppTheme.errorColor,
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
                    'Vente #${creance.venteId}',
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
                      'Montant total',
                      '${NumberFormat('#,##0').format(creance.montantTotal)} FCFA',
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Payé',
                      '${NumberFormat('#,##0').format(creance.montantPaye)} FCFA',
                      Icons.check_circle,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Restant',
                      '${NumberFormat('#,##0').format(creance.montantRestant)} FCFA',
                      Icons.pending,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Barre de progression
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progression du paiement',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${pourcentagePaye.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatutColor(creance.statut),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pourcentagePaye / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatutColor(creance.statut),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Échéance: ${DateFormat('dd/MM/yyyy').format(creance.dateEcheance)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isRetard ? AppTheme.errorColor : AppTheme.textSecondary,
                      fontWeight: isRetard ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showCreanceDetail(context, viewModel, creance),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Détails'),
                  ),
                  if (!creance.isPayee) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _enregistrerPaiement(context, viewModel, creance),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Enregistrer paiement'),
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

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return AppTheme.infoColor;
      case 'partiellement_payee':
        return AppTheme.warningColor;
      case 'payee':
        return AppTheme.successColor;
      case 'en_retard':
        return AppTheme.errorColor;
      case 'bloquee':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  void _showCreanceDetail(BuildContext context, VenteViewModel viewModel, CreanceClientModel creance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Créance #${creance.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Vente', '#${creance.venteId}'),
              _buildDetailRow('Client', '#${creance.clientId}'),
              _buildDetailRow('Statut', creance.statut),
              _buildDetailRow('Montant total', '${NumberFormat('#,##0').format(creance.montantTotal)} FCFA'),
              _buildDetailRow('Montant payé', '${NumberFormat('#,##0').format(creance.montantPaye)} FCFA'),
              _buildDetailRow('Montant restant', '${NumberFormat('#,##0').format(creance.montantRestant)} FCFA'),
              _buildDetailRow('Pourcentage payé', '${creance.pourcentagePaye.toStringAsFixed(1)}%'),
              _buildDetailRow('Date vente', DateFormat('dd/MM/yyyy').format(creance.dateVente)),
              _buildDetailRow('Date échéance', DateFormat('dd/MM/yyyy').format(creance.dateEcheance)),
              if (creance.datePaiement != null)
                _buildDetailRow('Date paiement', DateFormat('dd/MM/yyyy').format(creance.datePaiement!)),
              if (creance.joursRetard != null)
                _buildDetailRow('Jours de retard', '${creance.joursRetard}'),
              if (creance.isClientBloque)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Text(
                        'Client bloqué',
                        style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
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

  void _enregistrerPaiement(BuildContext context, VenteViewModel viewModel, CreanceClientModel creance) {
    final montantController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enregistrer un paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Montant restant: ${NumberFormat('#,##0').format(creance.montantRestant)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: montantController,
              decoration: const InputDecoration(
                labelText: 'Montant payé (FCFA)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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

              final montant = double.parse(montantController.text);
              if (montant <= 0 || montant > creance.montantRestant) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Montant invalide'),
                    backgroundColor: AppTheme.errorColor,
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }

              final authViewModel = context.read<AuthViewModel>();
              final userId = authViewModel.currentUser?.id ?? 0;

              final success = await viewModel.enregistrerPaiement(
                creanceId: creance.id!,
                montantPaye: montant,
                userId: userId,
              );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Paiement enregistré avec succès'),
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

