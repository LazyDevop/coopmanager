import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/settings/capital_settings_model.dart';
import '../../widgets/settings/setting_section_card.dart';
import '../../widgets/settings/setting_toggle.dart';
import '../../widgets/settings/setting_number_input.dart';
import '../../widgets/settings/save_bar.dart';

class CapitalSettingsScreen extends StatefulWidget {
  const CapitalSettingsScreen({super.key});

  @override
  State<CapitalSettingsScreen> createState() => _CapitalSettingsScreenState();
}

class _CapitalSettingsScreenState extends State<CapitalSettingsScreen> {
  CapitalSettingsModel? _settings;
  bool _hasChanges = false;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sauvegarder une référence au ScaffoldMessenger pour éviter les erreurs de widget désactivé
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    
    final provider = context.read<SettingsProvider>();
    await provider.loadCapitalSettings();
    
    if (!mounted) return;
    
    setState(() {
      _settings = provider.capitalSettings ?? CapitalSettingsModel(
        valeurPart: 1000.0,
        nombreMinParts: 1,
      );
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser == null) return;

    final provider = context.read<SettingsProvider>();
    final success = await provider.saveCapitalSettings(_settings!, currentUser.id!);

    if (!mounted) return;
    
    if (success) {
      setState(() => _hasChanges = false);
      // Utiliser la référence sauvegardée du ScaffoldMessenger
      if (!mounted || _scaffoldMessenger == null) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _scaffoldMessenger == null) return;
        
        try {
          if (_scaffoldMessenger!.mounted) {
            _scaffoldMessenger!.showSnackBar(
              const SnackBar(content: Text('Paramètres sauvegardés')),
            );
          }
        } catch (e) {
          debugPrint('Erreur affichage SnackBar: $e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    if (_settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Capital Social')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SettingSectionCard(
                    title: 'Configuration du capital',
                    icon: Icons.account_balance,
                    child: Column(
                      children: [
                        SettingNumberInput(
                          label: 'Valeur d\'une part (FCFA)',
                          value: _settings!.valeurPart,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                valeurPart: value ?? 0.0,
                              );
                              _hasChanges = true;
                            });
                          },
                          required: true,
                          min: 1,
                          suffix: 'FCFA',
                        ),
                        SettingNumberInput(
                          label: 'Nombre minimum de parts',
                          value: _settings!.nombreMinParts.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                nombreMinParts: value?.toInt() ?? 1,
                              );
                              _hasChanges = true;
                            });
                          },
                          required: true,
                          min: 1,
                        ),
                        SettingNumberInput(
                          label: 'Nombre maximum de parts',
                          value: _settings!.nombreMaxParts?.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                nombreMaxParts: value?.toInt(),
                              );
                              _hasChanges = true;
                            });
                          },
                          min: 1,
                        ),
                        SettingToggle(
                          label: 'Libération obligatoire',
                          description: 'Les parts doivent être libérées immédiatement',
                          value: _settings!.liberationObligatoire,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(liberationObligatoire: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        if (!_settings!.liberationObligatoire)
                          SettingNumberInput(
                            label: 'Délai de libération (jours)',
                            value: _settings!.delaiLiberationJours?.toDouble(),
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings!.copyWith(
                                  delaiLiberationJours: value?.toInt(),
                                );
                                _hasChanges = true;
                              });
                            },
                            min: 1,
                            max: 365,
                          ),
                        SettingToggle(
                          label: 'Dividendes activés',
                          value: _settings!.dividendesActives,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(dividendesActives: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        if (_settings!.dividendesActives)
                          SettingNumberInput(
                            label: 'Taux de dividende (%)',
                            value: _settings!.tauxDividende,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings!.copyWith(tauxDividende: value);
                                _hasChanges = true;
                              });
                            },
                            min: 0,
                            max: 100,
                            suffix: '%',
                            decimals: 2,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SaveBar(
            hasChanges: _hasChanges,
            isSaving: provider.isLoading,
            onSave: _saveSettings,
            onCancel: () {
              setState(() => _hasChanges = false);
              _loadSettings();
            },
            errorMessage: provider.errorMessage,
          ),
        ],
      ),
    );
  }
}

