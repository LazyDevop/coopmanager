import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/adherent/credit_social_service.dart';
import '../../../data/models/adherent_expert/credit_social_model.dart';
import '../../viewmodels/auth_viewmodel.dart';

class CreditSocialFormScreen extends StatefulWidget {
  final int adherentId;
  final CreditSocialModel? credit; // Si fourni, c'est une modification

  const CreditSocialFormScreen({
    super.key,
    required this.adherentId,
    this.credit,
  });

  @override
  State<CreditSocialFormScreen> createState() => _CreditSocialFormScreenState();
}

class _CreditSocialFormScreenState extends State<CreditSocialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _quantiteProduitController = TextEditingController();
  final _typeProduitController = TextEditingController();
  final _motifController = TextEditingController();
  final _observationController = TextEditingController();

  final CreditSocialService _service = CreditSocialService();

  String? _typeCredit;
  String _typeAide = 'credit';
  DateTime? _dateOctroi;
  DateTime? _echeanceRemboursement;
  bool _isLoading = false;

  final List<String> _typesCredit = [
    'credit_produit',
    'credit_argent',
  ];

  final List<String> _typesAide = [
    'credit',
    'don',
    'soutien',
    'aide_sante',
    'aide_education',
    'autre',
  ];

  final List<String> _typesProduit = [
    'cacao',
    'engrais',
    'pesticide',
    'semences',
    'outils',
    'autre',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.credit != null) {
      _loadCreditData();
    } else {
      _dateOctroi = DateTime.now();
    }
  }

  void _loadCreditData() {
    final credit = widget.credit!;
    _typeCredit = credit.typeCredit;
    _typeAide = credit.typeAide;
    _montantController.text = credit.montant.toString();
    _quantiteProduitController.text = credit.quantiteProduit?.toString() ?? '';
    _typeProduitController.text = credit.typeProduit ?? '';
    _motifController.text = credit.motif;
    _dateOctroi = credit.dateOctroi;
    _echeanceRemboursement = credit.echeanceRemboursement;
    _observationController.text = credit.observation ?? '';
  }

  @override
  void dispose() {
    _montantController.dispose();
    _quantiteProduitController.dispose();
    _typeProduitController.dispose();
    _motifController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_typeCredit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner le type de crédit')),
      );
      return;
    }

    if (_dateOctroi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner la date d\'octroi')),
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

      final montant = double.tryParse(_montantController.text.trim());
      if (montant == null || montant <= 0) {
        throw Exception('Le montant doit être supérieur à 0');
      }

      double? quantiteProduit;
      String? typeProduit;
      
      if (_typeCredit == 'credit_produit') {
        quantiteProduit = double.tryParse(_quantiteProduitController.text.trim());
        if (quantiteProduit == null || quantiteProduit <= 0) {
          throw Exception('La quantité de produit doit être supérieure à 0');
        }
        typeProduit = _typeProduitController.text.trim().isEmpty 
            ? null 
            : _typeProduitController.text.trim();
      }

      if (widget.credit == null) {
        // Création
        await _service.createCredit(
          adherentId: widget.adherentId,
          typeCredit: _typeCredit!,
          typeAide: _typeAide,
          montant: montant,
          quantiteProduit: quantiteProduit,
          typeProduit: typeProduit,
          dateOctroi: _dateOctroi!,
          motif: _motifController.text.trim(),
          echeanceRemboursement: _echeanceRemboursement,
          observation: _observationController.text.trim().isEmpty 
              ? null 
              : _observationController.text.trim(),
          createdBy: currentUser.id!,
        );
      } else {
        // Modification
        await _service.updateCredit(
          id: widget.credit!.id!,
          typeCredit: _typeCredit,
          typeAide: _typeAide,
          montant: montant,
          quantiteProduit: quantiteProduit,
          typeProduit: typeProduit,
          dateOctroi: _dateOctroi,
          motif: _motifController.text.trim(),
          echeanceRemboursement: _echeanceRemboursement,
          observation: _observationController.text.trim().isEmpty 
              ? null 
              : _observationController.text.trim(),
          updatedBy: currentUser.id!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.credit == null 
                ? 'Crédit ajouté avec succès' 
                : 'Crédit modifié avec succès'),
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

  String _getTypeCreditLabel(String type) {
    switch (type) {
      case 'credit_produit':
        return 'Crédit Produit';
      case 'credit_argent':
        return 'Crédit Argent';
      default:
        return type;
    }
  }

  String _getTypeAideLabel(String type) {
    switch (type) {
      case 'credit':
        return 'Crédit';
      case 'don':
        return 'Don';
      case 'soutien':
        return 'Soutien';
      case 'aide_sante':
        return 'Aide Santé';
      case 'aide_education':
        return 'Aide Éducation';
      case 'autre':
        return 'Autre';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.credit != null;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier le crédit' : 'Ajouter un crédit'),
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
              // Type de crédit
              DropdownButtonFormField<String>(
                initialValue: _typeCredit,
                decoration: InputDecoration(
                  labelText: 'Type de crédit *',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _typesCredit.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getTypeCreditLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _typeCredit = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner le type de crédit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type d'aide
              DropdownButtonFormField<String>(
                initialValue: _typeAide,
                decoration: InputDecoration(
                  labelText: 'Type d\'aide',
                  prefixIcon: const Icon(Icons.help_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _typesAide.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getTypeAideLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _typeAide = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Montant (toujours requis)
              TextFormField(
                controller: _montantController,
                decoration: InputDecoration(
                  labelText: _typeCredit == 'credit_produit' 
                      ? 'Valeur estimée (FCFA) *' 
                      : 'Montant (FCFA) *',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: _typeCredit == 'credit_produit' 
                      ? 'Valeur estimée du produit' 
                      : 'Montant du crédit',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le montant est requis';
                  }
                  final montant = double.tryParse(value.trim());
                  if (montant == null || montant <= 0) {
                    return 'Le montant doit être supérieur à 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Champs spécifiques au crédit produit
              if (_typeCredit == 'credit_produit') ...[
                // Quantité de produit
                TextFormField(
                  controller: _quantiteProduitController,
                  decoration: InputDecoration(
                    labelText: 'Quantité de produit (kg) *',
                    prefixIcon: const Icon(Icons.scale),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_typeCredit == 'credit_produit') {
                      if (value == null || value.trim().isEmpty) {
                        return 'La quantité est requise pour un crédit produit';
                      }
                      final quantite = double.tryParse(value.trim());
                      if (quantite == null || quantite <= 0) {
                        return 'La quantité doit être supérieure à 0';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Type de produit
                DropdownButtonFormField<String>(
                  initialValue: _typeProduitController.text.isEmpty ? null : _typeProduitController.text,
                  decoration: InputDecoration(
                    labelText: 'Type de produit',
                    prefixIcon: const Icon(Icons.eco),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _typesProduit.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type[0].toUpperCase() + type.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _typeProduitController.text = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Motif
              TextFormField(
                controller: _motifController,
                decoration: InputDecoration(
                  labelText: 'Motif *',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Raison de l\'octroi du crédit',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le motif est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date d'octroi
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateOctroi ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _dateOctroi = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date d\'octroi *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _dateOctroi != null
                        ? dateFormat.format(_dateOctroi!)
                        : 'Sélectionner une date',
                    style: TextStyle(
                      color: _dateOctroi != null 
                          ? Colors.black87 
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date d'échéance
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _echeanceRemboursement ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() => _echeanceRemboursement = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date d\'échéance (optionnel)',
                    prefixIcon: const Icon(Icons.event),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _echeanceRemboursement != null
                        ? dateFormat.format(_echeanceRemboursement!)
                        : 'Sélectionner une date',
                    style: TextStyle(
                      color: _echeanceRemboursement != null 
                          ? Colors.black87 
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Observations
              TextFormField(
                controller: _observationController,
                decoration: InputDecoration(
                  labelText: 'Observations',
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

