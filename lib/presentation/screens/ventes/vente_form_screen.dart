import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/vente_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/stock_viewmodel.dart';
import '../../../data/models/adherent_model.dart';
import '../../../data/models/vente_detail_model.dart';
import '../../../config/routes/routes.dart';

class VenteFormScreen extends StatefulWidget {
  final String type; // 'individuelle' ou 'groupee'

  const VenteFormScreen({super.key, required this.type});

  @override
  State<VenteFormScreen> createState() => _VenteFormScreenState();
}

class _VenteFormScreenState extends State<VenteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteController = TextEditingController();
  final _prixUnitaireController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedAdherentId;
  int? _selectedClientId;
  DateTime? _dateVente;
  String? _modePaiement;
  double? _stockDisponible;

  // Pour ventes groupées
  final List<VenteDetailItem> _details = [];

  @override
  void initState() {
    super.initState();
    _dateVente = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadAdherents();
      viewModel.loadClients();
    });
  }

  @override
  void dispose() {
    _quantiteController.dispose();
    _prixUnitaireController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'individuelle'
              ? 'Nouvelle vente individuelle'
              : 'Nouvelle vente groupée',
        ),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Container pour limiter la largeur et centrer le formulaire
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.type == 'individuelle')
                        _buildIndividuelleForm(),
                      if (widget.type == 'groupee') _buildGroupeeForm(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividuelleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations de la vente'),
        const SizedBox(height: 12),
        _buildClientAcheteurField(),
        const SizedBox(height: 16),
        Consumer<VenteViewModel>(
          builder: (context, viewModel, child) {
            return DropdownButtonFormField<int>(
              initialValue: _selectedAdherentId,
              decoration: InputDecoration(
                labelText: 'Adhérent *',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: viewModel.adherents.map((adherent) {
                return DropdownMenuItem<int>(
                  value: adherent.id,
                  child: Text('${adherent.code} - ${adherent.fullName}'),
                );
              }).toList(),
              onChanged: (value) async {
                setState(() {
                  _selectedAdherentId = value;
                  _stockDisponible = null;
                });
                if (value != null) {
                  final stock = await viewModel.getStockDisponible(value);
                  setState(() => _stockDisponible = stock);
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner un adhérent';
                }
                return null;
              },
            );
          },
        ),
        if (_stockDisponible != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _stockDisponible! > 0
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _stockDisponible! > 0
                    ? Colors.green.shade200
                    : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _stockDisponible! > 0 ? Icons.check_circle : Icons.warning,
                  color: _stockDisponible! > 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Stock disponible: ${NumberFormat('#,##0.00').format(_stockDisponible)} kg',
                  style: TextStyle(
                    color: _stockDisponible! > 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _quantiteController,
          decoration: InputDecoration(
            labelText: 'Quantité (kg) *',
            prefixIcon: const Icon(Icons.scale),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La quantité est obligatoire';
            }
            final quantite = double.tryParse(value);
            if (quantite == null || quantite <= 0) {
              return 'La quantité doit être supérieure à 0';
            }
            if (_stockDisponible != null && quantite > _stockDisponible!) {
              return 'Stock insuffisant';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _prixUnitaireController,
          decoration: InputDecoration(
            labelText: 'Prix unitaire (FCFA/kg) *',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le prix unitaire est obligatoire';
            }
            final prix = double.tryParse(value);
            if (prix == null || prix <= 0) {
              return 'Le prix doit être supérieur à 0';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _modePaiement,
          decoration: InputDecoration(
            labelText: 'Mode de paiement',
            prefixIcon: const Icon(Icons.payment),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'especes', child: Text('Espèces')),
            DropdownMenuItem(
              value: 'mobile_money',
              child: Text('Mobile Money'),
            ),
            DropdownMenuItem(value: 'virement', child: Text('Virement')),
          ],
          onChanged: (value) {
            setState(() => _modePaiement = value);
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dateVente ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _dateVente = date);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date de vente *',
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _dateVente != null
                  ? DateFormat('dd/MM/yyyy').format(_dateVente!)
                  : 'Sélectionner une date',
              style: TextStyle(
                color: _dateVente != null
                    ? Colors.black87
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Observations',
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildGroupeeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations générales'),
        const SizedBox(height: 12),
        _buildClientAcheteurField(),
        const SizedBox(height: 16),
        TextFormField(
          controller: _prixUnitaireController,
          decoration: InputDecoration(
            labelText: 'Prix unitaire (FCFA/kg) *',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le prix unitaire est obligatoire';
            }
            final prix = double.tryParse(value);
            if (prix == null || prix <= 0) {
              return 'Le prix doit être supérieur à 0';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _modePaiement,
          decoration: InputDecoration(
            labelText: 'Mode de paiement',
            prefixIcon: const Icon(Icons.payment),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'especes', child: Text('Espèces')),
            DropdownMenuItem(
              value: 'mobile_money',
              child: Text('Mobile Money'),
            ),
            DropdownMenuItem(value: 'virement', child: Text('Virement')),
          ],
          onChanged: (value) {
            setState(() => _modePaiement = value);
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dateVente ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _dateVente = date);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date de vente *',
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _dateVente != null
                  ? DateFormat('dd/MM/yyyy').format(_dateVente!)
                  : 'Sélectionner une date',
              style: TextStyle(
                color: _dateVente != null
                    ? Colors.black87
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Observations',
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Détails des adhérents'),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _addDetail,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un adhérent'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown.shade700,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ..._details.asMap().entries.map((entry) {
          return _buildDetailItem(entry.key, entry.value);
        }),
        if (_details.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Aucun adhérent ajouté',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailItem(int index, VenteDetailItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Consumer<VenteViewModel>(
                    builder: (context, viewModel, child) {
                      return DropdownButtonFormField<int>(
                        initialValue: item.adherentId,
                        decoration: const InputDecoration(
                          labelText: 'Adhérent *',
                          isDense: true,
                        ),
                        items: viewModel.adherents.map((adherent) {
                          return DropdownMenuItem<int>(
                            value: adherent.id,
                            child: Text(
                              '${adherent.code} - ${adherent.fullName}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            item.adherentId = value;
                            item.stockDisponible = null;
                          });
                          if (value != null) {
                            viewModel.getStockDisponible(value).then((stock) {
                              setState(() => item.stockDisponible = stock);
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => _details.removeAt(index));
                  },
                ),
              ],
            ),
            if (item.stockDisponible != null) ...[
              const SizedBox(height: 8),
              Text(
                'Stock: ${NumberFormat('#,##0.00').format(item.stockDisponible)} kg',
                style: TextStyle(
                  fontSize: 12,
                  color: item.stockDisponible! > 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              controller: item.quantiteController,
              decoration: const InputDecoration(
                labelText: 'Quantité (kg) *',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final quantite = double.tryParse(value);
                if (quantite != null &&
                    _prixUnitaireController.text.isNotEmpty) {
                  final prix = double.tryParse(_prixUnitaireController.text);
                  if (prix != null) {
                    item.montant = quantite * prix;
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addDetail() {
    setState(() {
      _details.add(VenteDetailItem());
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.brown.shade700,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<VenteViewModel>(
      builder: (context, viewModel, child) {
        return ElevatedButton(
          onPressed: viewModel.isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: viewModel.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Créer la vente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un client acheteur'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_dateVente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date de vente'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final viewModel = context.read<VenteViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: utilisateur non connecté'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    bool success = false;

    final selectedClientId = _selectedClientId!;
    final selectedClient = viewModel.clients.where(
      (c) => c.id == selectedClientId,
    );
    if (selectedClient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Client acheteur introuvable: #$selectedClientId'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    final acheteur = selectedClient.first.raisonSociale;

    if (widget.type == 'individuelle') {
      if (_selectedAdherentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un adhérent'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      success = await viewModel.createVenteIndividuelle(
        adherentId: _selectedAdherentId!,
        quantite: double.parse(_quantiteController.text),
        prixUnitaire: double.parse(_prixUnitaireController.text),
        acheteur: acheteur,
        clientId: selectedClientId,
        modePaiement: _modePaiement,
        dateVente: _dateVente!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdBy: currentUser.id!,
      );
    } else {
      if (_details.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez ajouter au moins un adhérent'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final prixUnitaire = double.parse(_prixUnitaireController.text);
      final details = _details.map((item) {
        if (item.adherentId == null) {
          throw Exception('Adhérent manquant');
        }
        final quantite = double.tryParse(item.quantiteController.text) ?? 0.0;
        return VenteDetailModel(
          venteId: 0, // Temporaire, sera mis à jour par le service
          adherentId: item.adherentId!,
          quantite: quantite,
          prixUnitaire: prixUnitaire,
          montant: quantite * prixUnitaire,
        );
      }).toList();

      success = await viewModel.createVenteGroupee(
        details: details,
        prixUnitaire: prixUnitaire,
        acheteur: acheteur,
        clientId: selectedClientId,
        modePaiement: _modePaiement,
        dateVente: _dateVente!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdBy: currentUser.id!,
      );
    }

    if (success && context.mounted) {
      // Recharger les stocks après la vente
      try {
        final stockViewModel = context.read<StockViewModel>();
        await stockViewModel.loadStocks();
      } catch (e) {
        print('Erreur lors du rechargement des stocks: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vente créée avec succès'),
          duration: const Duration(seconds: 3),
          action: viewModel.lastCreatedFactureId != null
              ? SnackBarAction(
                  label: 'Voir le reçu',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(context, rootNavigator: false).pushNamed(
                      AppRoutes.factureDetail,
                      arguments: viewModel.lastCreatedFactureId,
                    );
                  },
                )
              : null,
        ),
      );

      // Si une facture a été créée, naviguer vers le reçu
      if (viewModel.lastCreatedFactureId != null) {
        final navigator = Navigator.of(context, rootNavigator: false);
        navigator.pushNamed(
          AppRoutes.factureDetail,
          arguments: viewModel.lastCreatedFactureId,
        );
      } else {
        Navigator.pop(context);
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Une erreur est survenue'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildClientAcheteurField() {
    return Consumer<VenteViewModel>(
      builder: (context, viewModel, child) {
        final clients = viewModel.clients;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedClientId,
              decoration: InputDecoration(
                labelText: 'Acheteur (Client) *',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: clients.isEmpty
                    ? 'Aucun client disponible (module Clients)'
                    : 'Sélectionnez un client acheteur',
              ),
              items: clients
                  .where((c) => c.id != null)
                  .map(
                    (client) => DropdownMenuItem<int>(
                      value: client.id!,
                      child: Text(
                        '${client.codeClient} - ${client.raisonSociale}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: clients.isEmpty
                  ? null
                  : (value) {
                      setState(() => _selectedClientId = value);
                    },
              validator: (value) {
                if (value == null) return 'Le client acheteur est obligatoire';
                return null;
              },
            ),
          ],
        );
      },
    );
  }
}

class VenteDetailItem {
  int? adherentId;
  final TextEditingController quantiteController = TextEditingController();
  double? stockDisponible;
  double montant = 0.0;

  VenteDetailItem();
}
