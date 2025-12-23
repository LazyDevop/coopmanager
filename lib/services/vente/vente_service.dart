import '../database/db_initializer.dart';
import '../../data/models/vente_model.dart';
import '../../data/models/vente_detail_model.dart';
import '../stock/stock_service.dart';
import '../adherent/adherent_service.dart';
import '../auth/audit_service.dart';
import '../notification/notification_service.dart';
// V2: Nouveaux imports
import '../comptabilite/comptabilite_service.dart';
import '../qrcode/document_security_service.dart';

class VenteService {
  final StockService _stockService = StockService();
  final AdherentService _adherentService = AdherentService();
  final AuditService _auditService = AuditService();
  final NotificationService _notificationService = NotificationService();
  // V2: Nouveaux services
  final ComptabiliteService _comptabiliteService = ComptabiliteService();

  /// Créer une vente individuelle
  Future<VenteModel> createVenteIndividuelle({
    required int adherentId,
    required double quantite,
    required double prixUnitaire,
    String? acheteur,
    int? clientId, // V2: Lien avec client
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
    bool generateEcritureComptable = true, // V2: Générer écriture comptable
  }) async {
    try {
      // Vérifier le stock disponible
      final stockDisponible = await _stockService.getStockActuel(adherentId);
      if (stockDisponible < quantite) {
        throw Exception(
          'Stock insuffisant. Stock disponible: ${stockDisponible.toStringAsFixed(2)} kg, Quantité demandée: ${quantite.toStringAsFixed(2)} kg',
        );
      }

      final db = await DatabaseInitializer.database;
      final montantTotal = quantite * prixUnitaire;

      final vente = VenteModel(
        type: 'individuelle',
        adherentId: adherentId,
        quantiteTotal: quantite,
        prixUnitaire: prixUnitaire,
        montantTotal: montantTotal,
        acheteur: acheteur,
        modePaiement: modePaiement,
        dateVente: dateVente,
        notes: notes,
        statut: 'valide',
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      // V2: Ajouter client_id si fourni
      final venteMap = vente.toMap();
      if (clientId != null) {
        venteMap['client_id'] = clientId;
      }

      // Insérer la vente
      final venteId = await db.insert('ventes', venteMap);
      
      // V2: Générer écriture comptable si demandé et client fourni
      int? ecritureComptableId;
      if (generateEcritureComptable && clientId != null) {
        try {
          final ecriture = await _comptabiliteService.createEcritureVente(
            venteId: venteId,
            montant: montantTotal,
            clientId: clientId,
            dateVente: dateVente,
            createdBy: createdBy,
          );
          ecritureComptableId = ecriture.id;
          
          // Mettre à jour la vente avec l'ID de l'écriture comptable
          await db.update(
            'ventes',
            {'ecriture_comptable_id': ecritureComptableId},
            where: 'id = ?',
            whereArgs: [venteId],
          );
        } catch (e) {
          print('Erreur lors de la génération de l\'écriture comptable: $e');
          // Ne pas faire échouer la vente si l'écriture échoue
        }
      }
      
      // V2: Générer QR Code pour la vente
      try {
        final documentContent = {
          'vente_id': venteId,
          'adherent_id': adherentId,
          'montant': montantTotal,
          'quantite': quantite,
          'date': dateVente.toIso8601String(),
        };
        
        await DocumentSecurityService.generateSecureDocument(
          documentType: 'vente',
          documentId: venteId,
          documentContent: documentContent,
          createdBy: createdBy,
        );
        
        // Mettre à jour la vente avec le hash QR Code
        final documentSecurise = await DocumentSecurityService.getSecureDocument(
          documentType: 'vente',
          documentId: venteId,
        );
        
        if (documentSecurise != null) {
          await db.update(
            'ventes',
            {'qr_code_hash': documentSecurise.hashVerification},
            where: 'id = ?',
            whereArgs: [venteId],
          );
        }
      } catch (e) {
        print('Erreur lors de la génération du QR Code: $e');
        // Ne pas faire échouer la vente si le QR Code échoue
      }

      // Déduire du stock
      await _stockService.deductStockForVente(
        adherentId: adherentId,
        quantite: quantite,
        venteId: venteId,
        createdBy: createdBy,
      );

      // Enregistrer dans l'historique de l'adhérent
      await _adherentService.logVente(
        adherentId: adherentId,
        venteId: venteId,
        quantite: quantite,
        montant: montantTotal,
        dateVente: dateVente,
        createdBy: createdBy,
      );

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_VENTE',
        entityType: 'ventes',
        entityId: venteId,
        details: 'Vente individuelle de $quantite kg pour adhérent $adherentId',
      );

      // Notification : Vente créée
      await _notificationService.notifyVenteCreated(
        venteId: venteId,
        montant: montantTotal,
        userId: createdBy,
      );

      return vente.copyWith(id: venteId);
    } catch (e) {
      throw Exception('Erreur lors de la création de la vente: $e');
    }
  }

