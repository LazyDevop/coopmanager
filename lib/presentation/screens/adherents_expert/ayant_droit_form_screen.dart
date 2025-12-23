import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/adherent/ayant_droit_service.dart';
import '../../../data/models/adherent_expert/ayant_droit_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class AyantDroitFormScreen extends StatefulWidget {
  final int adherentId;
  final AyantDroitModel? ayantDroit; // Si fourni, c'est une modification

  const AyantDroitFormScreen({
    super.key,
    required this.adherentId,
    this.ayantDroit,
  });

  @override
  State<AyantDroitFormScreen> createState() => _AyantDroitFormScreenState();
}

class _AyantDroitFormScreenState extends State<AyantDroitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCompletController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _numeroPieceController = TextEditingController();
  final _notesController = TextEditingController();

  final AyantDroitService _service = AyantDroitService();

  String? _lienFamilial;
  String? _typePiece;
  DateTime? _dateNaissance;
  bool _beneficiaireSocial = false;
  int _prioriteSuccession = 999;
  bool _isLoading = false;

  final List<String> _liensFamiliaux = [
    'enfant',
    'conjoint',
    'parent',
    'frere_soeur',
    'autre',
  ];

  final List<String> _typesPiece = [
    'CNI',
    'Passeport',
    'Acte_naissance',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ayantDroit != null) {
      _loadAyantDroitData();
    }
  }

  void _loadAyantDroitData() {
    final ayantDroit = widget.ayantDroit!;
    _nomCompletController.text = ayantDroit.nomComplet;
    _lienFamilial = ayantDroit.lienFamilial;
    _dateNaissance = ayantDroit.dateNaissance;
    _contactController.text = ayantDroit.contact ?? '';
    _emailController.text = ayantDroit.email ?? '';
    _beneficiaireSocial = ayantDroit.beneficiaireSocial;
    _prioriteSuccession = ayantDroit.prioriteSuccession;
    _numeroPieceController.text = ayantDroit.numeroPiece ?? '';
    _typePiece = ayantDroit.typePiece;
    _notesController.text = ayantDroit.notes ?? '';
  }

  @override
  void dispose() {
    _nomCompletController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _numeroPieceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lienFamilial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner le lien familial')),
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

      if (widget.ayantDroit == null) {
        // Création
        await _service.createAyantDroit(
          adherentId: widget.adherentId,
          nomComplet: _nomCompletController.text.trim(),
          lienFamilial: _lienFamilial!,
          dateNaissance: _dateNaissance,
          contact: _contactController.text.trim().isEmpty 
              ? null 
              : _contactController.text.trim(),
          email: _emailController.text.trim().isEmpty 
              ? null 
              : _emailController.text.trim(),
          beneficiaireSocial: _beneficiaireSocial,
          prioriteSuccession: _prioriteSuccession,
          numeroPiece: _numeroPieceController.text.trim().isEmpty 
              ? null 
              : _numeroPieceController.text.trim(),
          typePiece: _typePiece,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
          createdBy: currentUser.id!,
        );
      } else {
        // Modification
        await _service.updateAyantDroit(
          id: widget.ayantDroit!.id!,
          nomComplet: _nomCompletController.text.trim(),
          lienFamilial: _lienFamilial,
          dateNaissance: _dateNaissance,
          contact: _contactController.text.trim().isEmpty 
              ? null 
              : _contactController.text.trim(),
          email: _emailController.text.trim().isEmpty 
              ? null 
              : _emailController.text.trim(),
          beneficiaireSocial: _beneficiaireSocial,
          prioriteSuccession: _prioriteSuccession,
          numeroPiece: _numeroPieceController.text.trim().isEmpty 
              ? null 
              : _numeroPieceController.text.trim(),
          typePiece: _typePiece,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
          updatedBy: currentUser.id!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.ayantDroit == null 
                ? 'Ayant droit ajouté avec succès' 
                : 'Ayant droit modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner true pour indiquer un succès
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

  String _getLienFamilialLabel(String value) {
    switch (value) {
      case 'enfant':
        return 'Enfant';
      case 'conjoint':
        return 'Conjoint(e)';
      case 'parent':
        return 'Parent';
      case 'frere_soeur':
        return 'Frère/Sœur';
      case 'autre':
        return 'Autre';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.ayantDroit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier l\'ayant droit' : 'Ajouter un ayant droit'),
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
              // Nom complet
              TextFormField(
                controller: _nomCompletController,
                decoration: InputDecoration(
                  labelText: 'Nom complet *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom complet est requis';
                  }
                  if (value.trim().length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Lien familial
              DropdownButtonFormField<String>(
                value: _lienFamilial,
                decoration: InputDecoration(
                  labelText: 'Lien familial *',
                  prefixIcon: const Icon(Icons.family_restroom),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _liensFamiliaux.map((lien) {
                  return DropdownMenuItem(
                    value: lien,
                    child: Text(_getLienFamilialLabel(lien)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _lienFamilial = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner le lien familial';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date de naissance
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateNaissance ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _dateNaissance = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de naissance',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _dateNaissance != null
                        ? DateFormat('dd/MM/yyyy').format(_dateNaissance!)
                        : 'Sélectionner une date',
                    style: TextStyle(
                      color: _dateNaissance != null 
                          ? Colors.black87 
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contact
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type de pièce
              DropdownButtonFormField<String>(
                value: _typePiece,
                decoration: InputDecoration(
                  labelText: 'Type de pièce',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _typesPiece.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _typePiece = value);
                },
              ),
              const SizedBox(height: 16),

              // Numéro de pièce
              TextFormField(
                controller: _numeroPieceController,
                decoration: InputDecoration(
                  labelText: 'Numéro de pièce',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Priorité de succession
              TextFormField(
                initialValue: _prioriteSuccession.toString(),
                decoration: InputDecoration(
                  labelText: 'Priorité de succession',
                  prefixIcon: const Icon(Icons.sort),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: '1 = première priorité, 999 = dernière',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final priority = int.tryParse(value);
                  if (priority != null && priority >= 1) {
                    _prioriteSuccession = priority;
                  }
                },
              ),
              const SizedBox(height: 16),

              // Bénéficiaire social
              CheckboxListTile(
                title: const Text('Bénéficiaire d\'aides sociales'),
                value: _beneficiaireSocial,
                onChanged: (value) {
                  setState(() => _beneficiaireSocial = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
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

