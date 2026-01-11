import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/settings/sales_settings_model.dart';
import '../../widgets/settings/setting_section_card.dart';
import '../../widgets/settings/setting_toggle.dart';
import '../../widgets/settings/setting_select.dart';
import '../../widgets/settings/setting_number_input.dart';
import '../../widgets/settings/save_bar.dart';

class SalesSettingsScreen extends StatefulWidget {
  const SalesSettingsScreen({super.key});

  @override
  State<SalesSettingsScreen> createState() => _SalesSettingsScreenState();
}

class _SalesSettingsScreenState extends State<SalesSettingsScreen> {
  SalesSettingsModel? _settings;
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
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    
    final provider = context.read<SettingsProvider>();
    await provider.loadSalesSettings();
    
    if (!mounted) return;
    
    setState(() {
      _settings = provider.salesSettings ?? SalesSettingsModel(
        prixMinimumCacao: 1000.0,
        prixMaximumCacao: 2000.0,
      );
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser == null) return;

    final provider = context.read<SettingsProvider>();
    final success = await provider.saveSalesSettings(_settings!, currentUser.id!);

    if (!mounted) return;
    
    if (success) {
      setState(() => _hasChanges = false);
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
      appBar: AppBar(title: const Text('Ventes & Prix du Marché')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SettingSectionCard(
                    title: 'Prix du cacao',
                    icon: Icons.attach_money,
                    child: Column(
                      children: [
                        SettingNumberInput(
                          label: 'Prix minimum cacao (FCFA/kg)',
                          value: _settings!.prixMinimumCacao,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                prixMinimumCacao: value ?? 0.0,
                              );
                              _hasChanges = true;
                            });
                          },
                          required: true,
                          min: 0,
                          suffix: 'FCFA/kg',
                        ),
                        SettingNumberInput(
                          label: 'Prix maximum cacao (FCFA/kg)',
                          value: _settings!.prixMaximumCacao,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                prixMaximumCacao: value ?? 0.0,
                              );
                              _hasChanges = true;
                            });
                          },
                          required: true,
                          min: _settings!.prixMinimumCacao,
                          suffix: 'FCFA/kg',
                        ),
                        SettingNumberInput(
                          label: 'Prix du jour (FCFA/kg)',
                          value: _settings!.prixDuJour,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(prixDuJour: value);
                              _hasChanges = true;
                            });
                          },
                          min: _settings!.prixMinimumCacao,
                          max: _settings!.prixMaximumCacao,
                          suffix: 'FCFA/kg',
                        ),
                        SettingSelect<String>(
                          label: 'Mode de validation prix',
                          value: _settings!.modeValidationPrix,
                          options: [
                            SettingSelectOption(value: 'auto', label: 'Automatique'),
                            SettingSelectOption(value: 'manuel', label: 'Manuel'),
                            SettingSelectOption(value: 'validation_requise', label: 'Validation requise'),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(modeValidationPrix: value ?? 'auto');
                              _hasChanges = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SettingSectionCard(
                    title: 'Commissions et retenues',
                    icon: Icons.percent,
                    child: Column(
                      children: [
                        SettingNumberInput(
                          label: 'Commission coopérative (%)',
                          value: _settings!.commissionCooperative,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                commissionCooperative: value ?? 0.0,
                              );
                              _hasChanges = true;
                            });
                          },
                          min: 0,
                          max: 100,
                          suffix: '%',
                          decimals: 2,
                        ),
                        SettingToggle(
                          label: 'Alerte si prix hors plage',
                          value: _settings!.alertePrixHorsPlage,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(alertePrixHorsPlage: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        SettingToggle(
                          label: 'Historique des prix actif',
                          value: _settings!.historiquePrixActif,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(historiquePrixActif: value);
                              _hasChanges = true;
                            });
                          },
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

