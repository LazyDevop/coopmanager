import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/settings/module_settings_model.dart';
import '../../widgets/settings/setting_section_card.dart';
import '../../widgets/settings/setting_toggle.dart';
import '../../widgets/settings/setting_number_input.dart';
import '../../widgets/settings/save_bar.dart';

class ModuleSettingsScreen extends StatefulWidget {
  const ModuleSettingsScreen({super.key});

  @override
  State<ModuleSettingsScreen> createState() => _ModuleSettingsScreenState();
}

class _ModuleSettingsScreenState extends State<ModuleSettingsScreen> {
  ModuleSettingsModel? _settings;
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
    await provider.loadModuleSettings();
    
    if (!mounted) return;
    
    setState(() {
      _settings = provider.moduleSettings ?? ModuleSettingsModel();
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser == null) return;

    final provider = context.read<SettingsProvider>();
    final success = await provider.saveModuleSettings(_settings!, currentUser.id!);

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
      appBar: AppBar(title: const Text('Modules & Sécurité')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SettingSectionCard(
                    title: 'Modules',
                    icon: Icons.apps,
                    child: Column(
                      children: [
                        ...['ventes', 'recettes', 'stock', 'adherents', 'facturation']
                            .map((module) {
                          final isActive = _settings!.modulesActives[module] ?? true;
                          return SettingToggle(
                            label: 'Module ${module.capitalize()}',
                            value: isActive,
                            onChanged: (value) {
                              setState(() {
                                final newModules = Map<String, bool>.from(_settings!.modulesActives);
                                newModules[module] = value;
                                _settings = _settings!.copyWith(modulesActives: newModules);
                                _hasChanges = true;
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  SettingSectionCard(
                    title: 'Sécurité',
                    icon: Icons.security,
                    child: Column(
                      children: [
                        SettingToggle(
                          label: 'Verrouillage paramétrage',
                          description: 'Empêche la modification des paramètres sans autorisation',
                          value: _settings!.verrouillageParametrage,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(verrouillageParametrage: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        SettingToggle(
                          label: 'Audit & logs actifs',
                          value: _settings!.auditLogsActif,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(auditLogsActif: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        if (_settings!.auditLogsActif)
                          SettingNumberInput(
                            label: 'Durée de conservation des logs (jours)',
                            value: _settings!.dureeConservationLogsJours?.toDouble(),
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings!.copyWith(
                                  dureeConservationLogsJours: value?.toInt() ?? 365,
                                );
                                _hasChanges = true;
                              });
                            },
                            min: 30,
                            max: 3650,
                          ),
                        SettingToggle(
                          label: 'Authentification à deux facteurs',
                          value: _settings!.authentificationDoubleFacteur,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                authentificationDoubleFacteur: value,
                              );
                              _hasChanges = true;
                            });
                          },
                        ),
                        SettingNumberInput(
                          label: 'Durée de session (minutes)',
                          value: _settings!.dureeSessionMinutes?.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                dureeSessionMinutes: value?.toInt() ?? 30,
                              );
                              _hasChanges = true;
                            });
                          },
                          min: 5,
                          max: 480,
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

