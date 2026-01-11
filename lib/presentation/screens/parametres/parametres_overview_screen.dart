import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../viewmodels/parametres_viewmodel.dart';
import '../../providers/settings_provider.dart';
import '../../../data/models/parametres_cooperative_model.dart';
import '../../../config/app_config.dart';

class ParametresOverviewScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const ParametresOverviewScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<ParametresOverviewScreen> createState() => _ParametresOverviewScreenState();
}

class _ParametresOverviewScreenState extends State<ParametresOverviewScreen> {
  bool _hasLoadedInitialData = false;
  
  // Méthode pour naviguer vers un écran de paramètres spécifique
  void _navigateToSettingsScreen(BuildContext context, String route) {
    // Si onNavigateToTab est fourni, l'utiliser (pour TabBar)
    // Sinon, naviguer vers la route appropriée
    if (widget.onNavigateToTab != null) {
      // Mapping des routes vers les index de tabs
      switch (route) {
        case 'cooperative':
          widget.onNavigateToTab!(1); // Index pour "Coopérative" dans ParametresMainScreen
          break;
        case 'finances':
          widget.onNavigateToTab!(2); // Index pour "Finances"
          break;
        case 'campagnes':
          widget.onNavigateToTab!(3); // Index pour "Campagnes"
          break;
      }
    } else {
      // Navigation normale via Navigator
      Navigator.of(context).pushNamed(route);
    }
  }

