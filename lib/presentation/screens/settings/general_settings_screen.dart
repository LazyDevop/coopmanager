import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/settings/general_settings_model.dart';
import '../../widgets/settings/setting_section_card.dart';
import '../../widgets/settings/setting_toggle.dart';
import '../../widgets/settings/setting_select.dart';
import '../../widgets/settings/setting_number_input.dart';
import '../../widgets/settings/save_bar.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  GeneralSettingsModel? _settings;
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
    await provider.loadGeneralSettings();
    
    if (!mounted) return;
    
    setState(() {
      _settings = provider.generalSettings ?? GeneralSettingsModel();
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser == null) return;

    final provider = context.read<SettingsProvider>();
    final success = await provider.saveGeneralSettings(_settings!, currentUser.id!);

    if (!mounted) return;
    
    if (success) {
      setState(() => _hasChanges = false);
      // Utiliser la référence sauvegardée du ScaffoldMessenger
      // Vérifier que le widget est toujours monté avant d'afficher le SnackBar
      if (!mounted || _scaffoldMessenger == null) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Vérifier à nouveau que le widget est toujours monté
        if (!mounted || _scaffoldMessenger == null) return;
        
        try {
          // Vérifier que le ScaffoldMessenger est toujours valide et monté
          if (_scaffoldMessenger!.mounted) {
            _scaffoldMessenger!.showSnackBar(
              const SnackBar(content: Text('Paramètres sauvegardés')),
            );
          }
        } catch (e) {
          // Ignorer l'erreur si le contexte n'est plus valide
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
      appBar: AppBar(title: const Text('Paramètres Généraux')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SettingSectionCard(
                    title: 'Général',
                    icon: Icons.settings,
                    child: Column(
                      children: [
                        SettingSelect<String>(
                          label: 'Devise',
                          value: _settings!.devise,
                          options: [
                            SettingSelectOption(value: 'XAF', label: 'FCFA (XAF)'),
                            SettingSelectOption(value: 'XOF', label: 'FCFA (XOF)'),
                            SettingSelectOption(value: 'EUR', label: 'Euro'),
                            SettingSelectOption(value: 'USD', label: 'Dollar US'),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(devise: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        SettingSelect<String>(
                          label: 'Format de date',
                          value: _settings!.dateFormat,
                          options: [
                            SettingSelectOption(value: 'dd/MM/yyyy', label: 'JJ/MM/AAAA'),
                            SettingSelectOption(value: 'MM/dd/yyyy', label: 'MM/JJ/AAAA'),
                            SettingSelectOption(value: 'yyyy-MM-dd', label: 'AAAA-MM-JJ'),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(dateFormat: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        SettingSelect<String>(
                          label: 'Thème UI',
                          value: _settings!.uiTheme,
                          options: [
                            SettingSelectOption(value: 'light', label: 'Clair'),
                            SettingSelectOption(value: 'dark', label: 'Sombre'),
                            SettingSelectOption(value: 'auto', label: 'Automatique'),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(uiTheme: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        SettingNumberInput(
                          label: 'Durée de session (minutes)',
                          value: _settings!.sessionDurationMinutes.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                sessionDurationMinutes: value?.toInt() ?? 30,
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
                  SettingSectionCard(
                    title: 'Fonctionnalités',
                    icon: Icons.tune,
                    child: Column(
                      children: [
                        SettingToggle(
                          label: 'Mode hors ligne',
                          description: 'Permet d\'utiliser l\'application sans connexion',
                          value: _settings!.offlineMode,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(offlineMode: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        SettingToggle(
                          label: 'Notifications activées',
                          value: _settings!.notificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(notificationsEnabled: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        SettingToggle(
                          label: 'Sauvegarde automatique',
                          value: _settings!.autoBackup,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(autoBackup: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        if (_settings!.autoBackup)
                          SettingNumberInput(
                            label: 'Intervalle de sauvegarde (jours)',
                            value: _settings!.backupIntervalDays.toDouble(),
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings!.copyWith(
                                  backupIntervalDays: value?.toInt() ?? 7,
                                );
                                _hasChanges = true;
                              });
                            },
                            min: 1,
                            max: 30,
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