  /// Créer une vente groupée
  Future<VenteModel> createVenteGroupee({
    required List<VenteDetailModel> details,
    required double prixUnitaire,
    String? acheteur,
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
  }) async {
    try {
      // Vérifier les stocks pour tous les adhérents
      for (final detail in details) {
        final stockDisponible = await _stockService.getStockActuel(detail.adherentId);
        if (stockDisponible < detail.quantite) {
          throw Exception(
            'Stock insuffisant pour l\'adhérent ${detail.adherentId}. Stock disponible: ${stockDisponible.toStringAsFixed(2)} kg, Quantité demandée: ${detail.quantite.toStringAsFixed(2)} kg',
          );
        }
      }

      final db = await DatabaseInitializer.database;
      
      // Calculer le total
      final quantiteTotal = details.fold<double>(
        0.0,
        (sum, detail) => sum + detail.quantite,
      );
      final montantTotal = quantiteTotal * prixUnitaire;

      final vente = VenteModel(
        type: 'groupee',
        quantiteTotal: quantiteTotal,
        prixUnitaire: prixUnitaire,
        montantTotal: montantTotal,
        acheteur: acheteur,
        modePaiement: modePaiement,
        dateVente: dateVente,
        notes: notes,
        statut: 'valide',
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      // Insérer la vente
      final venteId = await db.insert('ventes', vente.toMap());

      // Insérer les détails et déduire les stocks
      for (final detail in details) {
        // Insérer le détail avec l'ID de la vente
        await db.insert('vente_details', detail.copyWith(venteId: venteId).toMap());

        // Déduire du stock
        await _stockService.deductStockForVente(
          adherentId: detail.adherentId,
          quantite: detail.quantite,
          venteId: venteId,
          createdBy: createdBy,
        );

        // Enregistrer dans l'historique de l'adhérent
        await _adherentService.logVente(
          adherentId: detail.adherentId,
          venteId: venteId,
          quantite: detail.quantite,
          montant: detail.montant,
          dateVente: dateVente,
          createdBy: createdBy,
        );
      }

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_VENTE_GROUPEE',
        entityType: 'ventes',
        entityId: venteId,
        details: 'Vente groupée de $quantiteTotal kg pour ${details.length} adhérent(s)',
      );

      // Notification : Vente créée
      await _notificationService.notifyVenteCreated(
        venteId: venteId,
        montant: montantTotal,
        userId: createdBy,
      );

      return vente.copyWith(id: venteId);
    } catch (e) {
      throw Exception('Erreur lors de la création de la vente groupée: $e');
    }
  }

