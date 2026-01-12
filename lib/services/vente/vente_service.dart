import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/db_initializer.dart';
import '../../data/models/vente_model.dart';
import '../../data/models/vente_detail_model.dart';
import '../../data/models/vente_ligne_model.dart';
import '../../data/models/vente_adherent_model.dart';
import '../../data/models/journal_vente_model.dart';
import '../../data/models/vente_mensuelle_stats_model.dart';
import '../../data/models/vente_top_client_stats_model.dart';
import '../../data/models/parametres_cooperative_model.dart';
import '../../data/models/stock_model.dart';
import '../stock/stock_service.dart';
import '../adherent/adherent_service.dart';
import '../auth/audit_service.dart';
import '../notification/notification_service.dart';
import '../parametres/parametres_service.dart';
import '../recette/recette_service.dart';
// V2: Nouveaux imports
import '../comptabilite/comptabilite_service.dart';
import '../qrcode/document_security_service.dart';
import '../facture/facture_service.dart';

class VenteService {
  final StockService _stockService = StockService();
  final AdherentService _adherentService = AdherentService();
  final AuditService _auditService = AuditService();
  final NotificationService _notificationService = NotificationService();
  final ParametresService _parametresService = ParametresService();
  final RecetteService _recetteService = RecetteService();
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
        final documentSecurise =
            await DocumentSecurityService.getSecureDocument(
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

      // Créer automatiquement la recette pour cette vente
      print(
        '🛒 Tentative de création de recette pour vente individuelle #$venteId',
      );
      try {
        await _recetteService.createRecetteFromVente(
          adherentId: adherentId,
          venteId: venteId,
          montantBrut: montantTotal,
          notes:
              'Recette générée automatiquement pour vente individuelle #$venteId',
          createdBy: createdBy,
          generateEcritureComptable: generateEcritureComptable,
        );
        print('✅ Recette créée avec succès pour vente individuelle #$venteId');
      } catch (e, stackTrace) {
        print('❌ Erreur lors de la création de la recette: $e');
        print('❌ Stack trace: $stackTrace');
        // Ne pas faire échouer la vente si la recette échoue
      }

      // Créer automatiquement une facture (reçu) pour la vente
      int? factureId;
      try {
        print('🧾 Création de la facture (reçu) pour vente #$venteId');
        final factureService = FactureService();
        final facture = await factureService.createFactureFromVente(
          adherentId: adherentId,
          venteId: venteId,
          montantTotal: montantTotal,
          dateVente: dateVente,
          notes: notes,
          createdBy: createdBy,
        );
        factureId = facture.id;
        print(
          '✅ Facture (reçu) créée avec succès! ID: $factureId, Numéro: ${facture.numero}',
        );

        // Mettre à jour la vente avec l'ID de la facture
        await db.update(
          'ventes',
          {'facture_id': factureId},
          where: 'id = ?',
          whereArgs: [venteId],
        );
        print('✅ Vente #$venteId liée à la facture #$factureId');
      } catch (e, stackTrace) {
        print('❌ Erreur lors de la création de la facture (reçu): $e');
        print('❌ Stack trace: $stackTrace');
        // Ne pas faire échouer la vente si la facture échoue
      }

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
    int? clientId, // V2: Lien avec client
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
  }) async {
    try {
      // Vérifier les stocks pour tous les adhérents
      for (final detail in details) {
        final stockDisponible = await _stockService.getStockActuel(
          detail.adherentId,
        );
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
        clientId: clientId,
      );

      // Insérer la vente
      final venteId = await db.insert('ventes', vente.toMap());

      // Insérer les détails et déduire les stocks
      for (final detail in details) {
        // Insérer le détail avec l'ID de la vente
        await db.insert(
          'vente_details',
          detail.copyWith(venteId: venteId).toMap(),
        );

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

        // Créer automatiquement la recette pour cet adhérent
        print(
          '🛒 Tentative de création de recette pour vente groupée #$venteId, adhérent #${detail.adherentId}',
        );
        try {
          await _recetteService.createRecetteFromVente(
            adherentId: detail.adherentId,
            venteId: venteId,
            montantBrut: detail.montant,
            notes:
                'Recette générée automatiquement pour vente groupée #$venteId',
            createdBy: createdBy,
            generateEcritureComptable:
                false, // Générer une seule écriture pour toute la vente groupée
          );
          print(
            '✅ Recette créée avec succès pour vente groupée #$venteId, adhérent #${detail.adherentId}',
          );
        } catch (e, stackTrace) {
          print(
            '❌ Erreur lors de la création de la recette pour adhérent ${detail.adherentId}: $e',
          );
          print('❌ Stack trace: $stackTrace');
          // Ne pas faire échouer la vente si la recette échoue
        }
      }

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_VENTE_GROUPEE',
        entityType: 'ventes',
        entityId: venteId,
        details:
            'Vente groupée de $quantiteTotal kg pour ${details.length} adhérent(s)',
      );

      // Créer automatiquement une facture (reçu) pour la vente groupée
      int? factureId;
      try {
        print('🧾 Création de la facture (reçu) pour vente groupée #$venteId');
        final factureService = FactureService();
        // Pour une vente groupée, utiliser le premier adhérent comme référence
        final facture = await factureService.createFactureFromVente(
          adherentId: details.first.adherentId,
          venteId: venteId,
          montantTotal: montantTotal,
          dateVente: dateVente,
          notes: notes,
          createdBy: createdBy,
        );
        factureId = facture.id;
        print(
          '✅ Facture (reçu) créée avec succès pour vente groupée! ID: $factureId, Numéro: ${facture.numero}',
        );

        // Mettre à jour la vente avec l'ID de la facture
        await db.update(
          'ventes',
          {'facture_id': factureId},
          where: 'id = ?',
          whereArgs: [venteId],
        );
        print('✅ Vente groupée #$venteId liée à la facture #$factureId');
      } catch (e, stackTrace) {
        print(
          '❌ Erreur lors de la création de la facture (reçu) pour vente groupée: $e',
        );
        print('❌ Stack trace: $stackTrace');
        // Ne pas faire échouer la vente si la facture échoue
      }

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
        {'statut': 'annulee'},
        where: 'id = ?',
        whereArgs: [venteId],
      );

      // Restaurer le stock
      if (vente.isIndividuelle && vente.adherentId != null) {
        // Créer un mouvement positif pour restaurer le stock
        await _stockService.createAjustement(
          adherentId: vente.adherentId!,
          quantite: vente.quantiteTotal, // Positif pour restaurer
          raison:
              'Annulation de vente #$venteId${raison != null ? ': $raison' : ''}',
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
            raison:
                'Annulation de vente groupée #$venteId${raison != null ? ': $raison' : ''}',
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

  /// Récupérer les ventes d'un adhérent (vue Expert).
  ///
  /// Important: les ventes "groupées" n'ont pas de `adherent_id` dans `ventes`.
  /// Elles sont rattachées via la table pivot `vente_adherents`.
  ///
  /// Cette méthode renvoie :
  /// - les ventes individuelles (ventes.adherent_id = adherentId)
  /// - les ventes groupées où l'adhérent apparaît dans vente_adherents
  ///   en surchargeant quantite/montant avec la part de l'adhérent.
  Future<List<VenteModel>> getVentesForAdherentExpert({
    required int adherentId,
    String? statut,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // 1) Ventes individuelles
      final individuelleWhere = <String>['adherent_id = ?'];
      final individuelleArgs = <Object?>[adherentId];
      if (statut != null) {
        individuelleWhere.add('statut = ?');
        individuelleArgs.add(statut);
      }

      final individuelles = await db.query(
        'ventes',
        where: individuelleWhere.join(' AND '),
        whereArgs: individuelleArgs,
      );
      final ventesIndividuelles =
          individuelles.map((m) => VenteModel.fromMap(m)).toList();

      // 2) Ventes groupées (répartition via vente_adherents)
      final groupedWhere = <String>['va.adherent_id = ?'];
      final groupedArgs = <Object?>[adherentId];
      if (statut != null) {
        groupedWhere.add('v.statut = ?');
        groupedArgs.add(statut);
      }

      final groupedRows = await db.rawQuery(
        '''
        SELECT
          v.*,
          va.poids_utilise,
          va.prix_kg,
          va.montant_brut,
          va.commission_rate,
          va.commission_amount,
          va.montant_net
        FROM ventes v
        INNER JOIN vente_adherents va ON va.vente_id = v.id
        WHERE ${groupedWhere.join(' AND ')}
        ORDER BY v.date_vente DESC, v.created_at DESC
      ''',
        groupedArgs,
      );

      final ventesGroupees = groupedRows.map((row) {
        final map = Map<String, dynamic>.from(row);

        // Forcer l'adhérent courant pour homogénéiser l'affichage.
        map['adherent_id'] = adherentId;

        // Surcharger les totaux pour refléter la part de cet adhérent.
        if (map['poids_utilise'] != null) {
          map['quantite_total'] = (map['poids_utilise'] as num).toDouble();
        }
        if (map['prix_kg'] != null) {
          map['prix_unitaire'] = (map['prix_kg'] as num).toDouble();
        }
        if (map['montant_brut'] != null) {
          map['montant_total'] = (map['montant_brut'] as num).toDouble();
        }

        // Champs V1 utilisés dans certains écrans/stats.
        if (map['commission_amount'] != null) {
          map['montant_commission'] =
              (map['commission_amount'] as num).toDouble();
        }
        if (map['montant_net'] != null) {
          map['montant_net'] = (map['montant_net'] as num).toDouble();
        }

        return VenteModel.fromMap(map);
      }).toList();

      // Fusionner sans doublons (une vente peut être individuelle ou groupée)
      final seenIds = <int>{};
      final merged = <VenteModel>[];

      for (final v in ventesGroupees) {
        if (v.id != null && seenIds.add(v.id!)) {
          merged.add(v);
        }
      }
      for (final v in ventesIndividuelles) {
        if (v.id != null) {
          if (seenIds.add(v.id!)) merged.add(v);
        } else {
          merged.add(v);
        }
      }

      merged.sort((a, b) {
        final cmpDate = b.dateVente.compareTo(a.dateVente);
        if (cmpDate != 0) return cmpDate;
        return b.createdAt.compareTo(a.createdAt);
      });

      return merged;
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des ventes (expert): $e',
      );
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
        whereArgs: ['%$query%', '%$query%'],
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

  /// Obtenir les ventes agrégées par mois (pour graphiques)
  Future<List<VenteMensuelleStatsModel>> getVentesParMois({
    DateTime? startDate,
    DateTime? endDate,
    int? adherentId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = 'statut = ?';
      final whereArgs = <dynamic>['valide'];

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

      // date_vente est stockée en ISO-8601 ; substr(1,7) => YYYY-MM
      final rows = await db.rawQuery('''
        SELECT
          substr(date_vente, 1, 7) as mois,
          COUNT(*) as nombre_ventes,
          COALESCE(SUM(quantite_total), 0) as quantite_totale,
          COALESCE(SUM(montant_total), 0) as montant_total
        FROM ventes
        WHERE $where
        GROUP BY mois
        ORDER BY mois ASC
      ''', whereArgs);

      return rows.map((r) => VenteMensuelleStatsModel.fromDbRow(r)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des ventes par mois: $e');
    }
  }

  /// Obtenir les top clients (agrégé) sur une période
  ///
  /// `orderBy` accepte: `montant_total`, `quantite_totale`, `nombre_ventes`.
  Future<List<VenteTopClientStatsModel>> getTopClients({
    DateTime? startDate,
    DateTime? endDate,
    int? adherentId,
    int limit = 10,
    String orderBy = 'montant_total',
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      final allowedOrderBy = <String>{
        'montant_total',
        'quantite_totale',
        'nombre_ventes',
      };
      final safeOrderBy = allowedOrderBy.contains(orderBy)
          ? orderBy
          : 'montant_total';

      String where = 'v.statut = ?';
      final whereArgs = <dynamic>['valide'];

      if (adherentId != null) {
        where += ' AND v.adherent_id = ?';
        whereArgs.add(adherentId);
      }

      if (startDate != null) {
        where += ' AND v.date_vente >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND v.date_vente <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      // Détecter une colonne "nom" valide dans la table clients (migrations différentes selon versions)
      String? clientNameExpr;
      try {
        final cols = await db.rawQuery('PRAGMA table_info(clients)');
        final names = cols.map((c) => (c['name'] as String?) ?? '').toSet();

        if (names.contains('raison_sociale')) {
          clientNameExpr = 'c.raison_sociale';
        } else if (names.contains('nom')) {
          clientNameExpr = 'c.nom';
        } else if (names.contains('code_client')) {
          clientNameExpr = 'c.code_client';
        } else if (names.contains('code')) {
          clientNameExpr = 'c.code';
        }
      } catch (_) {
        clientNameExpr = null;
      }

      final joinClients = clientNameExpr != null;

      // Si on n'a pas la table/colonnes clients, on fallback sur "acheteur"
      if (!joinClients) {
        final rows = await db.rawQuery(
          '''
          SELECT
            COALESCE(v.acheteur, 'Inconnu') as client_key,
            COALESCE(v.acheteur, 'Inconnu') as client_nom,
            COUNT(*) as nombre_ventes,
            COALESCE(SUM(v.quantite_total), 0) as quantite_totale,
            COALESCE(SUM(v.montant_total), 0) as montant_total
          FROM ventes v
          WHERE $where
          GROUP BY client_key, client_nom
          ORDER BY $safeOrderBy DESC
          LIMIT ?
        ''',
          [...whereArgs, limit],
        );

        return rows.map((r) => VenteTopClientStatsModel.fromDbRow(r)).toList();
      }

      final rows = await db.rawQuery(
        '''
        SELECT
          COALESCE(CAST(v.client_id AS TEXT), v.acheteur, 'Inconnu') as client_key,
          COALESCE($clientNameExpr, v.acheteur, 'Inconnu') as client_nom,
          COUNT(*) as nombre_ventes,
          COALESCE(SUM(v.quantite_total), 0) as quantite_totale,
          COALESCE(SUM(v.montant_total), 0) as montant_total
        FROM ventes v
        LEFT JOIN clients c ON c.id = v.client_id
        WHERE $where
        GROUP BY client_key, client_nom
        ORDER BY $safeOrderBy DESC
        LIMIT ?
      ''',
        [...whereArgs, limit],
      );

      return rows.map((r) => VenteTopClientStatsModel.fromDbRow(r)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des top clients: $e');
    }
  }

  // ========== MODULE VENTES V1 ==========

  /// Créer une vente V1 avec toutes les fonctionnalités requises
  /// Transaction atomique complète : validation prix, stock FIFO, calculs, recettes, QR Code, journal
  Future<VenteModel> createVenteV1({
    required int clientId, // OBLIGATOIRE V1
    required int campagneId, // OBLIGATOIRE V1
    required int adherentId,
    required double quantiteTotal,
    required double prixUnitaire,
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
    bool overridePrixValidation =
        false, // Pour admin override si prix hors seuil
  }) async {
    final db = await DatabaseInitializer.database;

    // Démarrer une transaction atomique
    await db.execute('BEGIN TRANSACTION');

    try {
      // 1. VALIDATION PRIX (seuils min/max)
      await _validatePrix(prixUnitaire, overridePrixValidation);

      // 2. VÉRIFICATION STOCK DISPONIBLE
      final stockDisponible = await _stockService.getStockActuel(adherentId);
      if (stockDisponible < quantiteTotal) {
        await db.execute('ROLLBACK');
        throw Exception(
          'Stock insuffisant. Stock disponible: ${stockDisponible.toStringAsFixed(2)} kg, Quantité demandée: ${quantiteTotal.toStringAsFixed(2)} kg',
        );
      }

      // 3. CALCULS
      final montantBrut = quantiteTotal * prixUnitaire;
      final parametres = await _parametresService.getParametres();
      final commissionRate = parametres.commissionRate;
      final montantCommission = montantBrut * commissionRate;
      final montantNet = montantBrut - montantCommission;

      // 4. CRÉER LA VENTE
      final vente = VenteModel(
        type: 'individuelle',
        adherentId: adherentId,
        quantiteTotal: quantiteTotal,
        prixUnitaire: prixUnitaire,
        montantTotal: montantBrut,
        modePaiement: modePaiement,
        dateVente: dateVente,
        notes: notes,
        statut: 'valide',
        statutPaiement: 'non_payee',
        createdBy: createdBy,
        createdAt: DateTime.now(),
        clientId: clientId,
        campagneId: campagneId,
        montantCommission: montantCommission,
        montantNet: montantNet,
      );

      final venteId = await db.insert('ventes', vente.toMap());

      // 5. DÉBITER LE STOCK EN FIFO (créer vente_lignes)
      await _debiterStockFIFO(
        db: db,
        venteId: venteId,
        adherentId: adherentId,
        quantiteDemandee: quantiteTotal,
        prixUnitaire: prixUnitaire,
        createdBy: createdBy,
      );

      // 6. CRÉER LES RECETTES ADHÉRENTS
      await _recetteService.createRecetteFromVente(
        adherentId: adherentId,
        venteId: venteId,
        montantBrut: montantBrut,
        commissionRate: commissionRate,
        notes: 'Recette générée automatiquement pour vente #$venteId',
        createdBy: createdBy,
        generateEcritureComptable: true,
      );

      // 7. GÉNÉRER QR CODE
      try {
        final documentContent = {
          'vente_id': venteId,
          'client_id': clientId,
          'adherent_id': adherentId,
          'montant_brut': montantBrut,
          'montant_net': montantNet,
          'quantite': quantiteTotal,
          'date': dateVente.toIso8601String(),
        };

        await DocumentSecurityService.generateSecureDocument(
          documentType: 'vente',
          documentId: venteId,
          documentContent: documentContent,
          createdBy: createdBy,
        );

        final documentSecurise =
            await DocumentSecurityService.getSecureDocument(
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
        // Ne pas faire échouer la transaction
      }

      // 8. ENREGISTRER DANS LE JOURNAL
      await _logJournalVente(
        db: db,
        venteId: venteId,
        action: 'CREATE',
        nouveauStatut: 'valide',
        nouveauMontant: montantBrut,
        details: 'Vente V1 créée pour client $clientId, campagne $campagneId',
        createdBy: createdBy,
      );

      // 9. ENREGISTRER DANS L'HISTORIQUE ADHÉRENT
      await _adherentService.logVente(
        adherentId: adherentId,
        venteId: venteId,
        quantite: quantiteTotal,
        montant: montantBrut,
        dateVente: dateVente,
        createdBy: createdBy,
      );

      // 10. AUDIT
      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_VENTE_V1',
        entityType: 'ventes',
        entityId: venteId,
        details:
            'Vente V1 de $quantiteTotal kg pour adhérent $adherentId, client $clientId',
      );

      // 11. NOTIFICATION
      await _notificationService.notifyVenteCreated(
        venteId: venteId,
        montant: montantBrut,
        userId: createdBy,
      );

      // Valider la transaction
      await db.execute('COMMIT');

      return vente.copyWith(id: venteId);
    } catch (e) {
      // Rollback en cas d'erreur
      await db.execute('ROLLBACK');
      throw Exception('Erreur lors de la création de la vente V1: $e');
    }
  }

  /// Valider le prix par rapport aux seuils min/max
  Future<void> _validatePrix(double prixUnitaire, bool override) async {
    if (override) return; // Admin override

    try {
      final db = await DatabaseInitializer.database;

      // Récupérer tous les barèmes de qualité
      final baremes = await db.query('baremes_qualite');

      bool prixValide = false;
      String? messageErreur;

      for (final bareme in baremes) {
        final prixMin = bareme['prix_min'] as num?;
        final prixMax = bareme['prix_max'] as num?;

        if (prixMin != null && prixUnitaire < prixMin) {
          messageErreur =
              'Prix trop bas: ${prixUnitaire.toStringAsFixed(0)} FCFA/kg < ${prixMin.toStringAsFixed(0)} FCFA/kg (minimum)';
          break;
        }

        if (prixMax != null && prixUnitaire > prixMax) {
          messageErreur =
              'Prix trop élevé: ${prixUnitaire.toStringAsFixed(0)} FCFA/kg > ${prixMax.toStringAsFixed(0)} FCFA/kg (maximum)';
          break;
        }

        // Si on arrive ici, le prix est dans les seuils pour au moins un barème
        if ((prixMin == null || prixUnitaire >= prixMin) &&
            (prixMax == null || prixUnitaire <= prixMax)) {
          prixValide = true;
        }
      }

      if (!prixValide && messageErreur != null) {
        throw Exception(
          '$messageErreur. Override admin requis pour continuer.',
        );
      }
    } catch (e) {
      if (e.toString().contains('Override')) {
        rethrow;
      }
      // Si pas de barèmes configurés, on accepte le prix
      print('Avertissement: Validation prix impossible: $e');
    }
  }

  /// Débiter le stock en FIFO (créer les vente_lignes)
  Future<void> _debiterStockFIFO({
    required Database db,
    required int venteId,
    required int adherentId,
    required double quantiteDemandee,
    required double prixUnitaire,
    required int createdBy,
  }) async {
    // Récupérer les dépôts disponibles en FIFO
    final depotsDisponibles = await _stockService.getDepotsDisponiblesFIFO(
      adherentId,
    );

    double quantiteRestante = quantiteDemandee;
    final venteLignes = <VenteLigneModel>[];

    for (final depotInfo in depotsDisponibles) {
      if (quantiteRestante <= 0) break;

      final depot = depotInfo['depot'] as StockDepotModel;
      final quantiteDisponible = depotInfo['quantite_disponible'] as double;
      final depotId = depotInfo['depot_id'] as int;

      final quantiteAPrelever = quantiteRestante < quantiteDisponible
          ? quantiteRestante
          : quantiteDisponible;

      final montantLigne = quantiteAPrelever * prixUnitaire;

      final venteLigne = VenteLigneModel(
        venteId: venteId,
        stockDepotId: depotId,
        adherentId: adherentId,
        quantite: quantiteAPrelever,
        prixUnitaire: prixUnitaire,
        montant: montantLigne,
        createdAt: DateTime.now(),
      );

      await db.insert('vente_lignes', venteLigne.toMap());

      // Créer un mouvement de stock négatif
      await db.insert('stock_mouvements', {
        'adherent_id': adherentId,
        'type': 'vente',
        'quantite': -quantiteAPrelever,
        'stock_depot_id': depotId,
        'vente_id': venteId,
        'date_mouvement': DateTime.now().toIso8601String(),
        'notes': 'Vente V1 - Débit FIFO depuis dépôt #$depotId',
        'created_by': createdBy,
        'created_at': DateTime.now().toIso8601String(),
      });

      quantiteRestante -= quantiteAPrelever;
    }

    if (quantiteRestante > 0) {
      throw Exception(
        'Stock insuffisant pour compléter la vente. Quantité restante: ${quantiteRestante.toStringAsFixed(2)} kg',
      );
    }
  }

  /// Enregistrer dans le journal des ventes
  Future<void> _logJournalVente({
    required Database db,
    required int venteId,
    required String action,
    String? ancienStatut,
    String? nouveauStatut,
    double? ancienMontant,
    double? nouveauMontant,
    String? details,
    required int createdBy,
  }) async {
    final journalEntry = JournalVenteModel(
      venteId: venteId,
      action: action,
      ancienStatut: ancienStatut,
      nouveauStatut: nouveauStatut,
      ancienMontant: ancienMontant,
      nouveauMontant: nouveauMontant,
      details: details,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    await db.insert('journal_ventes', journalEntry.toMap());
  }

  // ========== INTÉGRATION ADHÉRENTS ↔ VENTES ==========

  /// Créer une vente avec répartition automatique par adhérents
  ///
  /// Cette méthode :
  /// 1. Sélectionne les stocks disponibles par campagne/qualité
  /// 2. Répartit automatiquement selon FIFO et priorité catégorie
  /// 3. Crée les lignes vente_adherents avec calculs de commission
  /// 4. Crée les recettes automatiquement
  /// 5. Tout en transaction atomique
  Future<VenteModel> createVenteWithRepartition({
    required double quantiteTotal,
    required double prixUnitaire,
    required int campagneId,
    String? qualite,
    String? acheteur,
    int? clientId,
    String? modePaiement,
    required DateTime dateVente,
    String? notes,
    required int createdBy,
    List<int>? adherentIdsPrioritaires, // Adhérents à prioriser (optionnel)
    bool overridePrixValidation = false,
  }) async {
    final db = await DatabaseInitializer.database;

    // Démarrer une transaction atomique
    await db.execute('BEGIN TRANSACTION');

    try {
      // 1. VALIDATION PRIX
      await _validatePrix(prixUnitaire, overridePrixValidation);

      // 2. SÉLECTIONNER LES STOCKS DISPONIBLES
      final stocksDisponibles = await _selectStocksDisponibles(
        quantiteDemandee: quantiteTotal,
        campagneId: campagneId,
        qualite: qualite,
        adherentIdsPrioritaires: adherentIdsPrioritaires,
      );

      if (stocksDisponibles.isEmpty) {
        await db.execute('ROLLBACK');
        throw Exception(
          'Aucun stock disponible pour cette campagne et qualité',
        );
      }

      // Vérifier que la quantité totale disponible est suffisante
      final quantiteDisponible = stocksDisponibles.fold<double>(
        0.0,
        (sum, stock) => sum + stock['quantite_disponible'],
      );

      if (quantiteDisponible < quantiteTotal) {
        await db.execute('ROLLBACK');
        throw Exception(
          'Stock insuffisant. Disponible: ${quantiteDisponible.toStringAsFixed(2)} kg, '
          'Demandé: ${quantiteTotal.toStringAsFixed(2)} kg',
        );
      }

      // 3. CRÉER LA VENTE
      final montantTotal = quantiteTotal * prixUnitaire;
      final vente = VenteModel(
        type: 'groupee', // Vente avec répartition = groupée
        quantiteTotal: quantiteTotal,
        prixUnitaire: prixUnitaire,
        montantTotal: montantTotal,
        acheteur: acheteur,
        modePaiement: modePaiement,
        dateVente: dateVente,
        notes: notes,
        statut: 'valide',
        statutPaiement: 'non_payee',
        createdBy: createdBy,
        createdAt: DateTime.now(),
        clientId: clientId,
        campagneId: campagneId,
      );

      final venteId = await db.insert('ventes', vente.toMap());

      // 4. RÉPARTIR AUTOMATIQUEMENT PAR ADHÉRENTS (FIFO + PRIORITÉ)
      double quantiteRestante = quantiteTotal;
      final venteAdherents = <VenteAdherentModel>[];

      for (final stockInfo in stocksDisponibles) {
        if (quantiteRestante <= 0) break;

        final adherentId = stockInfo['adherent_id'] as int;
        final quantiteDisponibleStock =
            stockInfo['quantite_disponible'] as double;
        final depotId = stockInfo['depot_id'] as int?;
        final qualiteStock = stockInfo['qualite'] as String?;

        // Vérifier que l'adhérent peut vendre
        final canSell = await _adherentService.canAdherentSell(adherentId);
        if (!canSell) {
          continue; // Passer au suivant
        }

        final quantiteAPrelever = quantiteRestante < quantiteDisponibleStock
            ? quantiteRestante
            : quantiteDisponibleStock;

        // Calculer les montants pour cet adhérent
        final montantBrut = VenteAdherentModel.calculateMontantBrut(
          quantiteAPrelever,
          prixUnitaire,
        );

        // Obtenir le taux de commission selon catégorie
        final commissionRate = await _adherentService
            .getCommissionRateForAdherent(adherentId);

        final commissionAmount = VenteAdherentModel.calculateCommissionAmount(
          montantBrut,
          commissionRate,
        );

        final montantNet = VenteAdherentModel.calculateMontantNet(
          montantBrut,
          commissionRate,
        );

        // Créer la ligne vente_adherents
        final venteAdherent = VenteAdherentModel(
          venteId: venteId,
          adherentId: adherentId,
          poidsUtilise: quantiteAPrelever,
          prixKg: prixUnitaire,
          montantBrut: montantBrut,
          commissionRate: commissionRate,
          commissionAmount: commissionAmount,
          montantNet: montantNet,
          campagneId: campagneId,
          qualite: qualiteStock ?? qualite,
          createdAt: DateTime.now(),
          createdBy: createdBy,
        );

        await db.insert('vente_adherents', venteAdherent.toMap());
        venteAdherents.add(venteAdherent);

        // Débiter le stock (créer mouvement)
        await db.insert('stock_mouvements', {
          'adherent_id': adherentId,
          'type': 'vente',
          'quantite': -quantiteAPrelever,
          'stock_depot_id': depotId,
          'vente_id': venteId,
          'date_mouvement': dateVente.toIso8601String(),
          'notes':
              'Vente avec répartition automatique - Débit FIFO depuis dépôt ${depotId ?? "N/A"}',
          'created_by': createdBy,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Créer la recette pour cet adhérent
        await _recetteService.createRecetteFromVente(
          adherentId: adherentId,
          venteId: venteId,
          montantBrut: montantBrut,
          commissionRate: commissionRate,
          notes:
              'Recette générée automatiquement pour vente #$venteId (répartition automatique)',
          createdBy: createdBy,
          generateEcritureComptable:
              false, // Générer une seule écriture pour toute la vente
        );

        // Enregistrer dans l'historique de l'adhérent
        await _adherentService.logVente(
          adherentId: adherentId,
          venteId: venteId,
          quantite: quantiteAPrelever,
          montant: montantBrut,
          dateVente: dateVente,
          createdBy: createdBy,
        );

        quantiteRestante -= quantiteAPrelever;
      }

      if (quantiteRestante > 0) {
        await db.execute('ROLLBACK');
        throw Exception(
          'Stock insuffisant pour compléter la vente. Quantité restante: ${quantiteRestante.toStringAsFixed(2)} kg',
        );
      }

      // 5. GÉNÉRER QR CODE
      try {
        final documentContent = {
          'vente_id': venteId,
          'client_id': clientId,
          'campagne_id': campagneId,
          'montant_total': montantTotal,
          'quantite_total': quantiteTotal,
          'nombre_adherents': venteAdherents.length,
          'date': dateVente.toIso8601String(),
        };

        await DocumentSecurityService.generateSecureDocument(
          documentType: 'vente',
          documentId: venteId,
          documentContent: documentContent,
          createdBy: createdBy,
        );

        final documentSecurise =
            await DocumentSecurityService.getSecureDocument(
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
      }

      // 6. ENREGISTRER DANS LE JOURNAL
      await _logJournalVente(
        db: db,
        venteId: venteId,
        action: 'CREATE',
        nouveauStatut: 'valide',
        nouveauMontant: montantTotal,
        details:
            'Vente avec répartition automatique sur ${venteAdherents.length} adhérent(s), campagne $campagneId',
        createdBy: createdBy,
      );

      // 7. AUDIT
      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_VENTE_REPARTITION',
        entityType: 'ventes',
        entityId: venteId,
        details:
            'Vente avec répartition automatique: $quantiteTotal kg sur ${venteAdherents.length} adhérent(s)',
      );

      // 8. NOTIFICATION
      await _notificationService.notifyVenteCreated(
        venteId: venteId,
        montant: montantTotal,
        userId: createdBy,
      );

      // Valider la transaction
      await db.execute('COMMIT');

      return vente.copyWith(id: venteId);
    } catch (e) {
      // Rollback en cas d'erreur
      await db.execute('ROLLBACK');
      throw Exception(
        'Erreur lors de la création de la vente avec répartition: $e',
      );
    }
  }

  /// Sélectionner les stocks disponibles pour une répartition automatique
  ///
  /// Retourne une liste triée selon :
  /// 1. Priorité catégorie (actionnaire > adherent > producteur)
  /// 2. FIFO (date dépôt)
  Future<List<Map<String, dynamic>>> _selectStocksDisponibles({
    required double quantiteDemandee,
    required int campagneId,
    String? qualite,
    List<int>? adherentIdsPrioritaires,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Construire la requête SQL
      // Note: campagne_id n'existe pas dans stock_depots
      // La campagne est une propriété de la vente, pas du stock
      // On récupère tous les stocks disponibles pour la répartition
      String whereClause = '''
        sd.adherent_id = a.id
        AND a.is_active = 1
        AND (a.statut IS NULL OR a.statut = 'actif')
      ''';

      List<dynamic> whereArgs = [];

      if (qualite != null) {
        whereClause += ' AND (sd.qualite = ? OR sd.qualite IS NULL)';
        whereArgs.add(qualite);
      }

      // Construire la clause ORDER BY
      String orderByClause = '';
      List<dynamic> orderByArgs = [];

      if (adherentIdsPrioritaires != null &&
          adherentIdsPrioritaires.isNotEmpty) {
        final placeholders = adherentIdsPrioritaires.map((e) => '?').join(',');
        orderByClause =
            '''
          CASE WHEN sd.adherent_id IN ($placeholders) THEN 0 ELSE 1 END,
        ''';
        orderByArgs.addAll(adherentIdsPrioritaires);
      }

      orderByClause += '''
        CASE 
          WHEN a.categorie = 'actionnaire' THEN 1
          WHEN a.categorie = 'adherent' THEN 2
          ELSE 3
        END,
        sd.date_depot ASC
      ''';

      // Récupérer les dépôts disponibles avec informations adhérents
      final result = await db.rawQuery(
        '''
        SELECT 
          sd.id as depot_id,
          sd.adherent_id,
          sd.date_depot,
          sd.qualite,
          COALESCE(sd.poids_net, sd.quantite, 0) as quantite_depot,
          a.categorie,
          a.code as adherent_code,
          a.nom as adherent_nom,
          a.prenom as adherent_prenom
        FROM stock_depots sd
        INNER JOIN adherents a ON sd.adherent_id = a.id
        WHERE $whereClause
        ORDER BY $orderByClause
      ''',
        [...whereArgs, ...orderByArgs],
      );

      // Filtrer par campagne après récupération si nécessaire
      // (en vérifiant que les dépôts n'ont pas été utilisés dans des ventes d'une autre campagne)

      // Calculer les quantités disponibles (déduire les ventes)
      final stocksDisponibles = <Map<String, dynamic>>[];

      for (final row in result) {
        final depotId = row['depot_id'] as int;
        final adherentId = row['adherent_id'] as int;
        final quantiteDepot = (row['quantite_depot'] as num).toDouble();

        // Calculer les quantités déjà vendues depuis ce dépôt
        final ventesResult = await db.rawQuery(
          '''
          SELECT COALESCE(SUM(ABS(sm.quantite)), 0) as total_vendu
          FROM stock_mouvements sm
          WHERE sm.stock_depot_id = ? AND sm.type = 'vente'
        ''',
          [depotId],
        );

        final quantiteVendue =
            (ventesResult.first['total_vendu'] as num?)?.toDouble() ?? 0.0;
        final quantiteDisponible = quantiteDepot - quantiteVendue;

        if (quantiteDisponible > 0) {
          stocksDisponibles.add({
            'depot_id': depotId,
            'adherent_id': adherentId,
            'quantite_disponible': quantiteDisponible,
            'date_depot': DateTime.parse(row['date_depot'] as String),
            'qualite': row['qualite'] as String?,
            'categorie': row['categorie'] as String?,
            'adherent_code': row['adherent_code'] as String,
            'adherent_nom': row['adherent_nom'] as String,
            'adherent_prenom': row['adherent_prenom'] as String,
          });
        }
      }

      return stocksDisponibles;
    } catch (e) {
      throw Exception('Erreur lors de la sélection des stocks disponibles: $e');
    }
  }

  /// Récupérer la répartition d'une vente (adhérents impactés)
  Future<List<VenteAdherentModel>> getRepartitionVente(int venteId) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.query(
        'vente_adherents',
        where: 'vente_id = ?',
        whereArgs: [venteId],
        orderBy: 'created_at ASC',
      );

      return result.map((map) => VenteAdherentModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la répartition: $e');
    }
  }

  /// Récupérer les ventes d'un adhérent avec répartition
  Future<List<Map<String, dynamic>>> getVentesByAdherent(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.rawQuery(
        '''
        SELECT 
          v.*,
          va.poids_utilise,
          va.montant_brut,
          va.commission_rate,
          va.commission_amount,
          va.montant_net,
          va.campagne_id,
          va.qualite
        FROM ventes v
        INNER JOIN vente_adherents va ON va.vente_id = v.id
        WHERE va.adherent_id = ?
        ORDER BY v.date_vente DESC
      ''',
        [adherentId],
      );

      return result;
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des ventes par adhérent: $e',
      );
    }
  }
}
