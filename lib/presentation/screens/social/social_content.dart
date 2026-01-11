import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/local_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/stat_card.dart';
import '../../../services/social/social_service.dart';
import '../../../data/models/social/social_aide_model.dart';
import '../../../config/app_config.dart';
import '../../../config/routes/routes.dart';
import 'package:intl/intl.dart';

/// Contenu du module Social (sans Scaffold)
class SocialContent extends StatefulWidget {
  const SocialContent({super.key});

  @override
  State<SocialContent> createState() => _SocialContentState();
}

class _SocialContentState extends State<SocialContent> {
  final SocialService _socialService = SocialService();
  
  List<SocialAideModel> _aides = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = false;
  String? _errorMessage;
  String? _filterStatut;
  int? _filterTypeId;

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
      final aides = await _socialService.getAllAides(
        statut: _filterStatut,
        aideTypeId: _filterTypeId,
      );
      final stats = await _socialService.getStatistiques();
      
      setState(() {
        _aides = aides;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  List<SocialAideModel> get _filteredAides => _aides;

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
          if (_statistics != null) _buildStats(context),
          const SizedBox(height: 24),
          // Filtres
          _buildFilters(context),
          const SizedBox(height: 16),
          // Liste
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
              'Module Social',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gestion des aides et actions sociales',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Naviguer vers le formulaire d'aide
            // Navigator.of(context).push(...);
          },
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle Aide'),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    if (_statistics == null) return const SizedBox.shrink();
    
    final format = NumberFormat('#,##0', 'fr_FR');
    final totalAides = _statistics!['total_aides'] as int? ?? 0;
    final totalMontant = (_statistics!['total_montant'] as num?)?.toDouble() ?? 0.0;
    final parStatut = _statistics!['par_statut'] as Map<String, dynamic>? ?? {};
    final accordees = parStatut['accordee'] as int? ?? 0;
    final remboursees = parStatut['remboursée'] as int? ?? 0;
    
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Total Aides',
            value: '$totalAides',
            icon: Icons.favorite,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Accordées',
            value: '$accordees',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Remboursées',
            value: '$remboursees',
            icon: Icons.payment,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Montant Total',
            value: '${format.format(totalMontant)} FCFA',
            icon: Icons.attach_money,
            color: Colors.orange,
          ),
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
            child: DropdownButtonFormField<String?>(
              value: _filterStatut,
              decoration: InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                DropdownMenuItem<String>(value: 'accordee', child: Text('Accordée')),
                DropdownMenuItem<String>(value: 'en_cours', child: Text('En cours')),
                DropdownMenuItem<String>(value: 'remboursée', child: Text('Remboursée')),
                DropdownMenuItem<String>(value: 'annulée', child: Text('Annulée')),
              ],
              onChanged: (value) {
                setState(() {
                  _filterStatut = value;
                });
                _loadData();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder<List>(
              future: _socialService.getAllAideTypes(actifsOnly: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return DropdownButtonFormField<int?>(
                    value: null,
                    items: const [],
                    decoration: const InputDecoration(
                      labelText: 'Type d\'aide',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Ne rien faire pendant le chargement
                    },
                  );
                }
                
                final types = snapshot.data!;
                return DropdownButtonFormField<int?>(
                  value: _filterTypeId,
                  decoration: InputDecoration(
                    labelText: 'Type d\'aide',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Tous')),
                    ...types.map((type) => DropdownMenuItem<int?>(
                      value: type.id,
                      child: Text(type.libelle),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterTypeId = value;
                    });
                    _loadData();
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            tooltip: 'Réinitialiser',
            onPressed: () {
              setState(() {
                _filterStatut = null;
                _filterTypeId = null;
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const LocalLoader(message: 'Chargement des aides sociales...');
    }

    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadData,
      );
    }

    if (_filteredAides.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        title: 'Aucune aide sociale',
        message: 'Ajoutez votre première aide sociale',
      );
    }

    final format = NumberFormat('#,##0', 'fr_FR');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return ListView.builder(
      itemCount: _filteredAides.length,
      itemBuilder: (context, index) {
        final aide = _filteredAides[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategorieColor(aide.aideType?.categorie ?? ''),
              child: Icon(
                _getCategorieIcon(aide.aideType?.categorie ?? ''),
                color: Colors.white,
              ),
            ),
            title: Text(
              aide.aideType?.libelle ?? 'Type inconnu',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (aide.adherentNom != null)
                  Text('Adhérent: ${aide.adherentNom}'),
                Text('Montant: ${format.format(aide.montant)} FCFA'),
                Text('Date: ${dateFormat.format(aide.dateOctroi)}'),
                Text('Statut: ${_getStatutLabel(aide.statut)}'),
                if (aide.observations != null && aide.observations!.isNotEmpty)
                  Text(
                    aide.observations!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: _buildStatutBadge(aide.statut),
            onTap: () {
              // TODO: Naviguer vers le détail de l'aide
              // Navigator.of(context).push(...);
            },
          ),
        );
      },
    );
  }

  Color _getCategorieColor(String categorie) {
    switch (categorie) {
      case 'FINANCIERE':
        return Colors.green;
      case 'MATERIELLE':
        return Colors.blue;
      case 'SOCIALE':
        return Colors.pink;
      case 'TECHNIQUE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategorieIcon(String categorie) {
    switch (categorie) {
      case 'FINANCIERE':
        return Icons.attach_money;
      case 'MATERIELLE':
        return Icons.inventory;
      case 'SOCIALE':
        return Icons.people;
      case 'TECHNIQUE':
        return Icons.build;
      default:
        return Icons.help;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'accordee':
        return 'Accordée';
      case 'en_cours':
        return 'En cours';
      case 'remboursée':
        return 'Remboursée';
      case 'annulée':
        return 'Annulée';
      default:
        return statut;
    }
  }

  Widget _buildStatutBadge(String statut) {
    Color color;
    switch (statut) {
      case 'accordee':
        color = Colors.blue;
        break;
      case 'en_cours':
        color = Colors.orange;
        break;
      case 'remboursée':
        color = Colors.green;
        break;
      case 'annulée':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        _getStatutLabel(statut),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

