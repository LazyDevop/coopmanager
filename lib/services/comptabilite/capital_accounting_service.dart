import '../../data/models/ecriture_capital_model.dart';
import '../../data/models/compte_comptable_model.dart' show PlanComptesFusionne;
import '../database/db_initializer.dart';
import '../auth/audit_service.dart';
import 'accounting_service.dart';

/// Service d'intégration Capital Social + Comptabilité
/// 
/// Gère automatiquement les écritures comptables pour les opérations de capital
class CapitalAccountingService {
  final AccountingService _accountingService = AccountingService();
  final AuditService _auditService = AuditService();

  /// Souscription de parts sociales (avec écriture comptable automatique)
  /// 
  /// Règle métier :
  /// - Débit : Compte Actionnaire (413)
  /// - Crédit : Capital souscrit (1011)
  /// - Pas d'impact trésorerie
  Future<EcritureCapitalModel> souscrireCapital({
    required int actionnaireId,
    required double montant,
    required DateTime dateSouscription,
    String? reference,
    String? notes,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      await db.execute('BEGIN TRANSACTION');
      
      // 1. Créer l'écriture dans le journal comptable
      final journalEntry = await _accountingService.createJournalEntry(
        dateOperation: dateSouscription,
        typeJournal: 'Capital',
        libelle: 'Souscription de capital - Actionnaire ID: $actionnaireId',
        debit: montant,
        credit: montant, // Débit actionnaire = Crédit capital souscrit
        sourceModule: 'Capital',
        sourceId: actionnaireId,
        reference: reference,
        createdBy: createdBy,
      );
      
      // 2. Créer l'écriture capital (liaison)
      final ecritureCapital = EcritureCapitalModel(
        actionnaireId: actionnaireId,
        typeOperation: 'Souscription',
        montant: montant,
        compteDebit: PlanComptesFusionne.compteActionnaires,
        compteCredit: PlanComptesFusionne.compteCapitalSouscrit,
        journalId: journalEntry.id!,
        date: dateSouscription,
        reference: reference,
        notes: notes,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );
      
      final ecritureId = await db.insert('ecritures_capital', ecritureCapital.toMap());
      
      // 3. Mettre à jour les soldes des comptes
      await _updateCompteSolde(
        codeCompte: PlanComptesFusionne.compteActionnaires,
        montant: montant,
        isDebit: true,
      );
      
      await _updateCompteSolde(
        codeCompte: PlanComptesFusionne.compteCapitalSouscrit,
        montant: montant,
        isDebit: false,
      );
      
      await db.execute('COMMIT');
      
      // Audit
      await _auditService.logAction(
        userId: createdBy,
        action: 'souscrire_capital',
        entityType: 'ecriture_capital',
        entityId: ecritureId,
        details: 'Souscription capital: $montant FCFA pour actionnaire $actionnaireId',
      );
      
      return ecritureCapital.copyWith(id: ecritureId);
    } catch (e) {
      await db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Libération de capital (avec écriture comptable automatique)
  /// 
  /// Règle métier :
  /// - Débit : Caisse (530) ou Banque (512)
  /// - Crédit : Capital libéré (1012)
  /// - Impact trésorerie : OUI
  Future<EcritureCapitalModel> libererCapital({
    required int actionnaireId,
    required double montant,
    required DateTime dateLiberation,
    String modePaiement = 'caisse', // 'caisse' ou 'banque'
    String? reference,
    String? notes,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      await db.execute('BEGIN TRANSACTION');
      
      // Vérifier que le capital souscrit existe et est suffisant
      final soldeSouscrit = await _getSoldeCompteActionnaire(actionnaireId);
      if (montant > soldeSouscrit) {
        throw Exception('Montant de libération ($montant) supérieur au capital souscrit ($soldeSouscrit)');
      }
      
      // Déterminer le compte de trésorerie
      final compteTresorerie = modePaiement == 'banque' 
          ? PlanComptesFusionne.compteBanque 
          : PlanComptesFusionne.compteCaisse;
      
      // 1. Créer l'écriture dans le journal comptable
      final journalEntry = await _accountingService.createJournalEntry(
        dateOperation: dateLiberation,
        typeJournal: 'Capital',
        libelle: 'Libération de capital - Actionnaire ID: $actionnaireId',
        debit: montant,
        credit: montant, // Débit trésorerie = Crédit capital libéré
        sourceModule: 'Capital',
        sourceId: actionnaireId,
        reference: reference,
        createdBy: createdBy,
      );
      
      // 2. Créer l'écriture capital (liaison)
      final ecritureCapital = EcritureCapitalModel(
        actionnaireId: actionnaireId,
        typeOperation: 'Liberation',
        montant: montant,
        compteDebit: compteTresorerie,
        compteCredit: PlanComptesFusionne.compteCapitalLibere,
        journalId: journalEntry.id!,
        date: dateLiberation,
        reference: reference,
        notes: notes,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );
      
      final ecritureId = await db.insert('ecritures_capital', ecritureCapital.toMap());
      
      // 3. Mettre à jour les soldes des comptes
      await _updateCompteSolde(
        codeCompte: compteTresorerie,
        montant: montant,
        isDebit: true,
      );
      
      await _updateCompteSolde(
        codeCompte: PlanComptesFusionne.compteCapitalLibere,
        montant: montant,
        isDebit: false,
      );
      
      // 4. Réduire le compte actionnaire (capital souscrit devient libéré)
      await _updateCompteSolde(
        codeCompte: PlanComptesFusionne.compteActionnaires,
        montant: montant,
        isDebit: false, // Réduction du compte actionnaire
      );
      
      await db.execute('COMMIT');
      
      // Audit
      await _auditService.logAction(
        userId: createdBy,
        action: 'liberer_capital',
        entityType: 'ecriture_capital',
        entityId: ecritureId,
        details: 'Libération capital: $montant FCFA pour actionnaire $actionnaireId',
      );
      
      return ecritureCapital.copyWith(id: ecritureId);
    } catch (e) {
      await db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Récupérer toutes les écritures capital d'un actionnaire
  Future<List<EcritureCapitalModel>> getEcrituresCapitalByActionnaire(int actionnaireId) async {
    final db = await DatabaseInitializer.database;
    
    final result = await db.query(
      'ecritures_capital',
      where: 'actionnaire_id = ?',
      whereArgs: [actionnaireId],
      orderBy: 'date DESC',
    );
    
    return result.map((map) => EcritureCapitalModel.fromMap(map)).toList();
  }

  /// Récupérer le solde du compte actionnaire
  Future<double> _getSoldeCompteActionnaire(int actionnaireId) async {
    final db = await DatabaseInitializer.database;
    
    // Calculer le solde depuis les écritures capital
    final souscriptionsResult = await db.rawQuery('''
      SELECT COALESCE(SUM(montant), 0) as total
      FROM ecritures_capital
      WHERE actionnaire_id = ? AND type_operation = 'Souscription'
    ''', [actionnaireId]);
    
    final liberationsResult = await db.rawQuery('''
      SELECT COALESCE(SUM(montant), 0) as total
      FROM ecritures_capital
      WHERE actionnaire_id = ? AND type_operation = 'Liberation'
    ''', [actionnaireId]);
    
    final totalSouscrit = (souscriptionsResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final totalLibere = (liberationsResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    return totalSouscrit - totalLibere;
  }

  /// Mettre à jour le solde d'un compte
  Future<void> _updateCompteSolde({
    required String codeCompte,
    required double montant,
    required bool isDebit,
  }) async {
    final db = await DatabaseInitializer.database;
    
    // Récupérer le compte
    final compteResult = await db.query(
      'comptes_comptables',
      where: 'code_compte = ?',
      whereArgs: [codeCompte],
      limit: 1,
    );
    
    if (compteResult.isEmpty) {
      throw Exception('Compte comptable non trouvé: $codeCompte');
    }
    
    final compte = compteResult.first;
    final soldeActuel = (compte['solde'] as num).toDouble();
    final type = compte['type'] as String;
    
    // Calculer le nouveau solde selon les règles comptables
    double nouveauSolde;
    if (type == 'Actif' || type == 'Charge') {
      // Débit augmente, crédit diminue
      nouveauSolde = isDebit ? soldeActuel + montant : soldeActuel - montant;
    } else {
      // Crédit augmente, débit diminue
      nouveauSolde = isDebit ? soldeActuel - montant : soldeActuel + montant;
    }
    
    await db.update(
      'comptes_comptables',
      {'solde': nouveauSolde},
      where: 'code_compte = ?',
      whereArgs: [codeCompte],
    );
  }

  /// Obtenir le résumé financier du capital
  Future<CapitalFinancialSummary> getCapitalFinancialSummary() async {
    final db = await DatabaseInitializer.database;
    
    // Capital souscrit
    final souscritResult = await db.rawQuery('''
      SELECT COALESCE(SUM(montant), 0) as total
      FROM ecritures_capital
      WHERE type_operation = 'Souscription'
    ''');
    
    // Capital libéré
    final libereResult = await db.rawQuery('''
      SELECT COALESCE(SUM(montant), 0) as total
      FROM ecritures_capital
      WHERE type_operation = 'Liberation'
    ''');
    
    // Nombre d'actionnaires
    final actionnairesResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT actionnaire_id) as count
      FROM ecritures_capital
      WHERE type_operation = 'Souscription'
    ''');
    
    final capitalSouscrit = (souscritResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final capitalLibere = (libereResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final nombreActionnaires = actionnairesResult.first['count'] as int? ?? 0;
    
    return CapitalFinancialSummary(
      capitalSouscrit: capitalSouscrit,
      capitalLibere: capitalLibere,
      capitalRestant: capitalSouscrit - capitalLibere,
      nombreActionnaires: nombreActionnaires,
    );
  }
}

/// Résumé financier du capital
class CapitalFinancialSummary {
  final double capitalSouscrit;
  final double capitalLibere;
  final double capitalRestant;
  final int nombreActionnaires;

  CapitalFinancialSummary({
    required this.capitalSouscrit,
    required this.capitalLibere,
    required this.capitalRestant,
    required this.nombreActionnaires,
  });
}

