import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../data/models/journal_comptable_model.dart';
import '../../data/models/compte_comptable_model.dart';
import '../../data/models/ecriture_comptable_model.dart';
import '../database/db_initializer.dart';
import '../auth/audit_service.dart';
import 'dart:math';

/// Service de comptabilité unifié (fusion Capital + Comptabilité)
/// 
/// Gère le journal comptable unifié pour toutes les opérations financières
class AccountingService {
  final AuditService _auditService = AuditService();

  /// Générer un numéro de référence unique pour le journal
  Future<String> generateJournalReference({
    required String typeJournal,
    DateTime? date,
  }) async {
    final db = await DatabaseInitializer.database;
    final refDate = date ?? DateTime.now();
    final year = refDate.year;
    final month = refDate.month.toString().padLeft(2, '0');
    
    final prefix = _getJournalPrefix(typeJournal);
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM journal_comptable WHERE reference LIKE ? AND date_operation LIKE ?',
      ['$prefix-$year-$month-%', '${refDate.year}-${refDate.month.toString().padLeft(2, '0')}%'],
    );
    
    final count = (result.first['count'] as int) + 1;
    return '$prefix-$year-$month-${count.toString().padLeft(4, '0')}';
  }

  String _getJournalPrefix(String typeJournal) {
    switch (typeJournal) {
      case 'Capital':
        return 'CAP';
      case 'Vente':
        return 'VEN';
      case 'Paiement':
        return 'PAY';
      case 'Social':
        return 'SOC';
      case 'Charge':
        return 'CHG';
      default:
        return 'JRN';
    }
  }

  /// Créer une écriture dans le journal comptable unifié
  Future<JournalComptableModel> createJournalEntry({
    required DateTime dateOperation,
    required String typeJournal,
    required String libelle,
    required double debit,
    required double credit,
    required String sourceModule,
    int? sourceId,
    String? reference,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    // Générer la référence si non fournie
    final journalReference = reference ?? await generateJournalReference(
      typeJournal: typeJournal,
      date: dateOperation,
    );
    
    // Calculer le solde après (basé sur le compte de trésorerie si applicable)
    final soldeApres = await _calculateSoldeApres(
      debit: debit,
      credit: credit,
      dateOperation: dateOperation,
    );
    
    final journalEntry = JournalComptableModel(
      dateOperation: dateOperation,
      typeJournal: typeJournal,
      reference: journalReference,
      libelle: libelle,
      debit: debit,
      credit: credit,
      soldeApres: soldeApres,
      sourceModule: sourceModule,
      sourceId: sourceId,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
    
    final id = await db.insert('journal_comptable', journalEntry.toMap());
    
    // Mettre à jour les soldes des comptes
    await _updateCompteSoldes(debit: debit, credit: credit, dateOperation: dateOperation);
    
    // Mettre à jour la trésorerie si nécessaire
    if (sourceModule == 'Paiement' || sourceModule == 'Vente' || sourceModule == 'Capital') {
      await _updateTresorerie(debit: debit, credit: credit, dateOperation: dateOperation);
    }
    
    // Audit
    await _auditService.logAction(
      userId: createdBy,
      action: 'create_journal_entry',
      entityType: 'journal_comptable',
      entityId: id,
      details: 'Création écriture journal: $libelle - Débit: $debit, Crédit: $credit',
    );
    
    return journalEntry.copyWith(id: id);
  }

  /// Calculer le solde après l'opération
  Future<double> _calculateSoldeApres({
    required double debit,
    required double credit,
    required DateTime dateOperation,
  }) async {
    final db = await DatabaseInitializer.database;
    
    // Récupérer le dernier solde de trésorerie
    final tresorerieResult = await db.query(
      'tresorerie',
      orderBy: 'date_reference DESC',
      limit: 1,
    );
    
    if (tresorerieResult.isEmpty) {
      return credit - debit; // Nouvelle trésorerie
    }
    
    final soldeActuel = (tresorerieResult.first['solde_actuel'] as num).toDouble();
    return soldeActuel + (credit - debit);
  }

  /// Mettre à jour les soldes des comptes
  Future<void> _updateCompteSoldes({
    required double debit,
    required double credit,
    required DateTime dateOperation,
  }) async {
    // Cette méthode sera appelée pour mettre à jour les comptes spécifiques
    // selon les règles comptables (débit augmente actif, crédit augmente passif/produit)
  }

  /// Mettre à jour la trésorerie
  Future<void> _updateTresorerie({
    required double debit,
    required double credit,
    required DateTime dateOperation,
  }) async {
    final db = await DatabaseInitializer.database;
    
    // Récupérer la trésorerie actuelle
    final tresorerieResult = await db.query(
      'tresorerie',
      orderBy: 'date_reference DESC',
      limit: 1,
    );
    
    if (tresorerieResult.isEmpty) {
      // Créer une nouvelle entrée de trésorerie
      await db.insert('tresorerie', {
        'solde_initial': 0.0,
        'solde_actuel': credit - debit,
        'date_reference': dateOperation.toIso8601String(),
        'periode': 'Mois',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      final soldeActuel = (tresorerieResult.first['solde_actuel'] as num).toDouble();
      final nouveauSolde = soldeActuel + (credit - debit);
      
      await db.update(
        'tresorerie',
        {
          'solde_actuel': nouveauSolde,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [tresorerieResult.first['id']],
      );
    }
  }

  /// Récupérer toutes les écritures du journal
  Future<List<JournalComptableModel>> getJournalEntries({
    DateTime? dateDebut,
    DateTime? dateFin,
    String? typeJournal,
    String? sourceModule,
  }) async {
    final db = await DatabaseInitializer.database;
    
    String? where;
    List<Object?>? whereArgs = [];
    
    if (dateDebut != null) {
      where = 'date_operation >= ?';
      whereArgs.add(dateDebut.toIso8601String());
    }
    
    if (dateFin != null) {
      where = where != null 
          ? '$where AND date_operation <= ?'
          : 'date_operation <= ?';
      whereArgs.add(dateFin.toIso8601String());
    }
    
    if (typeJournal != null) {
      where = where != null
          ? '$where AND type_journal = ?'
          : 'type_journal = ?';
      whereArgs.add(typeJournal);
    }
    
    if (sourceModule != null) {
      where = where != null
          ? '$where AND source_module = ?'
          : 'source_module = ?';
      whereArgs.add(sourceModule);
    }
    
    final result = await db.query(
      'journal_comptable',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date_operation DESC, reference DESC',
    );
    
    return result.map((map) => JournalComptableModel.fromMap(map)).toList();
  }

  /// Récupérer le solde d'un compte
  Future<double> getCompteSolde(String codeCompte, {DateTime? dateLimite}) async {
    final db = await DatabaseInitializer.database;
    
    // Récupérer le compte
    final compteResult = await db.query(
      'comptes_comptables',
      where: 'code_compte = ?',
      whereArgs: [codeCompte],
      limit: 1,
    );
    
    if (compteResult.isEmpty) {
      return 0.0;
    }
    
    final compte = compteResult.first;
    final type = compte['type'] as String;
    
    // Calculer le solde depuis le journal
    String? where = '(compte_debit = ? OR compte_credit = ?)';
    List<Object?> whereArgs = [codeCompte, codeCompte];
    
    if (dateLimite != null) {
      where = '$where AND date_operation <= ?';
      whereArgs.add(dateLimite.toIso8601String());
    }
    
    // Pour simplifier, on utilise les écritures comptables existantes
    // TODO: Adapter selon la structure réelle
    
    return (compte['solde'] as num?)?.toDouble() ?? 0.0;
  }

  /// Obtenir tous les comptes comptables
  Future<List<CompteComptableModel>> getAllComptes() async {
    final db = await DatabaseInitializer.database;
    
    final result = await db.query(
      'comptes_comptables',
      orderBy: 'code_compte ASC',
    );
    
    return result.map((map) => CompteComptableModel.fromMap(map)).toList();
  }

  /// Créer une écriture comptable depuis une écriture existante (compatibilité)
  Future<JournalComptableModel> createFromEcritureComptable(
    EcritureComptableModel ecriture,
  ) async {
    return await createJournalEntry(
      dateOperation: ecriture.dateEcriture,
      typeJournal: _mapTypeOperationToJournal(ecriture.typeOperation),
      libelle: ecriture.libelle,
      debit: ecriture.montant,
      credit: 0.0,
      sourceModule: ecriture.typeOperation,
      sourceId: ecriture.operationId,
      reference: ecriture.reference,
      createdBy: ecriture.createdBy ?? 0,
    );
  }

  String _mapTypeOperationToJournal(String typeOperation) {
    switch (typeOperation) {
      case 'capital':
        return 'Capital';
      case 'vente':
        return 'Vente';
      case 'paiement':
      case 'PAIEMENT':
        return 'Paiement';
      case 'aide_sociale':
      case 'fonds_social':
        return 'Social';
      default:
        return 'Charge';
    }
  }
}

