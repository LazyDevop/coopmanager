import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/recette_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/recette_model.dart';
import '../../../config/routes/routes.dart';
import '../../../services/auth/permission_service.dart';
import 'recette_detail_screen.dart';
import 'recette_bordereau_screen.dart';
import 'recette_export_screen.dart';

class RecettesListScreen extends StatefulWidget {
  const RecettesListScreen({super.key});

  @override
  State<RecettesListScreen> createState() => _RecettesListScreenState();
}

class _RecettesListScreenState extends State<RecettesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecetteViewModel>().loadRecettesSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recetteViewModel = context.watch<RecetteViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    // Le MainAppShell gère déjà le layout avec sidebar, donc on retourne seulement le contenu
    return Column(
      children: [
        // Barre d'actions en haut (remplace l'AppBar)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              const Text(
                'Gestion des Recettes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exporter',
                onPressed: () {
                  Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.recetteExport);
                },
              ),
            ],
          ),
        ),
        // Contenu
        Expanded(
          child: Column(
            children: [
              // Statistiques globales
              _buildStatisticsCard(recetteViewModel),
              
              // Liste des recettes
              Expanded(
                child: recetteViewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : recetteViewModel.recettesSummary.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune recette enregistrée',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => recetteViewModel.loadRecettesSummary(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: recetteViewModel.recettesSummary.length,
                              itemBuilder: (context, index) {
                                final summary = recetteViewModel.recettesSummary[index];
                                return _buildRecetteCard(context, summary, recetteViewModel);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(RecetteViewModel viewModel) {
    final totalBrut = viewModel.recettesSummary.fold(
      0.0,
      (sum, s) => sum + s.totalMontantBrut,
    );
    final totalCommission = viewModel.recettesSummary.fold(
      0.0,
      (sum, s) => sum + s.totalCommission,
    );
    final totalNet = viewModel.recettesSummary.fold(
      0.0,
      (sum, s) => sum + s.totalMontantNet,
    );

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Montant Brut',
            '${NumberFormat('#,##0').format(totalBrut)} FCFA',
            Icons.attach_money,
            Colors.blue.shade700,
          ),
          _buildStatItem(
            'Commission',
            '${NumberFormat('#,##0').format(totalCommission)} FCFA',
            Icons.percent,
            Colors.orange.shade700,
          ),
          _buildStatItem(
            'Montant Net',
            '${NumberFormat('#,##0').format(totalNet)} FCFA',
            Icons.account_balance_wallet,
            Colors.teal.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecetteCard(
    BuildContext context,
    RecetteSummaryModel summary,
    RecetteViewModel viewModel,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          viewModel.loadRecettesByAdherent(summary.adherentId);
          Navigator.of(context, rootNavigator: false).pushNamed(
            AppRoutes.recetteDetail,
            arguments: summary.adherentId,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.teal.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Informations adhérent
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          summary.adherentCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            summary.adherentFullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.receipt, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${summary.nombreRecettes} recette${summary.nombreRecettes > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (summary.derniereRecette != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Dernière: ${DateFormat('dd/MM/yyyy').format(summary.derniereRecette!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Montants
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${NumberFormat('#,##0').format(summary.totalMontantNet)} FCFA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Brut: ${NumberFormat('#,##0').format(summary.totalMontantBrut)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Comm: ${NumberFormat('#,##0').format(summary.totalCommission)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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
}

