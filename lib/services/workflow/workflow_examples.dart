/// Exemples d'utilisation du WorkflowService
/// 
/// Ce fichier contient des exemples pratiques d'utilisation du WorkflowService
/// pour intégrer les workflows transactionnels dans votre application Flutter.

import 'workflow_service.dart';
import '../../data/models/vente_detail_model.dart';
import '../notification/notification_service.dart';

class WorkflowExamples {
  final WorkflowService _workflowService = WorkflowService();
  final NotificationService _notificationService = NotificationService();

  /// Exemple 1 : Créer une vente individuelle complète
  /// 
  /// Ce workflow effectue automatiquement :
  /// - Vérification du stock
  /// - Création de la vente
  /// - Déduction du stock
  /// - Calcul de la recette
  /// - Génération de la facture
  /// - Notifications
  Future<void> exempleCreationVenteIndividuelle({
    required int adherentId,
    required int currentUserId,
  }) async {
    try {
      final result = await _workflowService.workflowCreateVenteIndividuelle(
        adherentId: adherentId,
        quantite: 50.0, // 50 kg de cacao
        prixUnitaire: 1500.0, // 1500 FCFA/kg
        acheteur: 'Client ABC',
        modePaiement: 'especes',
        dateVente: DateTime.now(),
        notes: 'Vente de cacao premium',
        createdBy: currentUserId,
        generateFacture: true,
        generateBordereau: false,
      );

      // Afficher les résultats
      print('✅ Vente créée avec succès !');
      print('   - ID Vente: ${result['vente'].id}');
      print('   - Montant total: ${result['vente'].montantTotal.toStringAsFixed(0)} FCFA');
      print('   - Recette nette: ${result['recette'].montantNet.toStringAsFixed(0)} FCFA');
      print('   - Stock restant: ${result['stockRestant'].toStringAsFixed(2)} kg');
      
      if (result['factureNumero'] != null) {
        print('   - Facture: ${result['factureNumero']}');
      }

      // Afficher une notification de succès personnalisée
      _notificationService.showToast(
        message: 'Vente #${result['vente'].id} créée avec succès',
      );
    } catch (e) {
      // L'erreur est déjà gérée par le WorkflowService
      // La transaction a été annulée automatiquement
      print('❌ Erreur lors de la création de la vente: $e');
      
      // Afficher une notification d'erreur
      _notificationService.showToast(
        message: 'Erreur: ${e.toString()}',
      );
    }
  }

  /// Exemple 2 : Créer une vente groupée
  /// 
  /// Permet de vendre le cacao de plusieurs adhérents en une seule transaction
  Future<void> exempleCreationVenteGroupee({
    required int currentUserId,
  }) async {
    try {
      // Préparer les détails de la vente groupée
      final details = [
        VenteDetailModel(
          adherentId: 1,
          quantite: 30.0, // kg
          prixUnitaire: 1500.0, // FCFA/kg
          montant: 45000.0, // FCFA
        ),
        VenteDetailModel(
          adherentId: 2,
          quantite: 25.0, // kg
          prixUnitaire: 1500.0, // FCFA/kg
          montant: 37500.0, // FCFA
        ),
        VenteDetailModel(
          adherentId: 3,
          quantite: 20.0, // kg
          prixUnitaire: 1500.0, // FCFA/kg
          montant: 30000.0, // FCFA
        ),
      ];

      final result = await _workflowService.workflowCreateVenteGroupee(
        details: details,
        prixUnitaire: 1500.0,
        acheteur: 'Client XYZ',
        modePaiement: 'mobile_money',
        dateVente: DateTime.now(),
        notes: 'Vente groupée de cacao',
        createdBy: currentUserId,
        generateFacture: true,
      );

      print('✅ Vente groupée créée avec succès !');
      print('   - ID Vente: ${result['vente'].id}');
      print('   - Quantité totale: ${result['vente'].quantiteTotal.toStringAsFixed(2)} kg');
      print('   - Montant total: ${result['vente'].montantTotal.toStringAsFixed(0)} FCFA');
      print('   - Nombre de recettes créées: ${result['recettes'].length}');
      
      // Afficher les détails de chaque recette
      for (final recette in result['recettes']) {
        print('   - Adhérent ${recette.adherentId}: ${recette.montantNet.toStringAsFixed(0)} FCFA');
      }
    } catch (e) {
      print('❌ Erreur lors de la création de la vente groupée: $e');
    }
  }

