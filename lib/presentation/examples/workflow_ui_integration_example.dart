import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/workflow/workflow_service.dart';
import '../../data/models/vente_model.dart';
import '../widgets/common/loading_overlay.dart';
import '../widgets/common/toast_helper.dart';
import '../widgets/common/loading_button.dart';
import '../widgets/common/confirmation_dialog.dart';
import '../../config/theme/app_theme.dart';

/// Exemple d'intégration du WorkflowService avec les nouveaux composants UI
/// 
/// Cet exemple montre comment utiliser le WorkflowService dans un écran
/// avec les nouveaux composants UI pour un feedback utilisateur optimal.
class WorkflowUIIntegrationExample extends StatefulWidget {
  const WorkflowUIIntegrationExample({super.key});

  @override
  State<WorkflowUIIntegrationExample> createState() => _WorkflowUIIntegrationExampleState();
}

class _WorkflowUIIntegrationExampleState extends State<WorkflowUIIntegrationExample> {
  final WorkflowService _workflowService = WorkflowService();
  bool _isProcessing = false;

  /// Exemple : Créer une vente individuelle avec feedback UI complet
  Future<void> _createVenteIndividuelle() async {
    // Afficher un dialog de confirmation
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Confirmer la vente',
      message: 'Voulez-vous créer cette vente et générer la facture ?',
      confirmText: 'Créer',
      icon: Icons.shopping_cart,
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _workflowService.workflowCreateVenteIndividuelle(
        adherentId: 1,
        quantite: 50.0,
        prixUnitaire: 1200.0,
        dateVente: DateTime.now(),
        notes: 'Vente de cacao premium',
        generateFacture: true,
        createdBy: 1,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Afficher un toast de succès
        ToastHelper.showSuccess(
          'Vente créée avec succès ! Facture #${result.factureNumero} générée.',
        );

        // Afficher un snackbar avec action
        CustomSnackbar.showSuccess(
          context,
          'Vente #${result.venteId} enregistrée',
        );

        // Optionnel : Naviguer vers les détails
        // Navigator.pushNamed(context, AppRoutes.venteDetail, arguments: result.venteId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Afficher un toast d'erreur
        ToastHelper.showError('Erreur lors de la création de la vente: ${e.toString()}');

        // Afficher un snackbar d'erreur avec action de retry
        CustomSnackbar.show(
          context,
          message: 'Échec de la création de la vente',
          backgroundColor: AppTheme.errorColor,
          icon: Icons.error,
          actionLabel: 'Réessayer',
          onAction: _createVenteIndividuelle,
        );
      }
    }
  }

  /// Exemple : Créer un dépôt avec feedback UI
  Future<void> _createDepot() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _workflowService.workflowCreateDepot(
        adherentId: 1,
        quantite: 100.0,
        qualite: 'premium',
        dateDepot: DateTime.now(),
        notes: 'Dépôt de cacao premium',
        createdBy: 1,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ToastHelper.showSuccess('Dépôt enregistré avec succès !');
        CustomSnackbar.showSuccess(
          context,
          'Stock mis à jour: ${result.nouveauStock.toStringAsFixed(1)} kg',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ToastHelper.showError('Erreur lors du dépôt: ${e.toString()}');
      }
    }
  }

  /// Exemple : Annuler une vente avec confirmation
  Future<void> _annulerVente(int venteId) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Annuler la vente',
      message: 'Cette action est irréversible. Le stock sera réajusté automatiquement.',
      confirmText: 'Annuler la vente',
      cancelText: 'Fermer',
      icon: Icons.cancel,
      confirmColor: AppTheme.errorColor,
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _workflowService.workflowAnnulerVente(
        venteId: venteId,
        raison: 'Annulation demandée par le client',
        cancelledBy: 1,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ToastHelper.showSuccess('Vente annulée avec succès. Stock réajusté.');

        // Optionnel : Snackbar avec undo (si l'action peut être annulée)
        CustomSnackbar.showWithUndo(
          context,
          message: 'Vente annulée',
          onUndo: () {
            // TODO: Implémenter la réactivation si nécessaire
            ToastHelper.showInfo('Réactivation non disponible');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ToastHelper.showError('Erreur lors de l\'annulation: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemple d\'intégration WorkflowService + UI'),
      ),
      body: LoadingOverlay(
        isLoading: _isProcessing,
        message: 'Traitement en cours...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Exemple 1 : Créer une vente
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exemple 1 : Créer une vente individuelle',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cet exemple montre comment créer une vente avec confirmation, '
                        'indicateur de chargement et feedback utilisateur.',
                      ),
                      const SizedBox(height: 16),
                      LoadingButton(
                        text: 'Créer une vente',
                        icon: Icons.add_shopping_cart,
                        isLoading: _isProcessing,
                        onPressed: _createVenteIndividuelle,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Exemple 2 : Créer un dépôt
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exemple 2 : Créer un dépôt',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cet exemple montre comment créer un dépôt avec feedback automatique.',
                      ),
                      const SizedBox(height: 16),
                      LoadingButton(
                        text: 'Enregistrer un dépôt',
                        icon: Icons.inventory_2,
                        isLoading: _isProcessing,
                        onPressed: _createDepot,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Exemple 3 : Annuler une vente
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exemple 3 : Annuler une vente',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cet exemple montre comment annuler une vente avec confirmation '
                        'et feedback utilisateur.',
                      ),
                      const SizedBox(height: 16),
                      LoadingButton(
                        text: 'Annuler une vente (ID: 1)',
                        icon: Icons.cancel,
                        isLoading: _isProcessing,
                        backgroundColor: AppTheme.errorColor,
                        onPressed: () => _annulerVente(1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Guide d'utilisation
              Card(
                color: AppTheme.infoColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: AppTheme.infoColor),
                          const SizedBox(width: 8),
                          Text(
                            'Guide d\'utilisation',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.infoColor,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '1. Toutes les opérations du WorkflowService sont transactionnelles\n'
                        '2. Utilisez LoadingOverlay pour les opérations longues\n'
                        '3. Utilisez ToastHelper pour les notifications simples\n'
                        '4. Utilisez CustomSnackbar pour les notifications avec actions\n'
                        '5. Utilisez ConfirmationDialog pour les actions critiques\n'
                        '6. Les erreurs sont automatiquement gérées et affichées',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
