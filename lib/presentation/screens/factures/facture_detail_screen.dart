import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import '../../viewmodels/facture_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/facture_model.dart';
import '../../../data/models/adherent_model.dart';
import '../../../services/facture/facture_pdf_service.dart';

class FactureDetailScreen extends StatefulWidget {
  final int factureId;

  const FactureDetailScreen({super.key, required this.factureId});

  @override
  State<FactureDetailScreen> createState() => _FactureDetailScreenState();
}

class _FactureDetailScreenState extends State<FactureDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<FactureViewModel>();
      viewModel.loadFactureDetails(widget.factureId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<FactureViewModel>(
          builder: (context, viewModel, child) {
            final facture = viewModel.selectedFacture;
            return Text(facture?.numero ?? 'Détails de la facture');
          },
        ),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          Consumer<FactureViewModel>(
            builder: (context, viewModel, child) {
              final facture = viewModel.selectedFacture;
              if (facture == null) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, value, facture, viewModel),
                itemBuilder: (context) => [
                  if (facture.pdfPath != null)
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, size: 18),
                          SizedBox(width: 8),
                          Text('Voir le PDF'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'print',
                    child: Row(
                      children: [
                        Icon(Icons.print, size: 18),
                        SizedBox(width: 8),
                        Text('Imprimer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('Exporter PDF'),
                      ],
                    ),
                  ),
                  if (!facture.isPayee && !facture.isAnnulee) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'payee',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 18, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Marquer comme payée', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'annuler',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Annuler la facture', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<FactureViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.selectedFacture == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.selectedFacture == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Facture non trouvée',
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
                _buildFactureInfo(viewModel.selectedFacture!),
                const SizedBox(height: 24),
                if (viewModel.selectedAdherent != null)
                  _buildAdherentInfo(viewModel.selectedAdherent!),
                const SizedBox(height: 24),
                if (viewModel.selectedVente != null)
                  _buildVenteInfo(viewModel.selectedVente!, viewModel.venteDetails),
                if (viewModel.selectedRecette != null)
                  _buildRecetteInfo(viewModel.selectedRecette!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFactureInfo(FactureModel facture) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facture.numero,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${dateFormat.format(facture.dateFacture)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (facture.dateEcheance != null)
                        Text(
                          'Échéance: ${dateFormat.format(facture.dateEcheance!)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatutColor(facture.statut).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatutLabel(facture.statut),
                    style: TextStyle(
                      color: _getStatutColor(facture.statut),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Montant total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${numberFormat.format(facture.montantTotal)} FCFA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Type', _getTypeLabel(facture.type)),
            if (facture.notes != null) _buildInfoRow('Notes', facture.notes!),
            if (facture.pdfPath != null)
              _buildInfoRow('Fichier PDF', facture.pdfPath!.split('/').last),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherentInfo(AdherentModel adherent) {
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
              'Informations client',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Nom', adherent.fullName),
            _buildInfoRow('Code', adherent.code),
            if (adherent.village != null) _buildInfoRow('Village', adherent.village!),
            if (adherent.telephone != null) _buildInfoRow('Téléphone', adherent.telephone!),
            if (adherent.email != null) _buildInfoRow('Email', adherent.email!),
          ],
        ),
      ),
    );
  }

  Widget _buildVenteInfo(dynamic vente, List<dynamic> details) {
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
            Text(
              'Détails de la vente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Date', dateFormat.format(vente.dateVente)),
            _buildInfoRow('Quantité', '${numberFormat.format(vente.quantiteTotal)} kg'),
            _buildInfoRow('Prix unitaire', '${numberFormat.format(vente.prixUnitaire)} FCFA/kg'),
            _buildInfoRow('Montant total', '${numberFormat.format(vente.montantTotal)} FCFA'),
            if (vente.acheteur != null) _buildInfoRow('Acheteur', vente.acheteur),
            if (vente.modePaiement != null)
              _buildInfoRow('Mode de paiement', _getModePaiementLabel(vente.modePaiement)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecetteInfo(dynamic recette) {
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
            Text(
              'Détails de la recette',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Date', dateFormat.format(recette.dateRecette)),
            _buildInfoRow('Montant brut', '${numberFormat.format(recette.montantBrut)} FCFA'),
            _buildInfoRow(
              'Taux de commission',
              '${(recette.commissionRate * 100).toStringAsFixed(2)}%',
            ),
            _buildInfoRow('Commission', '${numberFormat.format(recette.commissionAmount)} FCFA'),
            _buildInfoRow('Montant net', '${numberFormat.format(recette.montantNet)} FCFA'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'payee':
        return Colors.green;
      case 'annulee':
        return Colors.red;
      case 'validee':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'payee':
        return 'Payée';
      case 'annulee':
        return 'Annulée';
      case 'validee':
        return 'Validée';
      case 'brouillon':
        return 'Brouillon';
      default:
        return statut;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'vente':
        return 'Facture de vente';
      case 'recette':
        return 'Facture de recette';
      case 'bordereau':
        return 'Bordereau de recettes';
      default:
        return type;
    }
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
    FactureModel facture,
    FactureViewModel viewModel,
  ) async {
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) return;

    switch (action) {
      case 'view':
        if (facture.pdfPath != null) {
          // Ouvrir le PDF
          // TODO: Implémenter l'ouverture du PDF
          Fluttertoast.showToast(
            msg: 'Ouverture du PDF: ${facture.pdfPath}',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
        break;
      case 'print':
        await _printFacture(context, facture, viewModel);
        break;
      case 'export':
        await _exportFacture(context, facture);
        break;
      case 'payee':
        final success = await viewModel.marquerPayee(
          facture.id!,
          currentUser.id!,
        );
        if (success && context.mounted) {
          Fluttertoast.showToast(
            msg: 'Facture marquée comme payée',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
        break;
      case 'annuler':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Annuler la facture'),
            content: const Text('Voulez-vous vraiment annuler cette facture ?'),
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

          final success = await viewModel.annulerFacture(
            facture.id!,
            currentUser.id!,
            raison?.isEmpty == true ? null : raison,
          );

          if (success && context.mounted) {
            Fluttertoast.showToast(
              msg: 'Facture annulée avec succès',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
        }
        break;
    }
  }

  Future<void> _printFacture(
    BuildContext context,
    FactureModel facture,
    FactureViewModel viewModel,
  ) async {
    try {
      final pdfService = FacturePdfService();
      
      // Régénérer le PDF si nécessaire
      if (facture.pdfPath == null || !File(facture.pdfPath!).existsSync()) {
        Fluttertoast.showToast(
          msg: 'Génération du PDF en cours...',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        
        // Régénérer selon le type
        if (facture.isPourVente && viewModel.selectedVente != null) {
          await viewModel.generateFactureFromVente(
            adherentId: facture.adherentId,
            venteId: viewModel.selectedVente!.id!,
            createdBy: context.read<AuthViewModel>().currentUser?.id ?? 0,
          );
        } else if (facture.isPourRecette && viewModel.selectedRecette != null) {
          await viewModel.generateFactureFromRecette(
            adherentId: facture.adherentId,
            recetteId: viewModel.selectedRecette!.id!,
            createdBy: context.read<AuthViewModel>().currentUser?.id ?? 0,
          );
        }
      }

      // Imprimer
      if (facture.pdfPath != null && File(facture.pdfPath!).existsSync()) {
        final pdfBytes = await File(facture.pdfPath!).readAsBytes();
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Fluttertoast.showToast(
          msg: 'Erreur lors de l\'impression: ${e.toString()}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  Future<void> _exportFacture(BuildContext context, FactureModel facture) async {
    if (facture.pdfPath != null && File(facture.pdfPath!).existsSync()) {
      Fluttertoast.showToast(
        msg: 'PDF disponible: ${facture.pdfPath}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'PDF non disponible. Veuillez régénérer la facture.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}
