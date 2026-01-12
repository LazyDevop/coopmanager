import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../providers/settings_provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/settings/cooperative_settings_model.dart';
import '../../widgets/settings/setting_section_card.dart';
import '../../widgets/settings/setting_input.dart';
import '../../widgets/settings/setting_select.dart';
import '../../widgets/settings/save_bar.dart';
import '../../widgets/settings/setting_history_dialog.dart';

/// Écran 1 - Informations de la Coopérative
class CooperativeSettingsScreen extends StatefulWidget {
  const CooperativeSettingsScreen({super.key});

  @override
  State<CooperativeSettingsScreen> createState() => _CooperativeSettingsScreenState();
}

class _CooperativeSettingsScreenState extends State<CooperativeSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _raisonSocialeController = TextEditingController();
  final _sigleController = TextEditingController();
  final _formeJuridiqueController = TextEditingController();
  final _numeroAgrementController = TextEditingController();
  final _rccmController = TextEditingController();
  final _adresseController = TextEditingController();
  final _regionController = TextEditingController();
  final _departementController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _dateCreation;
  File? _selectedLogoFile;
  String? _logoPath;
  bool _hasChanges = false;
  bool _isLoading = false;
  String? _lastLoadedRaisonSociale;
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
    
    // S'assurer que le service est initialisé
    try {
      await provider.initialize(null);
    } catch (e) {
      print('⚠️ Erreur lors de l\'initialisation du provider: $e');
    }
    
    await provider.loadCooperativeSettings();

    if (!mounted) return;
    
    final settings = provider.cooperativeSettings;
    if (settings != null) {
      print('📥 Chargement des paramètres dans l\'écran: ${settings.raisonSociale}');
      setState(() {
        _raisonSocialeController.text = settings.raisonSociale;
        _sigleController.text = settings.sigle ?? '';
        _formeJuridiqueController.text = settings.formeJuridique ?? '';
        _numeroAgrementController.text = settings.numeroAgrement ?? '';
        _rccmController.text = settings.rccm ?? '';
        _dateCreation = settings.dateCreation;
        _adresseController.text = settings.adresse ?? '';
        _regionController.text = settings.region ?? '';
        _departementController.text = settings.departement ?? '';
        _telephoneController.text = settings.telephone ?? '';
        _emailController.text = settings.email ?? '';
        _logoPath = settings.logoPath;
        _lastLoadedRaisonSociale = settings.raisonSociale;
        _hasChanges = false;
      });
      print('✅ Paramètres chargés dans les champs du formulaire');
    } else {
      print('⚠️ Aucun paramètre trouvé dans le provider');
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedLogoFile = File(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection du logo: $e')),
        );
      }
    }
  }

  Future<void> _selectDateCreation() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateCreation ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dateCreation = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      final currentUser = authViewModel.currentUser;
      if (currentUser == null) return;

      final provider = context.read<SettingsProvider>();
      final currentSettings = provider.cooperativeSettings;

      String? finalLogoPath = _logoPath;
      if (_selectedLogoFile != null) {
        // Copier le logo vers le répertoire de l'application
        finalLogoPath = await _copyLogoFile(_selectedLogoFile!);
      }

      final settings = CooperativeSettingsModel(
        id: currentSettings?.id,
        raisonSociale: _raisonSocialeController.text.trim(),
        sigle: _sigleController.text.trim().isEmpty ? null : _sigleController.text.trim(),
        formeJuridique: _formeJuridiqueController.text.trim().isEmpty
            ? null
            : _formeJuridiqueController.text.trim(),
        numeroAgrement: _numeroAgrementController.text.trim().isEmpty
            ? null
            : _numeroAgrementController.text.trim(),
        rccm: _rccmController.text.trim().isEmpty ? null : _rccmController.text.trim(),
        dateCreation: _dateCreation,
        adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
        region: _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
        departement: _departementController.text.trim().isEmpty
            ? null
            : _departementController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty
            ? null
            : _telephoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        devise: currentSettings?.devise ?? 'XOF',
        langue: currentSettings?.langue ?? 'fr',
        logoPath: finalLogoPath,
        isActive: currentSettings?.isActive ?? true,
        updatedBy: currentUser.id,
      );

      final success = await provider.saveCooperativeSettings(settings, currentUser.id!);

      if (!mounted) return;
      
      if (success) {
        // Recharger les paramètres depuis la base de données
        await provider.loadCooperativeSettings();
        
        if (!mounted) return;
        
        setState(() {
          _hasChanges = false;
          _selectedLogoFile = null;
          _logoPath = finalLogoPath;
        });
        
        // Recharger les données dans les champs
        await _loadSettings();
        
        if (!mounted) return;
        
        if (!mounted || _scaffoldMessenger == null) return;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _scaffoldMessenger == null) return;
          
          try {
            if (_scaffoldMessenger!.mounted) {
              _scaffoldMessenger!.showSnackBar(
                const SnackBar(content: Text('Paramètres sauvegardés avec succès')),
              );
            }
          } catch (e) {
            debugPrint('Erreur affichage SnackBar: $e');
          }
        });
      } else {
        if (!mounted || _scaffoldMessenger == null) return;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _scaffoldMessenger == null) return;
          
          try {
            if (_scaffoldMessenger!.mounted) {
              _scaffoldMessenger!.showSnackBar(
                SnackBar(content: Text(provider.errorMessage ?? 'Erreur lors de la sauvegarde')),
              );
            }
          } catch (e) {
            debugPrint('Erreur affichage SnackBar: $e');
          }
        });
      }
    } catch (e) {
      if (!mounted || _scaffoldMessenger == null) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _scaffoldMessenger == null) return;
        
        try {
          if (_scaffoldMessenger!.mounted) {
            _scaffoldMessenger!.showSnackBar(
              SnackBar(content: Text('Erreur: $e')),
            );
          }
        } catch (err) {
          debugPrint('Erreur affichage SnackBar: $err');
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _copyLogoFile(File sourceFile) async {
    // Implémenter la copie du fichier vers le répertoire de l'application
    // Pour l'instant, retourner le chemin source
    return sourceFile.path;
  }

  void _showHistory() async {
    final provider = context.read<SettingsProvider>();
    final history = await provider.getSettingHistory(category: 'cooperative');
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => SettingHistoryDialog(
          history: history,
          category: 'cooperative',
          settingKey: null,
        ),
      );
    }
  }

  @override
  void dispose() {
    _raisonSocialeController.dispose();
    _sigleController.dispose();
    _formeJuridiqueController.dispose();
    _numeroAgrementController.dispose();
    _rccmController.dispose();
    _adresseController.dispose();
    _regionController.dispose();
    _departementController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final settings = provider.cooperativeSettings;

    // Mettre à jour automatiquement les contrôleurs quand les paramètres changent dans le Provider
    // (seulement si pas de modifications en cours par l'utilisateur)
    if (settings != null && !_hasChanges && _lastLoadedRaisonSociale != settings.raisonSociale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasChanges) {
          _raisonSocialeController.text = settings.raisonSociale;
          _sigleController.text = settings.sigle ?? '';
          _formeJuridiqueController.text = settings.formeJuridique ?? '';
          _numeroAgrementController.text = settings.numeroAgrement ?? '';
          _rccmController.text = settings.rccm ?? '';
          _dateCreation = settings.dateCreation;
          _adresseController.text = settings.adresse ?? '';
          _regionController.text = settings.region ?? '';
          _departementController.text = settings.departement ?? '';
          _telephoneController.text = settings.telephone ?? '';
          _emailController.text = settings.email ?? '';
          _logoPath = settings.logoPath;
          _lastLoadedRaisonSociale = settings.raisonSociale;
        }
      });
    }

    // Recharger automatiquement si les paramètres sont chargés mais les champs sont vides
    if (settings != null && _raisonSocialeController.text.isEmpty && !provider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasChanges) {
          _loadSettings();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations de la Coopérative'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
            tooltip: 'Historique',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        onChanged: () {
          if (!_hasChanges) {
            setState(() {
              _hasChanges = true;
            });
          }
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SettingSectionCard(
                      title: 'Informations générales',
                      icon: Icons.business,
                      child: Column(
                        children: [
                          SettingInput(
                            label: 'Raison sociale',
                            value: _raisonSocialeController.text,
                            onChanged: (value) {
                              _raisonSocialeController.text = value;
                            },
                            required: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La raison sociale est obligatoire';
                              }
                              return null;
                            },
                          ),
                          SettingInput(
                            label: 'Sigle',
                            value: _sigleController.text,
                            onChanged: (value) => _sigleController.text = value,
                          ),
                          SettingInput(
                            label: 'Forme juridique',
                            value: _formeJuridiqueController.text,
                            onChanged: (value) => _formeJuridiqueController.text = value,
                          ),
                          SettingInput(
                            label: 'Numéro d\'agrément',
                            value: _numeroAgrementController.text,
                            onChanged: (value) => _numeroAgrementController.text = value,
                          ),
                          SettingInput(
                            label: 'RCCM',
                            value: _rccmController.text,
                            onChanged: (value) => _rccmController.text = value,
                          ),
                          InkWell(
                            onTap: _selectDateCreation,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date de création',
                                suffixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _dateCreation != null
                                    ? DateFormat('dd/MM/yyyy').format(_dateCreation!)
                                    : 'Sélectionner une date',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    SettingSectionCard(
                      title: 'Adresse et contacts',
                      icon: Icons.location_on,
                      child: Column(
                        children: [
                          SettingInput(
                            label: 'Adresse complète',
                            value: _adresseController.text,
                            onChanged: (value) => _adresseController.text = value,
                            maxLines: 3,
                          ),
                          SettingInput(
                            label: 'Région',
                            value: _regionController.text,
                            onChanged: (value) => _regionController.text = value,
                          ),
                          SettingInput(
                            label: 'Département',
                            value: _departementController.text,
                            onChanged: (value) => _departementController.text = value,
                          ),
                          SettingInput(
                            label: 'Téléphone',
                            value: _telephoneController.text,
                            onChanged: (value) => _telephoneController.text = value,
                            keyboardType: TextInputType.phone,
                          ),
                          SettingInput(
                            label: 'Email',
                            value: _emailController.text,
                            onChanged: (value) => _emailController.text = value,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  !value.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SettingSectionCard(
                      title: 'Logo',
                      icon: Icons.image,
                      child: Column(
                        children: [
                          if (_logoPath != null || _selectedLogoFile != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Image.file(
                                _selectedLogoFile ?? File(_logoPath!),
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: _pickLogo,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Choisir un logo'),
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
              isSaving: _isLoading || provider.isLoading,
              onSave: _saveSettings,
              onCancel: () {
                setState(() {
                  _hasChanges = false;
                  _selectedLogoFile = null;
                });
                _loadSettings();
              },
              errorMessage: provider.errorMessage,
            ),
          ],
        ),
      ),
    );
  }
}

