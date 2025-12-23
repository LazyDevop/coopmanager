import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/adherent/capital_social_service.dart';
import '../../../data/models/adherent_expert/capital_social_model.dart';
import '../../viewmodels/auth_viewmodel.dart';

class CapitalSocialFormScreen extends StatefulWidget {
  final int adherentId;
  final CapitalSocialModel? souscription; // Si fourni, c'est une modification

  const CapitalSocialFormScreen({
    super.key,
    required this.adherentId,
    this.souscription,
  });

  @override
  State<CapitalSocialFormScreen> createState() => _CapitalSocialFormScreenState();
}

class _CapitalSocialFormScreenState extends State<CapitalSocialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombrePartsController = TextEditingController();
  final _valeurPartController = TextEditingController();
  final _notesController = TextEditingController();

  final CapitalSocialService _service = CapitalSocialService();

  DateTime? _dateSouscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.souscription != null) {
      _loadSouscriptionData();
    } else {
      _dateSouscription = DateTime.now();
    }
  }

  void _loadSouscriptionData() {
    final souscription = widget.souscription!;
    _nombrePartsController.text = souscription.nombrePartsSouscrites.toString();
    _valeurPartController.text = souscription.valeurPart.toString();
    _dateSouscription = souscription.dateSouscription;
    _notesController.text = souscription.notes ?? '';
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

    if (_dateSouscription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner la date de souscription')),
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

      if (widget.souscription == null) {
        // Création
        await _service.createSouscription(
          adherentId: widget.adherentId,
          nombrePartsSouscrites: nombreParts,
          valeurPart: valeurPart,
          dateSouscription: _dateSouscription!,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
          createdBy: currentUser.id!,
        );
      } else {
        // Modification - ne pas modifier les parts libérées via ce formulaire
        // Utiliser le dialog de libération pour libérer des parts
        await _service.updateSouscription(
          id: widget.souscription!.id!,
          nombrePartsSouscrites: nombreParts,
          valeurPart: valeurPart,
          dateSouscription: _dateSouscription,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
          updatedBy: currentUser.id!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.souscription == null 
                ? 'Souscription ajoutée avec succès' 
                : 'Souscription modifiée avec succès'),
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
    final isEdit = widget.souscription != null;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier la souscription' : 'Ajouter une souscription'),
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
              // Nombre de parts
              TextFormField(
                controller: _nombrePartsController,
                decoration: InputDecoration(
                  labelText: 'Nombre de parts *',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Nombre de parts souscrites',
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
                  helperText: 'Montant en FCFA pour une part',
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Capital total :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${NumberFormat('#,##0').format((int.tryParse(_nombrePartsController.text) ?? 0) * (double.tryParse(_valeurPartController.text) ?? 0))} FCFA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade700,
                            fontSize: 16,
                          ),
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
                    : Text(isEdit ? 'Modifier' : 'Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

