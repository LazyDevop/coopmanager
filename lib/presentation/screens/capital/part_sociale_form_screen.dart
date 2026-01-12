import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/adherent/capital_social_service.dart';
import '../../../services/capital/capital_service.dart';
import '../../../data/models/adherent_expert/capital_social_model.dart';
import '../../../data/models/adherent_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/adherent_viewmodel.dart';

class PartSocialeFormScreen extends StatefulWidget {
  const PartSocialeFormScreen({super.key});

  @override
  State<PartSocialeFormScreen> createState() => _PartSocialeFormScreenState();
}

class _PartSocialeFormScreenState extends State<PartSocialeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombrePartsController = TextEditingController();
  final _valeurPartController = TextEditingController();
  final _notesController = TextEditingController();

  final CapitalSocialService _capitalSocialService = CapitalSocialService();
  final CapitalService _capitalService = CapitalService();

  AdherentModel? _selectedAdherent;
  DateTime? _dateSouscription;
  bool _isLoading = false;
  bool _isLoadingAdherents = false;
  List<AdherentModel> _adherents = [];
  double? _valeurPartActuelle;

  @override
  void initState() {
    super.initState();
    _dateSouscription = DateTime.now();
    _loadAdherents();
    _loadValeurPartActuelle();
  }

  Future<void> _loadAdherents() async {
    setState(() => _isLoadingAdherents = true);
    try {
      final viewModel = context.read<AdherentViewModel>();
      await viewModel.loadAdherents();
      if (mounted) {
        setState(() {
          _adherents = viewModel.adherents;
          _isLoadingAdherents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAdherents = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des adhérents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadValeurPartActuelle() async {
    try {
      final valeur = await _capitalService.getValeurPartActuelle();
      if (mounted) {
        setState(() {
          _valeurPartActuelle = valeur;
          _valeurPartController.text = valeur.toStringAsFixed(0);
        });
      }
    } catch (e) {
      // Utiliser une valeur par défaut
      if (mounted) {
        setState(() {
          _valeurPartActuelle = 5000.0;
          _valeurPartController.text = '5000';
        });
      }
    }
  }

  @override
  void dispose() {
    _nombrePartsController.dispose();
    _valeurPartController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAdherent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un adhérent'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_dateSouscription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner la date de souscription'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authViewModel = context.read<AuthViewModel>();
      final currentUser = authViewModel.currentUser;

      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final nombreParts = int.tryParse(_nombrePartsController.text.trim());
      if (nombreParts == null || nombreParts <= 0) {
        throw Exception('Le nombre de parts doit être supérieur à 0');
      }

      final valeurPart = double.tryParse(_valeurPartController.text.trim());
      if (valeurPart == null || valeurPart <= 0) {
        throw Exception('La valeur de la part doit être supérieure à 0');
      }

      await _capitalSocialService.createSouscription(
        adherentId: _selectedAdherent!.id!,
        nombrePartsSouscrites: nombreParts,
        valeurPart: valeurPart,
        dateSouscription: _dateSouscription!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdBy: currentUser.id!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parts ajoutées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle acquisition de parts'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sélection de l'adhérent
              DropdownButtonFormField<AdherentModel>(
                initialValue: _selectedAdherent,
                decoration: InputDecoration(
                  labelText: 'Adhérent *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Sélectionner l\'adhérent qui acquiert les parts',
                ),
                items: _adherents.map((adherent) {
                  return DropdownMenuItem<AdherentModel>(
                    value: adherent,
                    child: Text('${adherent.code} - ${adherent.prenom} ${adherent.nom}'),
                  );
                }).toList(),
                onChanged: _isLoadingAdherents
                    ? null
                    : (value) {
                        setState(() => _selectedAdherent = value);
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner un adhérent';
                  }
                  return null;
                },
              ),
              if (_isLoadingAdherents)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 16),

              // Nombre de parts
              TextFormField(
                controller: _nombrePartsController,
                decoration: InputDecoration(
                  labelText: 'Nombre de parts *',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Nombre de parts à acquérir',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nombre de parts est requis';
                  }
                  final nombreParts = int.tryParse(value.trim());
                  if (nombreParts == null || nombreParts <= 0) {
                    return 'Le nombre de parts doit être supérieur à 0';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}), // Pour mettre à jour l'aperçu
              ),
              const SizedBox(height: 16),

              // Valeur d'une part
              TextFormField(
                controller: _valeurPartController,
                decoration: InputDecoration(
                  labelText: 'Valeur d\'une part (FCFA) *',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: _valeurPartActuelle != null
                      ? 'Valeur actuelle: ${numberFormat.format(_valeurPartActuelle)} FCFA'
                      : 'Montant en FCFA pour une part',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La valeur de la part est requise';
                  }
                  final valeurPart = double.tryParse(value.trim());
                  if (valeurPart == null || valeurPart <= 0) {
                    return 'La valeur de la part doit être supérieure à 0';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}), // Pour mettre à jour l'aperçu
              ),
              const SizedBox(height: 16),

              // Date de souscription
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateSouscription ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _dateSouscription = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de souscription *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _dateSouscription != null
                        ? dateFormat.format(_dateSouscription!)
                        : 'Sélectionner une date',
                    style: TextStyle(
                      color: _dateSouscription != null
                          ? Colors.black87
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Aperçu du capital total
              if (_nombrePartsController.text.isNotEmpty &&
                  _valeurPartController.text.isNotEmpty)
                Card(
                  color: Colors.brown.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aperçu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Capital total :'),
                            Text(
                              '${numberFormat.format((int.tryParse(_nombrePartsController.text) ?? 0) * (double.tryParse(_valeurPartController.text) ?? 0))} FCFA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Informations complémentaires (optionnel)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Bouton de soumission
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Ajouter les parts'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

