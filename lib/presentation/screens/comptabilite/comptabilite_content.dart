import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/local_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../../services/comptabilite/comptabilite_service.dart';
import '../../../data/models/ecriture_comptable_model.dart';
import '../../../config/routes/routes.dart';
import 'package:intl/intl.dart';

/// Contenu du module Comptabilité (sans Scaffold)
class ComptabiliteContent extends StatefulWidget {
  const ComptabiliteContent({super.key});

  @override
  State<ComptabiliteContent> createState() => _ComptabiliteContentState();
}

class _ComptabiliteContentState extends State<ComptabiliteContent> {
  final ComptabiliteService _comptabiliteService = ComptabiliteService();
  
  List<EcritureComptableModel> _ecritures = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    _loadEcritures();
  }

  Future<void> _loadEcritures() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ecritures = await _comptabiliteService.getAllEcritures(
        dateDebut: _dateDebut,
        dateFin: _dateFin,
      );
      setState(() {
        _ecritures = ecritures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildHeader(context),
          const SizedBox(height: 16),
          // Filtres
          _buildFilters(context),
          const SizedBox(height: 16),
          // Liste des écritures
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comptabilité',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Écritures comptables et grand livre',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.grandLivre);
              },
              icon: const Icon(Icons.book),
              label: const Text('Grand Livre'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.etatsFinanciers);
              },
              icon: const Icon(Icons.assessment),
              label: const Text('États Financiers'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateDebut ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _dateDebut = date;
                  });
                  _loadEcritures();
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date début',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                child: Text(
                  _dateDebut != null
                      ? DateFormat('dd/MM/yyyy').format(_dateDebut!)
                      : 'Sélectionner',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateFin ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _dateFin = date;
                  });
                  _loadEcritures();
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date fin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                child: Text(
                  _dateFin != null
                      ? DateFormat('dd/MM/yyyy').format(_dateFin!)
                      : 'Sélectionner',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Réinitialiser',
            onPressed: () {
              setState(() {
                _dateDebut = null;
                _dateFin = null;
              });
              _loadEcritures();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const LocalLoader(message: 'Chargement des écritures...');
    }

    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadEcritures,
      );
    }

    if (_ecritures.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Aucune écriture comptable',
        message: 'Les écritures seront générées automatiquement lors des opérations',
      );
    }

    final format = NumberFormat('#,##0.00', 'fr_FR');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      child: Column(
        children: [
          // En-tête du tableau
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.brown.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('N°', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Libellé', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Débit', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Crédit', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          // Liste des écritures
          Expanded(
            child: ListView.builder(
              itemCount: _ecritures.length,
              itemBuilder: (context, index) {
                final ecriture = _ecritures[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Row(
                      children: [
                        Expanded(flex: 2, child: Text(dateFormat.format(ecriture.dateEcriture))),
                        Expanded(flex: 2, child: Text(ecriture.numero)),
                        Expanded(flex: 3, child: Text(ecriture.libelle)),
                        Expanded(flex: 2, child: Text(ecriture.compteDebit)),
                        Expanded(flex: 2, child: Text(ecriture.compteCredit)),
                        Expanded(flex: 2, child: Text('${format.format(ecriture.montant)} FCFA')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

