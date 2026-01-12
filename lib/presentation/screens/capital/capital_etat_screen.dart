import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/capital_viewmodel.dart';
import '../../widgets/common/stat_card.dart';

/// Écran "État du capital" (sans Scaffold).
///
/// Affiche un récapitulatif détaillé du capital (souscrit/libéré/restant,
/// pourcentage de libération, valeur de part, nombre d'actionnaires).
class CapitalSocialEtatScreen extends StatefulWidget {
  const CapitalSocialEtatScreen({super.key});

  @override
  State<CapitalSocialEtatScreen> createState() => _CapitalSocialEtatScreenState();
}

class _CapitalSocialEtatScreenState extends State<CapitalSocialEtatScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<CapitalViewModel>().loadStatistiquesCapital();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Consumer<CapitalViewModel>(
        builder: (context, viewModel, child) {
          final stats = viewModel.statistiquesCapital;
          final error = viewModel.errorMessage;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              if (_isLoading) const LinearProgressIndicator(),
              if (error != null && error.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(error),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: stats == null
                    ? _buildEmptyState()
                    : _buildBody(context, stats),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Retour',
          onPressed: () {
            Navigator.of(context, rootNavigator: false).maybePop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'État du capital',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Récapitulatif du capital social',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _isLoading ? null : _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(
            'Aucune statistique disponible',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> stats) {
    final formatMoney = NumberFormat('#,##0', 'fr_FR');

    final capitalSouscrit = (stats['capital_souscrit'] as num?)?.toDouble() ?? 0.0;
    final capitalLibere = (stats['capital_libere'] as num?)?.toDouble() ?? 0.0;
    final capitalRestant = (stats['capital_restant'] as num?)?.toDouble() ?? 0.0;
    final valeurPart = (stats['valeur_part'] as num?)?.toDouble() ?? 0.0;
    final nombreActionnaires = (stats['nombre_actionnaires'] as int?) ?? 0;
    final pourcentageLiberation =
        (stats['pourcentage_liberation'] as num?)?.toDouble() ?? 0.0;

    final ratio = capitalSouscrit <= 0 ? 0.0 : (capitalLibere / capitalSouscrit);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressCard(
            context,
            ratio: ratio,
            capitalSouscrit: capitalSouscrit,
            capitalLibere: capitalLibere,
            pourcentageLiberation: pourcentageLiberation,
            formatMoney: formatMoney,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Capital souscrit',
                  value: '${formatMoney.format(capitalSouscrit)} FCFA',
                  icon: Icons.account_balance,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Capital libéré',
                  value: '${formatMoney.format(capitalLibere)} FCFA',
                  icon: Icons.check_circle,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Reste à libérer',
                  value: '${formatMoney.format(capitalRestant)} FCFA',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Taux de libération',
                  value: '${pourcentageLiberation.toStringAsFixed(1)}%',
                  icon: Icons.percent,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Valeur de part',
                  value: '${formatMoney.format(valeurPart)} FCFA',
                  icon: Icons.attach_money,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Actionnaires',
                  value: '$nombreActionnaires',
                  icon: Icons.people,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context, {
    required double ratio,
    required double capitalSouscrit,
    required double capitalLibere,
    required double pourcentageLiberation,
    required NumberFormat formatMoney,
  }) {
    final clamped = ratio.clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Progression des libérations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '${pourcentageLiberation.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: clamped,
                minHeight: 10,
                backgroundColor: Colors.teal.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${formatMoney.format(capitalLibere)} FCFA libérés sur ${formatMoney.format(capitalSouscrit)} FCFA',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
