import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/social/social_service.dart';
import '../../../data/models/social/social_aide_type_model.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Écran de formulaire pour créer/modifier un type d'aide sociale
class SocialAideTypeFormScreen extends StatefulWidget {
  final SocialAideTypeModel? aideType;

  const SocialAideTypeFormScreen({
    super.key,
    this.aideType,
  });

  @override
  State<SocialAideTypeFormScreen> createState() => _SocialAideTypeFormScreenState();
}

class _SocialAideTypeFormScreenState extends State<SocialAideTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SocialService _socialService = SocialService();
  
  late TextEditingController _codeController;
  late TextEditingController _libelleController;
  late TextEditingController _descriptionController;
  late TextEditingController _plafondController;
  late TextEditingController _dureeController;
  
  String _categorie = 'SOCIALE';
  bool _estRemboursable = false;
  String? _modeRemboursement;
  bool _activation = true;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final type = widget.aideType;
    _codeController = TextEditingController(text: type?.code ?? '');
    _libelleController = TextEditingController(text: type?.libelle ?? '');
    _descriptionController = TextEditingController(text: type?.description ?? '');
    _plafondController = TextEditingController(
      text: type?.plafondMontant?.toStringAsFixed(0) ?? '',
    );
    _dureeController = TextEditingController(
      text: type?.dureeMaxMois?.toString() ?? '',
    );
    
    if (type != null) {
      _categorie = type.categorie;
      _estRemboursable = type.estRemboursable;
      _modeRemboursement = type.modeRemboursement;
      _activation = type.activation;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _libelleController.dispose();
    _descriptionController.dispose();
    _plafondController.dispose();
    _dureeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non connecté')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final plafond = _plafondController.text.isNotEmpty
          ? double.tryParse(_plafondController.text)
          : null;
      final duree = _dureeController.text.isNotEmpty
          ? int.tryParse(_dureeController.text)
          : null;

      SocialAideTypeModel result;

      if (widget.aideType == null) {
        // Création
        result = await _socialService.createAideType(
          code: _codeController.text.trim().toUpperCase(),
          libelle: _libelleController.text.trim(),
          categorie: _categorie,
          estRemboursable: _estRemboursable,
          plafondMontant: plafond,
          dureeMaxMois: duree,
          modeRemboursement: _estRemboursable ? _modeRemboursement : null,
          activation: _activation,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          createdBy: currentUser.id!,
        );
      } else {
        // Modification
        result = await _socialService.updateAideType(
          id: widget.aideType!.id!,
          code: _codeController.text.trim().toUpperCase(),
          libelle: _libelleController.text.trim(),
          categorie: _categorie,
          estRemboursable: _estRemboursable,
          plafondMontant: plafond,
          dureeMaxMois: duree,
          modeRemboursement: _estRemboursable ? _modeRemboursement : null,
          activation: _activation,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          updatedBy: currentUser.id!,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.aideType == null
              ? 'Nouveau type d\'aide'
              : 'Modifier le type d\'aide',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Code
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code *',
                  hintText: 'Ex: AIDE_SANTE',
                  helperText: 'Code unique en majuscules',
                ),
                textCapitalization: TextCapitalization.characters,
                enabled: widget.aideType == null, // Non modifiable après création
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le code est obligatoire';
                  }
                  if (!RegExp(r'^[A-Z0-9_]+$').hasMatch(value.trim().toUpperCase())) {
                    return 'Code invalide (lettres majuscules, chiffres et _ uniquement)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Libellé
              TextFormField(
                controller: _libelleController,
                decoration: const InputDecoration(
                  labelText: 'Libellé *',
                  hintText: 'Ex: Aide médicale',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le libellé est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Catégorie
              DropdownButtonFormField<String>(
                initialValue: _categorie,
                decoration: const InputDecoration(
                  labelText: 'Catégorie *',
                ),
                items: const [
                  DropdownMenuItem(value: 'FINANCIERE', child: Text('Financière')),
                  DropdownMenuItem(value: 'MATERIELLE', child: Text('Matérielle')),
                  DropdownMenuItem(value: 'SOCIALE', child: Text('Sociale')),
                  DropdownMenuItem(value: 'TECHNIQUE', child: Text('Technique')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _categorie = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Remboursable
              SwitchListTile(
                title: const Text('Aide remboursable'),
                subtitle: const Text('Prêt/avance plutôt qu\'un don'),
                value: _estRemboursable,
                onChanged: (value) {
                  setState(() {
                    _estRemboursable = value;
                    if (!value) {
                      _modeRemboursement = null;
                    }
                  });
                },
              ),

              // Mode de remboursement (si remboursable)
              if (_estRemboursable) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _modeRemboursement,
                  decoration: const InputDecoration(
                    labelText: 'Mode de remboursement',
                    helperText: 'Comment l\'aide sera remboursée',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'RETENUE_RECETTE',
                      child: Text('Retenue automatique sur recettes'),
                    ),
                    DropdownMenuItem(
                      value: 'MANUEL',
                      child: Text('Remboursement manuel'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _modeRemboursement = value);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Plafond montant
              TextFormField(
                controller: _plafondController,
                decoration: const InputDecoration(
                  labelText: 'Plafond montant (FCFA)',
                  hintText: 'Ex: 50000',
                  helperText: 'Montant maximum autorisé (optionnel)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final montant = double.tryParse(value);
                    if (montant == null || montant <= 0) {
                      return 'Montant invalide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Durée max (mois)
              TextFormField(
                controller: _dureeController,
                decoration: const InputDecoration(
                  labelText: 'Durée maximale (mois)',
                  hintText: 'Ex: 12',
                  helperText: 'Durée maximale pour remboursement (optionnel)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final duree = int.tryParse(value);
                    if (duree == null || duree <= 0) {
                      return 'Durée invalide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Description détaillée du type d\'aide',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Activation
              SwitchListTile(
                title: const Text('Activer ce type d\'aide'),
                subtitle: const Text('Les types inactifs ne peuvent pas être utilisés'),
                value: _activation,
                onChanged: (value) {
                  setState(() => _activation = value);
                },
              ),
              const SizedBox(height: 32),

              // Bouton sauvegarder
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sauvegarder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

