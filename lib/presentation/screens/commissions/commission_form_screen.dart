/// Écran de formulaire pour créer/modifier une commission
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/commission_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/commission_model.dart';

class CommissionFormScreen extends StatefulWidget {
  final CommissionModel? commission;

  const CommissionFormScreen({super.key, this.commission});

  @override
  State<CommissionFormScreen> createState() => _CommissionFormScreenState();
}

class _CommissionFormScreenState extends State<CommissionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _libelleController = TextEditingController();
  final _montantController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _periodeReconductionController = TextEditingController();

  CommissionTypeApplication _typeApplication = CommissionTypeApplication.parKg;
  DateTime _dateDebut = DateTime.now();
  DateTime? _dateFin;
  bool _reconductible = false;
  bool _isLoading = false;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _loadCommissionData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
  }

  void _loadCommissionData() {
    if (widget.commission != null) {
      final c = widget.commission!;
      _codeController.text = c.code;
      _libelleController.text = c.libelle;
      _montantController.text = c.montantFixe.toStringAsFixed(0);
      _descriptionController.text = c.description ?? '';
      _typeApplication = c.typeApplication;
      _dateDebut = c.dateDebut;
      _dateFin = c.dateFin;
      _reconductible = c.reconductible;
      _periodeReconductionController.text =
          c.periodeReconductionDays?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _libelleController.dispose();
    _montantController.dispose();
    _descriptionController.dispose();
    _periodeReconductionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateDebut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateDebut,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dateDebut = picked);
    }
  }

  Future<void> _selectDateFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFin ?? _dateDebut.add(const Duration(days: 30)),
      firstDate: _dateDebut,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dateFin = picked);
    }
  }

  Future<void> _saveCommission() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<CommissionViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final montantFixe = double.tryParse(_montantController.text);
    if (montantFixe == null || montantFixe <= 0) {
      setState(() => _isLoading = false);
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          const SnackBar(content: Text('Montant invalide')),
        );
      }
      return;
    }

    final periodeReconduction = _reconductible
        ? int.tryParse(_periodeReconductionController.text)
        : null;

    final commission = CommissionModel(
      id: widget.commission?.id,
      code: _codeController.text.trim().toUpperCase(),
      libelle: _libelleController.text.trim(),
      montantFixe: montantFixe,
      typeApplication: _typeApplication,
      dateDebut: _dateDebut,
      dateFin: _dateFin,
      reconductible: _reconductible,
      periodeReconductionDays: periodeReconduction,
      statut: widget.commission?.statut ?? CommissionStatut.active,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      createdAt: widget.commission?.createdAt ?? DateTime.now(),
      createdBy: widget.commission?.createdBy ?? currentUser.id,
    );

    final success = widget.commission == null
        ? await viewModel.createCommission(
            commission: commission,
            userId: currentUser.id!,
          )
        : await viewModel.updateCommission(
            commission: commission,
            userId: currentUser.id!,
          );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      if (_scaffoldMessenger != null && _scaffoldMessenger!.mounted) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text(widget.commission == null
                ? 'Commission créée avec succès'
                : 'Commission mise à jour avec succès'),
          ),
        );
      }
      Navigator.of(context).pop();
    } else {
      if (_scaffoldMessenger != null && _scaffoldMessenger!.mounted) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Erreur lors de la sauvegarde'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.commission == null
            ? 'Nouvelle commission'
            : 'Modifier la commission'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Code *',
                hintText: 'Ex: TRANSPORT',
                helperText: 'Code unique en majuscules',
              ),
              textCapitalization: TextCapitalization.characters,
              enabled: widget.commission == null,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le code est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _libelleController,
              decoration: const InputDecoration(
                labelText: 'Libellé *',
                hintText: 'Ex: Commission Transport',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le libellé est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montantController,
              decoration: const InputDecoration(
                labelText: 'Montant fixe (FCFA) *',
                hintText: 'Ex: 25',
                suffixText: 'FCFA',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le montant est obligatoire';
                }
                final montant = double.tryParse(value);
                if (montant == null || montant <= 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CommissionTypeApplication>(
              initialValue: _typeApplication,
              decoration: const InputDecoration(
                labelText: 'Type d\'application *',
              ),
              items: CommissionTypeApplication.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type == CommissionTypeApplication.parKg
                      ? 'Par kilogramme'
                      : 'Par vente'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _typeApplication = value);
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date de début *'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_dateDebut)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDateDebut,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Commission permanente'),
              subtitle: Text(_dateFin == null
                  ? 'Sans date de fin'
                  : 'Se termine le ${DateFormat('dd/MM/yyyy').format(_dateFin!)}'),
              value: _dateFin == null,
              onChanged: (value) {
                setState(() => _dateFin = value ? null : _dateDebut.add(const Duration(days: 30)));
              },
            ),
            if (_dateFin != null) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Date de fin'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_dateFin!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDateFin,
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Reconductible'),
              subtitle: const Text('Reconduction automatique à l\'expiration'),
              value: _reconductible,
              onChanged: (value) {
                setState(() => _reconductible = value);
              },
            ),
            if (_reconductible) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _periodeReconductionController,
                decoration: const InputDecoration(
                  labelText: 'Période de reconduction (jours)',
                  hintText: 'Ex: 183',
                  helperText: 'Nombre de jours pour la nouvelle période',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_reconductible &&
                      (value == null || value.trim().isEmpty)) {
                    return 'La période est obligatoire si reconductible';
                  }
                  if (value != null && value.trim().isNotEmpty) {
                    final jours = int.tryParse(value);
                    if (jours == null || jours <= 0) {
                      return 'Nombre de jours invalide';
                    }
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description optionnelle',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveCommission,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.commission == null
                      ? 'Créer la commission'
                      : 'Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }
}