  @override
  void initState() {
    super.initState();
    // Charger les données une seule fois au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoadedInitialData && mounted) {
        _hasLoadedInitialData = true;
        _loadAllData();
      }
    });
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    
    final viewModel = context.read<ParametresViewModel>();
    final settingsProvider = context.read<SettingsProvider>();
    
    // Charger les données de l'ancien système
    await Future.wait([
      if (viewModel.parametres == null) viewModel.loadParametres(),
      if (viewModel.campagnes.isEmpty) viewModel.loadCampagnes(),
      if (viewModel.baremes.isEmpty) viewModel.loadBaremes(),
    ]);
    
    // Charger toutes les données du nouveau système
    await settingsProvider.loadAllSettings();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ParametresViewModel>();
    final settingsProvider = context.watch<SettingsProvider>();
    
    final parametres = viewModel.parametres;
    final campagnes = viewModel.campagnes;
    final baremes = viewModel.baremes;
    
    // Récupérer toutes les données des settings
    final cooperativeSettings = settingsProvider.cooperativeSettings;
    final generalSettings = settingsProvider.generalSettings;
    final capitalSettings = settingsProvider.capitalSettings;
    final accountingSettings = settingsProvider.accountingSettings;
    final salesSettings = settingsProvider.salesSettings;
    final documentSettings = settingsProvider.documentSettings;
    final socialSettings = settingsProvider.socialSettings;
    final moduleSettings = settingsProvider.moduleSettings;

    // Afficher un loader uniquement lors du chargement initial
    if (!_hasLoadedInitialData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Message d'erreur si présent
          if (viewModel.errorMessage != null && !viewModel.isLoading)
            Card(
              color: Colors.red.shade50,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        viewModel.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => viewModel.clearError(),
                      color: Colors.red.shade700,
                    ),
                  ],
                ),
              ),
            ),
          
          // En-tête
          Card(
            color: Colors.brown.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.settings, size: 32, color: Colors.brown.shade700),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vue d\'ensemble des paramètres',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tous les paramètres de la coopérative en un coup d\'œil',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Informations de la coopérative
          _buildSectionHeader(
            icon: Icons.business,
            title: 'Informations de la coopérative',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo et nom
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: viewModel.selectedLogoFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  viewModel.selectedLogoFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : cooperativeSettings?.logoPath != null
                                ? _buildLogoWidget(cooperativeSettings!.logoPath!)
                                : parametres?.logoPath != null
                                    ? _buildLogoWidget(parametres!.logoPath!)
                                    : Icon(
                                        Icons.business,
                                        size: 40,
                                        color: Colors.grey.shade400,
                                      ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cooperativeSettings?.raisonSociale ?? parametres?.nomCooperative ?? 'Non défini',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (cooperativeSettings?.sigle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Sigle: ${cooperativeSettings!.sigle}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            if (cooperativeSettings?.updatedAt != null || parametres?.updatedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Dernière mise à jour: ${DateFormat('dd/MM/yyyy à HH:mm').format(cooperativeSettings?.updatedAt ?? parametres!.updatedAt!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Détails complets
                  if (cooperativeSettings?.formeJuridique != null) ...[
                    _buildInfoRow(
                      icon: Icons.business_center,
                      label: 'Forme juridique',
                      value: cooperativeSettings!.formeJuridique!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (cooperativeSettings?.numeroAgrement != null) ...[
                    _buildInfoRow(
                      icon: Icons.verified,
                      label: 'Numéro d\'agrément',
                      value: cooperativeSettings!.numeroAgrement!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (cooperativeSettings?.rccm != null) ...[
                    _buildInfoRow(
                      icon: Icons.description,
                      label: 'RCCM',
                      value: cooperativeSettings!.rccm!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (cooperativeSettings?.dateCreation != null) ...[
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date de création',
                      value: DateFormat('dd/MM/yyyy').format(cooperativeSettings!.dateCreation!),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Adresse',
                    value: cooperativeSettings?.adresse ?? parametres?.adresse ?? 'Non définie',
                  ),
                  if (cooperativeSettings?.region != null || cooperativeSettings?.departement != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.map,
                      label: 'Localisation',
                      value: [
                        if (cooperativeSettings?.region != null) cooperativeSettings!.region,
                        if (cooperativeSettings?.departement != null) cooperativeSettings!.departement,
                      ].where((e) => e != null).join(', '),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'Téléphone',
                    value: cooperativeSettings?.telephone ?? parametres?.telephone ?? 'Non défini',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: cooperativeSettings?.email ?? parametres?.email ?? 'Non défini',
                  ),
                  if (cooperativeSettings?.devise != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.currency_exchange,
                      label: 'Devise',
                      value: cooperativeSettings!.devise,
                    ),
                  ],
                  // Dates de campagne par défaut si définies
                  if (parametres?.dateDebutCampagne != null && parametres?.dateFinCampagne != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Période campagne par défaut',
                      value: 'Du ${DateFormat('dd/MM/yyyy').format(parametres!.dateDebutCampagne!)} au ${DateFormat('dd/MM/yyyy').format(parametres.dateFinCampagne!)}',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Paramètres financiers
          _buildSectionHeader(
            icon: Icons.attach_money,
            title: 'Paramètres financiers',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    icon: Icons.percent,
                    label: 'Taux de commission général',
                    value: parametres != null
                        ? '${(parametres.commissionRate * 100).toStringAsFixed(2)}%'
                        : 'Non défini',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Période de campagne par défaut',
                    value: parametres != null
                        ? '${parametres.periodeCampagneDays} jours'
                        : 'Non défini',
                  ),
                  if (parametres?.commissionRateActionnaire != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.account_circle,
                      label: 'Taux commission actionnaires',
                      value: '${(parametres!.commissionRateActionnaire! * 100).toStringAsFixed(2)}%',
                    ),
                  ],
                  if (parametres?.commissionRateProducteur != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'Taux commission producteurs',
                      value: '${(parametres!.commissionRateProducteur! * 100).toStringAsFixed(2)}%',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Barèmes par qualité
          _buildSectionHeader(
            icon: Icons.star,
            title: 'Barèmes par qualité',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          // Statistiques des barèmes
          if (baremes.isNotEmpty)
            Card(
              color: Colors.orange.shade50,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatisticItem(
                      icon: Icons.star,
                      label: 'Qualités',
                      value: '${baremes.length}',
                      color: Colors.orange,
                    ),
                    _buildStatisticItem(
                      icon: Icons.attach_money,
                      label: 'Avec prix',
                      value: '${baremes.where((b) => b.prixMin != null || b.prixMax != null).length}',
                      color: Colors.green,
                    ),
                    _buildStatisticItem(
                      icon: Icons.percent,
                      label: 'Avec commission',
                      value: '${baremes.where((b) => b.commissionRate != null).length}',
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          if (baremes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Aucun barème configuré',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            )
          else
            ...baremes.map((bareme) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Text(
                                bareme.qualite.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoRow(
                                icon: Icons.arrow_downward,
                                label: 'Prix min',
                                value: bareme.prixMin != null
                                    ? '${bareme.prixMin!.toStringAsFixed(0)} FCFA/kg'
                                    : 'Non défini',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoRow(
                                icon: Icons.arrow_upward,
                                label: 'Prix max',
                                value: bareme.prixMax != null
                                    ? '${bareme.prixMax!.toStringAsFixed(0)} FCFA/kg'
                                    : 'Non défini',
                              ),
                            ),
                          ],
                        ),
                        if (bareme.commissionRate != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.percent,
                            label: 'Commission spécifique',
                            value: '${(bareme.commissionRate! * 100).toStringAsFixed(2)}%',
                          ),
                        ],
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 24),

          // Section 4: Campagnes
          _buildSectionHeader(
            icon: Icons.calendar_today,
            title: 'Campagnes',
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          // Statistiques des campagnes
          if (campagnes.isNotEmpty)
            Card(
              color: Colors.purple.shade50,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatisticItem(
                      icon: Icons.calendar_today,
                      label: 'Total',
                      value: '${campagnes.length}',
                      color: Colors.purple,
                    ),
                    _buildStatisticItem(
                      icon: Icons.play_circle,
                      label: 'En cours',
                      value: '${campagnes.where((c) => c.isEnCours).length}',
                      color: Colors.green,
                    ),
                    _buildStatisticItem(
                      icon: Icons.check_circle,
                      label: 'Actives',
                      value: '${campagnes.where((c) => c.isActive).length}',
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          if (campagnes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune campagne enregistrée',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...campagnes.take(5).map((campagne) {
              final isEnCours = campagne.isEnCours;
              final statusColor = campagne.isActive
                  ? (isEnCours ? Colors.green : Colors.orange)
                  : Colors.grey;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Icon(
                      isEnCours ? Icons.play_circle : Icons.calendar_today,
                      color: statusColor,
                    ),
                  ),
                  title: Text(
                    campagne.nom,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Du ${DateFormat('dd/MM/yyyy').format(campagne.dateDebut)} au ${DateFormat('dd/MM/yyyy').format(campagne.dateFin)}',
                      ),
                      if (campagne.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          campagne.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      campagne.isActive
                          ? (isEnCours ? 'En cours' : 'Planifiée')
                          : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          if (campagnes.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... et ${campagnes.length - 5} autre(s) campagne(s)',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),

          // Section 5: Paramètres généraux
          _buildSectionHeader(
            icon: Icons.settings,
            title: 'Paramètres généraux',
            color: Colors.teal,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (generalSettings != null) ...[
                    _buildInfoRow(
                      icon: Icons.currency_exchange,
                      label: 'Devise',
                      value: generalSettings!.devise,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.calendar_view_day,
                      label: 'Format de date',
                      value: generalSettings!.dateFormat,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.cloud_off,
                      label: 'Mode hors ligne',
                      value: generalSettings!.offlineMode ? 'Activé' : 'Désactivé',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.timer,
                      label: 'Durée de session',
                      value: '${generalSettings!.sessionDurationMinutes} minutes',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.notifications,
                      label: 'Notifications',
                      value: generalSettings!.notificationsEnabled ? 'Activées' : 'Désactivées',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.palette,
                      label: 'Thème',
                      value: generalSettings!.uiTheme == 'light' ? 'Clair' : 'Sombre',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.backup,
                      label: 'Sauvegarde automatique',
                      value: generalSettings!.autoBackup 
                          ? 'Activée (tous les ${generalSettings!.backupIntervalDays} jours)'
                          : 'Désactivée',
                    ),
                  ] else
                    Center(
                      child: Text(
                        'Aucun paramètre général configuré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 6: Capital Social
          _buildSectionHeader(
            icon: Icons.account_balance,
            title: 'Capital Social',
            color: Colors.indigo,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (capitalSettings != null) ...[
                    _buildInfoRow(
                      icon: Icons.monetization_on,
                      label: 'Valeur d\'une part',
                      value: '${capitalSettings!.valeurPart.toStringAsFixed(0)} FCFA',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.numbers,
                      label: 'Nombre de parts',
                      value: capitalSettings!.nombreMaxParts != null
                          ? '${capitalSettings!.nombreMinParts} - ${capitalSettings!.nombreMaxParts}'
                          : 'Minimum: ${capitalSettings!.nombreMinParts}',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.lock,
                      label: 'Libération obligatoire',
                      value: capitalSettings!.liberationObligatoire ? 'Oui' : 'Non',
                    ),
                    if (capitalSettings!.delaiLiberationJours != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.schedule,
                        label: 'Délai de libération',
                        value: '${capitalSettings!.delaiLiberationJours} jours',
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.trending_up,
                      label: 'Dividendes',
                      value: capitalSettings!.dividendesActives 
                          ? 'Actifs${capitalSettings!.tauxDividende != null ? ' (${(capitalSettings!.tauxDividende! * 100).toStringAsFixed(2)}%)' : ''}'
                          : 'Inactifs',
                    ),
                  ] else
                    Center(
                      child: Text(
                        'Aucun paramètre de capital social configuré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 7: Comptabilité
          _buildSectionHeader(
            icon: Icons.calculate,
            title: 'Comptabilité',
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (accountingSettings != null) ...[
                    if (accountingSettings!.exerciceActif != null) ...[
                      _buildInfoRow(
                        icon: Icons.event,
                        label: 'Exercice actif',
                        value: accountingSettings!.exerciceActif!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildInfoRow(
                      icon: Icons.account_balance_wallet,
                      label: 'Solde initial caisse',
                      value: '${accountingSettings!.soldeInitialCaisse.toStringAsFixed(0)} FCFA',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.account_balance,
                      label: 'Solde initial banque',
                      value: '${accountingSettings!.soldeInitialBanque.toStringAsFixed(0)} FCFA',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.percent,
                      label: 'Taux frais de gestion',
                      value: '${(accountingSettings!.tauxFraisGestion * 100).toStringAsFixed(2)}%',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.savings,
                      label: 'Taux réserve',
                      value: '${(accountingSettings!.tauxReserve * 100).toStringAsFixed(2)}%',
                    ),
                    if (accountingSettings!.compteCaisse != null || 
                        accountingSettings!.compteBanque != null ||
                        accountingSettings!.compteVente != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Plan comptable',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (accountingSettings!.compteCaisse != null)
                        _buildInfoRow(
                          icon: Icons.account_balance_wallet,
                          label: 'Compte caisse',
                          value: accountingSettings!.compteCaisse!,
                        ),
                      if (accountingSettings!.compteBanque != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.account_balance,
                          label: 'Compte banque',
                          value: accountingSettings!.compteBanque!,
                        ),
                      ],
                      if (accountingSettings!.compteVente != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.shopping_cart,
                          label: 'Compte vente',
                          value: accountingSettings!.compteVente!,
                        ),
                      ],
                    ],
                  ] else
                    Center(
                      child: Text(
                        'Aucun paramètre comptable configuré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 8: Ventes & Prix
          _buildSectionHeader(
            icon: Icons.shopping_cart,
            title: 'Ventes & Prix',
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (salesSettings != null) ...[
                    _buildInfoRow(
                      icon: Icons.arrow_downward,
                      label: 'Prix minimum cacao',
                      value: '${salesSettings!.prixMinimumCacao.toStringAsFixed(0)} FCFA/kg',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.arrow_upward,
                      label: 'Prix maximum cacao',
                      value: '${salesSettings!.prixMaximumCacao.toStringAsFixed(0)} FCFA/kg',
                    ),
                    if (salesSettings!.prixDuJour != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.today,
                        label: 'Prix du jour',
                        value: '${salesSettings!.prixDuJour!.toStringAsFixed(0)} FCFA/kg',
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.verified,
                      label: 'Mode validation prix',
                      value: salesSettings!.modeValidationPrix == 'auto' 
                          ? 'Automatique'
                          : salesSettings!.modeValidationPrix == 'manuel'
                              ? 'Manuel'
                              : 'Validation requise',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.percent,
                      label: 'Commission coopérative',
                      value: '${(salesSettings!.commissionCooperative * 100).toStringAsFixed(2)}%',
                    ),
                    if (salesSettings!.retenuesAutomatiques.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.auto_fix_high,
                        label: 'Retenues automatiques',
                        value: salesSettings!.retenuesAutomatiques.join(', '),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.warning,
                      label: 'Alerte prix hors plage',
                      value: salesSettings!.alertePrixHorsPlage ? 'Activée' : 'Désactivée',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.history,
                      label: 'Historique des prix',
                      value: salesSettings!.historiquePrixActif ? 'Actif' : 'Inactif',
                    ),
                  ] else
                    Center(
                      child: Text(
                        'Aucun paramètre de ventes configuré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 10: Documents & QR Code
          _buildSectionHeader(
            icon: Icons.description,
            title: 'Documents & QR Code',
            color: Colors.cyan,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (documentSettings != null) ...[
                    // Signature automatique
                    _buildInfoRow(
                      icon: Icons.edit,
                      label: 'Signature automatique',
                      value: documentSettings!.signatureAutomatique ? 'Activée' : 'Désactivée',
                    ),
                    // Mentions légales
                    if (documentSettings!.mentionsLegales != null && documentSettings!.mentionsLegales!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.gavel,
                        label: 'Mentions légales',
                        value: documentSettings!.mentionsLegales!.length > 50
                            ? '${documentSettings!.mentionsLegales!.substring(0, 50)}...'
                            : documentSettings!.mentionsLegales!,
                      ),
                    ],
                    // QR Code
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.qr_code,
                      label: 'QR Code',
                      value: documentSettings!.qrCodeActif ? 'Activé' : 'Désactivé',
                    ),
                    if (documentSettings!.qrCodeActif) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.format_align_left,
                        label: 'Format QR Code',
                        value: documentSettings!.qrCodeFormat ?? 'url',
                      ),
                      if (documentSettings!.qrCodeUrlBase != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.link,
                          label: 'URL de base',
                          value: documentSettings!.qrCodeUrlBase!,
                        ),
                      ],
                    ],
                    // Types de documents
                    if (documentSettings!.typesDocuments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Types de documents',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...documentSettings!.typesDocuments.entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: entry.value.actif 
                                    ? Colors.green.shade50 
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: entry.value.actif 
                                      ? Colors.green.shade200 
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.description, 
                                        size: 18, 
                                        color: entry.value.actif 
                                            ? Colors.green.shade700 
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.key.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: entry.value.actif 
                                                ? Colors.green.shade900 
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      if (entry.value.actif)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'ACTIF',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade900,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'INACTIF',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.tag, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Préfixe: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        entry.value.prefixe,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.numbers, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Format: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry.value.formatNumero,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ] else
                    Center(
                      child: Text(
                        'Aucun paramètre de documents configuré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 11: Social
          _buildSectionHeader(
            icon: Icons.people,
            title: 'Social',
            color: Colors.pink,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (socialSettings != null) ...[
                    _buildInfoRow(
                      icon: Icons.verified_user,
                      label: 'Validation requise',
                      value: socialSettings!.validationRequise ? 'Oui' : 'Non',
                    ),
                    if (socialSettings!.typesAides.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Types d\'aides sociales',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...socialSettings!.typesAides.map((aide) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.favorite, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        aide.libelle,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      if (aide.plafond != null)
                                        Text(
                                          'Plafond: ${aide.plafond!.toStringAsFixed(0)} FCFA',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                    ],
                                  ),
                                ),
                                if (aide.actif)
                                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                              ],
                            ),
                          )),
                    ],
                  ] else
                    Center(
                      child: Text(
                        'Aucun paramètre social configuré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 12: Modules & Sécurité
          _buildSectionHeader(
            icon: Icons.security,
            title: 'Modules & Sécurité',
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (moduleSettings != null) ...[
                    if (moduleSettings!.modulesActives.isNotEmpty) ...[
                      const Text(
                        'Modules actifs',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: moduleSettings!.modulesActives.entries
                            .where((entry) => entry.value)
                            .map((entry) => Chip(
                                  label: Text(entry.key),
                                  avatar: const Icon(Icons.check_circle, size: 18),
                                  backgroundColor: Colors.green.shade50,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                    ],
                    _buildInfoRow(
                      icon: Icons.lock,
                      label: 'Verrouillage paramétrage',
                      value: moduleSettings!.verrouillageParametrage ? 'Activé' : 'Désactivé',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.history,
                      label: 'Logs d\'audit',
                      value: moduleSettings!.auditLogsActif ? 'Actifs' : 'Inactifs',
                    ),
                    if (moduleSettings!.auditLogsActif) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.schedule,
                        label: 'Durée conservation logs',
                        value: '${moduleSettings!.dureeConservationLogsJours} jours',
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.verified_user,
                      label: 'Authentification 2FA',
                      value: moduleSettings!.authentificationDoubleFacteur ? 'Activée' : 'Désactivée',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.timer,
                      label: 'Durée de session',
                      value: '${moduleSettings!.dureeSessionMinutes} minutes',
                    ),
                    if (moduleSettings!.ipAutorisees != null && moduleSettings!.ipAutorisees!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.computer,
                        label: 'IP autorisées',
                        value: '${moduleSettings!.ipAutorisees!.length} adresse(s)',
                      ),
                    ],
                  ] else
                    Center(
                      child: Text(
                        'Aucun paramètre de modules configuré',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bouton pour accéder aux paramètres détaillés
          Card(
            color: Colors.brown.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Pour modifier ces paramètres, utilisez le menu de navigation',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinkChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.brown.shade700,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoWidget(String logoPath) {
    try {
      final file = File(logoPath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.broken_image,
                size: 40,
                color: Colors.grey.shade400,
              );
            },
          ),
        );
      } else {
        return Icon(
          Icons.business,
          size: 40,
          color: Colors.grey.shade400,
        );
      }
    } catch (e) {
      return Icon(
        Icons.broken_image,
        size: 40,
        color: Colors.grey.shade400,
      );
    }
  }
}