  /// Exemple 3 : Créer un dépôt de stock
  /// 
  /// Enregistre un dépôt de cacao avec mise à jour automatique du stock
  Future<void> exempleCreationDepot({
    required int adherentId,
    required int currentUserId,
  }) async {
    try {
      final result = await _workflowService.workflowCreateDepot(
        adherentId: adherentId,
        quantite: 100.0, // 100 kg
        prixUnitaire: 1200.0, // 1200 FCFA/kg
        dateDepot: DateTime.now(),
        qualite: 'premium',
        observations: 'Cacao de première qualité, bien séché',
        createdBy: currentUserId,
      );

      print('✅ Dépôt créé avec succès !');
      print('   - ID Dépôt: ${result['depot'].id}');
      print('   - Quantité: ${result['depot'].quantite.toStringAsFixed(2)} kg');
      print('   - Qualité: ${result['depot'].qualite ?? 'standard'}');
      print('   - Stock actuel: ${result['stockActuel'].toStringAsFixed(2)} kg');
    } catch (e) {
      print('❌ Erreur lors de la création du dépôt: $e');
    }
  }

  /// Exemple 4 : Annuler une vente
  /// 
  /// Annule une vente et restaure automatiquement le stock
  Future<void> exempleAnnulationVente({
    required int venteId,
    required int currentUserId,
  }) async {
    try {
      final result = await _workflowService.workflowAnnulerVente(
        venteId: venteId,
        annulePar: currentUserId,
        raison: 'Erreur de saisie - Quantité incorrecte',
      );

      print('✅ Vente annulée avec succès !');
      print('   - ID Vente: ${result['vente'].id}');
      print('   - Statut: ${result['vente'].statut}');
      print('   - Message: ${result['message']}');
      
      // Le stock a été automatiquement restauré
      // La recette associée a été supprimée
    } catch (e) {
      print('❌ Erreur lors de l\'annulation de la vente: $e');
    }
  }

  /// Exemple 5 : Modifier une vente
  /// 
  /// Modifie une vente existante avec recalcul automatique
  Future<void> exempleModificationVente({
    required int venteId,
    required int adherentId,
    required int currentUserId,
  }) async {
    try {
      final result = await _workflowService.workflowModifierVente(
        venteId: venteId,
        adherentId: adherentId,
        nouvelleQuantite: 60.0, // Ancienne: 50.0 kg
        nouveauPrixUnitaire: 1600.0, // Ancien: 1500.0 FCFA/kg
        nouveauAcheteur: 'Nouveau Client',
        nouveauModePaiement: 'virement',
        nouvellesNotes: 'Quantité et prix modifiés',
        modifiePar: currentUserId,
      );

      print('✅ Vente modifiée avec succès !');
      print('   - ID Vente: ${result['vente'].id}');
      print('   - Nouvelle quantité: ${result['vente'].quantiteTotal.toStringAsFixed(2)} kg');
      print('   - Nouveau montant: ${result['vente'].montantTotal.toStringAsFixed(0)} FCFA');
      print('   - Nouvelle recette nette: ${result['recette'].montantNet.toStringAsFixed(0)} FCFA');
      print('   - Stock restant: ${result['stockRestant'].toStringAsFixed(2)} kg');
    } catch (e) {
      print('❌ Erreur lors de la modification de la vente: $e');
    }
  }

