import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/client_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/client_viewmodel.dart';
import '../../../config/routes/routes.dart';

class ClientFormScreen extends StatefulWidget {
  final int? clientId;

  const ClientFormScreen({super.key, this.clientId});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _raisonController = TextEditingController();
  final _responsableController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _paysController = TextEditingController(text: 'Cameroun');
  final _villeController = TextEditingController();
  final _nrcController = TextEditingController();
  final _ifuController = TextEditingController();
  final _plafondController = TextEditingController();

  String _typeClient = ClientModel.typeLocal;
  String _statut = ClientModel.statutActif;

  bool _initialized = false;

  void _closeOrGoToClients(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: false);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushNamed(AppRoutes.clients);
  }

  Future<void> _generateClientCode({
    required ClientViewModel clientVm,
    bool force = false,
  }) async {
    if (!force && _codeController.text.trim().isNotEmpty) return;

    final code = await clientVm.generateNextClientCode();
    if (!mounted) return;
    if (code == null) return;

    setState(() {
      _codeController.text = code;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _raisonController.dispose();
    _responsableController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _paysController.dispose();
    _villeController.dispose();
    _nrcController.dispose();
    _ifuController.dispose();
    _plafondController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ClientViewModel, AuthViewModel>(
      builder: (context, clientVm, authVm, child) {
        _tryInitFromSelected(clientVm);

        final isEdit = widget.clientId != null;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => _closeOrGoToClients(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? 'Modifier un client' : 'Créer un client',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const Spacer(),
                  if (clientVm.isLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildSectionTitle('Identité'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _codeController,
                              decoration: InputDecoration(
                                labelText: 'Code client*',
                                hintText: isEdit ? null : 'Auto',
                                suffixIcon: isEdit
                                    ? null
                                    : IconButton(
                                        tooltip: 'Générer un code',
                                        icon: const Icon(Icons.autorenew),
                                        onPressed: clientVm.isLoading
                                            ? null
                                            : () => _generateClientCode(
                                                clientVm: clientVm,
                                                force: true,
                                              ),
                                      ),
                              ),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (isEdit && value.isEmpty)
                                  return 'Code requis';
                                if (value.length < 2) return 'Code trop court';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _typeClient,
                              decoration: const InputDecoration(
                                labelText: 'Type*',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: ClientModel.typeLocal,
                                  child: Text('Acheteur local'),
                                ),
                                DropdownMenuItem(
                                  value: ClientModel.typeGrossiste,
                                  child: Text('Grossiste'),
                                ),
                                DropdownMenuItem(
                                  value: ClientModel.typeExportateur,
                                  child: Text('Exportateur'),
                                ),
                                DropdownMenuItem(
                                  value: ClientModel.typeIndustriel,
                                  child: Text('Industriel'),
                                ),
                                DropdownMenuItem(
                                  value: ClientModel.typeOccasionnel,
                                  child: Text('Occasionnel'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _typeClient = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _raisonController,
                        decoration: const InputDecoration(
                          labelText: 'Raison sociale*',
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Raison sociale requise';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _responsableController,
                              decoration: const InputDecoration(
                                labelText: 'Responsable',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _statut,
                              decoration: const InputDecoration(
                                labelText: 'Statut',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: ClientModel.statutActif,
                                  child: Text('Actif'),
                                ),
                                DropdownMenuItem(
                                  value: ClientModel.statutSuspendu,
                                  child: Text('Suspendu'),
                                ),
                                DropdownMenuItem(
                                  value: ClientModel.statutBloque,
                                  child: Text('Bloqué'),
                                ),
                                DropdownMenuItem(
                                  value: ClientModel.statutArchive,
                                  child: Text('Archivé'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _statut = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Contact'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _telephoneController,
                              decoration: const InputDecoration(
                                labelText: 'Téléphone',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _adresseController,
                        decoration: const InputDecoration(labelText: 'Adresse'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _villeController,
                              decoration: const InputDecoration(
                                labelText: 'Ville',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _paysController,
                              decoration: const InputDecoration(
                                labelText: 'Pays',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Informations légales'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nrcController,
                              decoration: const InputDecoration(
                                labelText: 'NRC',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _ifuController,
                              decoration: const InputDecoration(
                                labelText: 'IFU',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _plafondController,
                        decoration: const InputDecoration(
                          labelText: 'Plafond crédit (FCFA)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (clientVm.errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            clientVm.errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: clientVm.isLoading
                                  ? null
                                  : () => _onSubmit(
                                      context: context,
                                      clientVm: clientVm,
                                      authVm: authVm,
                                    ),
                              icon: const Icon(Icons.save),
                              label: Text(isEdit ? 'Enregistrer' : 'Créer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _tryInitFromSelected(ClientViewModel clientVm) {
    if (_initialized) return;
    if (widget.clientId == null) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateClientCode(clientVm: clientVm);
      });
      return;
    }

    final client = clientVm.selectedClient;
    if (client == null || client.id != widget.clientId) {
      // Charger si pas déjà chargé
      WidgetsBinding.instance.addPostFrameCallback((_) {
        clientVm.loadClientById(widget.clientId!);
      });
      return;
    }

    _codeController.text = client.codeClient;
    _raisonController.text = client.raisonSociale;
    _responsableController.text = client.nomResponsable ?? '';
    _telephoneController.text = client.telephone ?? '';
    _emailController.text = client.email ?? '';
    _adresseController.text = client.adresse ?? '';
    _paysController.text = client.pays ?? 'Cameroun';
    _villeController.text = client.ville ?? '';
    _nrcController.text = client.nrc ?? '';
    _ifuController.text = client.ifu ?? '';
    _plafondController.text = client.plafondCredit != null
        ? client.plafondCredit!.toString()
        : '';

    _typeClient = client.typeClient;
    _statut = client.statut;
    _initialized = true;
  }

  Future<void> _onSubmit({
    required BuildContext context,
    required ClientViewModel clientVm,
    required AuthViewModel authVm,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    final userId = authVm.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Utilisateur non connecté')));
      return;
    }

    final plafond = double.tryParse(
      _plafondController.text.trim().replaceAll(',', '.'),
    );

    final isEdit = widget.clientId != null;

    if (!isEdit && _codeController.text.trim().isEmpty) {
      await _generateClientCode(clientVm: clientVm, force: true);
      if (_codeController.text.trim().isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de générer un code client')),
        );
        return;
      }
    }

    bool ok;
    if (!isEdit) {
      ok = await clientVm.createClient(
        codeClient: _codeController.text.trim(),
        typeClient: _typeClient,
        raisonSociale: _raisonController.text.trim(),
        nomResponsable: _responsableController.text.trim().isEmpty
            ? null
            : _responsableController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty
            ? null
            : _telephoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        adresse: _adresseController.text.trim().isEmpty
            ? null
            : _adresseController.text.trim(),
        pays: _paysController.text.trim().isEmpty
            ? null
            : _paysController.text.trim(),
        ville: _villeController.text.trim().isEmpty
            ? null
            : _villeController.text.trim(),
        nrc: _nrcController.text.trim().isEmpty
            ? null
            : _nrcController.text.trim(),
        ifu: _ifuController.text.trim().isEmpty
            ? null
            : _ifuController.text.trim(),
        plafondCredit: plafond,
        createdBy: userId,
      );
    } else {
      ok = await clientVm.updateClient(
        id: widget.clientId!,
        codeClient: _codeController.text.trim(),
        typeClient: _typeClient,
        raisonSociale: _raisonController.text.trim(),
        nomResponsable: _responsableController.text.trim().isEmpty
            ? null
            : _responsableController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty
            ? null
            : _telephoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        adresse: _adresseController.text.trim().isEmpty
            ? null
            : _adresseController.text.trim(),
        pays: _paysController.text.trim().isEmpty
            ? null
            : _paysController.text.trim(),
        ville: _villeController.text.trim().isEmpty
            ? null
            : _villeController.text.trim(),
        nrc: _nrcController.text.trim().isEmpty
            ? null
            : _nrcController.text.trim(),
        ifu: _ifuController.text.trim().isEmpty
            ? null
            : _ifuController.text.trim(),
        plafondCredit: plafond,
        updatedBy: userId,
      );

      // Appliquer le statut via actions dédiées si nécessaire
      if (ok) {
        if (_statut == ClientModel.statutBloque &&
            clientVm.selectedClient?.statut != ClientModel.statutBloque) {
          await clientVm.bloquerClient(
            id: widget.clientId!,
            raison: 'Bloqué depuis le formulaire',
            blockedBy: userId,
          );
        } else if (_statut == ClientModel.statutSuspendu &&
            clientVm.selectedClient?.statut != ClientModel.statutSuspendu) {
          await clientVm.suspendreClient(
            id: widget.clientId!,
            raison: 'Suspendu depuis le formulaire',
            suspendedBy: userId,
          );
        } else if (_statut == ClientModel.statutActif &&
            clientVm.selectedClient?.statut != ClientModel.statutActif) {
          await clientVm.reactiverClient(
            id: widget.clientId!,
            reactivatedBy: userId,
          );
        }
      }
    }

    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Client mis à jour' : 'Client créé')),
      );
      _closeOrGoToClients(context);
    }
  }
}
