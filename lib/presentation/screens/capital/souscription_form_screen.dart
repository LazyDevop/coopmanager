import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/models/adherent_model.dart';
import '../../../data/models/capital_social_model.dart';
import '../../../services/adherent/adherent_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/capital_viewmodel.dart';

class SouscriptionFormScreen extends StatefulWidget {
  const SouscriptionFormScreen({super.key});

  @override
  State<SouscriptionFormScreen> createState() => _SouscriptionFormScreenState();
}

class _SouscriptionFormScreenState extends State<SouscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombrePartsController = TextEditingController();
  final _notesController = TextEditingController();

  final _actionnaireController = TextEditingController();

  ActionnaireModel? _selectedActionnaire;
  DateTime _dateSouscription = DateTime.now();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<CapitalViewModel>();
      if (vm.actionnaires.isEmpty) {
        await vm.loadActionnaires(ignoreFilters: true);
      }
      if (vm.valeurPartActuelle <= 0) {
        await vm.loadStatistiquesCapital();
      }
    });
  }

  @override
  void dispose() {
    _nombrePartsController.dispose();
    _notesController.dispose();
    _actionnaireController.dispose();
    super.dispose();
  }

  String _norm(String? v) => (v ?? '').toLowerCase().trim();

  bool _matchesActionnaire(ActionnaireModel a, String rawQuery) {
    final q = _norm(rawQuery);
    if (q.isEmpty) return true;

    final haystack = <String?>[
      a.codeActionnaire,
      a.adherentCode,
      a.adherentNom,
      a.adherentPrenom,
      a.adherentTelephone,
    ].map(_norm).join(' ');

    return haystack.contains(q);
  }

  String _displayActionnaire(ActionnaireModel a) {
    final name = a.adherentDisplayName;
    if (name == a.codeActionnaire) return a.codeActionnaire;
    return '$name (${a.codeActionnaire})';
  }

  Future<ActionnaireModel?> _ensureActionnaireForAdherent(
    CapitalViewModel vm,
    AdherentModel adherent,
  ) async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user?.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur non connecté'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    final ok = await vm.createActionnaire(
      adherentId: adherent.id!,
      codeActionnaire: adherent.code,
      dateEntree: DateTime.now(),
      createdBy: user!.id!,
    );

    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              vm.errorMessage ?? 'Impossible de créer l\'actionnaire',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    await vm.loadActionnaires(ignoreFilters: true);
    try {
      return vm.actionnaires.firstWhere((a) => a.adherentId == adherent.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickActionnaire(CapitalViewModel vm) async {
    if (vm.actionnaires.isEmpty && !vm.isLoading) {
      await vm.loadActionnaires(ignoreFilters: true);
    }

    final picked = await showModalBottomSheet<ActionnaireModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final adherentService = AdherentService();
        final searchController = TextEditingController();
        String query = '';

        bool isSearchingAdherents = false;
        String? adherentError;
        List<AdherentModel> adherentResults = [];
        int adherentSearchToken = 0;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = query.trim().isEmpty
                ? vm.actionnaires
                : vm.actionnaires
                      .where((a) => _matchesActionnaire(a, query))
                      .toList();

            Future<void> searchAdherents(String q) async {
              final trimmed = q.trim();
              if (trimmed.length < 2) {
                setModalState(() {
                  adherentError = null;
                  adherentResults = [];
                  isSearchingAdherents = false;
                });
                return;
              }

              final token = ++adherentSearchToken;
              setModalState(() {
                isSearchingAdherents = true;
                adherentError = null;
              });

              try {
                final results = await adherentService.searchAdherents(trimmed);
                if (token != adherentSearchToken) return;
                setModalState(() {
                  adherentResults = results;
                  isSearchingAdherents = false;
                });
              } catch (e) {
                if (token != adherentSearchToken) return;
                setModalState(() {
                  adherentError = e.toString();
                  adherentResults = [];
                  isSearchingAdherents = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sélectionner un actionnaire',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par code / nom / téléphone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        query = value;
                      });

                      // Si aucun actionnaire ne correspond, on propose la recherche adhérents
                      searchAdherents(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: vm.isLoading && vm.actionnaires.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : (vm.errorMessage != null && vm.actionnaires.isEmpty)
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  vm.errorMessage!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await vm.loadActionnaires(
                                      ignoreFilters: true,
                                    );
                                    setModalState(() {});
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Rafraîchir'),
                                ),
                              ],
                            ),
                          )
                        : filtered.isNotEmpty
                        ? ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final a = filtered[index];
                              final selected = _selectedActionnaire?.id == a.id;
                              return ListTile(
                                dense: true,
                                title: Text(_displayActionnaire(a)),
                                subtitle: Text(
                                  'Statut: ${a.statutLabel}'
                                  '${a.adherentTelephone == null || a.adherentTelephone!.trim().isEmpty ? '' : ' • Tél: ${a.adherentTelephone}'}',
                                ),
                                trailing: selected
                                    ? const Icon(Icons.check)
                                    : null,
                                onTap: () => Navigator.of(context).pop(a),
                              );
                            },
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 24),
                              const Text('Aucun actionnaire trouvé'),
                              const SizedBox(height: 12),
                              if (isSearchingAdherents)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                )
                              else if (adherentError != null)
                                Text(
                                  adherentError!,
                                  textAlign: TextAlign.center,
                                )
                              else if (query.trim().length < 2)
                                const Text(
                                  'Saisissez au moins 2 caractères pour rechercher un adhérent',
                                  textAlign: TextAlign.center,
                                )
                              else if (adherentResults.isEmpty)
                                const Text(
                                  'Aucun adhérent trouvé',
                                  textAlign: TextAlign.center,
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.amber.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const Text(
                                          "Cet adhérent n’est pas encore actionnaire.",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Sélectionnez un adhérent ci-dessous pour le créer automatiquement comme actionnaire.',
                                        ),
                                        if (adherentResults.length == 1) ...[
                                          const SizedBox(height: 10),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              final adh = adherentResults.first;
                                              if (adh.id == null) return;
                                              final created =
                                                  await _ensureActionnaireForAdherent(
                                                    vm,
                                                    adh,
                                                  );
                                              if (created != null &&
                                                  context.mounted) {
                                                Navigator.of(
                                                  context,
                                                ).pop(created);
                                              }
                                            },
                                            icon: const Icon(Icons.add),
                                            label: Text(
                                              'Créer actionnaire (${adherentResults.first.code})',
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: adherentResults.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final adh = adherentResults[index];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.person),
                                      title: Text(
                                        '${adh.prenom} ${adh.nom}'.trim(),
                                      ),
                                      subtitle: Text(
                                        '${adh.code}${adh.telephone == null || adh.telephone!.trim().isEmpty ? '' : ' • ${adh.telephone}'}',
                                      ),
                                      trailing: const Icon(Icons.arrow_forward),
                                      onTap: () async {
                                        if (adh.id == null) return;
                                        final created =
                                            await _ensureActionnaireForAdherent(
                                              vm,
                                              adh,
                                            );
                                        if (created != null &&
                                            context.mounted) {
                                          Navigator.of(context).pop(created);
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedActionnaire = picked;
      _actionnaireController.text = _displayActionnaire(picked);
    });
  }

  double _valeurPart(CapitalViewModel vm) {
    if (vm.valeurPartActuelle > 0) return vm.valeurPartActuelle;
    return 5000.0;
  }

  int _nombreParts() {
    return int.tryParse(_nombrePartsController.text.trim()) ?? 0;
  }

  double _montantSouscrit(CapitalViewModel vm) {
    final nombre = _nombreParts();
    if (nombre <= 0) return 0;
    return nombre * _valeurPart(vm);
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final vm = context.read<CapitalViewModel>();
    final auth = context.read<AuthViewModel>();
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur non connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedActionnaire == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un actionnaire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nombreParts = _nombreParts();
    if (nombreParts <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nombre de parts doit être supérieur à 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final ok = await vm.createSouscription(
        actionnaireId: _selectedActionnaire!.id!,
        nombreParts: nombreParts,
        dateSouscription: _dateSouscription,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdBy: user.id!,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Souscription créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage ?? 'Erreur lors de la création'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CapitalViewModel>();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0');
    final valeurPart = _valeurPart(vm);
    final montant = _montantSouscrit(vm);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle souscription'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Actionnaire
              TextFormField(
                controller: _actionnaireController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Actionnaire *',
                  prefixIcon: const Icon(Icons.account_circle),
                  suffixIcon: IconButton(
                    tooltip: 'Choisir',
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: _submitting ? null : () => _pickActionnaire(vm),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Sélection obligatoire (pas de saisie libre)',
                ),
                onTap: _submitting ? null : () => _pickActionnaire(vm),
                validator: (_) {
                  if (_selectedActionnaire == null) {
                    return 'Veuillez sélectionner un actionnaire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nombre de parts
              TextFormField(
                controller: _nombrePartsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nombre de parts *',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final v = int.tryParse((value ?? '').trim());
                  if (v == null || v <= 0) {
                    return 'Veuillez saisir un nombre de parts > 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: _submitting
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateSouscription,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _dateSouscription = picked);
                        }
                      },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de souscription *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(dateFormat.format(_dateSouscription)),
                ),
              ),
              const SizedBox(height: 16),

              // Valeur part + montant
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.brown.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.brown.shade100),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Valeur part: ${numberFormat.format(valeurPart)} FCFA',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.brown.shade800,
                        ),
                      ),
                    ),
                    Text(
                      'Montant: ${numberFormat.format(montant)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (optionnel)',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_submitting ? 'Enregistrement...' : 'Enregistrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
