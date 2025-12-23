import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../data/models/adherent_model.dart';
import '../../config/app_config.dart';

class StockDepotFormScreen extends StatefulWidget {
  final int? adherentId; // Adhérent présélectionné (optionnel)
  
  const StockDepotFormScreen({super.key, this.adherentId});

  @override
  State<StockDepotFormScreen> createState() => _StockDepotFormScreenState();
}

class _StockDepotFormScreenState extends State<StockDepotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stockBrutController = TextEditingController();
  final _poidsSacController = TextEditingController();
  final _poidsDechetsController = TextEditingController();
  final _autresController = TextEditingController();
  final _prixUnitaireController = TextEditingController();
  final _humiditeController = TextEditingController();
  final _observationsController = TextEditingController();
  
  AdherentModel? _selectedAdherent;
  DateTime _selectedDate = DateTime.now();
  String? _selectedQualite;
  String? _photoPath;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Calculer le poids net automatiquement
  double get _poidsNet {
    final stockBrut = double.tryParse(_stockBrutController.text) ?? 0.0;
    final poidsSac = double.tryParse(_poidsSacController.text) ?? 0.0;
    final poidsDechets = double.tryParse(_poidsDechetsController.text) ?? 0.0;
    final autres = double.tryParse(_autresController.text) ?? 0.0;
    return stockBrut - poidsSac - poidsDechets - autres;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockViewModel>().loadAdherents();
    });
  }

  @override
  void dispose() {
    _stockBrutController.dispose();
    _poidsSacController.dispose();
    _poidsDechetsController.dispose();
    _autresController.dispose();
    _prixUnitaireController.dispose();
    _humiditeController.dispose();
    _observationsController.dispose();
    super.dispose();
  }
  
  void _updatePoidsNet() {
    setState(() {}); // Recalculer le poids net
  }
  
  Future<void> _pickImage() async {
    try {
      // Créer le dossier depots s'il n'existe pas
      final appDir = await getApplicationDocumentsDirectory();
      final depotsDir = Directory(path.join(appDir.path, 'depots'));
      if (!await depotsDir.exists()) {
        await depotsDir.create(recursive: true);
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Sauvegarder l'image dans le dossier de l'application
        final fileName = 'depot_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(image.path).copy(
          path.join(depotsDir.path, fileName),
        );
        
        setState(() {
          _photoPath = savedImage.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la prise de photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _removePhoto() {
    setState(() {
      _photoPath = null;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

    setState(() {
      _isLoading = true;
    });

    final stockViewModel = context.read<StockViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final stockBrut = double.parse(_stockBrutController.text);
    final poidsSac = _poidsSacController.text.isNotEmpty 
        ? double.parse(_poidsSacController.text) 
        : null;
    final poidsDechets = _poidsDechetsController.text.isNotEmpty 
        ? double.parse(_poidsDechetsController.text) 
        : null;
    final autres = _autresController.text.isNotEmpty 
        ? double.parse(_autresController.text) 
        : null;
    final poidsNet = _poidsNet;
    
    if (poidsNet <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le poids net doit être supérieur à 0'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final humidite = _humiditeController.text.isNotEmpty
        ? double.parse(_humiditeController.text)
        : null;
    
    if (humidite != null && (humidite < 0 || humidite > 100)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L\'humidité doit être entre 0 et 100%'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final success = await stockViewModel.createDepot(
      adherentId: _selectedAdherent!.id!,
      stockBrut: stockBrut,
      poidsSac: poidsSac,
      poidsDechets: poidsDechets,
      autres: autres,
      poidsNet: poidsNet,
      prixUnitaire: _prixUnitaireController.text.isNotEmpty
          ? double.parse(_prixUnitaireController.text)
          : null,
      dateDepot: _selectedDate,
      qualite: _selectedQualite,
      humidite: humidite,
      photoPath: _photoPath,
      observations: _observationsController.text.isNotEmpty
          ? _observationsController.text
          : null,
      createdBy: currentUser.id!,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dépôt enregistré avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      final errorMsg = stockViewModel.errorMessage ?? 'Erreur lors de l\'enregistrement';
      print('Erreur lors de la création du dépôt: $errorMsg'); // Debug
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Détails',
            textColor: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Erreur'),
                  content: Text(errorMsg),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockViewModel = context.watch<StockViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Dépôt'),
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
              // Sélection adhérent
              DropdownButtonFormField<AdherentModel>(
                value: _selectedAdherent,
                decoration: InputDecoration(
                  labelText: 'Adhérent *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: stockViewModel.adherents
                    .where((a) => a.isActive)
                    .map((adherent) {
                  return DropdownMenuItem<AdherentModel>(
                    value: adherent,
                    child: Text('${adherent.code} - ${adherent.fullName}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAdherent = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner un adhérent';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date de dépôt
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de dépôt *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section: Calcul du poids net
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calcul du poids net',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Stock brut
                      TextFormField(
                        controller: _stockBrutController,
                        decoration: InputDecoration(
                          labelText: 'Stock brut (kg) *',
                          hintText: 'Poids total amené par le producteur',
                          prefixIcon: const Icon(Icons.inventory),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _updatePoidsNet(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le stock brut';
                          }
                          final stockBrut = double.tryParse(value);
                          if (stockBrut == null || stockBrut <= 0) {
                            return 'Le stock brut doit être supérieur à 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Poids du sac
                      TextFormField(
                        controller: _poidsSacController,
                        decoration: InputDecoration(
                          labelText: 'Poids du sac (kg)',
                          hintText: 'Poids des sacs à déduire',
                          prefixIcon: const Icon(Icons.shopping_bag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _updatePoidsNet(),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final poids = double.tryParse(value);
                            if (poids == null || poids < 0) {
                              return 'Le poids doit être un nombre positif';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Poids des déchets
                      TextFormField(
                        controller: _poidsDechetsController,
                        decoration: InputDecoration(
                          labelText: 'Poids des déchets (kg)',
                          hintText: 'Poids des déchets à déduire',
                          prefixIcon: const Icon(Icons.delete_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _updatePoidsNet(),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final poids = double.tryParse(value);
                            if (poids == null || poids < 0) {
                              return 'Le poids doit être un nombre positif';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Autres déductions
                      TextFormField(
                        controller: _autresController,
                        decoration: InputDecoration(
                          labelText: 'Autres déductions (kg)',
                          hintText: 'Autres déductions diverses',
                          prefixIcon: const Icon(Icons.remove_circle_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _updatePoidsNet(),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final poids = double.tryParse(value);
                            if (poids == null || poids < 0) {
                              return 'Le poids doit être un nombre positif';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Affichage du poids net calculé
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _poidsNet > 0 ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _poidsNet > 0 ? Colors.green.shade300 : Colors.red.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Poids net calculé:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '${_poidsNet.toStringAsFixed(2)} kg',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _poidsNet > 0 ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Qualité
              DropdownButtonFormField<String>(
                value: _selectedQualite,
                decoration: InputDecoration(
                  labelText: 'Qualité',
                  prefixIcon: const Icon(Icons.star),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: AppConfig.qualitesCacao.map((qualite) {
                  return DropdownMenuItem<String>(
                    value: qualite,
                    child: Text(qualite.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedQualite = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Humidité
              TextFormField(
                controller: _humiditeController,
                decoration: InputDecoration(
                  labelText: 'Humidité (%) *',
                  hintText: 'Taux d\'humidité du cacao',
                  prefixIcon: const Icon(Icons.water_drop),
                  suffixText: '%',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le taux d\'humidité';
                  }
                  final humidite = double.tryParse(value);
                  if (humidite == null || humidite < 0 || humidite > 100) {
                    return 'L\'humidité doit être entre 0 et 100%';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Photo
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photo du dépôt (optionnel)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_photoPath != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_photoPath!),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: _removePhoto,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(_photoPath == null ? Icons.camera_alt : Icons.camera_alt_outlined),
                        label: Text(_photoPath == null ? 'Prendre une photo' : 'Changer la photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Prix unitaire (optionnel)
              TextFormField(
                controller: _prixUnitaireController,
                decoration: InputDecoration(
                  labelText: 'Prix unitaire (optionnel)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final prix = double.tryParse(value);
                    if (prix == null || prix < 0) {
                      return 'Le prix doit être un nombre positif';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Observations
              TextFormField(
                controller: _observationsController,
                decoration: InputDecoration(
                  labelText: 'Observations',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Bouton de soumission
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700,
                    foregroundColor: Colors.white,
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
                      : const Text(
                          'Enregistrer',
                          style: TextStyle(
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

