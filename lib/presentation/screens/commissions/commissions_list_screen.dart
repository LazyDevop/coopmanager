/// Écran de liste des commissions
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/commission_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/commission_model.dart';
import 'commission_form_screen.dart';

class CommissionsListScreen extends StatefulWidget {
  const CommissionsListScreen({super.key});

  @override
  State<CommissionsListScreen> createState() => _CommissionsListScreenState();
}

class _CommissionsListScreenState extends State<CommissionsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommissionViewModel>().loadCommissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CommissionViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.loadCommissions(),
            tooltip: 'Actualiser',
          ),
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToForm(context, null),
              tooltip: 'Ajouter une commission',
            ),
        ],
      ),
      body: _buildBody(context, viewModel, currentUser),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CommissionViewModel viewModel,
    dynamic currentUser,
  ) {
    if (viewModel.isLoading && viewModel.commissions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                viewModel.clearError();
                viewModel.loadCommissions();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (viewModel.commissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune commission',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez votre première commission',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
            const SizedBox(height: 24),
            if (currentUser != null)
              ElevatedButton.icon(
                onPressed: () => _navigateToForm(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une commission'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadCommissions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.commissions.length,
        itemBuilder: (context, index) {
          final commission = viewModel.commissions[index];
          return _buildCommissionCard(context, commission, currentUser);
        },
      ),
    );
  }

  Widget _buildCommissionCard(
    BuildContext context,
    CommissionModel commission,
    dynamic currentUser,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isActive = commission.statut == CommissionStatut.active;
    final isPermanente = commission.dateFin == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToForm(context, commission),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commission.libelle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${commission.code}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: isActive
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${commission.montantFixe.toStringAsFixed(0)} FCFA',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    commission.typeApplication == CommissionTypeApplication.parKg
                        ? 'Par kg'
                        : 'Par vente',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Du ${dateFormat.format(commission.dateDebut)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (isPermanente) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: const Text('Permanente'),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    Text(
                      'au ${dateFormat.format(commission.dateFin!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              if (commission.reconductible) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.autorenew, size: 16, color: Colors.orange.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Reconductible (${commission.periodeReconductionDays} jours)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                    ),
                  ],
                ),
              ],
              if (commission.description != null && commission.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  commission.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context, CommissionModel? commission) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommissionFormScreen(commission: commission),
      ),
    ).then((_) {
      // Recharger la liste après retour
      context.read<CommissionViewModel>().loadCommissions();
    });
  }
}


