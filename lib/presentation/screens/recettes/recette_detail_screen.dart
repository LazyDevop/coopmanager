import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/recette_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/recette_model.dart';
import '../../../services/auth/permission_service.dart';
import 'recette_bordereau_screen.dart';
import '../../../config/routes/routes.dart';

class RecetteDetailScreen extends StatefulWidget {
  final int adherentId;

  const RecetteDetailScreen({super.key, required this.adherentId});

  @override
  State<RecetteDetailScreen> createState() => _RecetteDetailScreenState();
}

class _RecetteDetailScreenState extends State<RecetteDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecetteViewModel>().loadRecettesByAdherent(widget.adherentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final recetteViewModel = context.watch<RecetteViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    final totalBrut = recetteViewModel.recettes.fold(
      0.0,
      (sum, r) => sum + r.montantBrut,
    );
    final totalCommission = recetteViewModel.recettes.fold(
      0.0,
      (sum, r) => sum + r.commissionAmount,
    );
    final totalNet = recetteViewModel.recettes.fold(
      0.0,
      (sum, r) => sum + r.montantNet,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail des Recettes'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Voir le compte financier',
            onPressed: () {
              Navigator.of(context, rootNavigator: false).pushNamed(
                AppRoutes.compteFinancierAdherent,
                arguments: widget.adherentId,
              );
            },
          ),
          if (currentUser != null &&
              (PermissionService.hasPermission(currentUser, 'manage_recettes') ||
                  PermissionService.hasPermission(currentUser, 'manage_users')))
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Générer bordereau PDF',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecetteBordereauScreen(adherentId: widget.adherentId),
                  ),
                );
              },
            ),
        ],
      ),
      body: recetteViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Résumé
                  Card(
                    color: Colors.teal.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Montant brut total:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '${NumberFormat('#,##0').format(totalBrut)} FCFA',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Commission totale:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '-${NumberFormat('#,##0').format(totalCommission)} FCFA',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Montant net total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,##0').format(totalNet)} FCFA',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Liste des recettes
                  const Text(
                    'Historique des recettes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (recetteViewModel.recettes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucune recette enregistrée'),
                    )
                  else
                    ...recetteViewModel.recettes.map((recette) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: SizedBox(
                              width: 24,
                              child: const Icon(Icons.receipt_long, color: Colors.teal),
                            ),
                            title: Text(
                              '${NumberFormat('#,##0').format(recette.montantNet)} FCFA',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${DateFormat('dd/MM/yyyy').format(recette.dateRecette)}'),
                                Text('Brut: ${NumberFormat('#,##0').format(recette.montantBrut)} FCFA'),
                                Text('Commission (${(recette.commissionRate * 100).toStringAsFixed(1)}%): ${NumberFormat('#,##0').format(recette.commissionAmount)} FCFA'),
                                if (recette.notes != null)
                                  Text('Note: ${recette.notes}'),
                              ],
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}

