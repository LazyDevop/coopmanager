import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/parametres_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/parametres_cooperative_model.dart';
import '../../../config/app_config.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ParametresFinancesScreen extends StatefulWidget {
  const ParametresFinancesScreen({super.key});

  @override
  State<ParametresFinancesScreen> createState() => _ParametresFinancesScreenState();
}

class _ParametresFinancesScreenState extends State<ParametresFinancesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commissionController = TextEditingController();
  final _periodeController = TextEditingController();
  
  // Contrôleurs pour les barèmes
  final Map<String, TextEditingController> _baremeControllers = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadParametres();
  }

  Future<void> _loadParametres() async {
    final viewModel = context.read<ParametresViewModel>();
    await viewModel.loadParametres();
    await viewModel.loadBaremes();
    
    final parametres = viewModel.parametres;
    if (parametres != null) {
      _commissionController.text = (parametres.commissionRate * 100).toStringAsFixed(2);
      _periodeController.text = parametres.periodeCampagneDays.toString();
    }
    
    // Initialiser les contrôleurs pour les barèmes
    for (final qualite in AppConfig.qualitesCacao) {
      final bareme = viewModel.baremes.firstWhere(
        (b) => b.qualite == qualite,
        orElse: () => BaremeQualiteModel(qualite: qualite),
      );
      
      _baremeControllers['${qualite}_min'] = TextEditingController(
        text: bareme.prixMin?.toStringAsFixed(0) ?? '',
      );
      _baremeControllers['${qualite}_max'] = TextEditingController(
        text: bareme.prixMax?.toStringAsFixed(0) ?? '',
      );
      _baremeControllers['${qualite}_commission'] = TextEditingController(
        text: bareme.commissionRate != null
            ? (bareme.commissionRate! * 100).toStringAsFixed(2)
            : '',
      );
    }
  }

  @override
  void dispose() {
    _commissionController.dispose();
    _periodeController.dispose();
    for (final controller in _baremeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveParametres() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = context.read<ParametresViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) return;

    final commissionRate = double.parse(_commissionController.text) / 100;
    final periodeDays = int.parse(_periodeController.text);

    final success = await viewModel.saveParametres(
      commissionRate: commissionRate,
      periodeCampagneDays: periodeDays,
      updatedBy: currentUser.id!,
    );

    if (success && mounted) {
      Fluttertoast.showToast(
        msg: 'Paramètres financiers sauvegardés avec succès',
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

  Future<void> _saveBareme(String qualite) async {
    final viewModel = context.read<ParametresViewModel>();
    
    final prixMin = _baremeControllers['${qualite}_min']?.text.isNotEmpty == true
        ? double.tryParse(_baremeControllers['${qualite}_min']!.text)
        : null;
    final prixMax = _baremeControllers['${qualite}_max']?.text.isNotEmpty == true
        ? double.tryParse(_baremeControllers['${qualite}_max']!.text)
        : null;
    final commissionRate = _baremeControllers['${qualite}_commission']?.text.isNotEmpty == true
        ? double.tryParse(_baremeControllers['${qualite}_commission']!.text)
        : null;

    final success = await viewModel.saveBareme(
      qualite: qualite,
      prixMin: prixMin,
      prixMax: prixMax,
      commissionRate: commissionRate != null ? commissionRate / 100 : null,
    );

    if (success && mounted) {
      Fluttertoast.showToast(
        msg: 'Barème sauvegardé avec succès',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Paramètres financiers généraux
            const Text(
              'Paramètres financiers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Taux de commission
                    TextFormField(
                      controller: _commissionController,
                      decoration: InputDecoration(
                        labelText: 'Taux de commission (%) *',
                        prefixIcon: const Icon(Icons.percent),
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
                          return 'Veuillez entrer le taux de commission';
                        }
                        final taux = double.tryParse(value);
                        if (taux == null || taux < 0 || taux > 100) {
                          return 'Le taux doit être entre 0 et 100';
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

                    // Période de campagne
                    TextFormField(
                      controller: _periodeController,
                      decoration: InputDecoration(
                        labelText: 'Période de campagne (jours) *',
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixText: 'jours',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer la période';
                        }
                        final periode = int.tryParse(value);
                        if (periode == null || periode <= 0) {
                          return 'La période doit être supérieure à 0';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        setState(() {
                          _hasChanges = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Barèmes de qualité
            const Text(
              'Barèmes par qualité',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Définissez les prix et commissions spécifiques pour chaque qualité de cacao',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            ...AppConfig.qualitesCacao.map((qualite) => Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          qualite.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _baremeControllers['${qualite}_min'],
                                decoration: InputDecoration(
                                  labelText: 'Prix min (FCFA/kg)',
                                  prefixIcon: const Icon(Icons.arrow_downward),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _baremeControllers['${qualite}_max'],
                                decoration: InputDecoration(
                                  labelText: 'Prix max (FCFA/kg)',
                                  prefixIcon: const Icon(Icons.arrow_upward),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _baremeControllers['${qualite}_commission'],
                          decoration: InputDecoration(
                            labelText: 'Commission spécifique (%)',
                            prefixIcon: const Icon(Icons.percent),
                            suffixText: '%',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            helperText: 'Laissez vide pour utiliser le taux général',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: viewModel.isLoading
                                ? null
                                : () => _saveBareme(qualite),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown.shade700,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Sauvegarder ce barème'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 24),

            // Bouton de sauvegarde des paramètres généraux
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _hasChanges && !viewModel.isLoading ? _saveParametres : null,
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
                        'Sauvegarder les paramètres financiers',
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

