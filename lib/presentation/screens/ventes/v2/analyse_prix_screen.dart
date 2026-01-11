/// Écran d'Analyse Prix/Marge V2
/// 
/// Analyse des prix et marges avec graphiques et indicateurs

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/vente_viewmodel.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/routes/routes.dart';
import 'package:intl/intl.dart';

class AnalysePrixScreen extends StatefulWidget {
  const AnalysePrixScreen({super.key});

  @override
  State<AnalysePrixScreen> createState() => _AnalysePrixScreenState();
}

class _AnalysePrixScreenState extends State<AnalysePrixScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedCampagneId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadVentes();
      viewModel.loadCampagnes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VenteViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            // En-tête
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
                    onPressed: () => Navigator.of(context, rootNavigator: false).pushReplacementNamed(AppRoutes.ventes),
                    tooltip: 'Retour',
                  ),
                  const Icon(Icons.trending_up, color: AppTheme.venteColor, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Analyse Prix / Marge',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.venteColor,
                    ),
                  ),
                  const Spacer(),
                  // Filtres
                  ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_startDate == null
                        ? 'Date début'
                        : DateFormat('dd/MM/yyyy').format(_startDate!)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_endDate == null
                        ? 'Date fin'
                        : DateFormat('dd/MM/yyyy').format(_endDate!)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Contenu d'analyse
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAnalyseContent(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyseContent(BuildContext context, VenteViewModel viewModel) {
    final ventes = viewModel.ventes.where((v) {
      if (_startDate != null && v.dateVente.isBefore(_startDate!)) return false;
      if (_endDate != null && v.dateVente.isAfter(_endDate!)) return false;
      if (_selectedCampagneId != null && v.campagneId != _selectedCampagneId) return false;
      return true;
    }).toList();

    if (ventes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée à analyser',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Calculs
    final prixMoyen = ventes.isEmpty
        ? 0.0
        : ventes.fold<double>(0.0, (sum, v) => sum + v.prixUnitaire) / ventes.length;
    
    final prixMin = ventes.isEmpty
        ? 0.0
        : ventes.map((v) => v.prixUnitaire).reduce((a, b) => a < b ? a : b);
    
    final prixMax = ventes.isEmpty
        ? 0.0
        : ventes.map((v) => v.prixUnitaire).reduce((a, b) => a > b ? a : b);

    final margeTotale = ventes.fold<double>(
      0.0,
      (sum, v) => sum + (v.montantCommission),
    );

    final margeMoyenne = ventes.isEmpty
        ? 0.0
        : margeTotale / ventes.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicateurs clés
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Prix Moyen',
                  '${NumberFormat('#,##0').format(prixMoyen)} FCFA/kg',
                  Icons.attach_money,
                  AppTheme.venteColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Prix Min',
                  '${NumberFormat('#,##0').format(prixMin)} FCFA/kg',
                  Icons.trending_down,
                  AppTheme.infoColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Prix Max',
                  '${NumberFormat('#,##0').format(prixMax)} FCFA/kg',
                  Icons.trending_up,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Marge Totale',
                  '${NumberFormat('#,##0').format(margeTotale)} FCFA',
                  Icons.account_balance,
                  AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Marge Moyenne',
                  '${NumberFormat('#,##0').format(margeMoyenne)} FCFA',
                  Icons.analytics,
                  AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Évolution des prix
          _buildEvolutionPrix(context, ventes),
          const SizedBox(height: 24),
          // Top ventes
          _buildTopVentes(context, ventes),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionPrix(BuildContext context, List ventes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évolution des Prix',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Graphique d\'évolution à implémenter',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopVentes(BuildContext context, List ventes) {
    final topVentes = ventes.toList()
      ..sort((a, b) => b.montantTotal.compareTo(a.montantTotal));
    final top5 = topVentes.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 Ventes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (top5.isEmpty)
            Center(
              child: Text(
                'Aucune vente',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
          else
            ...top5.asMap().entries.map((entry) {
              final index = entry.key;
              final vente = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.venteColor.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppTheme.venteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text('Vente #${vente.id}'),
                subtitle: Text(
                  '${vente.quantiteTotal.toStringAsFixed(2)} kg - ${DateFormat('dd/MM/yyyy').format(vente.dateVente)}',
                ),
                trailing: Text(
                  '${NumberFormat('#,##0').format(vente.montantTotal)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.venteColor,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

