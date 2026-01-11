import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/settings/accounting_settings_model.dart';
import '../../widgets/settings/setting_section_card.dart';
import '../../widgets/settings/setting_input.dart';
import '../../widgets/settings/setting_number_input.dart';
import '../../widgets/settings/save_bar.dart';

class AccountingSettingsScreen extends StatefulWidget {
  const AccountingSettingsScreen({super.key});

  @override
  State<AccountingSettingsScreen> createState() => _AccountingSettingsScreenState();
}

class _AccountingSettingsScreenState extends State<AccountingSettingsScreen> {
  AccountingSettingsModel? _settings;
  bool _hasChanges = false;
  final _exerciceController = TextEditingController();
  final _compteCaisseController = TextEditingController();
  final _compteBanqueController = TextEditingController();
  final _compteVenteController = TextEditingController();
  final _compteRecetteController = TextEditingController();
  final _compteCommissionController = TextEditingController();
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
    await provider.loadAccountingSettings();
    
    if (!mounted) return;
    
    setState(() {
      _settings = provider.accountingSettings ?? AccountingSettingsModel();
      _exerciceController.text = _settings!.exerciceActif ?? '';
      _compteCaisseController.text = _settings!.compteCaisse ?? '';
      _compteBanqueController.text = _settings!.compteBanque ?? '';
      _compteVenteController.text = _settings!.compteVente ?? '';
      _compteRecetteController.text = _settings!.compteRecette ?? '';
      _compteCommissionController.text = _settings!.compteCommission ?? '';
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser == null) return;

    final updatedSettings = _settings!.copyWith(
      exerciceActif: _exerciceController.text.trim().isEmpty
          ? null
          : _exerciceController.text.trim(),
      compteCaisse: _compteCaisseController.text.trim().isEmpty
          ? null
          : _compteCaisseController.text.trim(),
      compteBanque: _compteBanqueController.text.trim().isEmpty
          ? null
          : _compteBanqueController.text.trim(),
      compteVente: _compteVenteController.text.trim().isEmpty
          ? null
          : _compteVenteController.text.trim(),
      compteRecette: _compteRecetteController.text.trim().isEmpty
          ? null
          : _compteRecetteController.text.trim(),
      compteCommission: _compteCommissionController.text.trim().isEmpty
          ? null
          : _compteCommissionController.text.trim(),
    );

    final provider = context.read<SettingsProvider>();
    final success = await provider.saveAccountingSettings(updatedSettings, currentUser.id!);

    if (!mounted) return;
    
    if (success) {
      setState(() {
        _hasChanges = false;
        _settings = updatedSettings;
      });
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
  void dispose() {
    _exerciceController.dispose();
    _compteCaisseController.dispose();
    _compteBanqueController.dispose();
    _compteVenteController.dispose();
    _compteRecetteController.dispose();
    _compteCommissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    if (_settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Comptabilité Simplifiée')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SettingSectionCard(
                    title: 'Exercice comptable',
                    icon: Icons.calendar_month,
                    child: Column(
                      children: [
                        SettingInput(
                          label: 'Exercice actif',
                          value: _exerciceController.text,
                          onChanged: (value) {
                            _exerciceController.text = value;
                            setState(() => _hasChanges = true);
                          },
                          hint: 'Ex: 2024',
                        ),
                        SettingNumberInput(
                          label: 'Solde initial caisse (FCFA)',
                          value: _settings!.soldeInitialCaisse,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                soldeInitialCaisse: value ?? 0.0,
                              );
                              _hasChanges = true;
                            });
                          },
                          suffix: 'FCFA',
                        ),
                        SettingNumberInput(
                          label: 'Solde initial banque (FCFA)',
                          value: _settings!.soldeInitialBanque,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(
                                soldeInitialBanque: value ?? 0.0,
                              );
                              _hasChanges = true;
                            });
                          },
                          suffix: 'FCFA',
                        ),
                      ],
                    ),
                  ),
                  SettingSectionCard(
                    title: 'Taux et réserves',
                    icon: Icons.percent,
                    child: Column(
                      children: [
                        SettingNumberInput(
                          label: 'Taux frais de gestion (%)',
                          value: _settings!.tauxFraisGestion,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(tauxFraisGestion: value ?? 0.0);
                              _hasChanges = true;
                            });
                          },
                          suffix: '%',
                          decimals: 2,
                        ),
                        SettingNumberInput(
                          label: 'Taux réserve (%)',
                          value: _settings!.tauxReserve,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(tauxReserve: value ?? 0.0);
                              _hasChanges = true;
                            });
                          },
                          suffix: '%',
                          decimals: 2,
                        ),
                      ],
                    ),
                  ),
                  SettingSectionCard(
                    title: 'Comptes par défaut',
                    icon: Icons.account_tree,
                    child: Column(
                      children: [
                        SettingInput(
                          label: 'Compte Caisse',
                          value: _compteCaisseController.text,
                          onChanged: (value) {
                            _compteCaisseController.text = value;
                            setState(() => _hasChanges = true);
                          },
                        ),
                        SettingInput(
                          label: 'Compte Banque',
                          value: _compteBanqueController.text,
                          onChanged: (value) {
                            _compteBanqueController.text = value;
                            setState(() => _hasChanges = true);
                          },
                        ),
                        SettingInput(
                          label: 'Compte Vente',
                          value: _compteVenteController.text,
                          onChanged: (value) {
                            _compteVenteController.text = value;
                            setState(() => _hasChanges = true);
                          },
                        ),
                        SettingInput(
                          label: 'Compte Recette',
                          value: _compteRecetteController.text,
                          onChanged: (value) {
                            _compteRecetteController.text = value;
                            setState(() => _hasChanges = true);
                          },
                        ),
                        SettingInput(
                          label: 'Compte Commission',
                          value: _compteCommissionController.text,
                          onChanged: (value) {
                            _compteCommissionController.text = value;
                            setState(() => _hasChanges = true);
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

