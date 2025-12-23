import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/adherent/champ_parcelle_service.dart';
import '../../../data/models/adherent_expert/champ_parcelle_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class ChampParcelleFormScreen extends StatefulWidget {
  final int adherentId;
  final ChampParcelleModel? champ; // Si fourni, c'est une modification

  const ChampParcelleFormScreen({
    super.key,
    required this.adherentId,
    this.champ,
  });

  @override
  State<ChampParcelleFormScreen> createState() => _ChampParcelleFormScreenState();
}

class _ChampParcelleFormScreenState extends State<ChampParcelleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomChampController = TextEditingController();
  final _localisationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _superficieController = TextEditingController();
  final _anneeMiseEnCultureController = TextEditingController();
  final _rendementEstimeController = TextEditingController();
  final _campagneAgricoleController = TextEditingController();
  final _nombreArbresController = TextEditingController();
  final _ageMoyenArbresController = TextEditingController();
  final _notesController = TextEditingController();

  final ChampParcelleService _service = ChampParcelleService();

  String? _typeSol;
  String? _varieteCacao;
  String? _systemeIrrigation;
  String _etatChamp = 'actif';
  bool _isLoading = false;

  final List<String> _typesSol = [
    'argileux',
    'sableux',
    'limoneux',
    'volcanique',
    'autre',
  ];

  final List<String> _varietesCacao = [
    'forastero',
    'criollo',
    'trinitario',
    'hybride',
  ];

  final List<String> _systemesIrrigation = [
    'pluvial',
    'irrigue',
    'mixte',
  ];

  final List<String> _etatsChamp = [
    'actif',
    'repos',
    'abandonne',
    'en_preparation',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.champ != null) {
      _loadChampData();
    }
  }

  void _loadChampData() {
    final champ = widget.champ!;
    _nomChampController.text = champ.nomChamp ?? '';
    _localisationController.text = champ.localisation ?? '';
    _latitudeController.text = champ.latitude?.toString() ?? '';
    _longitudeController.text = champ.longitude?.toString() ?? '';
    _superficieController.text = champ.superficie.toString();
    _typeSol = champ.typeSol;
    _anneeMiseEnCultureController.text = champ.anneeMiseEnCulture?.toString() ?? '';
    _etatChamp = champ.etatChamp;
    _rendementEstimeController.text = champ.rendementEstime.toString();
    _campagneAgricoleController.text = champ.campagneAgricole ?? '';
    _varieteCacao = champ.varieteCacao;
    _nombreArbresController.text = champ.nombreArbres?.toString() ?? '';
    _ageMoyenArbresController.text = champ.ageMoyenArbres?.toString() ?? '';
    _systemeIrrigation = champ.systemeIrrigation;
    _notesController.text = champ.notes ?? '';
  }

  @override
  void dispose() {
    _nomChampController.dispose();
    _localisationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _superficieController.dispose();
    _anneeMiseEnCultureController.dispose();
    _rendementEstimeController.dispose();
    _campagneAgricoleController.dispose();
    _nombreArbresController.dispose();
    _ageMoyenArbresController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authViewModel = context.read<AuthViewModel>();
      final currentUser = authViewModel.currentUser;
      
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final superficie = double.tryParse(_superficieController.text.trim());
      if (superficie == null || superficie <= 0) {
        throw Exception('La superficie doit être supérieure à 0');
      }

      if (widget.champ == null) {
        // Création
        await _service.createChamp(
          adherentId: widget.adherentId,
          nomChamp: _nomChampController.text.trim().isEmpty 
              ? null 
              : _nomChampController.text.trim(),
          localisation: _localisationController.text.trim().isEmpty 
              ? null 
              : _localisationController.text.trim(),
          latitude: _latitudeController.text.trim().isEmpty 
              ? null 
              : double.tryParse(_latitudeController.text.trim()),
          longitude: _longitudeController.text.trim().isEmpty 
              ? null 
              : double.tryParse(_longitudeController.text.trim()),
          superficie: superficie,
          typeSol: _typeSol,
          anneeMiseEnCulture: _anneeMiseEnCultureController.text.trim().isEmpty 
              ? null 
              : int.tryParse(_anneeMiseEnCultureController.text.trim()),
          etatChamp: _etatChamp,
          rendementEstime: double.tryParse(_rendementEstimeController.text.trim()) ?? 0.0,
          campagneAgricole: _campagneAgricoleController.text.trim().isEmpty 
              ? null 
              : _campagneAgricoleController.text.trim(),
          varieteCacao: _varieteCacao,
          nombreArbres: _nombreArbresController.text.trim().isEmpty 
              ? null 
              : int.tryParse(_nombreArbresController.text.trim()),
          ageMoyenArbres: _ageMoyenArbresController.text.trim().isEmpty 
              ? null 
              : int.tryParse(_ageMoyenArbresController.text.trim()),
          systemeIrrigation: _systemeIrrigation,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
          createdBy: currentUser.id!,
        );
      } else {
        // Modification
        await _service.updateChamp(
          id: widget.champ!.id!,
          nomChamp: _nomChampController.text.trim().isEmpty 
              ? null 
              : _nomChampController.text.trim(),
          localisation: _localisationController.text.trim().isEmpty 
              ? null 
              : _localisationController.text.trim(),
          latitude: _latitudeController.text.trim().isEmpty 
              ? null 
              : double.tryParse(_latitudeController.text.trim()),
          longitude: _longitudeController.text.trim().isEmpty 
              ? null 
              : double.tryParse(_longitudeController.text.trim()),
          superficie: superficie,
          typeSol: _typeSol,
          anneeMiseEnCulture: _anneeMiseEnCultureController.text.trim().isEmpty 
              ? null 
              : int.tryParse(_anneeMiseEnCultureController.text.trim()),
          etatChamp: _etatChamp,
          rendementEstime: double.tryParse(_rendementEstimeController.text.trim()),
          campagneAgricole: _campagneAgricoleController.text.trim().isEmpty 
              ? null 
              : _campagneAgricoleController.text.trim(),
          varieteCacao: _varieteCacao,
          nombreArbres: _nombreArbresController.text.trim().isEmpty 
              ? null 
              : int.tryParse(_nombreArbresController.text.trim()),
          ageMoyenArbres: _ageMoyenArbresController.text.trim().isEmpty 
              ? null 
              : int.tryParse(_ageMoyenArbresController.text.trim()),
          systemeIrrigation: _systemeIrrigation,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
          updatedBy: currentUser.id!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.champ == null 
                ? 'Champ ajouté avec succès' 
                : 'Champ modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getLabel(String value, List<String> options) {
    return value.replaceAll('_', ' ').split(' ').map((word) {
      return word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.champ != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier le champ' : 'Ajouter un champ'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom du champ
              TextFormField(
                controller: _nomChampController,
                decoration: InputDecoration(
                  labelText: 'Nom du champ',
                  prefixIcon: const Icon(Icons.agriculture),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Ex: Champ Nord, Parcelle A',
                ),
              ),
              const SizedBox(height: 16),

              // Superficie (obligatoire)
              TextFormField(
                controller: _superficieController,
                decoration: InputDecoration(
                  labelText: 'Superficie (ha) *',
                  prefixIcon: const Icon(Icons.square_foot),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La superficie est requise';
                  }
                  final superficie = double.tryParse(value.trim());
                  if (superficie == null || superficie <= 0) {
                    return 'La superficie doit être supérieure à 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Localisation
              TextFormField(
                controller: _localisationController,
                decoration: InputDecoration(
                  labelText: 'Localisation',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Description de l\'emplacement',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Coordonnées GPS
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: const Icon(Icons.my_location),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: const Icon(Icons.my_location),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Type de sol
              DropdownButtonFormField<String>(
                value: _typeSol,
                decoration: InputDecoration(
                  labelText: 'Type de sol',
                  prefixIcon: const Icon(Icons.terrain),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _typesSol.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getLabel(type, _typesSol)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _typeSol = value);
                },
              ),
              const SizedBox(height: 16),

              // Année de mise en culture
              TextFormField(
                controller: _anneeMiseEnCultureController,
                decoration: InputDecoration(
                  labelText: 'Année de mise en culture',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // État du champ
              DropdownButtonFormField<String>(
                value: _etatChamp,
                decoration: InputDecoration(
                  labelText: 'État du champ *',
                  prefixIcon: const Icon(Icons.info),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _etatsChamp.map((etat) {
                  return DropdownMenuItem(
                    value: etat,
                    child: Text(_getLabel(etat, _etatsChamp)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _etatChamp = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Rendement estimé
              TextFormField(
                controller: _rendementEstimeController,
                decoration: InputDecoration(
                  labelText: 'Rendement estimé (t/ha)',
                  prefixIcon: const Icon(Icons.trending_up),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Campagne agricole
              TextFormField(
                controller: _campagneAgricoleController,
                decoration: InputDecoration(
                  labelText: 'Campagne agricole',
                  prefixIcon: const Icon(Icons.date_range),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Format: YYYY-YYYY (ex: 2023-2024)',
                ),
              ),
              const SizedBox(height: 16),

              // Variété de cacao
              DropdownButtonFormField<String>(
                value: _varieteCacao,
                decoration: InputDecoration(
                  labelText: 'Variété de cacao',
                  prefixIcon: const Icon(Icons.eco),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _varietesCacao.map((variete) {
                  return DropdownMenuItem(
                    value: variete,
                    child: Text(_getLabel(variete, _varietesCacao)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _varieteCacao = value);
                },
              ),
              const SizedBox(height: 16),

              // Nombre d'arbres
              TextFormField(
                controller: _nombreArbresController,
                decoration: InputDecoration(
                  labelText: 'Nombre d\'arbres',
                  prefixIcon: const Icon(Icons.park),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Âge moyen des arbres
              TextFormField(
                controller: _ageMoyenArbresController,
                decoration: InputDecoration(
                  labelText: 'Âge moyen des arbres (années)',
                  prefixIcon: const Icon(Icons.cake),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Système d'irrigation
              DropdownButtonFormField<String>(
                value: _systemeIrrigation,
                decoration: InputDecoration(
                  labelText: 'Système d\'irrigation',
                  prefixIcon: const Icon(Icons.water_drop),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _systemesIrrigation.map((systeme) {
                  return DropdownMenuItem(
                    value: systeme,
                    child: Text(_getLabel(systeme, _systemesIrrigation)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _systemeIrrigation = value);
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Bouton de soumission
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(isEdit ? 'Modifier' : 'Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

