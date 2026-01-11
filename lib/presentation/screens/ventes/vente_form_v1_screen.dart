import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/vente_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/adherent_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/parametres_cooperative_model.dart';
import '../../../config/routes/routes.dart';

/// Écran de création de vente V1 avec toutes les fonctionnalités requises
class VenteFormV1Screen extends StatefulWidget {
  const VenteFormV1Screen({super.key});

  @override
  State<VenteFormV1Screen> createState() => _VenteFormV1ScreenState();
}

class _VenteFormV1ScreenState extends State<VenteFormV1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteController = TextEditingController();
  final _prixUnitaireController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedClientId;
  int? _selectedCampagneId;
  int? _selectedAdherentId;
  DateTime? _dateVente;
  String? _modePaiement;
  double? _stockDisponible;
  bool _overridePrixValidation = false;

  @override
  void initState() {
    super.initState();
    _dateVente = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadAdherents();
      viewModel.loadClients();
      viewModel.loadCampagnes();
      viewModel.loadParametres();
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
        title: const Text('Nouvelle vente V1'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle('Informations obligatoires'),
                      const SizedBox(height: 12),
                      _buildClientField(),
                      const SizedBox(height: 16),
                      _buildCampagneField(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Informations de la vente'),
                      const SizedBox(height: 12),
                      _buildAdherentField(),
                      const SizedBox(height: 16),
                      _buildStockInfo(),
                      const SizedBox(height: 16),
                      _buildQuantiteField(),
                      const SizedBox(height: 16),
                      _buildPrixUnitaireField(),
                      const SizedBox(height: 16),
                      _buildApercuCalculs(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Informations complémentaires'),
                      const SizedBox(height: 12),
                      _buildModePaiementField(),
                      const SizedBox(height: 16),
                      _buildDateVenteField(),
                      const SizedBox(height: 16),
                      _buildNotesField(),
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

  Widget _buildClientField() {
    return Consumer<VenteViewModel>(
      builder: (context, viewModel, child) {
        return DropdownButtonFormField<int>(
          value: _selectedClientId,
          decoration: InputDecoration(
            labelText: 'Client (Acheteur) *',
            prefixIcon: const Icon(Icons.business),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            helperText: 'Sélectionnez le client acheteur',
          ),
          items: viewModel.clients.map((client) {
            return DropdownMenuItem<int>(
              value: client.id,
              child: Text('${client.codeClient} - ${client.raisonSociale}'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedClientId = value);
          },
          validator: (value) {
            if (value == null) {
              return 'Le client est obligatoire';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildCampagneField() {
    return Consumer<VenteViewModel>(
      builder: (context, viewModel, child) {
        // Pré-sélectionner la campagne active si disponible
        if (_selectedCampagneId == null && viewModel.campagneActive != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _selectedCampagneId = viewModel.campagneActive!.id);
          });
        }

        return DropdownButtonFormField<int>(
          value: _selectedCampagneId,
          decoration: InputDecoration(
            labelText: 'Campagne agricole *',
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            helperText: viewModel.campagneActive != null
                ? 'Campagne active: ${viewModel.campagneActive!.nom}'
                : 'Sélectionnez une campagne',
          ),
          items: viewModel.campagnes.map((campagne) {
            return DropdownMenuItem<int>(
              value: campagne.id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(campagne.nom),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(campagne.dateDebut)} - ${DateFormat('dd/MM/yyyy').format(campagne.dateFin)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedCampagneId = value);
          },
          validator: (value) {
            if (value == null) {
              return 'La campagne est obligatoire';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildAdherentField() {
    return Consumer<VenteViewModel>(
      builder: (context, viewModel, child) {
        return DropdownButtonFormField<int>(
          value: _selectedAdherentId,
          decoration: InputDecoration(
            labelText: 'Adhérent (Vendeur) *',
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
    );
  }

  Widget _buildStockInfo() {
    if (_stockDisponible == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _stockDisponible! > 0 ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _stockDisponible! > 0 ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _stockDisponible! > 0 ? Icons.check_circle : Icons.warning,
            color: _stockDisponible! > 0 ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            'Stock disponible: ${NumberFormat('#,##0.00').format(_stockDisponible)} kg',
            style: TextStyle(
              color: _stockDisponible! > 0 ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantiteField() {
    return TextFormField(
      controller: _quantiteController,
      decoration: InputDecoration(
        labelText: 'Quantité (kg) *',
        prefixIcon: const Icon(Icons.scale),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        _updateCalculs();
      },
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
    );
  }

  Widget _buildPrixUnitaireField() {
    return Consumer<VenteViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _prixUnitaireController,
              decoration: InputDecoration(
                labelText: 'Prix unitaire (FCFA/kg) *',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _updateCalculs();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le prix unitaire est obligatoire';
                }
                final prix = double.tryParse(value);
                if (prix == null || prix <= 0) {
                  return 'Le prix doit être supérieur à 0';
                }
                if (viewModel.prixHorsSeuil && !_overridePrixValidation) {
                  return viewModel.prixValidationMessage ?? 'Prix hors seuil';
                }
                return null;
              },
            ),
            if (viewModel.prixHorsSeuil) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        viewModel.prixValidationMessage ?? 'Prix hors des seuils configurés',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _overridePrixValidation,
                onChanged: (value) {
                  setState(() => _overridePrixValidation = value ?? false);
                },
                title: const Text('Override admin (contourner la validation)'),
                dense: true,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildApercuCalculs() {
    return Consumer<VenteViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.montantBrutCalcule == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aperçu des calculs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 12),
              _buildCalculLine(
                'Montant brut',
                viewModel.montantBrutCalcule!,
                Colors.blue.shade900,
              ),
              const SizedBox(height: 8),
              _buildCalculLine(
                'Commission (${((viewModel.parametres?.commissionRate ?? 0.05) * 100).toStringAsFixed(1)}%)',
                viewModel.montantCommissionCalcule!,
                Colors.orange.shade700,
              ),
              const Divider(),
              const SizedBox(height: 8),
              _buildCalculLine(
                'Montant net à répartir',
                viewModel.montantNetCalcule!,
                Colors.green.shade700,
                isBold: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalculLine(String label, double montant, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          '${NumberFormat('#,##0.00').format(montant)} FCFA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildModePaiementField() {
    return DropdownButtonFormField<String>(
      value: _modePaiement,
      decoration: InputDecoration(
        labelText: 'Mode de paiement',
        prefixIcon: const Icon(Icons.payment),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'especes', child: Text('Espèces')),
        DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money')),
        DropdownMenuItem(value: 'virement', child: Text('Virement')),
      ],
      onChanged: (value) {
        setState(() => _modePaiement = value);
      },
    );
  }

  Widget _buildDateVenteField() {
    return InkWell(
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
            color: _dateVente != null ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Observations',
        prefixIcon: const Icon(Icons.note),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 3,
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
                  'Créer la vente V1',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        );
      },
    );
  }

  void _updateCalculs() {
    final quantite = double.tryParse(_quantiteController.text);
    final prixUnitaire = double.tryParse(_prixUnitaireController.text);

    if (quantite != null && prixUnitaire != null && quantite > 0 && prixUnitaire > 0) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.calculateMontants(
        quantite: quantite,
        prixUnitaire: prixUnitaire,
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
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

    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un client'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_selectedCampagneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une campagne'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_selectedAdherentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un adhérent'),
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

    final success = await viewModel.createVenteV1(
      clientId: _selectedClientId!,
      campagneId: _selectedCampagneId!,
      adherentId: _selectedAdherentId!,
      quantiteTotal: double.parse(_quantiteController.text),
      prixUnitaire: double.parse(_prixUnitaireController.text),
      modePaiement: _modePaiement,
      dateVente: _dateVente!,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdBy: currentUser.id!,
      overridePrixValidation: _overridePrixValidation,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vente V1 créée avec succès'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
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
}

