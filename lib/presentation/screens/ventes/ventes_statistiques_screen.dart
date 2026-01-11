/// Écran de Statistiques Ventes V1
/// 
/// Affiche les statistiques et analyses des ventes

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/vente_viewmodel.dart';
import '../../../config/routes/routes.dart';
import 'package:intl/intl.dart';
import '../../../config/theme/app_theme.dart';

class VentesStatistiquesScreen extends StatefulWidget {
  const VentesStatistiquesScreen({super.key});

  @override
  State<VentesStatistiquesScreen> createState() => _VentesStatistiquesScreenState();
}

class _VentesStatistiquesScreenState extends State<VentesStatistiquesScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedAdherentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<VenteViewModel>();
      viewModel.loadVentes();
      viewModel.loadAdherents();
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
                  const Icon(Icons.analytics, color: AppTheme.venteColor, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Statistiques des Ventes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.venteColor,
                    ),
                  ),
                  const Spacer(),
                  // Filtres
                  Row(
                    children: [
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
                            _loadStats(viewModel);
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
                            _loadStats(viewModel);
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Statistiques
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStatsContent(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadStats(VenteViewModel viewModel) async {
    await viewModel.getStatistiques(
      startDate: _startDate,
      endDate: _endDate,
      adherentId: _selectedAdherentId,
    );
  }

  Widget _buildStatsContent(BuildContext context, VenteViewModel viewModel) {
    return FutureBuilder<Map<String, dynamic>>(
      future: viewModel.getStatistiques(
        startDate: _startDate,
        endDate: _endDate,
        adherentId: _selectedAdherentId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final stats = snapshot.data ?? {
          'nombreVentes': 0,
          'quantiteTotale': 0.0,
          'montantTotal': 0.0,
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cartes de statistiques
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Nombre de Ventes',
                      '${stats['nombreVentes']}',
                      Icons.shopping_cart,
                      AppTheme.venteColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Quantité Totale',
                      '${(stats['quantiteTotale'] as num).toStringAsFixed(2)} kg',
                      Icons.scale,
                      AppTheme.stockColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Montant Total',
                      '${NumberFormat('#,##0').format(stats['montantTotal'])} FCFA',
                      Icons.attach_money,
                      AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Graphiques et analyses
              _buildVentesParMois(context, viewModel),
              const SizedBox(height: 24),
              _buildTopClients(context, viewModel),
            ],
          ),
        );
      },
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentesParMois(BuildContext context, VenteViewModel viewModel) {
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
            'Ventes par Mois',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Graphique simple (barres)
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Graphique à implémenter',
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

  Widget _buildTopClients(BuildContext context, VenteViewModel viewModel) {
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
            'Top Clients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Liste des top clients
          Center(
            child: Text(
              'Liste des top clients à implémenter',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

