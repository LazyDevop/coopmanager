import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/compte_financier_adherent_model.dart';
import '../../../data/models/timeline_event_model.dart';
import '../../viewmodels/recette_viewmodel.dart';
import '../../../services/paiement/paiement_service.dart';
import '../../../config/routes/routes.dart';

class CompteFinancierAdherentScreen extends StatefulWidget {
  final int adherentId;

  const CompteFinancierAdherentScreen({
    super.key,
    required this.adherentId,
  });

  @override
  State<CompteFinancierAdherentScreen> createState() => _CompteFinancierAdherentScreenState();
}

class _CompteFinancierAdherentScreenState extends State<CompteFinancierAdherentScreen> {
  final PaiementService _paiementService = PaiementService();
  CompteFinancierAdherentModel? _compte;
  List<TimelineEventModel> _timelineEvents = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Helper functions to get shade colors from Color
  Color _getShade50(Color color) {
    return color.withOpacity(0.1);
  }

  Color _getShade700(Color color) {
    return Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1.0,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCompte();
  }

  Future<void> _loadCompte() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final compte = await _paiementService.getCompteFinancier(widget.adherentId);
      // TODO: Charger les événements timeline depuis le service
      
      setState(() {
        _compte = compte;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCompte,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _compte == null
                  ? const Center(child: Text('Compte non trouvé'))
                  : Column(
                      children: [
                        // En-tête avec informations adhérent
                        _buildHeader(context),
                        // Cartes de synthèse
                        _buildSummaryCards(context),
                        // Timeline interactive
                        Expanded(
                          child: _buildTimeline(context),
                        ),
                      ],
                    ),
      floatingActionButton: _compte != null && _compte!.soldeTotal > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context, rootNavigator: false).pushNamed(
                  AppRoutes.paiementForm,
                  arguments: {
                    'adherentId': widget.adherentId,
                    'soldeDisponible': _compte!.soldeTotal,
                  },
                ).then((_) => _loadCompte());
              },
              icon: const Icon(Icons.payment),
              label: const Text('Effectuer un paiement'),
              backgroundColor: Colors.green.shade700,
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.brown.shade100,
            child: Text(
              _compte!.adherentCode.substring(0, 2).toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _compte!.adherentFullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code: ${_compte!.adherentCode}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompte,
            tooltip: 'Actualiser',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00');
    final soldeColor = _compte!.soldeTotal > 0 
        ? Colors.green 
        : _compte!.soldeTotal < 0 
            ? Colors.red 
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Carte Solde Total
          Expanded(
            child: _buildSummaryCard(
              'Solde Total',
              '${numberFormat.format(_compte!.soldeTotal)} FCFA',
              Icons.account_balance_wallet,
              soldeColor,
            ),
          ),
          const SizedBox(width: 12),
          // Carte Recettes Générées
          Expanded(
            child: _buildSummaryCard(
              'Recettes',
              '${numberFormat.format(_compte!.totalRecettesGenerees)} FCFA',
              Icons.receipt_long,
              Colors.teal,
            ),
          ),
          const SizedBox(width: 12),
          // Carte Payé
          Expanded(
            child: _buildSummaryCard(
              'Payé',
              '${numberFormat.format(_compte!.totalPaye)} FCFA',
              Icons.payment,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          // Carte En Attente
          Expanded(
            child: _buildSummaryCard(
              'En Attente',
              '${numberFormat.format(_compte!.totalEnAttente)} FCFA',
              Icons.pending,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getShade50(color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getShade700(color),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getShade700(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    if (_timelineEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun événement dans la timeline',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _timelineEvents.length,
      itemBuilder: (context, index) {
        final event = _timelineEvents[index];
        return _buildTimelineItem(context, event, index == 0);
      },
    );
  }

  Widget _buildTimelineItem(BuildContext context, TimelineEventModel event, bool isFirst) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final numberFormat = NumberFormat('#,##0.00');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne verticale
        Column(
          children: [
            Container(
              width: 2,
              height: isFirst ? 0 : 20,
              color: Colors.grey.shade300,
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getShade50(event.color),
                shape: BoxShape.circle,
                border: Border.all(color: event.color, width: 2),
              ),
              child: Icon(event.icon, color: event.color, size: 20),
            ),
            Container(
              width: 2,
              height: 20,
              color: Colors.grey.shade300,
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Contenu de l'événement
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.titre,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getShade700(event.color),
                          ),
                        ),
                      ),
                      Text(
                        dateFormat.format(event.dateEvenement),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (event.montant != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getShade50(event.color),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${numberFormat.format(event.montant)} FCFA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getShade700(event.color),
                        ),
                      ),
                    ),
                  ],
                  if (event.documentPath != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Ouvrir le document PDF
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Voir le document'),
                      style: TextButton.styleFrom(
                        foregroundColor: _getShade700(event.color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

