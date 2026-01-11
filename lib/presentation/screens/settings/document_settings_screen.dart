import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/settings/document_settings_model.dart';
import '../../widgets/settings/setting_section_card.dart';
import '../../widgets/settings/setting_toggle.dart';
import '../../widgets/settings/setting_input.dart';
import '../../widgets/settings/setting_select.dart';
import '../../widgets/settings/save_bar.dart';

class DocumentSettingsScreen extends StatefulWidget {
  const DocumentSettingsScreen({super.key});

  @override
  State<DocumentSettingsScreen> createState() => _DocumentSettingsScreenState();
}

class _DocumentSettingsScreenState extends State<DocumentSettingsScreen> {
  DocumentSettingsModel? _settings;
  bool _hasChanges = false;
  final _mentionsController = TextEditingController();
  final _qrCodeUrlController = TextEditingController();
  String? _selectedQrCodeFormat;
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
    await provider.loadDocumentSettings();
    
    if (!mounted) return;
    
    setState(() {
      _settings = provider.documentSettings ?? DocumentSettingsModel();
      _mentionsController.text = _settings!.mentionsLegales ?? '';
      _qrCodeUrlController.text = _settings!.qrCodeUrlBase ?? '';
      _selectedQrCodeFormat = _settings!.qrCodeFormat ?? 'url';
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser == null) return;

    final updatedSettings = _settings!.copyWith(
      mentionsLegales: _mentionsController.text.trim().isEmpty
          ? null
          : _mentionsController.text.trim(),
      qrCodeUrlBase: _qrCodeUrlController.text.trim().isEmpty
          ? null
          : _qrCodeUrlController.text.trim(),
      qrCodeFormat: _selectedQrCodeFormat,
    );

    final provider = context.read<SettingsProvider>();
    final success = await provider.saveDocumentSettings(updatedSettings, currentUser.id!);

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
    _mentionsController.dispose();
    _qrCodeUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    if (_settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Documents & QR Code')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SettingSectionCard(
                    title: 'Configuration documents',
                    icon: Icons.description,
                    child: Column(
                      children: [
                        SettingInput(
                          label: 'Mentions légales',
                          value: _mentionsController.text,
                          onChanged: (value) {
                            _mentionsController.text = value;
                            setState(() => _hasChanges = true);
                          },
                          maxLines: 5,
                          description: 'Texte à afficher sur les documents',
                        ),
                        SettingToggle(
                          label: 'Signature automatique',
                          value: _settings!.signatureAutomatique,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(signatureAutomatique: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SettingSectionCard(
                    title: 'QR Code',
                    icon: Icons.qr_code,
                    child: Column(
                      children: [
                        SettingToggle(
                          label: 'QR Code actif',
                          value: _settings!.qrCodeActif,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(qrCodeActif: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        if (_settings!.qrCodeActif) ...[
                          SettingSelect<String>(
                            label: 'Format QR Code',
                            value: _selectedQrCodeFormat,
                            options: [
                              SettingSelectOption(value: 'url', label: 'URL (recommandé)'),
                              SettingSelectOption(value: 'json', label: 'JSON'),
                              SettingSelectOption(value: 'custom', label: 'Personnalisé'),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedQrCodeFormat = value;
                                _settings = _settings!.copyWith(qrCodeFormat: value);
                                _hasChanges = true;
                              });
                            },
                            description: 'Format d\'encodage du QR Code',
                          ),
                          SettingInput(
                            label: 'URL de base pour QR Code',
                            value: _qrCodeUrlController.text,
                            onChanged: (value) {
                              _qrCodeUrlController.text = value;
                              setState(() => _hasChanges = true);
                            },
                            hint: 'https://example.com/verify/',
                            description: _selectedQrCodeFormat == 'url' 
                                ? 'URL de vérification des documents'
                                : 'Optionnel si format JSON',
                          ),
                        ],
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

