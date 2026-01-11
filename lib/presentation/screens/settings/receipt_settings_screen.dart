import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/settings/receipt_settings_model.dart';
import '../../widgets/settings/setting_section_card.dart';
import '../../widgets/settings/setting_toggle.dart';
import '../../widgets/settings/setting_number_input.dart';
import '../../widgets/settings/save_bar.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  ReceiptSettingsModel? _settings;
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
    await provider.loadReceiptSettings();
    
    if (!mounted) return;
    
    setState(() {
      _settings = provider.receiptSettings ?? ReceiptSettingsModel();
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser == null) return;

    final provider = context.read<SettingsProvider>();
    final success = await provider.saveReceiptSettings(_settings!, currentUser.id!);

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
      appBar: AppBar(title: const Text('Recettes & Commissions')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SettingSectionCard(
                    title: 'Commissions',
                    icon: Icons.payments,
                    child: Column(
                      children: [
                        SettingToggle(
                          label: 'Calcul automatique',
                          value: _settings!.calculAutomatique,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(calculAutomatique: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        if (_settings!.typesCommissions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Aucun type de commission configuré',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SettingSectionCard(
                    title: 'Retenues',
                    icon: Icons.account_balance_wallet,
                    child: Column(
                      children: [
                        SettingNumberInput(
                          label: 'Taux retenue sociale (%)',
                          value: _settings!.tauxRetenueSociale,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                tauxRetenueSociale: value ?? 0.0,
                              );
                              _hasChanges = true;
                            });
                          },
                          min: 0,
                          max: 100,
                          suffix: '%',
                          decimals: 2,
                        ),
                        SettingNumberInput(
                          label: 'Taux retenue capital (%)',
                          value: _settings!.tauxRetenueCapital,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                tauxRetenueCapital: value ?? 0.0,
                              );
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

