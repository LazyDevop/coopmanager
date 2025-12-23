import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import '../../viewmodels/adherent_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../config/routes/routes.dart';
import '../../../data/models/adherent_model.dart';
import '../../../services/adherent/export_service.dart';
import '../../../config/app_config.dart';
import '../../screens/stock_depot_form_screen.dart';

class AdherentDetailScreen extends StatefulWidget {
  final int adherentId;

  const AdherentDetailScreen({super.key, required this.adherentId});

  @override
  State<AdherentDetailScreen> createState() => _AdherentDetailScreenState();
}

class _AdherentDetailScreenState extends State<AdherentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<AdherentViewModel>();
      viewModel.loadAdherentDetails(widget.adherentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AdherentViewModel>(
          builder: (context, viewModel, child) {
            final adherent = viewModel.selectedAdherent;
            return Text(adherent?.fullName ?? 'Détails de l\'adhérent');
          },
        ),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: 'Vue Expert (Complète)',
            onPressed: () {
              Navigator.of(context, rootNavigator: false).pushNamed(
                AppRoutes.adherentExpertDetail,
                arguments: widget.adherentId,
              );
            },
          ),
          Consumer<AdherentViewModel>(
            builder: (context, viewModel, child) {
              final adherent = viewModel.selectedAdherent;
              if (adherent == null) return const SizedBox.shrink();
              
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, value, adherent, viewModel),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: adherent.isActive ? 'deactivate' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          adherent.isActive ? Icons.block : Icons.check_circle,
                          size: 18,
                          color: adherent.isActive ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          adherent.isActive ? 'Désactiver' : 'Réactiver',
                          style: TextStyle(
                            color: adherent.isActive ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('Exporter l\'historique'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Informations'),
            Tab(icon: Icon(Icons.inventory), text: 'Dépôts'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Ventes'),
            Tab(icon: Icon(Icons.attach_money), text: 'Recettes'),
          ],
        ),
      ),
      body: Consumer<AdherentViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.selectedAdherent == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.selectedAdherent == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Adhérent non trouvé',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInformationsTab(viewModel.selectedAdherent!),
              _buildDepotsTab(viewModel),
              _buildVentesTab(viewModel),
              _buildRecettesTab(viewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInformationsTab(AdherentModel adherent) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: adherent.isActive
                            ? Colors.green.shade100
                            : Colors.grey.shade300,
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: adherent.isActive
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              adherent.fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Code: ${adherent.code}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (!adherent.isActive) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Inactif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // SECTION: IDENTIFICATION
          _buildInfoSection(
            'Identification',
            [
              _buildInfoRow('Code adhérent', adherent.code),
              _buildInfoRow(
                'Type de personne',
                _getTypePersonneLabel(adherent.categorie),
              ),
              _buildInfoRow(
                'Statut',
                _getStatutLabel(adherent.statut, adherent.isActive),
              ),
              if (adherent.siteCooperative != null && adherent.siteCooperative!.isNotEmpty)
                _buildInfoRow('Site coopérative', adherent.siteCooperative!),
              if (adherent.section != null && adherent.section!.isNotEmpty)
                _buildInfoRow('Section', adherent.section!),
              _buildInfoRow(
                'Date d\'adhésion',
                dateFormat.format(adherent.dateAdhesion),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // SECTION: IDENTITÉ PERSONNELLE
          _buildInfoSection(
            'Identité personnelle',
            [
              _buildInfoRow('Nom', adherent.nom),
              _buildInfoRow('Prénom', adherent.prenom),
              if (adherent.sexe != null && adherent.sexe!.isNotEmpty)
                _buildInfoRow('Sexe', _getSexeLabel(adherent.sexe!)),
              if (adherent.dateNaissance != null)
                _buildInfoRow(
                  'Date de naissance',
                  dateFormat.format(adherent.dateNaissance!),
                ),
              if (adherent.lieuNaissance != null && adherent.lieuNaissance!.isNotEmpty)
                _buildInfoRow('Lieu de naissance', adherent.lieuNaissance!),
              if (adherent.nationalite != null && adherent.nationalite!.isNotEmpty)
                _buildInfoRow('Nationalité', adherent.nationalite!),
              if (adherent.typePiece != null && adherent.typePiece!.isNotEmpty)
                _buildInfoRow('Type de pièce', adherent.typePiece!),
              if (adherent.numeroPiece != null && adherent.numeroPiece!.isNotEmpty)
                _buildInfoRow('Numéro de pièce', adherent.numeroPiece!),
              if (adherent.cnib != null && adherent.cnib!.isNotEmpty)
                _buildInfoRow('CNIB', adherent.cnib!),
            ],
          ),
          const SizedBox(height: 16),
          // SECTION: CONTACT
          _buildInfoSection(
            'Contact',
            [
              if (adherent.telephone != null && adherent.telephone!.isNotEmpty)
                _buildInfoRow('Téléphone', adherent.telephone!),
              if (adherent.email != null && adherent.email!.isNotEmpty)
                _buildInfoRow('Email', adherent.email!),
            ],
          ),
          const SizedBox(height: 16),
          // SECTION: LOCALISATION
          _buildInfoSection(
            'Localisation',
            [
              if (adherent.village != null && adherent.village!.isNotEmpty)
                _buildInfoRow('Village', adherent.village!),
              if (adherent.adresse != null && adherent.adresse!.isNotEmpty)
                _buildInfoRow('Adresse', adherent.adresse!),
            ],
          ),
          const SizedBox(height: 16),
          // SECTION: SITUATION FAMILIALE / FILIATION
          if (_hasSituationFamiliale(adherent))
            _buildInfoSection(
              'Situation familiale / Filiation',
              [
                if (adherent.nomPere != null && adherent.nomPere!.isNotEmpty)
                  _buildInfoRow('Nom du père', adherent.nomPere!),
                if (adherent.nomMere != null && adherent.nomMere!.isNotEmpty)
                  _buildInfoRow('Nom de la mère', adherent.nomMere!),
                if (adherent.conjoint != null && adherent.conjoint!.isNotEmpty)
                  _buildInfoRow('Conjoint(e)', adherent.conjoint!),
                if (adherent.nombreEnfants != null && adherent.nombreEnfants! > 0)
                  _buildInfoRow('Nombre d\'enfants', adherent.nombreEnfants!.toString()),
              ],
            ),
          if (_hasSituationFamiliale(adherent)) const SizedBox(height: 16),
          // SECTION: INDICATEURS AGRICOLES GLOBAUX
          if (_hasIndicateursAgricoles(adherent))
            _buildInfoSection(
              'Indicateurs agricoles globaux',
              [
                if (adherent.superficieTotaleCultivee != null && adherent.superficieTotaleCultivee! > 0)
                  _buildInfoRow(
                    'Superficie totale cultivée',
                    '${NumberFormat('#,##0.00').format(adherent.superficieTotaleCultivee)} ha',
                  ),
                if (adherent.nombreChamps != null && adherent.nombreChamps! > 0)
                  _buildInfoRow('Nombre de champs', adherent.nombreChamps!.toString()),
                if (adherent.rendementMoyenHa != null && adherent.rendementMoyenHa! > 0)
                  _buildInfoRow(
                    'Rendement moyen',
                    '${NumberFormat('#,##0.00').format(adherent.rendementMoyenHa)} t/ha',
                  ),
                if (adherent.tonnageTotalProduit != null && adherent.tonnageTotalProduit! > 0)
                  _buildInfoRow(
                    'Tonnage total produit',
                    '${NumberFormat('#,##0.00').format(adherent.tonnageTotalProduit)} t',
                  ),
                if (adherent.tonnageTotalVendu != null && adherent.tonnageTotalVendu! > 0)
                  _buildInfoRow(
                    'Tonnage total vendu',
                    '${NumberFormat('#,##0.00').format(adherent.tonnageTotalVendu)} t',
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  /// Vérifier si l'adhérent a des informations de situation familiale
  bool _hasSituationFamiliale(AdherentModel adherent) {
    return (adherent.nomPere != null && adherent.nomPere!.isNotEmpty) ||
        (adherent.nomMere != null && adherent.nomMere!.isNotEmpty) ||
        (adherent.conjoint != null && adherent.conjoint!.isNotEmpty) ||
        (adherent.nombreEnfants != null && adherent.nombreEnfants! > 0);
  }

  /// Vérifier si l'adhérent a des indicateurs agricoles
  bool _hasIndicateursAgricoles(AdherentModel adherent) {
    return (adherent.superficieTotaleCultivee != null && adherent.superficieTotaleCultivee! > 0) ||
        (adherent.nombreChamps != null && adherent.nombreChamps! > 0) ||
        (adherent.rendementMoyenHa != null && adherent.rendementMoyenHa! > 0) ||
        (adherent.tonnageTotalProduit != null && adherent.tonnageTotalProduit! > 0) ||
        (adherent.tonnageTotalVendu != null && adherent.tonnageTotalVendu! > 0);
  }

  /// Obtenir le libellé du type de personne
  String _getTypePersonneLabel(String? categorie) {
    switch (categorie) {
      case AppConfig.categorieProducteur:
        return 'Producteur';
      case AppConfig.categorieAdherent:
        return 'Adhérent';
      case 'adherent_actionnaire':
        return 'Adhérent Actionnaire';
      default:
        return 'Producteur';
    }
  }

  /// Obtenir le libellé du statut
  String _getStatutLabel(String? statut, bool isActive) {
    if (!isActive) return 'Inactif';
    switch (statut) {
      case 'actif':
        return 'Actif';
      case 'suspendu':
        return 'Suspendu';
      case 'radie':
        return 'Radié';
      default:
        return 'Actif';
    }
  }

  /// Obtenir le libellé du sexe
  String _getSexeLabel(String sexe) {
    switch (sexe) {
      case 'M':
        return 'Masculin';
      case 'F':
        return 'Féminin';
      case 'Autre':
        return 'Autre';
      default:
        return sexe;
    }
  }

  Widget _buildDepotsTab(AdherentViewModel viewModel) {
    if (viewModel.depots.isEmpty) {
      return Column(
        children: [
          // Bouton ajouter un dépôt
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockDepotFormScreen(adherentId: widget.adherentId),
                  ),
                ).then((_) {
                  // Recharger les dépôts après ajout
                  viewModel.loadAdherentDetails(widget.adherentId);
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un dépôt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Message vide
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun dépôt enregistré',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Utiliser CustomScrollView pour permettre le défilement de tout le contenu
    return CustomScrollView(
      slivers: [
        // Bouton ajouter un dépôt
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockDepotFormScreen(adherentId: widget.adherentId),
                  ),
                ).then((_) {
                  // Recharger les dépôts après ajout
                  viewModel.loadAdherentDetails(widget.adherentId);
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un dépôt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        
        // Graphique qualité vs humidité (si des dépôts existent)
        if (viewModel.depots.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildQualiteHumiditeChart(viewModel),
          ),
        
        // Titre de la liste
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Liste des dépôts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
          ),
        ),
        
        // Liste des dépôts
        _buildDepotsListSliver(viewModel),
      ],
    );
  }
  
  /// Construire le graphique qualité vs humidité
  Widget _buildQualiteHumiditeChart(AdherentViewModel viewModel) {
    // Préparer les données pour le graphique
    final depotsWithData = viewModel.depots.where((depot) {
      final qualite = depot['qualite'];
      final humidite = depot['humidite'];
      final hasQualite = qualite != null && qualite.toString().isNotEmpty;
      final hasHumidite = humidite != null;
      
      // Debug: afficher les données manquantes
      if (!hasQualite || !hasHumidite) {
        print('Dépôt sans données complètes - qualite: $qualite, humidite: $humidite');
      }
      
      return hasQualite && hasHumidite;
    }).toList();
    
    print('Nombre de dépôts avec données complètes: ${depotsWithData.length} sur ${viewModel.depots.length}');
    
    if (depotsWithData.isEmpty) {
      // Afficher un message informatif au lieu de rien
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Le graphique de qualité vs humidité sera affiché lorsque vous aurez enregistré des dépôts avec qualité et humidité',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Grouper par qualité et calculer la moyenne d'humidité
    final Map<String, List<double>> qualiteHumidite = {};
    for (var depot in depotsWithData) {
      final qualite = depot['qualite'] as String;
      final humidite = (depot['humidite'] as num).toDouble();
      qualiteHumidite.putIfAbsent(qualite, () => []).add(humidite);
    }
    
    // Calculer les moyennes
    final Map<String, double> moyennes = {};
    qualiteHumidite.forEach((qualite, humidites) {
      moyennes[qualite] = humidites.reduce((a, b) => a + b) / humidites.length;
    });
    
    print('Moyennes calculées: $moyennes');
    
    if (moyennes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Créer les points pour le graphique
    final spots = moyennes.entries.map((entry) {
      final qualiteIndex = AppConfig.qualitesCacao.indexOf(entry.key);
      if (qualiteIndex == -1) {
        print('Qualité non trouvée dans AppConfig.qualitesCacao: ${entry.key}');
        return null;
      }
      return FlSpot(qualiteIndex.toDouble(), entry.value);
    }).whereType<FlSpot>().toList();
    
    if (spots.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Courbe de qualité vs humidité',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: 10,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < AppConfig.qualitesCacao.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                AppConfig.qualitesCacao[index].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.brown.shade700,
                      barWidth: 4,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: Colors.brown.shade700,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.brown.shade50,
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final qualiteIndex = touchedSpot.x.toInt();
                          final qualite = qualiteIndex >= 0 && qualiteIndex < AppConfig.qualitesCacao.length
                              ? AppConfig.qualitesCacao[qualiteIndex]
                              : 'Inconnu';
                          return LineTooltipItem(
                            '$qualite\n${touchedSpot.y.toStringAsFixed(1)}%',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Légende avec les moyennes
            Wrap(
              spacing: 16,
              children: moyennes.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.brown.shade700,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.key.toUpperCase()}: ${entry.value.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDepotsList(AdherentViewModel viewModel) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: viewModel.depots.length,
      itemBuilder: (context, index) {
        final depot = viewModel.depots[index];
        final quantite = (depot['quantite'] as num?)?.toDouble() ?? 0.0;
        final prixUnitaire = (depot['prix_unitaire'] as num?)?.toDouble() ?? 0.0;
        final montant = quantite * prixUnitaire;
        final dateDepot = DateTime.parse(depot['date_depot'] as String);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: SizedBox(
              width: 40,
              child: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Icon(Icons.inventory, color: Colors.orange.shade700),
              ),
            ),
            title: Text(
              '${numberFormat.format(quantite)} kg',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Prix unitaire: ${numberFormat.format(prixUnitaire)} FCFA/kg'),
                Text('Date: ${dateFormat.format(dateDepot)}'),
              ],
            ),
            trailing: Text(
              '${numberFormat.format(montant)} FCFA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDepotsListSliver(AdherentViewModel viewModel) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final depot = viewModel.depots[index];
          final quantite = (depot['quantite'] as num?)?.toDouble() ?? 0.0;
          final prixUnitaire = (depot['prix_unitaire'] as num?)?.toDouble() ?? 0.0;
          final montant = quantite * prixUnitaire;
          final dateDepot = DateTime.parse(depot['date_depot'] as String);

          return Card(
            margin: EdgeInsets.fromLTRB(16, index == 0 ? 0 : 0, 16, 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: SizedBox(
                width: 40,
                child: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Icon(Icons.inventory, color: Colors.orange.shade700),
                ),
              ),
              title: Text(
                '${numberFormat.format(quantite)} kg',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Prix unitaire: ${numberFormat.format(prixUnitaire)} FCFA/kg'),
                  Text('Date: ${dateFormat.format(dateDepot)}'),
                ],
              ),
              trailing: Text(
                '${numberFormat.format(montant)} FCFA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          );
        },
        childCount: viewModel.depots.length,
      ),
    );
  }

  Widget _buildVentesTab(AdherentViewModel viewModel) {
    if (viewModel.ventes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune vente enregistrée',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: viewModel.ventes.length,
      itemBuilder: (context, index) {
        final vente = viewModel.ventes[index];
        final quantite = vente['quantite_total'] as double;
        final montantTotal = vente['montant_total'] as double;
        final dateVente = DateTime.parse(vente['date_vente'] as String);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: SizedBox(
              width: 40,
              child: CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Icon(Icons.shopping_cart, color: Colors.purple.shade700),
              ),
            ),
            title: Text(
              '${numberFormat.format(quantite)} kg',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Date: ${dateFormat.format(dateVente)}'),
            trailing: Text(
              '${numberFormat.format(montantTotal)} FCFA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecettesTab(AdherentViewModel viewModel) {
    if (viewModel.recettes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attach_money_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune recette enregistrée',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: viewModel.recettes.length,
      itemBuilder: (context, index) {
        final recette = viewModel.recettes[index];
        final montantBrut = recette['montant_brut'] as double;
        final commissionAmount = recette['commission_amount'] as double;
        final montantNet = recette['montant_net'] as double;
        final dateRecette = DateTime.parse(recette['date_recette'] as String);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: Icon(Icons.attach_money, color: Colors.teal.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paiement reçu',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Date: ${dateFormat.format(dateRecette)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${numberFormat.format(montantNet)} FCFA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Montant brut:',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text('${numberFormat.format(montantBrut)} FCFA'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commission:',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      '-${numberFormat.format(commissionAmount)} FCFA',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Montant net:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${numberFormat.format(montantNet)} FCFA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    String action,
    AdherentModel adherent,
    AdherentViewModel viewModel,
  ) async {
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    
    if (currentUser == null) return;

    switch (action) {
      case 'edit':
        Navigator.pushNamed(
          context,
          AppRoutes.adherentEdit,
          arguments: adherent,
        );
        break;
      case 'activate':
      case 'deactivate':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              action == 'activate' ? 'Réactiver l\'adhérent' : 'Désactiver l\'adhérent',
            ),
            content: Text(
              action == 'activate'
                  ? 'Voulez-vous réactiver ${adherent.fullName} ?'
                  : 'Voulez-vous désactiver ${adherent.fullName} ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: action == 'activate' ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final success = await viewModel.toggleAdherentStatus(
            adherent.id!,
            action == 'activate',
            currentUser.id!,
          );

          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  action == 'activate'
                      ? 'Adhérent réactivé avec succès'
                      : 'Adhérent désactivé avec succès',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
        break;
      case 'export':
        await _exportHistorique(context, adherent, viewModel);
        break;
    }
  }

  Future<void> _exportHistorique(
    BuildContext context,
    AdherentModel adherent,
    AdherentViewModel viewModel,
  ) async {
    try {
      final exportService = ExportService();
      final success = await exportService.exportAdherentHistorique(
        adherent: adherent,
        historique: viewModel.historique,
        depots: viewModel.depots,
        ventes: viewModel.ventes,
        recettes: viewModel.recettes,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Historique exporté avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
