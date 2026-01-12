/// Écran de Gestion des Lots de Vente V2
/// 
/// Permet de créer et gérer des lots intelligents par campagne, qualité, catégorie

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/vente_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../data/models/lot_vente_model.dart';
import '../../../../config/routes/routes.dart';
import 'package:intl/intl.dart';

class LotsVenteScreen extends StatefulWidget {
  const LotsVenteScreen({super.key});

  @override
  State<LotsVenteScreen> createState() => _LotsVenteScreenState();
}

class _LotsVenteScreenState extends State<LotsVenteScreen> {
  String _filterStatut = 'tous';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadLotsVente();
      viewModel.loadCampagnes();
      viewModel.loadAdherents();
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
                  const Icon(Icons.inventory_2, color: AppTheme.stockColor, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Lots de Vente',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.stockColor,
                    ),
                  ),
                  const Spacer(),
                  // Filtre statut
                  DropdownButton<String>(
                    value: _filterStatut,
                    items: const [
                      DropdownMenuItem(value: 'tous', child: Text('Tous')),
                      DropdownMenuItem(value: 'preparation', child: Text('En préparation')),
                      DropdownMenuItem(value: 'valide', child: Text('Validés')),
                      DropdownMenuItem(value: 'vendu', child: Text('Vendus')),
                    ],
                    onChanged: (value) {
                      setState(() => _filterStatut = value!);
                      viewModel.loadLotsVente(statut: value == 'tous' ? null : value);
                    },
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.add),
                    tooltip: 'Créer un lot',
                    onSelected: (value) => _showCreateLotDialog(context, viewModel, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'campagne',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 20),
                            SizedBox(width: 8),
                            Text('Par Campagne'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'qualite',
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 20),
                            SizedBox(width: 8),
                            Text('Par Qualité'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'categorie',
                        child: Row(
                          children: [
                            Icon(Icons.category, size: 20),
                            SizedBox(width: 8),
                            Text('Par Catégorie'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Liste des lots
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLotsList(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLotsList(BuildContext context, VenteViewModel viewModel) {
    final lots = _filterStatut == 'tous'
        ? viewModel.lotsVente
        : viewModel.lotsVente.where((l) => l.statut == _filterStatut).toList();

    if (lots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun lot',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showCreateLotDialog(context, viewModel, 'campagne'),
              icon: const Icon(Icons.add),
              label: const Text('Créer un lot'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lots.length,
      itemBuilder: (context, index) {
        final lot = lots[index];
        return _buildLotCard(context, viewModel, lot);
      },
    );
  }

  Widget _buildLotCard(BuildContext context, VenteViewModel viewModel, LotVenteModel lot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showLotDetail(context, viewModel, lot),
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
                      color: _getStatutColor(lot.statut).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lot.statut.toUpperCase(),
                      style: TextStyle(
                        color: _getStatutColor(lot.statut),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    lot.codeLot,
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
                      '${lot.quantiteTotal.toStringAsFixed(2)} kg',
                      Icons.scale,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Prix unitaire',
                      '${NumberFormat('#,##0').format(lot.prixUnitairePropose)} FCFA/kg',
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Montant total',
                      '${NumberFormat('#,##0').format(lot.quantiteTotal * lot.prixUnitairePropose)} FCFA',
                      Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),
              if (lot.qualite != null || lot.categorieProducteur != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (lot.qualite != null)
                      Chip(
                        label: Text('Qualité: ${lot.qualite}'),
                        backgroundColor: AppTheme.infoColor.withOpacity(0.1),
                      ),
                    if (lot.categorieProducteur != null)
                      Chip(
                        label: Text('Catégorie: ${lot.categorieProducteur}'),
                        backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showLotDetail(context, viewModel, lot),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Détails'),
                  ),
                  if (lot.isEnPreparation) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _validerLot(context, viewModel, lot.id!),
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

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'preparation':
        return AppTheme.infoColor;
      case 'valide':
        return AppTheme.successColor;
      case 'vendu':
        return AppTheme.venteColor;
      case 'exclu':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  void _showCreateLotDialog(BuildContext context, VenteViewModel viewModel, String type) {
    final prixController = TextEditingController();
    int? selectedCampagneId;
    String? selectedQualite;
    String? selectedCategorie;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Créer un lot par ${type == 'campagne' ? 'Campagne' : type == 'qualite' ? 'Qualité' : 'Catégorie'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type == 'campagne')
                DropdownButtonFormField<int?>(
                  initialValue: selectedCampagneId,
                  decoration: const InputDecoration(
                    labelText: 'Campagne',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Sélectionner')),
                    ...viewModel.campagnes.map((c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.nom),
                    )),
                  ],
                  onChanged: (value) => selectedCampagneId = value,
                ),
              if (type == 'qualite') ...[
                DropdownButtonFormField<String?>(
                  initialValue: selectedQualite,
                  decoration: const InputDecoration(
                    labelText: 'Qualité',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'standard', child: Text('Standard')),
                    DropdownMenuItem(value: 'premium', child: Text('Premium')),
                    DropdownMenuItem(value: 'bio', child: Text('Bio')),
                  ],
                  onChanged: (value) => selectedQualite = value,
                ),
                if (selectedCampagneId == null)
                  DropdownButtonFormField<int?>(
                    initialValue: selectedCampagneId,
                    decoration: const InputDecoration(
                      labelText: 'Campagne (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Aucune')),
                      ...viewModel.campagnes.map((c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.nom),
                      )),
                    ],
                    onChanged: (value) => selectedCampagneId = value,
                  ),
              ],
              if (type == 'categorie') ...[
                DropdownButtonFormField<String?>(
                  initialValue: selectedCategorie,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie Producteur',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'producteur', child: Text('Producteur')),
                    DropdownMenuItem(value: 'adherent', child: Text('Adhérent')),
                    DropdownMenuItem(value: 'actionnaire', child: Text('Actionnaire')),
                  ],
                  onChanged: (value) => selectedCategorie = value,
                ),
                if (selectedCampagneId == null)
                  DropdownButtonFormField<int?>(
                    initialValue: selectedCampagneId,
                    decoration: const InputDecoration(
                      labelText: 'Campagne (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Aucune')),
                      ...viewModel.campagnes.map((c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.nom),
                      )),
                    ],
                    onChanged: (value) => selectedCampagneId = value,
                  ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: prixController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire proposé (FCFA/kg)',
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
              if (prixController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Prix requis'),
                    backgroundColor: AppTheme.errorColor,
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }

              final authViewModel = context.read<AuthViewModel>();
              final userId = authViewModel.currentUser?.id ?? 0;

              bool success = false;
              if (type == 'campagne' && selectedCampagneId != null) {
                success = await viewModel.createLotParCampagne(
                  campagneId: selectedCampagneId!,
                  prixUnitairePropose: double.parse(prixController.text),
                  createdBy: userId,
                );
              } else if (type == 'qualite' && selectedQualite != null) {
                success = await viewModel.createLotParQualite(
                  qualite: selectedQualite!,
                  campagneId: selectedCampagneId,
                  prixUnitairePropose: double.parse(prixController.text),
                  createdBy: userId,
                );
              } else if (type == 'categorie' && selectedCategorie != null) {
                success = await viewModel.createLotParCategorie(
                  categorieProducteur: selectedCategorie!,
                  campagneId: selectedCampagneId,
                  prixUnitairePropose: double.parse(prixController.text),
                  createdBy: userId,
                );
              }

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lot créé avec succès'),
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
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showLotDetail(BuildContext context, VenteViewModel viewModel, LotVenteModel lot) {
    // Charger les détails du lot
    viewModel.loadLotDetails(lot.id!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lot: ${lot.codeLot}'),
        content: Consumer<VenteViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Statut', lot.statut),
                  _buildDetailRow('Quantité totale', '${lot.quantiteTotal.toStringAsFixed(2)} kg'),
                  _buildDetailRow('Prix unitaire', '${NumberFormat('#,##0').format(lot.prixUnitairePropose)} FCFA/kg'),
                  _buildDetailRow('Montant total', '${NumberFormat('#,##0').format(lot.quantiteTotal * lot.prixUnitairePropose)} FCFA'),
                  if (lot.qualite != null) _buildDetailRow('Qualité', lot.qualite!),
                  if (lot.categorieProducteur != null) _buildDetailRow('Catégorie', lot.categorieProducteur!),
                  const Divider(),
                  const Text(
                    'Adhérents inclus:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (vm.lotDetails.isEmpty)
                    const Text('Aucun détail disponible')
                  else
                    ...vm.lotDetails.map((detail) => ListTile(
                      dense: true,
                      title: Text('Adhérent #${detail.adherentId}'),
                      trailing: Text('${detail.quantite.toStringAsFixed(2)} kg'),
                      leading: detail.isExclu
                          ? const Icon(Icons.cancel, color: AppTheme.errorColor)
                          : const Icon(Icons.check_circle, color: AppTheme.successColor),
                    )),
                ],
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

  Future<void> _validerLot(BuildContext context, VenteViewModel viewModel, int lotId) async {
    final authViewModel = context.read<AuthViewModel>();
    final userId = authViewModel.currentUser?.id ?? 0;

    // TODO: Implémenter la validation du lot
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Validation du lot à implémenter'),
        backgroundColor: AppTheme.infoColor,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