  /// Exemple 6 : Créer un ajustement de stock
  /// 
  /// Permet d'ajuster le stock (ajout ou retrait) avec justification
  Future<void> exempleAjustementStock({
    required int adherentId,
    required int currentUserId,
  }) async {
    try {
      // Exemple 1 : Ajout de stock (correction d'erreur)
      final resultAjout = await _workflowService.workflowCreateAjustement(
        adherentId: adherentId,
        quantite: 10.0, // Positif = ajout
        raison: 'Correction d\'erreur de saisie - Stock manquant',
        createdBy: currentUserId,
      );

      print('✅ Ajustement (ajout) créé avec succès !');
      print('   - Quantité ajoutée: ${resultAjout['ajustement'].quantite.toStringAsFixed(2)} kg');
      print('   - Stock actuel: ${resultAjout['stockActuel'].toStringAsFixed(2)} kg');

      // Exemple 2 : Retrait de stock (perte)
      final resultRetrait = await _workflowService.workflowCreateAjustement(
        adherentId: adherentId,
        quantite: -5.0, // Négatif = retrait
        raison: 'Perte due à l\'humidité',
        createdBy: currentUserId,
      );

      print('✅ Ajustement (retrait) créé avec succès !');
      print('   - Quantité retirée: ${resultRetrait['ajustement'].quantite.toStringAsFixed(2)} kg');
      print('   - Stock actuel: ${resultRetrait['stockActuel'].toStringAsFixed(2)} kg');
    } catch (e) {
      print('❌ Erreur lors de la création de l\'ajustement: $e');
    }
  }

  /// Exemple 7 : Workflow complet avec gestion d'erreurs
  /// 
  /// Montre comment gérer proprement les erreurs transactionnelles
  Future<void> exempleGestionErreurs({
    required int adherentId,
    required int currentUserId,
  }) async {
    try {
      // Tentative de créer une vente avec un stock insuffisant
      final result = await _workflowService.workflowCreateVenteIndividuelle(
        adherentId: adherentId,
        quantite: 1000.0, // Quantité très élevée (probablement supérieure au stock)
        prixUnitaire: 1500.0,
        dateVente: DateTime.now(),
        createdBy: currentUserId,
        generateFacture: false,
      );

      // Ce code ne sera jamais exécuté si le stock est insuffisant
      print('Vente créée: ${result['vente'].id}');
    } catch (e) {
      // L'erreur est automatiquement gérée par le WorkflowService
      // La transaction a été annulée (rollback)
      // Les notifications d'erreur ont été envoyées
      
      print('❌ Erreur capturée: $e');
      
      // Vous pouvez ajouter votre propre logique de gestion d'erreur ici
      if (e.toString().contains('Stock insuffisant')) {
        // Afficher un message spécifique pour les erreurs de stock
        _notificationService.showToast(
          message: 'Stock insuffisant pour cette vente',
        );
      } else {
        // Afficher un message générique pour les autres erreurs
        _notificationService.showToast(
          message: 'Une erreur est survenue lors de l\'opération',
        );
      }
    }
  }
}

/// Exemple d'intégration dans un ViewModel Flutter
/// 
/// Montre comment utiliser le WorkflowService dans un ViewModel Provider
class VenteViewModelExample {
  final WorkflowService _workflowService = WorkflowService();
  final NotificationService _notificationService = NotificationService();

  /// Créer une vente depuis l'interface utilisateur
  Future<bool> creerVente({
    required int adherentId,
    required double quantite,
    required double prixUnitaire,
    String? acheteur,
    String? modePaiement,
    required int currentUserId,
  }) async {
    try {
      final result = await _workflowService.workflowCreateVenteIndividuelle(
        adherentId: adherentId,
        quantite: quantite,
        prixUnitaire: prixUnitaire,
        acheteur: acheteur,
        modePaiement: modePaiement,
        dateVente: DateTime.now(),
        createdBy: currentUserId,
        generateFacture: true,
      );

      // Succès - Retourner true pour indiquer que l'opération a réussi
      return true;
    } catch (e) {
      // Erreur - Retourner false
      // Les notifications d'erreur sont déjà gérées par le WorkflowService
      return false;
    }
  }

  /// Annuler une vente depuis l'interface utilisateur
  Future<bool> annulerVente({
    required int venteId,
    required int currentUserId,
    String? raison,
  }) async {
    try {
      await _workflowService.workflowAnnulerVente(
        venteId: venteId,
        annulePar: currentUserId,
        raison: raison,
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
