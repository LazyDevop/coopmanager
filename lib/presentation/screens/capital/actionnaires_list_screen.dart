import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/capital_social_model.dart';
import '../../viewmodels/capital_viewmodel.dart';
import '../../../config/routes/routes.dart';

class ActionnairesListScreen extends StatefulWidget {
  const ActionnairesListScreen({super.key});

  @override
  State<ActionnairesListScreen> createState() => _ActionnairesListScreenState();
}

class _ActionnairesListScreenState extends State<ActionnairesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatut;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<CapitalViewModel>();
      viewModel.loadActionnaires();
      viewModel.loadStatistiquesCapital();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête avec statistiques
        Consumer<CapitalViewModel>(
          builder: (context, viewModel, child) {
            return Container(
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
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Capital Social & Actionnariat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.bar_chart),
                        tooltip: 'État du capital',
                        onPressed: () {
                          Navigator.of(
                            context,
                            rootNavigator: false,
                          ).pushNamed(AppRoutes.capitalEtat);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Nouvelle souscription',
                        onPressed: () async {
                          final result = await Navigator.of(
                            context,
                            rootNavigator: false,
                          ).pushNamed(AppRoutes.capitalSouscription);

                          if (!context.mounted) return;

                          if (result == true) {
                            await context
                                .read<CapitalViewModel>()
                                .loadActionnaires();
                            await context
                                .read<CapitalViewModel>()
                                .loadStatistiquesCapital();
                          }
                        },
                      ),
                    ],
                  ),
                  if (viewModel.statistiquesCapital != null) ...[
                    const SizedBox(height: 16),
                    _buildStatistiquesCards(viewModel.statistiquesCapital!),
                  ],
                ],
              ),
            );
          },
        ),
        // Filtres et recherche
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par code actionnaire...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<CapitalViewModel>().searchActionnaires(
                              '',
                            );
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {});
                  context.read<CapitalViewModel>().searchActionnaires(value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedStatut,
                      decoration: InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tous')),
                        DropdownMenuItem(
                          value: ActionnaireModel.statutActif,
                          child: Text('Actif'),
                        ),
                        DropdownMenuItem(
                          value: ActionnaireModel.statutSuspendu,
                          child: Text('Suspendu'),
                        ),
                        DropdownMenuItem(
                          value: ActionnaireModel.statutRadie,
                          child: Text('Radié'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatut = value;
                        });
                        context.read<CapitalViewModel>().setFilterStatut(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedStatut = null;
                        _searchController.clear();
                      });
                      context.read<CapitalViewModel>().resetFilters();
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Réinitialiser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Liste des actionnaires
        Expanded(
          child: Consumer<CapitalViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading && viewModel.actionnaires.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(viewModel.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => viewModel.loadActionnaires(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }

              if (viewModel.filteredActionnaires.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun actionnaire trouvé',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => viewModel.loadActionnaires(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.filteredActionnaires.length,
                  itemBuilder: (context, index) {
                    final actionnaire = viewModel.filteredActionnaires[index];
                    return _buildActionnaireCard(context, actionnaire);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatistiquesCards(Map<String, dynamic> stats) {
    final numberFormat = NumberFormat('#,##0.00');
    final pourcentage =
        (stats['pourcentage_liberation'] as num?)?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Capital Souscrit',
            '${numberFormat.format(stats['capital_souscrit'])} FCFA',
            Colors.blue,
            Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Capital Libéré',
            '${numberFormat.format(stats['capital_libere'])} FCFA',
            Colors.green,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Capital Restant',
            '${numberFormat.format(stats['capital_restant'])} FCFA',
            Colors.orange,
            Icons.pending,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Actionnaires',
            '${stats['nombre_actionnaires']}',
            Colors.purple,
            Icons.people,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(
                (color.red * 0.7).round(),
                (color.green * 0.7).round(),
                (color.blue * 0.7).round(),
                1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionnaireCard(
    BuildContext context,
    ActionnaireModel actionnaire,
  ) {
    final numberFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Couleur selon le statut et l'état de libération
    Color cardColor = Colors.white;
    if (actionnaire.statut == ActionnaireModel.statutSuspendu) {
      cardColor = Colors.orange.shade50;
    } else if (!actionnaire.estAJour) {
      cardColor = Colors.yellow.shade50;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.read<CapitalViewModel>().loadActionnaireById(actionnaire.id!);
          Navigator.of(context, rootNavigator: false).pushNamed(
            AppRoutes.capitalActionnaireDetail,
            arguments: actionnaire.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_circle,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            actionnaire.codeActionnaire,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatutBadge(actionnaire.statut),
                        if (!actionnaire.estAJour)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'EN RETARD',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Parts: ${actionnaire.nombrePartsDetenues ?? 0} • Capital: ${numberFormat.format(actionnaire.capitalSouscrit ?? 0)} FCFA',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (actionnaire.capitalSouscrit != null &&
                        actionnaire.capitalSouscrit! > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Libéré: ${numberFormat.format(actionnaire.capitalLibere ?? 0)} FCFA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor:
                                        (actionnaire.pourcentageLiberation /
                                                100)
                                            .clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: actionnaire.estAJour
                                            ? Colors.green
                                            : Colors.orange,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${actionnaire.pourcentageLiberation.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: actionnaire.estAJour
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatutBadge(String statut) {
    Color color;
    String label;

    switch (statut) {
      case ActionnaireModel.statutActif:
        color = Colors.green;
        label = 'Actif';
        break;
      case ActionnaireModel.statutSuspendu:
        color = Colors.orange;
        label = 'Suspendu';
        break;
      case ActionnaireModel.statutRadie:
        color = Colors.red;
        label = 'Radié';
        break;
      default:
        color = Colors.grey;
        label = statut;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color.fromRGBO(
            (color.red * 0.7).round(),
            (color.green * 0.7).round(),
            (color.blue * 0.7).round(),
            1.0,
          ),
        ),
      ),
    );
  }
}
