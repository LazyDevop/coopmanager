import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/local_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/stat_card.dart';
import '../../../services/capital/capital_service.dart';
import '../../../data/models/part_sociale_model.dart';
import '../../../config/routes/routes.dart';
import 'package:intl/intl.dart';

/// Contenu du module Capital Social (sans Scaffold)
class CapitalContent extends StatefulWidget {
  const CapitalContent({super.key});

  @override
  State<CapitalContent> createState() => _CapitalContentState();
}

class _CapitalContentState extends State<CapitalContent> {
  final CapitalService _capitalService = CapitalService();
  
  CapitalSocialSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _capitalService.getCapitalSocialSummary();
      setState(() {
        _summary = summary;
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
          const SizedBox(height: 24),
          // Statistiques
          if (_summary != null) _buildStats(context),
          const SizedBox(height: 24),
          // Actions rapides
          _buildQuickActions(context),
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
              'Capital Social',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gestion des parts sociales et du capital',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.partsSociales);
          },
          icon: const Icon(Icons.list),
          label: const Text('Voir les Parts'),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    final format = NumberFormat('#,##0', 'fr_FR');
    
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Capital Total',
            value: '${format.format(_summary!.capitalTotal)} FCFA',
            icon: Icons.account_balance,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Parts Actives',
            value: format.format(_summary!.nombrePartsActives),
            icon: Icons.assignment,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Valeur Unitaire',
            value: '${format.format(_summary!.valeurUnitaire)} FCFA',
            icon: Icons.attach_money,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Actionnaires',
            value: '${_summary!.nombreActionnaires}',
            icon: Icons.people,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions rapides',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.partSocialeAdd);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle Acquisition'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.partsSociales);
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('Liste des Parts'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

