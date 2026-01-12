import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/adherent/traitement_agricole_service.dart';
import '../../../services/adherent/champ_parcelle_service.dart';
import '../../../data/models/adherent_expert/traitement_agricole_model.dart';
import '../../../data/models/adherent_expert/champ_parcelle_model.dart';
import '../../viewmodels/auth_viewmodel.dart';

class TraitementAgricoleFormScreen extends StatefulWidget {
  final int adherentId;
  final TraitementAgricoleModel? traitement; // Si fourni, c'est une modification
  final int? champIdPreselectionne; // Champ présélectionné (optionnel)

  const TraitementAgricoleFormScreen({
    super.key,
    required this.adherentId,
    this.traitement,
    this.champIdPreselectionne,
  });

  @override
  State<TraitementAgricoleFormScreen> createState() => _TraitementAgricoleFormScreenState();
}

class _TraitementAgricoleFormScreenState extends State<TraitementAgricoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _produitUtiliseController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _coutTraitementController = TextEditingController();
  final _operateurController = TextEditingController();
  final _observationController = TextEditingController();

  final TraitementAgricoleService _service = TraitementAgricoleService();
  final ChampParcelleService _champService = ChampParcelleService();

  List<ChampParcelleModel> _champs = [];
  ChampParcelleModel? _selectedChamp;
  String? _typeTraitement;
  String _uniteQuantite = 'kg';
  DateTime? _dateTraitement;
  bool _isLoading = false;
  bool _isLoadingChamps = true;

  final List<String> _typesTraitement = [
    'engrais',
    'pesticide',
    'entretien',
    'autre',
  ];

  final List<String> _unitesQuantite = [
    'kg',
    'L',
    'g',
    'ml',
    'unite',
  ];

  @override
  void initState() {
    super.initState();
    _loadChamps();
    if (widget.traitement != null) {
      // Pour les modifications, charger les données après le chargement des champs
      _loadChamps().then((_) {
        if (mounted && widget.traitement != null) {
          _loadTraitementData();
        }
      });
    }
  }

  Future<void> _loadChamps() async {
    try {
      final champs = await _champService.getChampsByAdherent(widget.adherentId);
      if (mounted) {
        setState(() {
          _champs = champs;
          _isLoadingChamps = false;
          
          // Sélectionner le champ présélectionné si fourni
          if (widget.champIdPreselectionne != null && champs.isNotEmpty) {
            _selectChampById(widget.champIdPreselectionne!);
          } else if (champs.isNotEmpty && _selectedChamp == null) {
            // Si aucun champ présélectionné, sélectionner le premier par défaut
            _selectedChamp = champs.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingChamps = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des champs: $e')),
        );
      }
    }
  }

  void _selectChampById(int champId) {
    if (_champs.isEmpty) {
      return;
    }
    
    try {
      final champ = _champs.firstWhere(
        (c) => c.id == champId,
        orElse: () => _champs.first,
      );
      setState(() => _selectedChamp = champ);
    } catch (e) {
      // Si aucun champ trouvé, ne rien faire ou sélectionner le premier si disponible
      if (_champs.isNotEmpty) {
        setState(() => _selectedChamp = _champs.first);
      }
    }
  }

  void _loadTraitementData() {
    if (widget.traitement == null) return;
    
    final traitement = widget.traitement!;
    _produitUtiliseController.text = traitement.produitUtilise;
    _typeTraitement = traitement.typeTraitement;
    _quantiteController.text = traitement.quantite.toString();
    _uniteQuantite = traitement.uniteQuantite;
    _dateTraitement = traitement.dateTraitement;
    _coutTraitementController.text = traitement.coutTraitement.toString();
    _operateurController.text = traitement.operateur ?? '';
    _observationController.text = traitement.observation ?? '';
    
    // Sélectionner le champ associé si disponible
    if (_champs.isNotEmpty) {
      _selectChampById(traitement.champId);
    }
  }

  @override
  void dispose() {
    _produitUtiliseController.dispose();
    _quantiteController.dispose();
    _coutTraitementController.dispose();
    _operateurController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedChamp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un champ')),
      );
      return;
    }

    if (_typeTraitement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner le type de traitement')),
      );
      return;
    }

    if (_dateTraitement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner la date du traitement')),
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

      final quantite = double.tryParse(_quantiteController.text.trim());
      if (quantite == null || quantite <= 0) {
        throw Exception('La quantité doit être supérieure à 0');
      }

      final coutTraitement = double.tryParse(_coutTraitementController.text.trim()) ?? 0.0;

      if (widget.traitement == null) {
        // Création
        await _service.createTraitement(
          champId: _selectedChamp!.id!,
          typeTraitement: _typeTraitement!,
          produitUtilise: _produitUtiliseController.text.trim(),
          quantite: quantite,
          uniteQuantite: _uniteQuantite,
          dateTraitement: _dateTraitement!,
          coutTraitement: coutTraitement,
          operateur: _operateurController.text.trim().isEmpty 
              ? null 
              : _operateurController.text.trim(),
          observation: _observationController.text.trim().isEmpty 
              ? null 
              : _observationController.text.trim(),
          createdBy: currentUser.id!,
        );
      } else {
        // Modification
        await _service.updateTraitement(
          id: widget.traitement!.id!,
          typeTraitement: _typeTraitement,
          produitUtilise: _produitUtiliseController.text.trim(),
          quantite: quantite,
          uniteQuantite: _uniteQuantite,
          dateTraitement: _dateTraitement,
          coutTraitement: coutTraitement,
          operateur: _operateurController.text.trim().isEmpty 
              ? null 
              : _operateurController.text.trim(),
          observation: _observationController.text.trim().isEmpty 
              ? null 
              : _observationController.text.trim(),
          updatedBy: currentUser.id!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.traitement == null 
                ? 'Traitement ajouté avec succès' 
                : 'Traitement modifié avec succès'),
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

  String _getTypeTraitementLabel(String value) {
    switch (value) {
      case 'engrais':
        return 'Engrais';
      case 'pesticide':
        return 'Pesticide';
      case 'entretien':
        return 'Entretien';
      case 'autre':
        return 'Autre';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.traitement != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier le traitement' : 'Ajouter un traitement'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingChamps
          ? const Center(child: CircularProgressIndicator())
          : _champs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.agriculture_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun champ disponible',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vous devez d\'abord créer au moins un champ pour pouvoir ajouter un traitement.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Retour'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sélection du champ
                        DropdownButtonFormField<ChampParcelleModel>(
                      initialValue: _selectedChamp,
                      decoration: InputDecoration(
                        labelText: 'Champ *',
                        prefixIcon: const Icon(Icons.agriculture),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _champs.map((champ) {
                        return DropdownMenuItem(
                          value: champ,
                          child: Text(champ.nomChamp ?? champ.codeChamp),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedChamp = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner un champ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Type de traitement
                    DropdownButtonFormField<String>(
                      initialValue: _typeTraitement,
                      decoration: InputDecoration(
                        labelText: 'Type de traitement *',
                        prefixIcon: const Icon(Icons.science),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _typesTraitement.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getTypeTraitementLabel(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _typeTraitement = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner le type de traitement';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Produit utilisé
                    TextFormField(
                      controller: _produitUtiliseController,
                      decoration: InputDecoration(
                        labelText: 'Produit utilisé *',
                        prefixIcon: const Icon(Icons.eco),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Nom du produit (ex: NPK 15-15-15)',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le produit utilisé est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantité et unité
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantiteController,
                            decoration: InputDecoration(
                              labelText: 'Quantité *',
                              prefixIcon: const Icon(Icons.scale),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La quantité est requise';
                              }
                              final quantite = double.tryParse(value.trim());
                              if (quantite == null || quantite <= 0) {
                                return 'La quantité doit être supérieure à 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _uniteQuantite,
                            decoration: InputDecoration(
                              labelText: 'Unité',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _unitesQuantite.map((unite) {
                              return DropdownMenuItem(
                                value: unite,
                                child: Text(unite.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _uniteQuantite = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date du traitement
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dateTraitement ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _dateTraitement = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date du traitement *',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _dateTraitement != null
                              ? DateFormat('dd/MM/yyyy').format(_dateTraitement!)
                              : 'Sélectionner une date',
                          style: TextStyle(
                            color: _dateTraitement != null 
                                ? Colors.black87 
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Coût du traitement
                    TextFormField(
                      controller: _coutTraitementController,
                      decoration: InputDecoration(
                        labelText: 'Coût du traitement (FCFA)',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Opérateur
                    TextFormField(
                      controller: _operateurController,
                      decoration: InputDecoration(
                        labelText: 'Opérateur',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Nom de la personne qui a effectué le traitement',
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

