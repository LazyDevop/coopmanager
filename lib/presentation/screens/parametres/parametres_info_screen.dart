import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../viewmodels/parametres_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/parametres_cooperative_model.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ParametresInfoScreen extends StatefulWidget {
  const ParametresInfoScreen({super.key});

  @override
  State<ParametresInfoScreen> createState() => _ParametresInfoScreenState();
}

class _ParametresInfoScreenState extends State<ParametresInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Différer le chargement pour éviter notifyListeners() pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParametres();
    });
  }

  Future<void> _loadParametres() async {
    if (!mounted) return;
    final viewModel = context.read<ParametresViewModel>();
    await viewModel.loadParametres();
    
    // Vérifier à nouveau après l'appel async
    if (!mounted) return;
    
    final parametres = viewModel.parametres;
    if (parametres != null) {
      _nomController.text = parametres.nomCooperative;
      _adresseController.text = parametres.adresse ?? '';
      _telephoneController.text = parametres.telephone ?? '';
      _emailController.text = parametres.email ?? '';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final viewModel = context.read<ParametresViewModel>();
    await viewModel.pickLogo();
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _saveParametres() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = context.read<ParametresViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) return;

    final success = await viewModel.saveParametres(
      nomCooperative: _nomController.text.trim(),
      adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
      telephone: _telephoneController.text.trim().isEmpty ? null : _telephoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      updatedBy: currentUser.id!,
    );

    if (success && mounted) {
      Fluttertoast.showToast(
        msg: 'Paramètres sauvegardés avec succès',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      setState(() {
        _hasChanges = false;
      });
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
    final parametres = viewModel.parametres;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Logo de la coopérative',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: viewModel.selectedLogoFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    viewModel.selectedLogoFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : parametres?.logoPath != null &&
                                      File(parametres!.logoPath!).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(parametres.logoPath!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.business,
                                      size: 80,
                                      color: Colors.grey.shade400,
                                    ),
                        ),
                        if (viewModel.selectedLogoFile != null)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                viewModel.clearSelectedLogo();
                                setState(() {
                                  _hasChanges = true;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.upload),
                      label: const Text('Choisir un logo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Informations générales
            const Text(
              'Informations générales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Nom de la coopérative
            TextFormField(
              controller: _nomController,
              decoration: InputDecoration(
                labelText: 'Nom de la coopérative *',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer le nom de la coopérative';
                }
                return null;
              },
              onChanged: (_) {
                setState(() {
                  _hasChanges = true;
                });
              },
            ),
            const SizedBox(height: 16),

            // Adresse
            TextFormField(
              controller: _adresseController,
              decoration: InputDecoration(
                labelText: 'Adresse',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 2,
              onChanged: (_) {
                setState(() {
                  _hasChanges = true;
                });
              },
            ),
            const SizedBox(height: 16),

            // Téléphone
            TextFormField(
              controller: _telephoneController,
              decoration: InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.phone,
              onChanged: (_) {
                setState(() {
                  _hasChanges = true;
                });
              },
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
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty && !value.contains('@')) {
                  return 'Email invalide';
                }
                return null;
              },
              onChanged: (_) {
                setState(() {
                  _hasChanges = true;
                });
              },
            ),
            const SizedBox(height: 24),

            // Bouton de sauvegarde
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _hasChanges ? _saveParametres : null,
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
                    : const Text(
                        'Sauvegarder',
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
    );
  }
}