  /// Annuler une vente
  Future<bool> annulerVente(int venteId, int annulePar, String? raison) async {
    try {
      final db = await DatabaseInitializer.database;

      // Récupérer la vente
      final venteResult = await db.query(
        'ventes',
        where: 'id = ?',
        whereArgs: [venteId],
        limit: 1,
      );

      if (venteResult.isEmpty) {
        throw Exception('Vente non trouvée');
      }

      final vente = VenteModel.fromMap(venteResult.first);

      if (vente.isAnnulee) {
        throw Exception('Cette vente est déjà annulée');
      }

      // Marquer la vente comme annulée
      await db.update(
        'ventes',
        {
          'statut': 'annulee',
        },
        where: 'id = ?',
        whereArgs: [venteId],
      );

      // Restaurer le stock
      if (vente.isIndividuelle && vente.adherentId != null) {
        // Créer un mouvement positif pour restaurer le stock
        await _stockService.createAjustement(
          adherentId: vente.adherentId!,
          quantite: vente.quantiteTotal, // Positif pour restaurer
          raison: 'Annulation de vente #$venteId${raison != null ? ': $raison' : ''}',
          createdBy: annulePar,
        );

        // Enregistrer dans l'historique
        await _adherentService.logVente(
          adherentId: vente.adherentId!,
          venteId: venteId,
          quantite: -vente.quantiteTotal, // Négatif pour indiquer annulation
          montant: -vente.montantTotal,
          dateVente: DateTime.now(),
          createdBy: annulePar,
        );
      } else if (vente.isGroupee) {
        // Récupérer les détails
        final detailsResult = await db.query(
          'vente_details',
          where: 'vente_id = ?',
          whereArgs: [venteId],
        );

        for (final detailMap in detailsResult) {
          final detail = VenteDetailModel.fromMap(detailMap);
          
          // Restaurer le stock pour chaque adhérent
          await _stockService.createAjustement(
            adherentId: detail.adherentId,
            quantite: detail.quantite,
            raison: 'Annulation de vente groupée #$venteId${raison != null ? ': $raison' : ''}',
            createdBy: annulePar,
          );

          // Enregistrer dans l'historique
          await _adherentService.logVente(
            adherentId: detail.adherentId,
            venteId: venteId,
            quantite: -detail.quantite,
            montant: -detail.montant,
            dateVente: DateTime.now(),
            createdBy: annulePar,
          );
        }
      }

      await _auditService.logAction(
        userId: annulePar,
        action: 'ANNULER_VENTE',
        entityType: 'ventes',
        entityId: venteId,
        details: 'Annulation de vente${raison != null ? ': $raison' : ''}',
      );

      // Notification : Vente annulée
      await _notificationService.notifyVenteAnnulee(
        venteId: venteId,
        raison: raison ?? '',
        userId: annulePar,
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la vente: $e');
    }
  }

  /// Récupérer toutes les ventes
  Future<List<VenteModel>> getAllVentes({
    int? adherentId,
    String? type,
    String? statut,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (adherentId != null) {
        where += ' AND adherent_id = ?';
        whereArgs.add(adherentId);
      }

      if (type != null) {
        where += ' AND type = ?';
        whereArgs.add(type);
      }

      if (statut != null) {
        where += ' AND statut = ?';
        whereArgs.add(statut);
      }

      if (startDate != null) {
        where += ' AND date_vente >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND date_vente <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.query(
        'ventes',
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'date_vente DESC, created_at DESC',
      );

      return result.map((map) => VenteModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des ventes: $e');
    }
  }

  /// Récupérer une vente par ID
  Future<VenteModel?> getVenteById(int id) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.query(
        'ventes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return VenteModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la vente: $e');
    }
  }

  /// Récupérer les détails d'une vente groupée
  Future<List<VenteDetailModel>> getVenteDetails(int venteId) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.query(
        'vente_details',
        where: 'vente_id = ?',
        whereArgs: [venteId],
      );

      return result.map((map) => VenteDetailModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des détails: $e');
    }
  }

  /// Rechercher des ventes
  Future<List<VenteModel>> searchVentes(String query) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.query(
        'ventes',
        where: '''
          (acheteur LIKE ? OR notes LIKE ?)
        ''',
        whereArgs: [
          '%$query%',
          '%$query%',
        ],
        orderBy: 'date_vente DESC',
      );

      return result.map((map) => VenteModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Obtenir les statistiques des ventes
  Future<Map<String, dynamic>> getStatistiques({
    DateTime? startDate,
    DateTime? endDate,
    int? adherentId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = 'statut = ?';
      List<dynamic> whereArgs = ['valide'];

      if (adherentId != null) {
        where += ' AND adherent_id = ?';
        whereArgs.add(adherentId);
      }

      if (startDate != null) {
        where += ' AND date_vente >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND date_vente <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as nombre_ventes,
          COALESCE(SUM(quantite_total), 0) as quantite_totale,
          COALESCE(SUM(montant_total), 0) as montant_total
        FROM ventes
        WHERE $where
      ''', whereArgs);

      final stats = result.first;

      return {
        'nombreVentes': stats['nombre_ventes'] as int? ?? 0,
        'quantiteTotale': (stats['quantite_totale'] as num?)?.toDouble() ?? 0.0,
        'montantTotal': (stats['montant_total'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }
}
