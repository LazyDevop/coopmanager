import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/paiement/paiement_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/paiement_model.dart';

class PaiementFormScreen extends StatefulWidget {
  final int adherentId;
  final double soldeDisponible;

  const PaiementFormScreen({
    super.key,
    required this.adherentId,
    required this.soldeDisponible,
  });

  @override
  State<PaiementFormScreen> createState() => _PaiementFormScreenState();
}

class _PaiementFormScreenState extends State<PaiementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paiementService = PaiementService();
  final _montantController = TextEditingController();
  
  String _modePaiement = 'especes';
  String? _numeroCheque;
  String? _referenceVirement;
  String? _notes;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _submitPaiement() async {
    if (!_formKey.currentState!.validate()) return;

    final montant = double.tryParse(_montantController.text.replaceAll(' ', '')) ?? 0.0;
    
    if (montant <= 0) {
      setState(() {
        _errorMessage = 'Le montant doit être supérieur à 0';
      });
      return;
    }

    if (montant > widget.soldeDisponible) {
      setState(() {
        _errorMessage = 'Le montant ne peut pas dépasser le solde disponible (${widget.soldeDisponible.toStringAsFixed(2)} FCFA)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      final currentUser = authViewModel.currentUser;
      
      if (currentUser == null || currentUser.id == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _paiementService.createPaiement(
        adherentId: widget.adherentId,
        montant: montant,
        modePaiement: _modePaiement,
        numeroCheque: _numeroCheque?.isEmpty ?? true ? null : _numeroCheque,
        referenceVirement: _referenceVirement?.isEmpty ?? true ? null : _referenceVirement,
        notes: _notes?.isEmpty ?? true ? null : _notes,
        createdBy: currentUser.id!,
        generateRecu: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paiement de ${montant.toStringAsFixed(2)} FCFA enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Paiement'),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Carte de solde disponible
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Solde disponible',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${numberFormat.format(widget.soldeDisponible)} FCFA',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Montant
              TextFormField(
                controller: _montantController,
                decoration: InputDecoration(
                  labelText: 'Montant à payer *',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'FCFA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir le montant';
                  }
                  final montant = double.tryParse(value.replaceAll(' ', ''));
                  if (montant == null || montant <= 0) {
                    return 'Montant invalide';
                  }
                  if (montant > widget.soldeDisponible) {
                    return 'Montant supérieur au solde disponible';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Mode de paiement
              DropdownButtonFormField<String>(
                initialValue: _modePaiement,
                decoration: InputDecoration(
                  labelText: 'Mode de paiement *',
                  prefixIcon: const Icon(Icons.payment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'especes', child: Text('Espèces')),
                  DropdownMenuItem(value: 'cheque', child: Text('Chèque')),
                  DropdownMenuItem(value: 'virement', child: Text('Virement bancaire')),
                  DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money')),
                ],
                onChanged: (value) {
                  setState(() {
                    _modePaiement = value!;
                    _numeroCheque = null;
                    _referenceVirement = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Numéro de chèque (si mode = cheque)
              if (_modePaiement == 'cheque')
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Numéro de chèque',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => _numeroCheque = value,
                ),
              
              // Référence virement (si mode = virement ou mobile_money)
              if (_modePaiement == 'virement' || _modePaiement == 'mobile_money')
                TextFormField(
                  decoration: InputDecoration(
                    labelText: _modePaiement == 'virement' 
                        ? 'Référence virement' 
                        : 'Référence Mobile Money',
                    prefixIcon: const Icon(Icons.receipt),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => _referenceVirement = value,
                ),
              
              if (_modePaiement == 'cheque' || _modePaiement == 'virement' || _modePaiement == 'mobile_money')
                const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Notes (optionnel)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                onChanged: (value) => _notes = value,
              ),
              const SizedBox(height: 24),
              
              // Message d'erreur
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (_errorMessage != null) const SizedBox(height: 16),
              
              // Bouton de soumission
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPaiement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Enregistrer le paiement',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

