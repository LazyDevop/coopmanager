import '../database/db_initializer.dart';
import '../database/migrations/adherent_expert_migrations.dart';
import '../../data/models/adherent_expert/credit_social_model.dart';
import '../auth/audit_service.dart';

/// Service pour gérer les crédits sociaux des adhérents
class CreditSocialService {
  final AuditService _auditService = AuditService();

  /// Créer un crédit social
  Future<CreditSocialModel> createCredit({
    required int adherentId,
    required String typeCredit, // 'credit_produit' ou 'credit_argent'
    String typeAide = 'credit',
    required double montant,
    double? quantiteProduit, // Pour crédit_produit
    String? typeProduit, // Pour crédit_produit
    required DateTime dateOctroi,
    required String motif,
    DateTime? echeanceRemboursement,
    String? observation,
    required int createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // S'assurer que la table existe et a les bonnes colonnes
      await AdherentExpertMigrations.ensureSocialCreditsColumns(db);
      
      // Vérifier les contraintes
      if (montant <= 0) {
        throw Exception('Le montant doit être supérieur à 0');
      }
      
      if (typeCredit == 'credit_produit' && quantiteProduit != null && quantiteProduit <= 0) {
        throw Exception('La quantité de produit doit être supérieure à 0');
      }
      
      // Valider le type de crédit
      if (typeCredit != 'credit_produit' && typeCredit != 'credit_argent') {
        throw Exception('Type de crédit invalide. Doit être "credit_produit" ou "credit_argent"');
      }
      
      // Vérifier quelles colonnes existent dans la table
      final tableInfo = await db.rawQuery('PRAGMA table_info(social_credits)');
      final columnNames = tableInfo.map((col) => col['name'] as String).toSet();
      
      // Si la table n'existe pas, la créer
      if (columnNames.isEmpty) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS social_credits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            adherent_id INTEGER NOT NULL,
            type_credit TEXT NOT NULL DEFAULT 'credit_argent',
            type_aide TEXT NOT NULL DEFAULT 'credit',
            montant REAL NOT NULL,
            quantite_produit REAL,
            type_produit TEXT,
            date_octroi TEXT NOT NULL,
            motif TEXT NOT NULL,
            statut_remboursement TEXT DEFAULT 'non_rembourse',
            solde_restant REAL NOT NULL,
            echeance_remboursement TEXT,
            observation TEXT,
            created_at TEXT NOT NULL,
            created_by INTEGER,
            
            FOREIGN KEY (adherent_id) REFERENCES adherents(id) ON DELETE CASCADE,
            FOREIGN KEY (created_by) REFERENCES users(id)
          )
        ''');
        // Recharger les colonnes après création
        final newTableInfo = await db.rawQuery('PRAGMA table_info(social_credits)');
        columnNames.addAll(newTableInfo.map((col) => col['name'] as String));
      }
      
      final credit = CreditSocialModel(
        adherentId: adherentId,
        typeCredit: typeCredit,
        typeAide: typeAide,
        montant: montant,
        quantiteProduit: quantiteProduit,
        typeProduit: typeProduit,
        dateOctroi: dateOctroi,
        motif: motif,
        soldeRestant: montant,
        echeanceRemboursement: echeanceRemboursement,
        observation: observation,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      final creditMap = credit.toMap();
      
      // Filtrer les colonnes qui n'existent pas dans la table
      final filteredMap = <String, dynamic>{};
      for (final entry in creditMap.entries) {
        if (columnNames.contains(entry.key)) {
          filteredMap[entry.key] = entry.value;
        }
      }
      
      // Si la colonne type_credit n'existe pas, utiliser type_aide pour stocker le type
      if (!columnNames.contains('type_credit')) {
        filteredMap.remove('type_credit');
        // Stocker le type dans type_aide si nécessaire
        if (typeCredit == 'credit_produit') {
          filteredMap['type_aide'] = 'credit_produit';
        } else {
          filteredMap['type_aide'] = typeAide;
        }
      }
      
      // S'assurer que les colonnes obligatoires sont présentes
      if (!filteredMap.containsKey('type_aide')) {
        filteredMap['type_aide'] = typeAide;
      }
      if (!filteredMap.containsKey('adherent_id')) {
        filteredMap['adherent_id'] = adherentId;
      }
      if (!filteredMap.containsKey('montant')) {
        filteredMap['montant'] = montant;
      }
      if (!filteredMap.containsKey('date_octroi')) {
        filteredMap['date_octroi'] = dateOctroi.toIso8601String();
      }
      if (!filteredMap.containsKey('motif')) {
        filteredMap['motif'] = motif;
      }
      if (!filteredMap.containsKey('solde_restant')) {
        filteredMap['solde_restant'] = montant;
      }
      if (!filteredMap.containsKey('statut_remboursement')) {
        filteredMap['statut_remboursement'] = 'non_rembourse';
      }
      if (!filteredMap.containsKey('created_at')) {
        filteredMap['created_at'] = DateTime.now().toIso8601String();
      }

      final id = await db.insert('social_credits', filteredMap);

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_CREDIT_SOCIAL',
        entityType: 'social_credits',
        entityId: id,
        details: 'Création crédit: $typeCredit - ${montant.toStringAsFixed(0)} FCFA pour adhérent $adherentId',
      );

      return credit.copyWith(id: id);
    } catch (e) {
      print('Erreur lors de la création du crédit: $e');
      throw Exception('Erreur lors de la création du crédit: $e');
    }
  }

  /// Enregistrer un remboursement
  Future<CreditSocialModel> enregistrerRemboursement({
    required int id,
    required double montantRembourse,
    DateTime? dateRemboursement,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer le crédit existant
      final existing = await getCreditById(id);
      if (existing == null) {
        throw Exception('Crédit non trouvé');
      }

      if (montantRembourse <= 0) {
        throw Exception('Le montant remboursé doit être supérieur à 0');
      }

      final nouveauSoldeRestant = existing.soldeRestant - montantRembourse;
      
      if (nouveauSoldeRestant < 0) {
        throw Exception('Le montant remboursé ne peut pas dépasser le solde restant');
      }

      final nouveauStatut = nouveauSoldeRestant == 0
          ? 'rembourse'
          : (nouveauSoldeRestant < existing.soldeRestant ? 'partiellement_rembourse' : existing.statutRemboursement);

      final updated = existing.copyWith(
        soldeRestant: nouveauSoldeRestant,
        statutRemboursement: nouveauStatut,
      );

      await db.update(
        'social_credits',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'REMBOURSER_CREDIT_SOCIAL',
        entityType: 'social_credits',
        entityId: id,
        details: 'Remboursement de ${montantRembourse.toStringAsFixed(0)} FCFA',
      );

      return updated;
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement du remboursement: $e');
    }
  }

  /// Mettre à jour un crédit
  Future<CreditSocialModel> updateCredit({
    required int id,
    String? typeCredit,
    String? typeAide,
    double? montant,
    double? quantiteProduit,
    String? typeProduit,
    DateTime? dateOctroi,
    String? motif,
    DateTime? echeanceRemboursement,
    String? observation,
    required int updatedBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer le crédit existant
      final existing = await getCreditById(id);
      if (existing == null) {
        throw Exception('Crédit non trouvé');
      }

      final updatedMontant = montant ?? existing.montant;
      final updatedSoldeRestant = existing.soldeRestant + (updatedMontant - existing.montant);

      final updated = existing.copyWith(
        typeCredit: typeCredit,
        typeAide: typeAide,
        montant: montant,
        quantiteProduit: quantiteProduit,
        typeProduit: typeProduit,
        dateOctroi: dateOctroi,
        motif: motif,
        soldeRestant: updatedSoldeRestant > 0 ? updatedSoldeRestant : existing.soldeRestant,
        echeanceRemboursement: echeanceRemboursement,
        observation: observation,
      );

      // Vérifier quelles colonnes existent dans la table
      final tableInfo = await db.rawQuery('PRAGMA table_info(social_credits)');
      final columnNames = tableInfo.map((col) => col['name'] as String).toSet();
      
      final updateMap = updated.toMap();
      // Filtrer les colonnes qui n'existent pas dans la table
      final filteredUpdateMap = <String, dynamic>{};
      for (final entry in updateMap.entries) {
        if (columnNames.contains(entry.key) && entry.key != 'id') {
          filteredUpdateMap[entry.key] = entry.value;
        }
      }

      await db.update(
        'social_credits',
        filteredUpdateMap,
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_CREDIT_SOCIAL',
        entityType: 'social_credits',
        entityId: id,
        details: 'Modification crédit',
      );

      return updated;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du crédit: $e');
    }
  }

  /// Annuler un crédit
  Future<void> annulerCredit(int id, int deletedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      await db.update(
        'social_credits',
        {
          'statut_remboursement': 'annule',
          'solde_restant': 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _auditService.logAction(
        userId: deletedBy,
        action: 'ANNULER_CREDIT_SOCIAL',
        entityType: 'social_credits',
        entityId: id,
        details: 'Annulation crédit $id',
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation du crédit: $e');
    }
  }

  /// Récupérer un crédit par ID
  Future<CreditSocialModel?> getCreditById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'social_credits',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return CreditSocialModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du crédit: $e');
    }
  }

  /// Récupérer tous les crédits d'un adhérent
  Future<List<CreditSocialModel>> getCreditsByAdherent(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'social_credits',
        where: 'adherent_id = ? AND statut_remboursement != ?',
        whereArgs: [adherentId, 'annule'],
        orderBy: 'date_octroi DESC',
      );

      return result.map((map) => CreditSocialModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des crédits: $e');
    }
  }

  /// Calculer les statistiques des crédits pour un adhérent
  Future<Map<String, dynamic>> getCreditsStats(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as nombre_credits,
          COALESCE(SUM(montant), 0) as montant_total_octroye,
          COALESCE(SUM(solde_restant), 0) as solde_total_restant,
          COALESCE(SUM(montant - solde_restant), 0) as montant_total_rembourse
        FROM social_credits
        WHERE adherent_id = ? AND statut_remboursement != 'annule'
      ''', [adherentId]);

      if (result.isEmpty) {
        return {
          'nombreCredits': 0,
          'montantTotalOctroye': 0.0,
          'soldeTotalRestant': 0.0,
          'montantTotalRembourse': 0.0,
        };
      }

      return {
        'nombreCredits': result.first['nombre_credits'] as int? ?? 0,
        'montantTotalOctroye': (result.first['montant_total_octroye'] as num?)?.toDouble() ?? 0.0,
        'soldeTotalRestant': (result.first['solde_total_restant'] as num?)?.toDouble() ?? 0.0,
        'montantTotalRembourse': (result.first['montant_total_rembourse'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }
}

