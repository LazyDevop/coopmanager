import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../data/models/adherent_model.dart';
import '../../services/adherent/adherent_service.dart';
import '../../services/stock/stock_service.dart';

class StockAdjustmentScreen extends StatefulWidget {
  final int adherentId;

  const StockAdjustmentScreen({super.key, required this.adherentId});

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteController = TextEditingController();
  final _raisonController = TextEditingController();
  
  AdherentModel? _adherent;
  double _stockActuel = 0;
  bool _isLoading = false;
  bool _isPositive = true;

  @override
  void initState() {
    super.initState();
    _loadAdherent();
    _loadStockActuel();
  }

  Future<void> _loadAdherent() async {
    final service = AdherentService();
    final adherent = await service.getAdherentById(widget.adherentId);
    if (adherent != null) {
      setState(() {
        _adherent = adherent;
      });
    }
  }

  Future<void> _loadStockActuel() async {
    final stockService = StockService();
    final stock = await stockService.getStockActuel(widget.adherentId);
    setState(() {
      _stockActuel = stock;
    });
  }

  @override
  void dispose() {
    _quantiteController.dispose();
    _raisonController.dispose();
    super.dispose();
  }

  Future<void> _submitAdjustment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantite = double.parse(_quantiteController.text);
    final quantiteFinale = _isPositive ? quantite : -quantite;

    if (!_isPositive && quantiteFinale.abs() > _stockActuel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le retrait ne peut pas dépasser le stock actuel (${_stockActuel.toStringAsFixed(2)} kg)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final stockViewModel = context.read<StockViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final success = await stockViewModel.createAjustement(
      adherentId: widget.adherentId,
      quantite: quantiteFinale,
      raison: _raisonController.text,
      createdBy: currentUser.id!,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajustement enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stockViewModel.errorMessage ?? 'Erreur lors de l\'ajustement',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustement de Stock'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Informations adhérent
              if (_adherent != null)
                Card(
                  child: ListTile(
                    leading: const SizedBox(
                      width: 24,
                      child: Icon(Icons.person),
                    ),
                    title: Text(_adherent!.fullName),
                    subtitle: Text('Code: ${_adherent!.code}'),
                  ),
                ),
              const SizedBox(height: 16),

              // Stock actuel
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Stock actuel:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${_stockActuel.toStringAsFixed(2)} kg',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Type d'ajustement
              const Text(
                'Type d\'ajustement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Ajout'),
                        ],
                      ),
                      selected: _isPositive,
                      onSelected: (selected) {
                        setState(() {
                          _isPositive = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove, color: Colors.red),
                          SizedBox(width: 4),
                          Text('Retrait'),
                        ],
                      ),
                      selected: !_isPositive,
                      onSelected: (selected) {
                        setState(() {
                          _isPositive = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quantité
              TextFormField(
                controller: _quantiteController,
                decoration: InputDecoration(
                  labelText: 'Quantité (kg) *',
                  prefixIcon: Icon(_isPositive ? Icons.add : Icons.remove),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la quantité';
                  }
                  final quantite = double.tryParse(value);
                  if (quantite == null || quantite <= 0) {
                    return 'La quantité doit être supérieure à 0';
                  }
                  if (!_isPositive && quantite > _stockActuel) {
                    return 'Le retrait ne peut pas dépasser le stock actuel';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Raison (obligatoire)
              TextFormField(
                controller: _raisonController,
                decoration: InputDecoration(
                  labelText: 'Raison de l\'ajustement *',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez indiquer la raison de l\'ajustement';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Bouton de soumission
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAdjustment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700,
                    foregroundColor: Colors.white,
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
                      : Text(
                          _isPositive ? 'Ajouter au stock' : 'Retirer du stock',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

