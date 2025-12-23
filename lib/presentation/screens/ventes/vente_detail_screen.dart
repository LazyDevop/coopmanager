import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../viewmodels/vente_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/vente_model.dart';
import '../../../data/models/adherent_model.dart';
import '../../../services/vente/export_service.dart';

class VenteDetailScreen extends StatefulWidget {
  final int venteId;

  const VenteDetailScreen({super.key, required this.venteId});

  @override
  State<VenteDetailScreen> createState() => _VenteDetailScreenState();
}

class _VenteDetailScreenState extends State<VenteDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadVenteDetails(widget.venteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<VenteViewModel>(
          builder: (context, viewModel, child) {
            final vente = viewModel.selectedVente;
            return Text(vente != null
                ? 'Vente #${vente.id}'
                : 'Détails de la vente');
          },
        ),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          Consumer<VenteViewModel>(
            builder: (context, viewModel, child) {
              final vente = viewModel.selectedVente;
              if (vente == null || vente.isAnnulee) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, value, vente, viewModel),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('Exporter'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'annuler',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Annuler la vente', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<VenteViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.selectedVente == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.selectedVente == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Vente non trouvée',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVenteInfo(viewModel.selectedVente!),
                const SizedBox(height: 24),
                if (viewModel.selectedVente!.isGroupee)
                  _buildDetailsSection(viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVenteInfo(VenteModel vente) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: vente.isValide
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Icon(
                    vente.isIndividuelle ? Icons.person : Icons.people,
                    size: 30,
                    color: vente.isValide
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vente.isIndividuelle
                            ? 'Vente individuelle'
                            : 'Vente groupée',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${dateFormat.format(vente.dateVente)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (!vente.isValide) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Annulée',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('Quantité totale', '${numberFormat.format(vente.quantiteTotal)} kg'),
            _buildInfoRow('Prix unitaire', '${numberFormat.format(vente.prixUnitaire)} FCFA/kg'),
            _buildInfoRow(
              'Montant total',
              '${numberFormat.format(vente.montantTotal)} FCFA',
              isBold: true,
              color: Colors.green.shade700,
            ),
            if (vente.acheteur != null)
              _buildInfoRow('Acheteur', vente.acheteur!),
            if (vente.modePaiement != null)
              _buildInfoRow(
                'Mode de paiement',
                _getModePaiementLabel(vente.modePaiement!),
              ),
            if (vente.notes != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Observations', vente.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(VenteViewModel viewModel) {
    if (viewModel.venteDetails.isEmpty) {
      return const SizedBox.shrink();
    }

    final numberFormat = NumberFormat('#,##0.00');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails par adhérent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 16),
            ...viewModel.venteDetails.map((detail) {
              AdherentModel? adherent;
              try {
                adherent = viewModel.adherents
                    .firstWhere((a) => a.id == detail.adherentId);
              } catch (e) {
                adherent = null;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.grey.shade50,
                child: ListTile(
                  title: Text(
                    adherent?.fullName ?? 'Adhérent #${detail.adherentId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Code: ${adherent?.code ?? 'N/A'}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${numberFormat.format(detail.quantite)} kg',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${numberFormat.format(detail.montant)} FCFA',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
                color: color,
                fontSize: isBold ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getModePaiementLabel(String mode) {
    switch (mode) {
      case 'especes':
        return 'Espèces';
      case 'mobile_money':
        return 'Mobile Money';
      case 'virement':
        return 'Virement';
      default:
        return mode;
    }
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    String action,
    VenteModel vente,
    VenteViewModel viewModel,
  ) async {
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) return;

    switch (action) {
      case 'export':
        await _exportVente(context, vente, viewModel);
        break;
      case 'annuler':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Annuler la vente'),
            content: const Text(
              'Voulez-vous vraiment annuler cette vente ? Le stock sera restauré.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Non'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Oui, annuler'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final raison = await showDialog<String>(
            context: context,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Raison de l\'annulation'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Raison (optionnel)',
                  ),
                  maxLines: 3,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, controller.text.trim()),
                    child: const Text('Confirmer'),
                  ),
                ],
              );
            },
          );

          final success = await viewModel.annulerVente(
            vente.id!,
            currentUser.id!,
            raison?.isEmpty == true ? null : raison,
          );

          if (success && context.mounted) {
            Fluttertoast.showToast(
              msg: 'Vente annulée avec succès',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
        }
        break;
    }
  }

  Future<void> _exportVente(
    BuildContext context,
    VenteModel vente,
    VenteViewModel viewModel,
  ) async {
    try {
      final exportService = ExportService();
      final success = await exportService.exportVente(
        vente: vente,
        details: viewModel.venteDetails,
        adherents: viewModel.adherents,
      );

      if (success && context.mounted) {
        Fluttertoast.showToast(
          msg: 'Vente exportée avec succès',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Fluttertoast.showToast(
          msg: 'Erreur lors de l\'export: ${e.toString()}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }
}
