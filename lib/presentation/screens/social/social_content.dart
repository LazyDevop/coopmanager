import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/local_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/stat_card.dart';
import '../../../services/social/social_service.dart';
import '../../../data/models/aide_sociale_model.dart';
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
  
  List<AideSocialeModel> _aides = [];
  SocialStatistics? _statistics;
  bool _isLoading = false;
  String? _errorMessage;
  String? _filterStatut;
  String? _filterType;

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
      final aides = await _socialService.getAllAidesSociales(
        statut: _filterStatut,
        typeAide: _filterType,
      );
      final stats = await _socialService.getStatistics();
      
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

  List<AideSocialeModel> get _filteredAides => _aides;

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
            Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.aideSocialeAdd);
          },
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle Aide'),
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
            title: 'Total Aides',
            value: '${_statistics!.totalAides}',
            icon: Icons.favorite,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Approuvées',
            value: '${_statistics!.approuvees}',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Versées',
            value: '${_statistics!.versees}',
            icon: Icons.payment,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Montant Total',
            value: '${format.format(_statistics!.montantTotal)} FCFA',
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
                DropdownMenuItem<String>(value: 'en_attente', child: Text('En attente')),
                DropdownMenuItem<String>(value: 'approuve', child: Text('Approuvé')),
                DropdownMenuItem<String>(value: 'verse', child: Text('Versé')),
                DropdownMenuItem<String>(value: 'refuse', child: Text('Refusé')),
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
            child: DropdownButtonFormField<String?>(
              value: _filterType,
              decoration: InputDecoration(
                labelText: 'Type d\'aide',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                DropdownMenuItem<String>(
                  value: AppConfig.aideTypeSante,
                  child: Text('Santé'),
                ),
                DropdownMenuItem<String>(
                  value: AppConfig.aideTypeEducation,
                  child: Text('Éducation'),
                ),
                DropdownMenuItem<String>(
                  value: AppConfig.aideTypeUrgence,
                  child: Text('Urgence'),
                ),
                DropdownMenuItem<String>(
                  value: AppConfig.aideTypeAutre,
                  child: Text('Autre'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _filterType = value;
                });
                _loadData();
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
                _filterType = null;
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
              backgroundColor: _getTypeColor(aide.typeAide),
              child: Icon(
                _getTypeIcon(aide.typeAide),
                color: Colors.white,
              ),
            ),
            title: Text(
              _getTypeLabel(aide.typeAide),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Montant: ${format.format(aide.montant)} FCFA'),
                Text('Date: ${dateFormat.format(aide.dateAide)}'),
                Text('Statut: ${_getStatutLabel(aide.statut)}'),
                if (aide.description.isNotEmpty)
                  Text(
                    aide.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: _buildStatutBadge(aide.statut),
            onTap: () {
              Navigator.of(context, rootNavigator: false).pushNamed(
                AppRoutes.aideSocialeDetail,
                arguments: aide.id,
              );
            },
          ),
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case AppConfig.aideTypeSante:
        return Colors.red;
      case AppConfig.aideTypeEducation:
        return Colors.blue;
      case AppConfig.aideTypeUrgence:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case AppConfig.aideTypeSante:
        return Icons.local_hospital;
      case AppConfig.aideTypeEducation:
        return Icons.school;
      case AppConfig.aideTypeUrgence:
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case AppConfig.aideTypeSante:
        return 'Aide Santé';
      case AppConfig.aideTypeEducation:
        return 'Aide Éducation';
      case AppConfig.aideTypeUrgence:
        return 'Aide Urgence';
      default:
        return 'Aide Autre';
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'approuve':
        return 'Approuvé';
      case 'verse':
        return 'Versé';
      case 'refuse':
        return 'Refusé';
      default:
        return statut;
    }
  }

  Widget _buildStatutBadge(String statut) {
    Color color;
    switch (statut) {
      case 'en_attente':
        color = Colors.orange;
        break;
      case 'approuve':
        color = Colors.blue;
        break;
      case 'verse':
        color = Colors.green;
        break;
      case 'refuse':
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

