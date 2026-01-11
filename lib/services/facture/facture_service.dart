import '../database/db_initializer.dart';
import '../../data/models/facture_model.dart';
import '../auth/audit_service.dart';
import '../notification/notification_service.dart';

class FactureService {
  final AuditService _auditService = AuditService();
  final NotificationService _notificationService = NotificationService();

  /// Générer un numéro de facture unique
  Future<String> generateNumero({
    required String type,
    required DateTime date,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Compter les factures du même type pour ce mois
      final year = date.year;
      final month = date.month;
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM factures
        WHERE type = ? 
        AND date_facture >= ? 
        AND date_facture <= ?
      ''', [type, startDate.toIso8601String(), endDate.toIso8601String()]);

      final sequence = (result.first['count'] as int? ?? 0) + 1;

      return FactureModel.generateNumero(
        type: type,
        date: date,
        sequence: sequence,
      );
    } catch (e) {
      throw Exception('Erreur lors de la génération du numéro: $e');
    }
  }

  /// Créer une facture
  Future<FactureModel> createFacture({
    required int adherentId,
    required String type,
    required double montantTotal,
    required DateTime dateFacture,
    DateTime? dateEcheance,
    String? notes,
    String? pdfPath,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      // Générer le numéro unique
      final numero = await generateNumero(type: type, date: dateFacture);

      final facture = FactureModel(
        numero: numero,
        adherentId: adherentId,
        type: type,
        montantTotal: montantTotal,
        dateFacture: dateFacture,
        dateEcheance: dateEcheance,
        statut: 'validee',
        notes: notes,
        pdfPath: pdfPath,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      final id = await db.insert('factures', facture.toMap());

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_FACTURE',
        entityType: 'factures',
        entityId: id,
        details: 'Création de facture $numero pour adhérent $adherentId',
      );

      // Notification : Facture générée
      await _notificationService.notifyFactureGenerated(
        numeroFacture: numero,
        montant: montantTotal,
        userId: createdBy,
      );

      return facture.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création de la facture: $e');
    }
  }

  /// Créer une facture depuis une vente
  Future<FactureModel> createFactureFromVente({
    required int adherentId,
    required int venteId,
    required double montantTotal,
    required DateTime dateVente,
    String? notes,
    String? pdfPath,
    required int createdBy,
  }) async {
    final factureNotes = notes != null 
        ? 'Vente #$venteId - $notes'
        : 'Vente #$venteId';
    
    final facture = await createFacture(
      adherentId: adherentId,
      type: 'vente',
      montantTotal: montantTotal,
      dateFacture: dateVente,
      notes: factureNotes,
      pdfPath: pdfPath,
      createdBy: createdBy,
    );

    // Mettre à jour la facture avec le venteId dans la base de données
    if (facture.id != null) {
      try {
        final db = await DatabaseInitializer.database;
        await db.update(
          'factures',
          {'vente_id': venteId},
          where: 'id = ?',
          whereArgs: [facture.id],
        );
        print('✅ Facture #${facture.id} liée à la vente #$venteId');
      } catch (e) {
        print('⚠️ Erreur lors de la mise à jour du lien vente_id dans la facture: $e');
      }
    }

    return facture.copyWith(venteId: venteId);
  }

  /// Créer une facture depuis une recette
  Future<FactureModel> createFactureFromRecette({
    required int adherentId,
    required int recetteId,
    required double montantNet,
    required DateTime dateRecette,
    String? notes,
    String? pdfPath,
    required int createdBy,
  }) async {
    final factureNotes = notes != null 
        ? 'Recette #$recetteId - $notes'
        : 'Recette #$recetteId';
    
    final facture = await createFacture(
      adherentId: adherentId,
      type: 'recette',
      montantTotal: montantNet,
      dateFacture: dateRecette,
      notes: factureNotes,
      pdfPath: pdfPath,
      createdBy: createdBy,
    );

    return facture.copyWith(recetteId: recetteId);
  }

  /// Mettre à jour une facture
  Future<FactureModel> updateFacture({
    required int id,
    String? statut,
    String? notes,
    String? pdfPath,
    DateTime? dateEcheance,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (statut != null) updateData['statut'] = statut;
      if (notes != null) updateData['notes'] = notes;
      if (pdfPath != null) updateData['pdf_path'] = pdfPath;
      if (dateEcheance != null) updateData['date_echeance'] = dateEcheance.toIso8601String();

      await db.update(
        'factures',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_FACTURE',
        entityType: 'factures',
        entityId: id,
        details: 'Mise à jour de la facture',
      );

      return (await getFactureById(id))!;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Marquer une facture comme payée
  Future<bool> marquerPayee(int id, int updatedBy) async {
    try {
      await updateFacture(
        id: id,
        statut: 'payee',
        updatedBy: updatedBy,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Annuler une facture
  Future<bool> annulerFacture(int id, int updatedBy, String? raison) async {
    try {
      await updateFacture(
        id: id,
        statut: 'annulee',
        notes: raison != null ? 'Annulée: $raison' : 'Annulée',
        updatedBy: updatedBy,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer toutes les factures
  Future<List<FactureModel>> getAllFactures({
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
        where += ' AND date_facture >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND date_facture <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.query(
        'factures',
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'date_facture DESC, created_at DESC',
      );

      return result.map((map) => FactureModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des factures: $e');
    }
  }

  /// Récupérer une facture par ID
  Future<FactureModel?> getFactureById(int id) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.query(
        'factures',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return FactureModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la facture: $e');
    }
  }

  /// Récupérer une facture par numéro
  Future<FactureModel?> getFactureByNumero(String numero) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.query(
        'factures',
        where: 'numero = ?',
        whereArgs: [numero],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return FactureModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la facture: $e');
    }
  }

  /// Rechercher des factures
  Future<List<FactureModel>> searchFactures(String query) async {
    try {
      final db = await DatabaseInitializer.database;

      final result = await db.query(
        'factures',
        where: 'numero LIKE ? OR notes LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'date_facture DESC',
      );

      return result.map((map) => FactureModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Obtenir les statistiques des factures
  Future<Map<String, dynamic>> getStatistiques({
    DateTime? startDate,
    DateTime? endDate,
    int? adherentId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;

      String where = 'statut != ?';
      List<dynamic> whereArgs = ['annulee'];

      if (adherentId != null) {
        where += ' AND adherent_id = ?';
        whereArgs.add(adherentId);
      }

      if (startDate != null) {
        where += ' AND date_facture >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND date_facture <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as nombre_factures,
          COALESCE(SUM(montant_total), 0) as montant_total,
          COUNT(CASE WHEN statut = 'payee' THEN 1 END) as nombre_payees,
          COALESCE(SUM(CASE WHEN statut = 'payee' THEN montant_total ELSE 0 END), 0) as montant_paye
        FROM factures
        WHERE $where
      ''', whereArgs);

      final stats = result.first;

      return {
        'nombreFactures': stats['nombre_factures'] as int? ?? 0,
        'montantTotal': (stats['montant_total'] as num?)?.toDouble() ?? 0.0,
        'nombrePayees': stats['nombre_payees'] as int? ?? 0,
        'montantPaye': (stats['montant_paye'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }
}
