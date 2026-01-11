/// ÉCRAN DÉTAIL ADHÉRENT EXPERT
/// 
/// Fiche complète d'un adhérent avec tous les onglets :
/// - Identité & Filiation
/// - Champs & Superficies
/// - Traitements
/// - Production & Stock
/// - Ventes & Journal de paie
/// - Capital social
/// - Social & Crédits

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/adherent_expert/adherent_expert_model.dart';
import '../../../data/models/adherent_expert/ayant_droit_model.dart';
import '../../../data/models/adherent_expert/champ_parcelle_model.dart';
import '../../../data/models/adherent_expert/traitement_agricole_model.dart';
import '../../../data/models/adherent_expert/production_model.dart';
import '../../../data/models/adherent_model.dart';
import '../../viewmodels/adherent_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/stat_card.dart';
import '../../../config/routes/routes.dart';
import '../../../services/adherent/ayant_droit_service.dart';
import '../../../services/adherent/champ_parcelle_service.dart';
import '../../../services/adherent/traitement_agricole_service.dart';
import '../../../services/adherent/production_service.dart';
import '../../../services/adherent/capital_social_service.dart';
import '../../../services/adherent/credit_social_service.dart';
import '../../../services/adherent/adherent_expert_export_service.dart';
import '../../../services/adherent/adherent_expert_export_service.dart';
import '../../../services/stock/stock_service.dart';
import '../../../services/vente/vente_service.dart';
import '../../../services/recette/recette_service.dart';
import '../../../data/models/stock_model.dart';
import '../../../data/models/vente_model.dart';
import '../../../data/models/vente_detail_model.dart';
import '../../../data/models/recette_model.dart';
import '../../../data/models/adherent_expert/capital_social_model.dart';
import '../../../data/models/adherent_expert/credit_social_model.dart';
import '../../../services/database/db_initializer.dart';
import 'ayant_droit_form_screen.dart';
import 'champ_parcelle_form_screen.dart';
import 'champs_map_screen.dart';
import 'traitement_agricole_form_screen.dart';
import 'capital_social_form_screen.dart';
import 'credit_social_form_screen.dart';

class AdherentExpertDetailScreen extends StatefulWidget {
  final int adherentId;
  
  const AdherentExpertDetailScreen({
    super.key,
    required this.adherentId,
  });
  
  @override
  State<AdherentExpertDetailScreen> createState() => _AdherentExpertDetailScreenState();
}

