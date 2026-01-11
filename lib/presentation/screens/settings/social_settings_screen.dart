import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/settings/social_settings_model.dart';
import '../../widgets/settings/setting_section_card.dart';
import '../../widgets/settings/setting_toggle.dart';
import '../../widgets/settings/save_bar.dart';
import '../social/social_aide_types_screen.dart';

class SocialSettingsScreen extends StatefulWidget {
  const SocialSettingsScreen({super.key});

  @override
  State<SocialSettingsScreen> createState() => _SocialSettingsScreenState();
}

class _SocialSettingsScreenState extends State<SocialSettingsScreen> {
  SocialSettingsModel? _settings;
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
    await provider.loadSocialSettings();
    
    if (!mounted) return;
    
    setState(() {
      _settings = provider.socialSettings ?? SocialSettingsModel();
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser == null) return;

    final provider = context.read<SettingsProvider>();
    final success = await provider.saveSocialSettings(_settings!, currentUser.id!);

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
      appBar: AppBar(title: const Text('Social')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SettingSectionCard(
                    title: 'Configuration sociale',
                    icon: Icons.people,
                    child: Column(
                      children: [
                        SettingToggle(
                          label: 'Validation requise',
                          description: 'Les aides sociales doivent être validées avant attribution',
                          value: _settings!.validationRequise,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings!.copyWith(validationRequise: value);
                              _hasChanges = true;
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('Gérer les types d\'aides'),
                          subtitle: const Text('Définir et configurer les types d\'aides sociales'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SocialAideTypesScreen(),
                              ),
                            );
                          },
                        ),
                        if (_settings!.typesAides.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Aucun type d\'aide configuré',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
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

