import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/parametres_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/parametres_cooperative_model.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CampagneFormScreen extends StatefulWidget {
  final CampagneModel? campagne;

  const CampagneFormScreen({super.key, this.campagne});

  @override
  State<CampagneFormScreen> createState() => _CampagneFormScreenState();
}

class _CampagneFormScreenState extends State<CampagneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 365));
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.campagne != null) {
      _nomController.text = widget.campagne!.nom;
      _descriptionController.text = widget.campagne!.description ?? '';
      _dateDebut = widget.campagne!.dateDebut;
      _dateFin = widget.campagne!.dateFin;
      _isActive = widget.campagne!.isActive;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateDebut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateDebut,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateDebut = picked;
        if (_dateFin.isBefore(_dateDebut)) {
          _dateFin = _dateDebut.add(const Duration(days: 365));
        }
      });
    }
  }

  Future<void> _selectDateFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFin,
      firstDate: _dateDebut,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateFin = picked;
      });
    }
  }

  Future<void> _saveCampagne() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateFin.isBefore(_dateDebut)) {
      Fluttertoast.showToast(
        msg: 'La date de fin doit être après la date de début',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final viewModel = context.read<ParametresViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) return;

    bool success;
    if (widget.campagne != null) {
      success = await viewModel.updateCampagne(
        id: widget.campagne!.id!,
        nom: _nomController.text.trim(),
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isActive: _isActive,
        updatedBy: currentUser.id!,
      );
    } else {
      success = await viewModel.createCampagne(
        nom: _nomController.text.trim(),
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdBy: currentUser.id!,
      );
    }

    if (success && mounted) {
      Fluttertoast.showToast(
        msg: widget.campagne != null
            ? 'Campagne mise à jour avec succès'
            : 'Campagne créée avec succès',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.pop(context);
    } else if (mounted) {
      Fluttertoast.showToast(
        msg: viewModel.errorMessage ?? 'Erreur lors de la sauvegarde',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ParametresViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campagne != null ? 'Modifier la campagne' : 'Nouvelle campagne'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom de la campagne
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Nom de la campagne *',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le nom de la campagne';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date de début
              InkWell(
                onTap: _selectDateDebut,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de début *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_dateDebut),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date de fin
              InkWell(
                onTap: _selectDateFin,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de fin *',
                    prefixIcon: const Icon(Icons.event),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_dateFin),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Statut actif (seulement pour modification)
              if (widget.campagne != null)
                SwitchListTile(
                  title: const Text('Campagne active'),
                  subtitle: const Text('Une campagne active peut être utilisée pour les opérations'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),

              const SizedBox(height: 24),

              // Bouton de sauvegarde
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading ? null : _saveCampagne,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700,
                    foregroundColor: Colors.white,
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
                      : Text(
                          widget.campagne != null ? 'Mettre à jour' : 'Créer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