class _AdherentExpertDetailScreenState extends State<AdherentExpertDetailScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AdherentModel? _adherent;
  bool _isLoading = true;
  List<AyantDroitModel> _ayantsDroit = [];
  List<ChampParcelleModel> _champs = [];
  List<TraitementAgricoleModel> _traitements = [];
  List<StockDepotModel> _depotsStock = [];
  List<ProductionModel> _productions = [];
  List<VenteModel> _ventes = [];
  List<RecetteModel> _recettes = [];
  List<CapitalSocialModel> _souscriptionsCapital = [];
  List<CreditSocialModel> _creditsSociaux = [];
  final AyantDroitService _ayantDroitService = AyantDroitService();
  final ChampParcelleService _champParcelleService = ChampParcelleService();
  final TraitementAgricoleService _traitementService = TraitementAgricoleService();
  final ProductionService _productionService = ProductionService();
  final StockService _stockService = StockService();
  final VenteService _venteService = VenteService();
  final RecetteService _recetteService = RecetteService();
  final CapitalSocialService _capitalSocialService = CapitalSocialService();
  final CreditSocialService _creditSocialService = CreditSocialService();
  final AdherentExpertExportService _exportService = AdherentExpertExportService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdherent();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  AdherentExpertModel? _expertModel;
  
  Future<void> _loadAdherent() async {
    final viewModel = context.read<AdherentViewModel>();
    await viewModel.loadAdherentDetails(widget.adherentId);
    
    if (mounted && viewModel.selectedAdherent != null) {
      final expertModel = await _convertToExpertModel(viewModel.selectedAdherent!, viewModel);
      
      // Charger les ayants droit
      final ayantsDroit = await _ayantDroitService.getAyantsDroitByAdherent(widget.adherentId);
      
      // Charger les champs
      final champs = await _champParcelleService.getChampsByAdherent(widget.adherentId);
      
      // Debug: vérifier les coordonnées récupérées
      for (final champ in champs) {
        print('🔍 _loadAdherent - Champ ${champ.codeChamp}: lat=${champ.latitude}, lng=${champ.longitude}');
      }
      
      // Charger les traitements
      final traitements = await _traitementService.getTraitementsByAdherent(widget.adherentId);
      
      // Charger les dépôts de stock
      final depotsStock = await _stockService.getDepotsByAdherent(widget.adherentId);
      
      // Charger les productions
      final productions = await _productionService.getProductionsByAdherent(widget.adherentId);
      
      // Charger les ventes
      final ventes = await _venteService.getAllVentes(
        adherentId: widget.adherentId,
        statut: 'valide',
      );
      
      // Charger les recettes (paiements)
      print('🔍 Chargement des recettes pour adhérent ID: ${widget.adherentId}');
      final recettes = await _recetteService.getRecettesByAdherent(widget.adherentId);
      print('🔍 Recettes récupérées: ${recettes.length}');
      for (final recette in recettes) {
        print('  - Recette ID ${recette.id}: ${recette.montantNet} FCFA le ${recette.dateRecette}');
      }
      
      // Charger les souscriptions au capital social
      final souscriptionsCapital = await _capitalSocialService.getSouscriptionsByAdherent(widget.adherentId);
      
      // Charger les crédits sociaux
      final creditsSociaux = await _creditSocialService.getCreditsByAdherent(widget.adherentId);
      
      setState(() {
        _adherent = viewModel.selectedAdherent;
        _expertModel = expertModel;
        _ayantsDroit = ayantsDroit;
        _champs = champs;
        _traitements = traitements;
        _depotsStock = depotsStock;
        _productions = productions;
        _ventes = ventes;
        _recettes = recettes;
        _souscriptionsCapital = souscriptionsCapital;
        _creditsSociaux = creditsSociaux;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAyantsDroit() async {
    final ayantsDroit = await _ayantDroitService.getAyantsDroitByAdherent(widget.adherentId);
    if (mounted) {
      setState(() {
        _ayantsDroit = ayantsDroit;
      });
    }
  }

  Future<void> _refreshChamps() async {
    final champs = await _champParcelleService.getChampsByAdherent(widget.adherentId);
    
    // Debug: vérifier les coordonnées récupérées
    for (final champ in champs) {
      print('🔍 _refreshChamps - Champ ${champ.codeChamp}: lat=${champ.latitude}, lng=${champ.longitude}');
    }
    
    if (mounted) {
      setState(() {
        _champs = champs;
      });
    }
  }

  Future<void> _refreshTraitements() async {
    final traitements = await _traitementService.getTraitementsByAdherent(widget.adherentId);
    if (mounted) {
      setState(() {
        _traitements = traitements;
      });
    }
  }

  Future<void> _refreshDepotsStock() async {
    final depotsStock = await _stockService.getDepotsByAdherent(widget.adherentId);
    if (mounted) {
      setState(() {
        _depotsStock = depotsStock;
      });
    }
  }

  Future<void> _refreshProductions() async {
    final productions = await _productionService.getProductionsByAdherent(widget.adherentId);
    if (mounted) {
      setState(() {
        _productions = productions;
      });
    }
  }

  Future<void> _refreshVentes() async {
    final ventes = await _venteService.getAllVentes(
      adherentId: widget.adherentId,
      statut: 'valide',
    );
    if (mounted) {
      setState(() {
        _ventes = ventes;
      });
    }
  }

  Future<void> _refreshRecettes() async {
    print('🔍 Rafraîchissement des recettes pour adhérent ID: ${widget.adherentId}');
    try {
      final recettes = await _recetteService.getRecettesByAdherent(widget.adherentId);
      print('🔍 Recettes récupérées lors du rafraîchissement: ${recettes.length}');
      if (mounted) {
        setState(() {
          _recettes = recettes;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des recettes: $e');
      if (mounted) {
        setState(() {
          _recettes = [];
        });
      }
    }
  }

  /// Créer les recettes manquantes pour les ventes existantes
  Future<void> _createMissingRecettes() async {
    try {
      // Récupérer toutes les ventes valides de cet adhérent
      final ventes = await _venteService.getAllVentes(
        adherentId: widget.adherentId,
        statut: 'valide',
      );

      if (ventes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune vente trouvée pour cet adhérent')),
        );
        return;
      }

      // Récupérer toutes les recettes existantes
      final recettesExistantes = await _recetteService.getRecettesByAdherent(widget.adherentId);
      final ventesAvecRecette = recettesExistantes
          .where((r) => r.venteId != null)
          .map((r) => r.venteId!)
          .toSet();

      // Identifier les ventes sans recette
      final ventesSansRecette = ventes.where((v) => !ventesAvecRecette.contains(v.id)).toList();

      if (ventesSansRecette.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toutes les recettes sont déjà générées')),
        );
        return;
      }

      // Afficher un dialogue de confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Générer les recettes manquantes'),
          content: Text(
            '${ventesSansRecette.length} vente(s) sans recette trouvée(s).\n'
            'Voulez-vous générer les recettes manquantes ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Générer'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      int recettesCreees = 0;
      int erreurs = 0;

      // Récupérer l'utilisateur actuel
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final currentUser = authViewModel.currentUser;
      if (currentUser == null || currentUser.id == null) {
        Navigator.pop(context); // Fermer le dialogue de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: utilisateur non connecté')),
        );
        return;
      }

      // Créer les recettes manquantes
      for (final vente in ventesSansRecette) {
        try {
          print('💰 Création de recette pour vente #${vente.id}');
          
          // Pour les ventes individuelles
          if (vente.isIndividuelle && vente.adherentId != null) {
            await _recetteService.createRecetteFromVente(
              adherentId: vente.adherentId!,
              venteId: vente.id!,
              montantBrut: vente.montantTotal,
              notes: 'Recette générée rétroactivement pour vente #${vente.id}',
              createdBy: currentUser.id!,
              generateEcritureComptable: false,
            );
            recettesCreees++;
          }
          // Pour les ventes groupées, récupérer les détails
          else if (vente.isGroupee) {
            final db = await DatabaseInitializer.database;
            final detailsResult = await db.query(
              'vente_details',
              where: 'vente_id = ? AND adherent_id = ?',
              whereArgs: [vente.id, widget.adherentId],
            );
            
            for (final detailMap in detailsResult) {
              final detail = VenteDetailModel.fromMap(detailMap);
              await _recetteService.createRecetteFromVente(
                adherentId: detail.adherentId,
                venteId: vente.id!,
                montantBrut: detail.montant,
                notes: 'Recette générée rétroactivement pour vente groupée #${vente.id}',
                createdBy: currentUser.id!,
                generateEcritureComptable: false,
              );
              recettesCreees++;
            }
          }
        } catch (e) {
          print('❌ Erreur lors de la création de la recette pour vente #${vente.id}: $e');
          erreurs++;
        }
      }

      Navigator.pop(context); // Fermer le dialogue de chargement

      // Rafraîchir les recettes
      await _refreshRecettes();

      // Afficher un message de résultat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$recettesCreees recette(s) créée(s)${erreurs > 0 ? ', $erreurs erreur(s)' : ''}',
          ),
          backgroundColor: erreurs > 0 ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Erreur lors de la création des recettes manquantes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshCapitalSocial() async {
    final souscriptions = await _capitalSocialService.getSouscriptionsByAdherent(widget.adherentId);
    if (mounted) {
      setState(() {
        _souscriptionsCapital = souscriptions;
      });
      // Recharger les indicateurs pour mettre à jour les statistiques
      await _loadAdherent();
    }
  }

  Future<void> _refreshCreditsSociaux() async {
    final credits = await _creditSocialService.getCreditsByAdherent(widget.adherentId);
    if (mounted) {
      setState(() {
        _creditsSociaux = credits;
      });
      // Recharger les indicateurs pour mettre à jour le solde débiteur
      await _loadAdherent();
    }
  }
  
  /// Convertir AdherentModel en AdherentExpertModel pour l'affichage
  Future<AdherentExpertModel> _convertToExpertModel(AdherentModel adherent, AdherentViewModel viewModel) async {
    // Calculer les indicateurs
    final indicators = await viewModel.calculateExpertIndicators(adherent.id!);
    
    return AdherentExpertModel(
      id: adherent.id,
      codeAdherent: adherent.code,
      typePersonne: adherent.categorie ?? 'producteur',
      statut: adherent.statut ?? 'actif',
      dateAdhesion: adherent.dateAdhesion,
      siteCooperative: adherent.siteCooperative,
      section: adherent.section,
      village: adherent.village,
      nom: adherent.nom,
      prenom: adherent.prenom,
      sexe: adherent.sexe,
      dateNaissance: adherent.dateNaissance,
      lieuNaissance: adherent.lieuNaissance,
      nationalite: adherent.nationalite ?? 'Camerounais',
      typePiece: adherent.typePiece,
      numeroPiece: adherent.numeroPiece,
      telephone: adherent.telephone,
      email: adherent.email,
      adresse: adherent.adresse,
      nomPere: adherent.nomPere,
      nomMere: adherent.nomMere,
      conjoint: adherent.conjoint,
      nombreEnfants: adherent.nombreEnfants ?? 0,
      situationMatrimoniale: null, // À implémenter dans le modèle
      superficieTotaleCultivee: adherent.superficieTotaleCultivee ?? 0.0,
      nombreChamps: adherent.nombreChamps ?? 0,
      rendementMoyenHa: indicators['rendementMoyenHa'] ?? 0.0,
      tonnageTotalProduit: indicators['tonnageTotalProduit'] ?? 0.0,
      tonnageTotalVendu: indicators['tonnageTotalVendu'] ?? 0.0,
      tonnageDisponibleStock: indicators['tonnageDisponibleStock'] ?? 0.0,
      capitalSocialSouscrit: indicators['capitalSocialSouscrit'] ?? 0.0,
      capitalSocialLibere: indicators['capitalSocialLibere'] ?? 0.0,
      capitalSocialRestant: indicators['capitalSocialRestant'] ?? 0.0,
      montantTotalVentes: indicators['montantTotalVentes'] ?? 0.0,
      montantTotalPaye: indicators['montantTotalPaye'] ?? 0.0,
      soldeCrediteur: indicators['soldeCrediteur'] ?? 0.0,
      soldeDebiteur: indicators['soldeDebiteur'] ?? 0.0,
      createdAt: adherent.createdAt,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AdherentViewModel>(
          builder: (context, viewModel, child) {
            final adherent = viewModel.selectedAdherent;
            return Text(adherent?.fullName ?? 'Vue Expert');
          },
        ),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Retour',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter le dossier',
            onPressed: _adherent != null && _expertModel != null ? _exportDossier : null,
          ),
        ],
      ),
      body: Consumer<AdherentViewModel>(
        builder: (context, viewModel, child) {
          if (_isLoading || (viewModel.isLoading && _adherent == null)) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final adherent = viewModel.selectedAdherent;
          if (adherent == null || _expertModel == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Adhérent non trouvé'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }
          
          final expertModel = _expertModel!;
          
          return Column(
            children: [
              // Header Résumé
              _buildHeader(expertModel),
        
              // Onglets
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.brown.shade700,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.brown.shade700,
                tabs: const [
                  Tab(text: 'Identité & Filiation'),
                  Tab(text: 'Champs & Superficies'),
                  Tab(text: 'Traitements'),
                  Tab(text: 'Production & Stock'),
                  Tab(text: 'Ventes & Paiements'),
                  Tab(text: 'Capital Social'),
                  Tab(text: 'Social & Crédits'),
                ],
              ),
        
              // Contenu des onglets
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIdentiteTab(expertModel),
                    _buildChampsTab(expertModel),
                    _buildTraitementsTab(expertModel),
                    _buildProductionTab(expertModel),
                    _buildVentesTab(expertModel),
                    _buildCapitalTab(expertModel),
                    _buildSocialTab(expertModel),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// Header avec résumé des indicateurs
  Widget _buildHeader(AdherentExpertModel adherent) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.brown.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Photo profil
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.brown.shade200,
                child: adherent.photoPath != null
                    ? Image.asset(adherent.photoPath!)
                    : Text(
                        adherent.prenom[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32),
                      ),
              ),
              const SizedBox(width: 16),
              
              // Informations principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adherent.fullName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      adherent.codeAdherent,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Badge statut
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: adherent.isActif ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        adherent.statut.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Indicateurs en cartes
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Capital Social',
                  value: '${adherent.capitalSocialSouscrit.toStringAsFixed(0)} FCFA',
                  subtitle: 'Libéré: ${adherent.capitalSocialLibere.toStringAsFixed(0)}',
                  icon: Icons.account_balance,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  title: 'Tonnage',
                  value: '${adherent.tonnageTotalProduit.toStringAsFixed(2)} t',
                  subtitle: 'Disponible: ${adherent.tonnageDisponibleStock.toStringAsFixed(2)}',
                  icon: Icons.inventory,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  title: 'Solde',
                  value: '${adherent.soldeCrediteur.toStringAsFixed(0)} FCFA',
                  subtitle: adherent.soldeDebiteur > 0 
                      ? 'Dû: ${adherent.soldeDebiteur.toStringAsFixed(0)}'
                      : 'Créditeur',
                  icon: Icons.account_balance_wallet,
                  color: adherent.soldeCrediteur >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Onglet Identité & Filiation
  Widget _buildIdentiteTab(AdherentExpertModel adherent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Informations Personnelles'),
          _buildInfoRow('Nom', adherent.nom),
          _buildInfoRow('Prénom', adherent.prenom),
          _buildInfoRow('Sexe', adherent.sexe ?? 'Non renseigné'),
          _buildInfoRow('Date de naissance', 
              adherent.dateNaissance != null 
                  ? '${adherent.dateNaissance!.day}/${adherent.dateNaissance!.month}/${adherent.dateNaissance!.year}'
                  : 'Non renseigné'),
          _buildInfoRow('Âge', adherent.age?.toString() ?? 'Non renseigné'),
          _buildInfoRow('Nationalité', adherent.nationalite),
          _buildInfoRow('Téléphone', adherent.telephone ?? 'Non renseigné'),
          _buildInfoRow('Email', adherent.email ?? 'Non renseigné'),
          _buildInfoRow('Adresse', adherent.adresse ?? 'Non renseigné'),
          _buildInfoRow('Village', adherent.village ?? 'Non renseigné'),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Situation Familiale'),
          _buildInfoRow('Père', adherent.nomPere ?? 'Non renseigné'),
          _buildInfoRow('Mère', adherent.nomMere ?? 'Non renseigné'),
          _buildInfoRow('Conjoint', adherent.conjoint ?? 'Non renseigné'),
          _buildInfoRow('Nombre d\'enfants', adherent.nombreEnfants.toString()),
          _buildInfoRow('Situation matrimoniale', 
              adherent.situationMatrimoniale ?? 'Non renseigné'),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          _buildSectionTitle('Ayants Droit'),
          ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AyantDroitFormScreen(
                        adherentId: widget.adherentId,
                      ),
                    ),
                  );
                  if (result == true) {
                    await _refreshAyantsDroit();
                  }
            },
            icon: const Icon(Icons.person_add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_ayantsDroit.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun ayant droit enregistré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._ayantsDroit.map((ayantDroit) => _buildAyantDroitCard(ayantDroit)),
        ],
      ),
    );
  }
  
  /// Onglet Champs & Superficies
  Widget _buildChampsTab(AdherentExpertModel adherent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Champs & Parcelles'),
              Row(
                children: [
                  // Bouton pour voir la carte
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChampsMapScreen(
                            adherentId: widget.adherentId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map),
                    tooltip: 'Voir sur la carte',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton pour ajouter un champ
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChampParcelleFormScreen(
                            adherentId: widget.adherentId,
                          ),
                        ),
                      );
                      if (result == true) {
                        await _refreshChamps();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Statistiques champs
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          _champs.length.toString(),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade700,
                          ),
                        ),
                        const Text('Champs totaux'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${_champs.fold<double>(0.0, (sum, champ) => sum + champ.superficie).toStringAsFixed(2)} ha',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade700,
                          ),
                        ),
                        const Text('Superficie totale'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Liste des champs
          if (_champs.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.agriculture_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun champ enregistré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._champs.map((champ) => _buildChampCard(champ)),
        ],
      ),
    );
  }
  
  /// Onglet Traitements
  Widget _buildTraitementsTab(AdherentExpertModel adherent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Traitements Agricoles'),
              ElevatedButton.icon(
                onPressed: () async {
                  // Si un seul champ, présélectionner
                  int? champIdPreselectionne;
                  if (_champs.length == 1) {
                    champIdPreselectionne = _champs.first.id;
                  }
                  
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TraitementAgricoleFormScreen(
                        adherentId: widget.adherentId,
                        champIdPreselectionne: champIdPreselectionne,
                      ),
                    ),
                  );
                  if (result == true) {
                    await _refreshTraitements();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Statistiques traitements
          if (_traitements.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            _traitements.length.toString(),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade700,
                            ),
                          ),
                          const Text('Traitements totaux'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '${_traitements.fold<double>(0.0, (sum, t) => sum + t.coutTraitement).toStringAsFixed(0)} FCFA',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const Text('Coût total'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Graphique d'évolution des traitements par type
          if (_traitements.isNotEmpty)
            _buildTraitementsEvolutionChart(),
          
          const SizedBox(height: 16),
          
          // Liste des traitements
          if (_traitements.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.science_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun traitement enregistré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._traitements.map((traitement) => _buildTraitementCard(traitement)),
        ],
      ),
    );
  }

  Widget _buildTraitementCard(TraitementAgricoleModel traitement) {
    // Trouver le nom du champ
    final champ = _champs.firstWhere(
      (c) => c.id == traitement.champId,
      orElse: () => ChampParcelleModel(
        id: traitement.champId,
        adherentId: widget.adherentId,
        codeChamp: 'N/A',
        nomChamp: 'Champ inconnu',
        superficie: 0.0,
        createdAt: DateTime.now(),
      ),
    );
    final champNom = champ.nomChamp ?? champ.codeChamp;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    String getTypeLabel(String type) {
      switch (type) {
        case 'engrais':
          return 'Engrais';
        case 'pesticide':
          return 'Pesticide';
        case 'entretien':
          return 'Entretien';
        case 'autre':
          return 'Autre';
        default:
          return type;
      }
    }

    Color getTypeColor(String type) {
      switch (type) {
        case 'engrais':
          return Colors.green;
        case 'pesticide':
          return Colors.red;
        case 'entretien':
          return Colors.blue;
        case 'autre':
          return Colors.grey;
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: getTypeColor(traitement.typeTraitement).withOpacity(0.2),
          child: Icon(
            Icons.science,
            color: getTypeColor(traitement.typeTraitement),
          ),
        ),
        title: Text(
          traitement.produitUtilise,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    getTypeLabel(traitement.typeTraitement),
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: getTypeColor(traitement.typeTraitement),
                ),
                const SizedBox(width: 8),
                Text('Champ: $champNom'),
              ],
            ),
            Text('Quantité: ${numberFormat.format(traitement.quantite)} ${traitement.uniteQuantite}'),
            Text('Date: ${dateFormat.format(traitement.dateTraitement)}'),
            if (traitement.coutTraitement > 0)
              Text(
                'Coût: ${numberFormat.format(traitement.coutTraitement)} FCFA',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
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
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TraitementAgricoleFormScreen(
                    adherentId: widget.adherentId,
                    traitement: traitement,
                  ),
                ),
              );
              if (result == true) {
                await _refreshTraitements();
              }
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmer la suppression'),
                  content: Text(
                    'Êtes-vous sûr de vouloir supprimer le traitement "${traitement.produitUtilise}" ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  final authViewModel = context.read<AuthViewModel>();
                  final currentUser = authViewModel.currentUser;
                  
                  if (currentUser != null) {
                    await _traitementService.deleteTraitement(
                      traitement.id!,
                      currentUser.id!,
                    );
                    await _refreshTraitements();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Traitement supprimé avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            }
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (traitement.operateur != null)
                  _buildInfoRow('Opérateur', traitement.operateur!),
                if (traitement.observation != null && traitement.observation!.isNotEmpty)
                  _buildInfoRow('Observations', traitement.observation!),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Onglet Production & Stock
  Widget _buildProductionTab(AdherentExpertModel adherent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques production
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${adherent.tonnageTotalProduit.toStringAsFixed(2)} t',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Text('Tonnage total produit'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${adherent.tonnageTotalVendu.toStringAsFixed(2)} t',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const Text('Stock réfracté'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${adherent.tonnageDisponibleStock.toStringAsFixed(2)} t',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const Text('Stock disponible'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Section Productions
          _buildSectionTitle('Productions'),
          const SizedBox(height: 8),
          
          if (_productions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.agriculture_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
                      Text(
                        'Aucune production enregistrée',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._productions.map((production) => _buildProductionCard(production)),
          
          const SizedBox(height: 24),
          
          // Section Dépôts de Stock
          _buildSectionTitle('Dépôts de Stock'),
          const SizedBox(height: 8),
          
          if (_depotsStock.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun dépôt de stock enregistré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._depotsStock.map((depot) => _buildDepotStockCard(depot)),
        ],
      ),
    );
  }

  Widget _buildProductionCard(ProductionModel production) {
    // Trouver le nom du champ
    String champNom = 'Non spécifié';
    if (production.champId != null) {
      final champ = _champs.firstWhere(
        (c) => c.id == production.champId,
        orElse: () => ChampParcelleModel(
          id: production.champId,
          adherentId: widget.adherentId,
          codeChamp: 'N/A',
          nomChamp: 'Champ inconnu',
          superficie: 0.0,
          createdAt: DateTime.now(),
        ),
      );
      champNom = champ.nomChamp ?? champ.codeChamp;
    }
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    String getQualiteLabel(String qualite) {
      switch (qualite) {
        case 'premium':
          return 'Premium';
        case 'bio':
          return 'Bio';
        case 'standard':
        default:
          return 'Standard';
      }
    }

    Color getQualiteColor(String qualite) {
      switch (qualite) {
        case 'premium':
          return Colors.purple;
        case 'bio':
          return Colors.green;
        case 'standard':
        default:
          return Colors.blue;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: getQualiteColor(production.qualite).withOpacity(0.2),
          child: Icon(
            Icons.agriculture,
            color: getQualiteColor(production.qualite),
          ),
        ),
        title: Text(
          '${numberFormat.format(production.tonnageNet)} t',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    getQualiteLabel(production.qualite),
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: getQualiteColor(production.qualite),
                ),
                const SizedBox(width: 8),
                Text('Campagne: ${production.campagne}'),
              ],
            ),
            Text('Date: ${dateFormat.format(production.dateRecolte)}'),
            if (champNom != 'Non spécifié')
              Text('Champ: $champNom'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Tonnage brut', '${numberFormat.format(production.tonnageBrut)} t'),
                _buildInfoRow('Tonnage net', '${numberFormat.format(production.tonnageNet)} t'),
                if (production.tauxHumidite > 0)
                  _buildInfoRow('Taux d\'humidité', '${production.tauxHumidite.toStringAsFixed(1)}%'),
                if (production.observation != null && production.observation!.isNotEmpty)
                  _buildInfoRow('Observations', production.observation!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepotStockCard(StockDepotModel depot) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Icon(Icons.inventory_2, color: Colors.orange.shade700),
        ),
        title: Text(
          '${numberFormat.format(depot.poidsNet)} kg',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${dateFormat.format(depot.dateDepot)}'),
            if (depot.qualite != null)
              Text('Qualité: ${depot.qualite}'),
            if (depot.humidite != null)
              Text('Humidité: ${depot.humidite!.toStringAsFixed(1)}%'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Stock brut', '${numberFormat.format(depot.stockBrut)} kg'),
                if (depot.poidsSac != null && depot.poidsSac! > 0)
                  _buildInfoRow('Poids sac', '${numberFormat.format(depot.poidsSac!)} kg'),
                if (depot.poidsDechets != null && depot.poidsDechets! > 0)
                  _buildInfoRow('Poids déchets', '${numberFormat.format(depot.poidsDechets!)} kg'),
                if (depot.autres != null && depot.autres! > 0)
                  _buildInfoRow('Autres', '${numberFormat.format(depot.autres!)} kg'),
                _buildInfoRow('Poids net', '${numberFormat.format(depot.poidsNet)} kg'),
                if (depot.prixUnitaire != null)
                  _buildInfoRow('Prix unitaire', '${numberFormat.format(depot.prixUnitaire!)} FCFA/kg'),
                if (depot.observations != null && depot.observations!.isNotEmpty)
                  _buildInfoRow('Observations', depot.observations!),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Onglet Ventes & Journal de paie
  Widget _buildVentesTab(AdherentExpertModel adherent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques financières
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${NumberFormat('#,##0').format(adherent.montantTotalVentes)} FCFA',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const Text('Montant total ventes'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${NumberFormat('#,##0').format(adherent.montantTotalPaye)} FCFA',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Text('Montant total payé'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${NumberFormat('#,##0').format(adherent.soldeCrediteur)} FCFA',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: adherent.soldeCrediteur > 0 ? Colors.orange.shade700 : Colors.grey.shade700,
                          ),
                        ),
                        const Text('Solde créditeur'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Graphique d'évolution Ventes vs Paiements
          _buildVentesPaiementsEvolutionChart(),
          
          const SizedBox(height: 24),
          
          // Section Ventes
          _buildSectionTitle('Ventes'),
          const SizedBox(height: 8),
          
          if (_ventes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune vente enregistrée',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._ventes.map((vente) => _buildVenteCard(vente)),
          
          const SizedBox(height: 24),
          
          // Section Paiements (Recettes)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Paiements (Recettes)'),
              if (_ventes.isNotEmpty && _recettes.isEmpty)
                TextButton.icon(
                  onPressed: () async {
                    await _createMissingRecettes();
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Générer les recettes'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (_recettes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.payment_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun paiement enregistré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (_ventes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Des ventes existent mais aucune recette n\'a été générée.',
                          style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _createMissingRecettes();
                          },
                          icon: const Icon(Icons.sync),
                          label: const Text('Générer les recettes manquantes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            ..._recettes.map((recette) => _buildRecetteCard(recette)),
        ],
      ),
    );
  }

  Widget _buildVenteCard(VenteModel vente) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    String getModePaiementLabel(String? mode) {
      if (mode == null) return 'Non spécifié';
      switch (mode) {
        case 'especes':
          return 'Espèces';
        case 'mobile_money':
          return 'Mobile Money';
        case 'virement':
          return 'Virement';
        default:
          return mode;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.shopping_cart, color: Colors.blue.shade700),
        ),
        title: Text(
          '${numberFormat.format(vente.montantTotal)} FCFA',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${dateFormat.format(vente.dateVente)}'),
            Text('Quantité: ${numberFormat.format(vente.quantiteTotal)} kg'),
            Text('Prix unitaire: ${numberFormat.format(vente.prixUnitaire)} FCFA/kg'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Type', vente.isIndividuelle ? 'Individuelle' : 'Groupée'),
                if (vente.acheteur != null)
                  _buildInfoRow('Acheteur', vente.acheteur!),
                _buildInfoRow('Mode de paiement', getModePaiementLabel(vente.modePaiement)),
                if (vente.notes != null && vente.notes!.isNotEmpty)
                  _buildInfoRow('Notes', vente.notes!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecetteCard(RecetteModel recette) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(Icons.payment, color: Colors.green.shade700),
        ),
        title: Text(
          '${numberFormat.format(recette.montantNet)} FCFA',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${dateFormat.format(recette.dateRecette)}'),
            Text('Montant brut: ${numberFormat.format(recette.montantBrut)} FCFA'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Montant brut', '${numberFormat.format(recette.montantBrut)} FCFA'),
                _buildInfoRow('Taux commission', '${(recette.commissionRate * 100).toStringAsFixed(1)}%'),
                _buildInfoRow('Commission', '${numberFormat.format(recette.commissionAmount)} FCFA'),
                _buildInfoRow('Montant net', '${numberFormat.format(recette.montantNet)} FCFA'),
                if (recette.notes != null && recette.notes!.isNotEmpty)
                  _buildInfoRow('Notes', recette.notes!),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Onglet Capital Social
  Widget _buildCapitalTab(AdherentExpertModel adherent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Capital Social'),
          
          // Résumé capital
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow('Capital souscrit', 
                      '${adherent.capitalSocialSouscrit.toStringAsFixed(0)} FCFA'),
                  _buildInfoRow('Capital libéré', 
                      '${adherent.capitalSocialLibere.toStringAsFixed(0)} FCFA'),
                  _buildInfoRow('Capital restant', 
                      '${adherent.capitalSocialRestant.toStringAsFixed(0)} FCFA'),
                  const Divider(),
                  LinearProgressIndicator(
                    value: adherent.capitalSocialSouscrit > 0
                        ? adherent.capitalSocialLibere / adherent.capitalSocialSouscrit
                        : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${((adherent.capitalSocialLibere / (adherent.capitalSocialSouscrit > 0 ? adherent.capitalSocialSouscrit : 1)) * 100).toStringAsFixed(1)}% libéré',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Section Souscriptions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Souscriptions au Capital Social'),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CapitalSocialFormScreen(
                        adherentId: widget.adherentId,
                      ),
                    ),
                  );
                  if (result == true) {
                    await _refreshCapitalSocial();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Liste des souscriptions
          if (_souscriptionsCapital.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune souscription enregistrée',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._souscriptionsCapital.map((souscription) => _buildSouscriptionCard(souscription)),
        ],
      ),
    );
  }

  Widget _buildSouscriptionCard(CapitalSocialModel souscription) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    String getStatutLabel(String statut) {
      switch (statut) {
        case 'souscrit':
          return 'Souscrit';
        case 'partiellement_libere':
          return 'Partiellement libéré';
        case 'libere':
          return 'Libéré';
        case 'annule':
          return 'Annulé';
        default:
          return statut;
      }
    }

    Color getStatutColor(String statut) {
      switch (statut) {
        case 'souscrit':
          return Colors.orange;
        case 'partiellement_libere':
          return Colors.blue;
        case 'libere':
          return Colors.green;
        case 'annule':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    final capitalLibere = souscription.nombrePartsLiberees * souscription.valeurPart;
    final capitalRestant = souscription.nombrePartsRestantes * souscription.valeurPart;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: getStatutColor(souscription.statut).withOpacity(0.2),
          child: Icon(
            Icons.account_balance,
            color: getStatutColor(souscription.statut),
          ),
        ),
        title: Text(
          '${numberFormat.format(souscription.capitalTotal)} FCFA',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    getStatutLabel(souscription.statut),
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: getStatutColor(souscription.statut),
                ),
                const SizedBox(width: 8),
                Text('Date: ${dateFormat.format(souscription.dateSouscription)}'),
              ],
            ),
            Text('Parts: ${souscription.nombrePartsSouscrites} (${souscription.nombrePartsLiberees} libérées)'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Nombre de parts souscrites', souscription.nombrePartsSouscrites.toString()),
                _buildInfoRow('Valeur d\'une part', '${numberFormat.format(souscription.valeurPart)} FCFA'),
                _buildInfoRow('Capital total souscrit', '${numberFormat.format(souscription.capitalTotal)} FCFA'),
                const Divider(),
                _buildInfoRow('Parts libérées', souscription.nombrePartsLiberees.toString()),
                _buildInfoRow('Capital libéré', '${numberFormat.format(capitalLibere)} FCFA'),
                const Divider(),
                _buildInfoRow('Parts restantes', souscription.nombrePartsRestantes.toString()),
                _buildInfoRow('Capital restant', '${numberFormat.format(capitalRestant)} FCFA'),
                if (souscription.dateLiberation != null)
                  _buildInfoRow('Date de libération', dateFormat.format(souscription.dateLiberation!)),
                if (souscription.notes != null && souscription.notes!.isNotEmpty)
                  _buildInfoRow('Notes', souscription.notes!),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!souscription.isLibere)
                      TextButton.icon(
                        onPressed: () async {
                          await _showLibererPartsDialog(souscription);
                        },
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Libérer des parts'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                        ),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CapitalSocialFormScreen(
                              adherentId: widget.adherentId,
                              souscription: souscription,
                            ),
                          ),
                        );
                        if (result == true) {
                          await _refreshCapitalSocial();
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmer l\'annulation'),
                            content: Text(
                              'Êtes-vous sûr de vouloir annuler cette souscription ?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Annuler la souscription'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            final authViewModel = context.read<AuthViewModel>();
                            final currentUser = authViewModel.currentUser;
                            
                            if (currentUser != null) {
                              await _capitalSocialService.annulerSouscription(
                                souscription.id!,
                                currentUser.id!,
                              );
                              await _refreshCapitalSocial();
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Souscription annulée avec succès'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                      label: const Text('Annuler', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLibererPartsDialog(CapitalSocialModel souscription) async {
    final nombrePartsController = TextEditingController();
    DateTime? dateLiberation = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Libérer des parts'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Parts restantes: ${souscription.nombrePartsRestantes}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nombrePartsController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de parts à libérer *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dateLiberation ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() {
                        dateLiberation = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date de libération *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      dateLiberation != null
                          ? DateFormat('dd/MM/yyyy').format(dateLiberation!)
                          : 'Sélectionner une date',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final nombreParts = int.tryParse(nombrePartsController.text.trim());
                if (nombreParts == null || nombreParts <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Veuillez entrer un nombre de parts valide')),
                  );
                  return;
                }
                if (nombreParts > souscription.nombrePartsRestantes) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Le nombre de parts ne peut pas dépasser ${souscription.nombrePartsRestantes}')),
                  );
                  return;
                }
                if (dateLiberation == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Veuillez sélectionner une date')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, {
                  'nombreParts': nombreParts,
                  'dateLiberation': dateLiberation,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Libérer'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final authViewModel = context.read<AuthViewModel>();
        final currentUser = authViewModel.currentUser;
        
        if (currentUser != null) {
          await _capitalSocialService.libererParts(
            id: souscription.id!,
            nombrePartsALiberer: result['nombreParts'] as int,
            dateLiberation: result['dateLiberation'] as DateTime,
            updatedBy: currentUser.id!,
          );
          await _refreshCapitalSocial();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Parts libérées avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  /// Onglet Social & Crédits
  Widget _buildSocialTab(AdherentExpertModel adherent) {
    // Calculer les statistiques des crédits
    final stats = _calculateCreditsStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques crédits
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${NumberFormat('#,##0').format(stats['montantTotalOctroye'])} FCFA',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const Text('Montant total octroyé'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${NumberFormat('#,##0').format(stats['soldeTotalRestant'])} FCFA',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const Text('Solde restant'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          stats['nombreCredits'].toString(),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        const Text('Nombre de crédits'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Section Crédits
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Crédits Sociaux'),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreditSocialFormScreen(
                        adherentId: widget.adherentId,
                      ),
                    ),
                  );
                  if (result == true) {
                    await _refreshCreditsSociaux();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Liste des crédits
          if (_creditsSociaux.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun crédit enregistré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._creditsSociaux.map((credit) => _buildCreditCard(credit)),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateCreditsStats() {
    if (_creditsSociaux.isEmpty) {
      return {
        'nombreCredits': 0,
        'montantTotalOctroye': 0.0,
        'soldeTotalRestant': 0.0,
        'montantTotalRembourse': 0.0,
      };
    }

    final montantTotalOctroye = _creditsSociaux.fold<double>(
      0.0, 
      (sum, credit) => sum + credit.montant,
    );
    
    final soldeTotalRestant = _creditsSociaux.fold<double>(
      0.0, 
      (sum, credit) => sum + credit.soldeRestant,
    );

    return {
      'nombreCredits': _creditsSociaux.length,
      'montantTotalOctroye': montantTotalOctroye,
      'soldeTotalRestant': soldeTotalRestant,
      'montantTotalRembourse': montantTotalOctroye - soldeTotalRestant,
    };
  }

  Widget _buildCreditCard(CreditSocialModel credit) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    String getTypeCreditLabel(String type) {
      switch (type) {
        case 'credit_produit':
          return 'Crédit Produit';
        case 'credit_argent':
          return 'Crédit Argent';
        default:
          return type;
      }
    }

    Color getTypeCreditColor(String type) {
      switch (type) {
        case 'credit_produit':
          return Colors.green;
        case 'credit_argent':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    String getStatutLabel(String statut) {
      switch (statut) {
        case 'non_rembourse':
          return 'Non remboursé';
        case 'partiellement_rembourse':
          return 'Partiellement remboursé';
        case 'rembourse':
          return 'Remboursé';
        case 'annule':
          return 'Annulé';
        default:
          return statut;
      }
    }

    Color getStatutColor(String statut) {
      switch (statut) {
        case 'non_rembourse':
          return Colors.red;
        case 'partiellement_rembourse':
          return Colors.orange;
        case 'rembourse':
          return Colors.green;
        case 'annule':
          return Colors.grey;
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: getTypeCreditColor(credit.typeCredit).withOpacity(0.2),
          child: Icon(
            credit.isCreditProduit ? Icons.agriculture : Icons.account_balance_wallet,
            color: getTypeCreditColor(credit.typeCredit),
          ),
        ),
        title: Text(
          '${numberFormat.format(credit.montant)} FCFA',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    getTypeCreditLabel(credit.typeCredit),
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: getTypeCreditColor(credit.typeCredit),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    getStatutLabel(credit.statutRemboursement),
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: getStatutColor(credit.statutRemboursement),
                ),
              ],
            ),
            Text('Date: ${dateFormat.format(credit.dateOctroi)}'),
            if (credit.soldeRestant > 0)
              Text(
                'Solde restant: ${numberFormat.format(credit.soldeRestant)} FCFA',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Type de crédit', getTypeCreditLabel(credit.typeCredit)),
                if (credit.isCreditProduit) ...[
                  if (credit.quantiteProduit != null)
                    _buildInfoRow('Quantité de produit', '${numberFormat.format(credit.quantiteProduit!)} kg'),
                  if (credit.typeProduit != null)
                    _buildInfoRow('Type de produit', credit.typeProduit!),
                ],
                _buildInfoRow('Montant octroyé', '${numberFormat.format(credit.montant)} FCFA'),
                _buildInfoRow('Montant remboursé', '${numberFormat.format(credit.montantRembourse)} FCFA'),
                _buildInfoRow('Solde restant', '${numberFormat.format(credit.soldeRestant)} FCFA'),
                _buildInfoRow('Pourcentage remboursé', '${credit.pourcentageRembourse.toStringAsFixed(1)}%'),
                _buildInfoRow('Motif', credit.motif),
                if (credit.echeanceRemboursement != null)
                  _buildInfoRow('Date d\'échéance', dateFormat.format(credit.echeanceRemboursement!)),
                if (credit.observation != null && credit.observation!.isNotEmpty)
                  _buildInfoRow('Observations', credit.observation!),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!credit.isRembourse && !credit.isAnnule)
                      TextButton.icon(
                        onPressed: () async {
                          await _showRemboursementDialog(credit);
                        },
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Enregistrer remboursement'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                        ),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreditSocialFormScreen(
                              adherentId: widget.adherentId,
                              credit: credit,
                            ),
                          ),
                        );
                        if (result == true) {
                          await _refreshCreditsSociaux();
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmer l\'annulation'),
                            content: Text(
                              'Êtes-vous sûr de vouloir annuler ce crédit ?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Annuler le crédit'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            final authViewModel = context.read<AuthViewModel>();
                            final currentUser = authViewModel.currentUser;
                            
                            if (currentUser != null) {
                              await _creditSocialService.annulerCredit(
                                credit.id!,
                                currentUser.id!,
                              );
                              await _refreshCreditsSociaux();
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Crédit annulé avec succès'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                      label: const Text('Annuler', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRemboursementDialog(CreditSocialModel credit) async {
    final montantController = TextEditingController();
    DateTime? dateRemboursement = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Enregistrer un remboursement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Solde restant: ${NumberFormat('#,##0').format(credit.soldeRestant)} FCFA',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: montantController,
                  decoration: InputDecoration(
                    labelText: 'Montant remboursé (FCFA) *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dateRemboursement ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() {
                        dateRemboursement = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date de remboursement *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      dateRemboursement != null
                          ? DateFormat('dd/MM/yyyy').format(dateRemboursement!)
                          : 'Sélectionner une date',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final montant = double.tryParse(montantController.text.trim());
                if (montant == null || montant <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Veuillez entrer un montant valide')),
                  );
                  return;
                }
                if (montant > credit.soldeRestant) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Le montant ne peut pas dépasser ${credit.soldeRestant.toStringAsFixed(0)} FCFA')),
                  );
                  return;
                }
                if (dateRemboursement == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Veuillez sélectionner une date')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, {
                  'montant': montant,
                  'date': dateRemboursement,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final authViewModel = context.read<AuthViewModel>();
        final currentUser = authViewModel.currentUser;
        
        if (currentUser != null) {
          await _creditSocialService.enregistrerRemboursement(
            id: credit.id!,
            montantRembourse: result['montant'] as double,
            dateRemboursement: result['date'] as DateTime,
            updatedBy: currentUser.id!,
          );
          await _refreshCreditsSociaux();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Remboursement enregistré avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.brown.shade700,
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label :',
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

  Widget _buildAyantDroitCard(AyantDroitModel ayantDroit) {
    String getLienLabel(String lien) {
      switch (lien) {
        case 'enfant':
          return 'Enfant';
        case 'conjoint':
          return 'Conjoint(e)';
        case 'parent':
          return 'Parent';
        case 'frere_soeur':
          return 'Frère/Sœur';
        case 'autre':
          return 'Autre';
        default:
          return lien;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.brown.shade100,
          child: Icon(Icons.person, color: Colors.brown.shade700),
        ),
        title: Text(
          ayantDroit.nomComplet,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Lien: ${getLienLabel(ayantDroit.lienFamilial)}'),
            if (ayantDroit.dateNaissance != null)
              Text('Âge: ${ayantDroit.age} ans'),
            if (ayantDroit.contact != null)
              Text('Contact: ${ayantDroit.contact}'),
            if (ayantDroit.beneficiaireSocial)
              Chip(
                label: const Text('Bénéficiaire social'),
                backgroundColor: Colors.green.shade100,
                labelStyle: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
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
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AyantDroitFormScreen(
                    adherentId: widget.adherentId,
                    ayantDroit: ayantDroit,
                  ),
                ),
              );
              if (result == true) {
                await _refreshAyantsDroit();
              }
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmer la suppression'),
                  content: Text(
                    'Êtes-vous sûr de vouloir supprimer ${ayantDroit.nomComplet} ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  final authViewModel = context.read<AuthViewModel>();
                  final currentUser = authViewModel.currentUser;
                  
                  if (currentUser != null) {
                    await _ayantDroitService.deleteAyantDroit(
                      ayantDroit.id!,
                      currentUser.id!,
                    );
                    await _refreshAyantsDroit();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ayant droit supprimé avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildChampCard(ChampParcelleModel champ) {
    String getEtatLabel(String etat) {
      switch (etat) {
        case 'actif':
          return 'Actif';
        case 'repos':
          return 'En repos';
        case 'abandonne':
          return 'Abandonné';
        case 'en_preparation':
          return 'En préparation';
        default:
          return etat;
      }
    }

    Color getEtatColor(String etat) {
      switch (etat) {
        case 'actif':
          return Colors.green;
        case 'repos':
          return Colors.orange;
        case 'abandonne':
          return Colors.red;
        case 'en_preparation':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    String getTypeSolLabel(String? typeSol) {
      if (typeSol == null) return 'Non renseigné';
      return typeSol.replaceAll('_', ' ').split(' ').map((word) {
        return word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1);
      }).join(' ');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.brown.shade100,
          child: Icon(Icons.agriculture, color: Colors.brown.shade700),
        ),
        title: Text(
          champ.nomChamp ?? champ.codeChamp,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Code: ${champ.codeChamp}'),
            Text('Superficie: ${champ.superficie.toStringAsFixed(2)} ha'),
            if (champ.rendementEstime > 0)
              Text('Rendement: ${champ.rendementEstime.toStringAsFixed(2)} t/ha'),
          ],
        ),
        trailing: Chip(
          label: Text(
            getEtatLabel(champ.etatChamp),
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          backgroundColor: getEtatColor(champ.etatChamp),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (champ.localisation != null)
                  _buildInfoRow('Localisation', champ.localisation!),
                Builder(
                  builder: (context) {
                    // Debug: vérifier les valeurs dans le widget
                    final hasCoords = champ.latitude != null && 
                                     champ.longitude != null && 
                                     champ.latitude != 0.0 && 
                                     champ.longitude != 0.0;
                    print('🔍 _buildChampCard - Champ ${champ.codeChamp}: lat=${champ.latitude}, lng=${champ.longitude}, hasCoords=$hasCoords');
                    
                    return _buildInfoRow(
                      'Coordonnées GPS',
                      hasCoords
                          ? '${champ.latitude!.toStringAsFixed(6)}, ${champ.longitude!.toStringAsFixed(6)}'
                          : 'Non renseignées',
                    );
                  },
                ),
                if (champ.typeSol != null)
                  _buildInfoRow('Type de sol', getTypeSolLabel(champ.typeSol)),
                if (champ.anneeMiseEnCulture != null)
                  _buildInfoRow('Année mise en culture', champ.anneeMiseEnCulture.toString()),
                if (champ.varieteCacao != null)
                  _buildInfoRow(
                    'Variété',
                    champ.varieteCacao!.replaceAll('_', ' ').split(' ').map((word) {
                      return word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1);
                    }).join(' '),
                  ),
                if (champ.nombreArbres != null)
                  _buildInfoRow('Nombre d\'arbres', champ.nombreArbres.toString()),
                if (champ.ageMoyenArbres != null)
                  _buildInfoRow('Âge moyen des arbres', '${champ.ageMoyenArbres} ans'),
                if (champ.systemeIrrigation != null)
                  _buildInfoRow(
                    'Système d\'irrigation',
                    champ.systemeIrrigation!.replaceAll('_', ' ').split(' ').map((word) {
                      return word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1);
                    }).join(' '),
                  ),
                if (champ.campagneAgricole != null)
                  _buildInfoRow('Campagne agricole', champ.campagneAgricole!),
                if (champ.notes != null && champ.notes!.isNotEmpty)
                  _buildInfoRow('Notes', champ.notes!),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChampParcelleFormScreen(
                              adherentId: widget.adherentId,
                              champ: champ,
                            ),
                          ),
                        );
                        if (result == true) {
                          await _refreshChamps();
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmer la suppression'),
                            content: Text(
                              'Êtes-vous sûr de vouloir supprimer ${champ.nomChamp ?? champ.codeChamp} ?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            final authViewModel = context.read<AuthViewModel>();
                            final currentUser = authViewModel.currentUser;
                            
                            if (currentUser != null) {
                              await _champParcelleService.deleteChamp(
                                champ.id!,
                                currentUser.id!,
                              );
                              await _refreshChamps();
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Champ supprimé avec succès'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitementsEvolutionChart() {
    // Préparer les données pour le graphique
    final chartData = _prepareTraitementsChartData();
    
    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Couleurs pour chaque type de traitement
    final colors = {
      'engrais': Colors.green,
      'pesticide': Colors.red,
      'entretien': Colors.blue,
      'autre': Colors.grey,
    };

    // Types de traitement présents dans les données
    final types = chartData.keys.toList();
    
    // Obtenir les mois uniques (tous les mois présents dans toutes les séries)
    final allMonths = <String>{};
    chartData.forEach((type, data) {
      allMonths.addAll(data.keys);
    });
    final sortedMonths = allMonths.toList()..sort();
    
    // Créer les lignes pour chaque type
    final lineBarsData = types.map((type) {
      final color = colors[type] ?? Colors.grey;
      final spots = <FlSpot>[];
      
      for (int i = 0; i < sortedMonths.length; i++) {
        final month = sortedMonths[i];
        final count = chartData[type]![month] ?? 0.0;
        spots.add(FlSpot(i.toDouble(), count));
      }
      
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: color.withOpacity(0.1),
        ),
      );
    }).toList();

    // Trouver la valeur maximale pour l'échelle Y
    final maxValue = chartData.values
        .expand((data) => data.values)
        .fold<double>(0.0, (max, value) => value > max ? value : max);
    final maxY = maxValue > 0 ? (maxValue * 1.2).ceil().toDouble() : 5.0;

    return Card(
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
              'Évolution des traitements par type',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 8),
            
            // Légende
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: types.map((type) {
                final color = colors[type] ?? Colors.grey;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTypeTraitementLabel(type),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 5 : 1,
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
                        reservedSize: 40,
                        interval: maxY > 0 ? maxY / 5 : 1,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return const Text('');
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
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
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedMonths.length) {
                            final month = sortedMonths[index];
                            // Formater le mois (ex: "2024-01" -> "Jan 2024")
                            try {
                              final parts = month.split('-');
                              if (parts.length == 2) {
                                final year = parts[0];
                                final monthNum = int.parse(parts[1]);
                                final monthNames = [
                                  'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                                  'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
                                ];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${monthNames[monthNum - 1]}\n$year',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                            } catch (e) {
                              // En cas d'erreur, afficher tel quel
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                month,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
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
                  minX: 0,
                  maxX: (sortedMonths.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: lineBarsData,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Préparer les données pour le graphique d'évolution
  /// Retourne une Map<type_traitement, Map<mois, nombre>>
  Map<String, Map<String, double>> _prepareTraitementsChartData() {
    final Map<String, Map<String, double>> data = {};
    
    for (final traitement in _traitements) {
      final type = traitement.typeTraitement;
      final date = traitement.dateTraitement;
      
      // Formater le mois comme "YYYY-MM"
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      
      // Initialiser la structure si nécessaire
      if (!data.containsKey(type)) {
        data[type] = {};
      }
      
      // Compter les traitements par mois et par type
      data[type]![monthKey] = (data[type]![monthKey] ?? 0.0) + 1.0;
    }
    
    return data;
  }

  String _getTypeTraitementLabel(String type) {
    switch (type) {
      case 'engrais':
        return 'Engrais';
      case 'pesticide':
        return 'Pesticide';
      case 'entretien':
        return 'Entretien';
      case 'autre':
        return 'Autre';
      default:
        return type;
    }
  }

  Widget _buildVentesPaiementsEvolutionChart() {
    // Préparer les données pour le graphique
    final chartData = _prepareVentesPaiementsChartData();
    
    // Vérifier s'il y a des données
    final hasVentes = chartData['ventes']!.isNotEmpty;
    final hasPaiements = chartData['paiements']!.isNotEmpty;
    
    if (!hasVentes && !hasPaiements) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.show_chart_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Aucune donnée disponible pour le graphique',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez des ventes ou des paiements pour voir l\'évolution',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Obtenir les mois uniques
    final allMonths = <String>{};
    allMonths.addAll(chartData['ventes']!.keys);
    allMonths.addAll(chartData['paiements']!.keys);
    final sortedMonths = allMonths.toList()..sort();
    
    if (sortedMonths.isEmpty) {
      return const SizedBox.shrink();
    }

    // Créer les lignes pour ventes et paiements
    final ventesSpots = <FlSpot>[];
    final paiementsSpots = <FlSpot>[];
    
    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final ventesMontant = chartData['ventes']![month] ?? 0.0;
      final paiementsMontant = chartData['paiements']![month] ?? 0.0;
      
      ventesSpots.add(FlSpot(i.toDouble(), ventesMontant));
      paiementsSpots.add(FlSpot(i.toDouble(), paiementsMontant));
    }

    // Trouver la valeur maximale pour l'échelle Y
    final maxVentes = chartData['ventes']!.values.fold<double>(0.0, (max, value) => value > max ? value : max);
    final maxPaiements = chartData['paiements']!.values.fold<double>(0.0, (max, value) => value > max ? value : max);
    final maxValue = maxVentes > maxPaiements ? maxVentes : maxPaiements;
    final maxY = maxValue > 0 ? (maxValue * 1.2).ceil().toDouble() : 100000.0;

    return Card(
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
              'Évolution Ventes vs Paiements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 8),
            
            // Légende
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ventes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Paiements',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 5 : 20000,
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
                        interval: maxY > 0 ? maxY / 5 : 20000,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return const Text('');
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              _formatMontant(value),
                              style: TextStyle(
                                fontSize: 10,
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
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedMonths.length) {
                            final month = sortedMonths[index];
                            // Formater le mois (ex: "2024-01" -> "Jan 2024")
                            try {
                              final parts = month.split('-');
                              if (parts.length == 2) {
                                final year = parts[0];
                                final monthNum = int.parse(parts[1]);
                                final monthNames = [
                                  'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                                  'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
                                ];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${monthNames[monthNum - 1]}\n$year',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                            } catch (e) {
                              // En cas d'erreur, afficher tel quel
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                month,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
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
                  minX: 0,
                  maxX: (sortedMonths.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    // Ligne des ventes
                    LineChartBarData(
                      spots: ventesSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                    // Ligne des paiements
                    LineChartBarData(
                      spots: paiementsSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.green,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Préparer les données pour le graphique d'évolution Ventes vs Paiements
  /// Retourne une Map avec 'ventes' et 'paiements', chaque clé étant une Map<mois, montant>
  Map<String, Map<String, double>> _prepareVentesPaiementsChartData() {
    final Map<String, double> ventesData = {};
    final Map<String, double> paiementsData = {};
    
    // Grouper les ventes par mois
    for (final vente in _ventes) {
      final date = vente.dateVente;
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      ventesData[monthKey] = (ventesData[monthKey] ?? 0.0) + vente.montantTotal;
    }
    
    // Grouper les paiements par mois
    for (final recette in _recettes) {
      final date = recette.dateRecette;
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      paiementsData[monthKey] = (paiementsData[monthKey] ?? 0.0) + recette.montantNet;
    }
    
    return {
      'ventes': ventesData,
      'paiements': paiementsData,
    };
  }

  String _formatMontant(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  Future<void> _exportDossier() async {
    if (_adherent == null || _expertModel == null) {
      return;
    }

    if (!mounted) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await _exportService.exportDossierExpert(
        adherent: _adherent!,
        expertModel: _expertModel!,
        ayantsDroit: _ayantsDroit,
        champs: _champs,
        traitements: _traitements,
        productions: _productions,
        depotsStock: _depotsStock,
        ventes: _ventes,
        recettes: _recettes,
        souscriptionsCapital: _souscriptionsCapital,
        creditsSociaux: _creditsSociaux,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dossier exporté avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'export du dossier'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Toujours fermer le loader, même en cas d'erreur
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

