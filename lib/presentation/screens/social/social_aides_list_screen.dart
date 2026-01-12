import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/social/social_service.dart';
import '../../../data/models/social/social_aide_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'social_aide_form_screen.dart';
import 'social_aide_detail_screen.dart';

/// Écran de liste des aides sociales accordées
class SocialAidesListScreen extends StatefulWidget {
  final int? adherentId; // Filtrer par adhérent si fourni

  const SocialAidesListScreen({
    super.key,
    this.adherentId,
  });

  @override
  State<SocialAidesListScreen> createState() => _SocialAidesListScreenState();
}

class _SocialAidesListScreenState extends State<SocialAidesListScreen> {
  final SocialService _socialService = SocialService();
  List<SocialAideModel> _aides = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _filterStatut;

  @override
  void initState() {
    super.initState();
    _loadAides();
  }

  Future<void> _loadAides() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final aides = await _socialService.getAllAides(
        adherentId: widget.adherentId,
        statut: _filterStatut,
      );
      setState(() {
        _aides = aides;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'accordee':
        return Colors.blue;
      case 'en_cours':
        return Colors.orange;
      case 'remboursée':
        return Colors.green;
      case 'annulée':
        return Colors.red;
      default:
        return Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.adherentId != null
              ? 'Aides sociales de l\'adhérent'
              : 'Aides sociales',
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatut = value == 'all' ? null : value;
              });
              _loadAides();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Tous les statuts'),
              ),
              const PopupMenuItem(
                value: 'accordee',
                child: Text('Accordées'),
              ),
              const PopupMenuItem(
                value: 'en_cours',
                child: Text('En cours'),
              ),
              const PopupMenuItem(
                value: 'remboursée',
                child: Text('Remboursées'),
              ),
              const PopupMenuItem(
                value: 'annulée',
                child: Text('Annulées'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push<SocialAideModel?>(
                MaterialPageRoute(
                  builder: (context) => SocialAideFormScreen(
                    adherentId: widget.adherentId,
                  ),
                ),
              );
              if (result != null && mounted) {
                _loadAides();
              }
            },
            tooltip: 'Accorder une aide',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAides,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _aides.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune aide enregistrée',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.of(context).push<SocialAideModel?>(
                                MaterialPageRoute(
                                  builder: (context) => SocialAideFormScreen(
                                    adherentId: widget.adherentId,
                                  ),
                                ),
                              );
                              if (result != null && mounted) {
                                _loadAides();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Accorder une aide'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAides,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _aides.length,
                        itemBuilder: (context, index) {
                          final aide = _aides[index];
                          final statutColor = _getStatutColor(aide.statut);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: statutColor.withOpacity(0.2),
                                child: Icon(
                                  aide.isRemboursable
                                      ? Icons.rotate_left
                                      : Icons.favorite,
                                  color: statutColor,
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
                                  Text(
                                    'Montant: ${NumberFormat('#,##0').format(aide.montant)} FCFA',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Date: ${DateFormat('dd/MM/yyyy').format(aide.dateOctroi)}',
                                  ),
                                  if (aide.isRemboursable) ...[
                                    const SizedBox(height: 4),
                                    FutureBuilder<double>(
                                      future: _socialService.getSoldeRestant(aide.id!),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          final solde = snapshot.data!;
                                          return Text(
                                            'Solde restant: ${NumberFormat('#,##0').format(solde)} FCFA',
                                            style: TextStyle(
                                              color: solde > 0 ? Colors.orange : Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statutColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statutColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      _getStatutLabel(aide.statut),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: statutColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SocialAideDetailScreen(
                                      aideId: aide.id!,
                                    ),
                                  ),
                                ).then((_) => _loadAides());
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

