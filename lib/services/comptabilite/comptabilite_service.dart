import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../data/models/ecriture_comptable_model.dart';
import '../../services/database/db_initializer.dart';
import '../auth/audit_service.dart';
import 'dart:math';

/// Service pour la comptabilité simplifiée
class ComptabiliteService {
  final AuditService _auditService = AuditService();

  /// Générer un numéro d'écriture unique
  Future<String> generateEcritureNumber() async {
    final db = await DatabaseInitializer.database;
    final year = DateTime.now().year;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ecritures_comptables WHERE date_ecriture LIKE ?',
      ['$year%'],
    );
    final count = result.first['count'] as int;
    return 'ECR-$year-${(count + 1).toString().padLeft(5, '0')}';
  }

  /// Créer une écriture comptable
  Future<EcritureComptableModel> createEcriture({
    required DateTime dateEcriture,
    required String typeOperation,
    int? operationId,
    required String compteDebit,
    required String compteCredit,
    required double montant,
    required String libelle,
    String? reference,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    final numero = await generateEcritureNumber();
    
    final ecriture = EcritureComptableModel(
      numero: numero,
      dateEcriture: dateEcriture,
      typeOperation: typeOperation,
      operationId: operationId,
      compteDebit: compteDebit,
      compteCredit: compteCredit,
      montant: montant,
      libelle: libelle,
      reference: reference,
      isValide: true,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    final id = await db.insert('ecritures_comptables', ecriture.toMap());
    
    // Audit
    await _auditService.logAction(
      userId: createdBy,
      action: 'create_ecriture_comptable',
      entityType: 'ecriture_comptable',
      entityId: id,
      details: 'Création écriture: $libelle - $montant FCFA',
    );

    return ecriture.copyWith(id: id);
  }

  /// Créer une écriture comptable pour une vente
  Future<EcritureComptableModel> createEcritureVente({
    required int venteId,
    required double montant,
    required int clientId,
    required DateTime dateVente,
    required int createdBy,
  }) async {
    return await createEcriture(
      dateEcriture: dateVente,
      typeOperation: 'vente',
      operationId: venteId,
      compteDebit: PlanComptes.compteClients,
      compteCredit: PlanComptes.compteVentes,
      montant: montant,
      libelle: 'Vente de cacao - Client ID: $clientId',
      reference: 'VENTE-$venteId',
      createdBy: createdBy,
    );
  }

  /// Générer une écriture comptable pour une libération de capital
  Future<int> generateEcritureForLiberationCapital({
    required int liberationId,
    required double montant,
    required int createdBy,
  }) async {
    final ecriture = await createEcriture(
      dateEcriture: DateTime.now(),
      typeOperation: 'LIBERATION_CAPITAL',
      operationId: liberationId,
      compteDebit: '512', // Caisse ou Banque
      compteCredit: '101', // Capital social
      montant: montant,
      libelle: 'Libération de capital - Libération #$liberationId',
      reference: 'LIB-CAP-$liberationId',
      createdBy: createdBy,
    );
    return ecriture.id!;
  }

  /// Générer une écriture comptable pour un paiement client
  Future<int> generateEcritureForPaiementClient({
    required int paiementId,
    required double montant,
    required int createdBy,
  }) async {
    final ecriture = await createEcriture(
      dateEcriture: DateTime.now(),
      typeOperation: 'PAIEMENT_CLIENT',
      operationId: paiementId,
      compteDebit: '512', // Caisse ou Banque
      compteCredit: '411', // Clients
      montant: montant,
      libelle: 'Paiement client - Paiement #$paiementId',
      reference: 'PAY-CLI-$paiementId',
      createdBy: createdBy,
    );
    return ecriture.id!;
  }

  /// Générer une écriture comptable pour un paiement
  Future<int> generateEcritureForPaiement({
    required int paiementId,
    required double montant,
    required int createdBy,
  }) async {
    final ecriture = await createEcriture(
      dateEcriture: DateTime.now(),
      typeOperation: 'PAIEMENT',
      operationId: paiementId,
      compteDebit: '512', // Caisse ou Banque
      compteCredit: '411', // Adhérents
      montant: montant,
      libelle: 'Paiement adhérent - Paiement #$paiementId',
      reference: 'PAY-$paiementId',
      createdBy: createdBy,
    );
    return ecriture.id!;
  }

  Future<EcritureComptableModel> generateEcritureForRecette({
    required int recetteId,
    required double montant,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    // Récupérer les informations de la recette
    final recetteResult = await db.query(
      'recettes',
      where: 'id = ?',
      whereArgs: [recetteId],
      limit: 1,
    );
    
    if (recetteResult.isEmpty) {
      throw Exception('Recette non trouvée: $recetteId');
    }
    
    final recette = recetteResult.first;
    final adherentId = recette['adherent_id'] as int;
    final montantNet = (recette['montant_net'] as num).toDouble();
    final commission = (recette['commission_amount'] as num).toDouble();
    final dateRecette = DateTime.parse(recette['date_recette'] as String);
    
    return await createEcritureRecette(
      recetteId: recetteId,
      montantNet: montantNet,
      commission: commission,
      adherentId: adherentId,
      dateRecette: dateRecette,
      createdBy: createdBy,
    );
  }

  /// Créer une écriture comptable pour une recette
  Future<EcritureComptableModel> createEcritureRecette({
    required int recetteId,
    required double montantNet,
    required double commission,
    required int adherentId,
    required DateTime dateRecette,
    required int createdBy,
  }) async {
    // Écriture 1: Caisse -> Adhérents (montant net)
    await createEcriture(
      dateEcriture: dateRecette,
      typeOperation: 'recette',
      operationId: recetteId,
      compteDebit: PlanComptes.compteCaisse,
      compteCredit: PlanComptes.compteAdherents,
      montant: montantNet,
      libelle: 'Paiement recette adhérent ID: $adherentId',
      reference: 'RECETTE-$recetteId',
      createdBy: createdBy,
    );
    
    // Écriture 2: Commission -> Produits
    return await createEcriture(
      dateEcriture: dateRecette,
      typeOperation: 'recette',
      operationId: recetteId,
      compteDebit: PlanComptes.compteAdherents,
      compteCredit: PlanComptes.compteCommissions,
      montant: commission,
      libelle: 'Commission sur recette adhérent ID: $adherentId',
      reference: 'COMMISSION-$recetteId',
      createdBy: createdBy,
    );
  }

  /// Créer une écriture comptable pour une aide sociale
  Future<EcritureComptableModel> createEcritureAideSociale({
    required int aideSocialeId,
    required double montant,
    required int adherentId,
    required DateTime dateAide,
    required int createdBy,
  }) async {
    return await createEcriture(
      dateEcriture: dateAide,
      typeOperation: 'aide_sociale',
      operationId: aideSocialeId,
      compteDebit: PlanComptes.compteAidesSociales,
      compteCredit: PlanComptes.compteCaisse,
      montant: montant,
      libelle: 'Aide sociale adhérent ID: $adherentId',
      reference: 'AIDE-$aideSocialeId',
      createdBy: createdBy,
    );
  }

  /// Créer une écriture comptable pour acquisition de parts
  Future<EcritureComptableModel> createEcritureCapital({
    required int partSocialeId,
    required double montant,
    required int adherentId,
    required DateTime dateAcquisition,
    required int createdBy,
  }) async {
    return await createEcriture(
      dateEcriture: dateAcquisition,
      typeOperation: 'capital',
      operationId: partSocialeId,
      compteDebit: PlanComptes.compteCaisse,
      compteCredit: PlanComptes.compteCapital,
      montant: montant,
      libelle: 'Acquisition parts sociales adhérent ID: $adherentId',
      reference: 'CAPITAL-$partSocialeId',
      createdBy: createdBy,
    );
  }

  /// Créer une écriture comptable pour le fonds social (V2)
  Future<EcritureComptableModel> createEcritureFondsSocial({
    required int fondsSocialId,
    required double montant,
    int? venteId,
    required DateTime dateContribution,
    required int createdBy,
  }) async {
    return await createEcriture(
      dateEcriture: dateContribution,
      typeOperation: 'fonds_social',
      operationId: fondsSocialId,
      compteDebit: PlanComptes.compteCaisse,
      compteCredit: PlanComptes.compteFondsSocial,
      montant: montant,
      libelle: 'Contribution au fonds social${venteId != null ? ' - Vente #$venteId' : ''}',
      reference: 'FONDS-$fondsSocialId',
      createdBy: createdBy,
    );
  }

  /// Récupérer toutes les écritures comptables
  Future<List<EcritureComptableModel>> getAllEcritures({
    DateTime? dateDebut,
    DateTime? dateFin,
    String? typeOperation,
  }) async {
    final db = await DatabaseInitializer.database;
    
    String? where;
    List<Object?>? whereArgs = [];
    
    if (dateDebut != null) {
      where = 'date_ecriture >= ?';
      whereArgs!.add(dateDebut.toIso8601String());
    }
    
    if (dateFin != null) {
      where = where != null 
          ? '$where AND date_ecriture <= ?'
          : 'date_ecriture <= ?';
      whereArgs!.add(dateFin.toIso8601String());
    }
    
    if (typeOperation != null) {
      where = where != null
          ? '$where AND type_operation = ?'
          : 'type_operation = ?';
      whereArgs!.add(typeOperation);
    }
    
    final result = await db.query(
      'ecritures_comptables',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date_ecriture DESC, numero DESC',
    );
    
    return result.map((map) => EcritureComptableModel.fromMap(map)).toList();
  }

  /// Obtenir le solde d'un compte
  Future<double> getSoldeCompte(String compte, {DateTime? dateLimite}) async {
    final db = await DatabaseInitializer.database;
    
    String? where = 'is_valide = 1';
    List<Object?>? whereArgs = [];
    
    if (dateLimite != null) {
      where = '$where AND date_ecriture <= ?';
      whereArgs.add(dateLimite.toIso8601String());
    }
    
    // Débits
    final debitsResult = await db.rawQuery('''
      SELECT COALESCE(SUM(montant), 0) as total
      FROM ecritures_comptables
      WHERE compte_debit = ? AND $where
    ''', [compte, ...whereArgs]);
    
    // Crédits
    final creditsResult = await db.rawQuery('''
      SELECT COALESCE(SUM(montant), 0) as total
      FROM ecritures_comptables
      WHERE compte_credit = ? AND $where
    ''', [compte, ...whereArgs]);
    
    final totalDebits = (debitsResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final totalCredits = (creditsResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // Pour les comptes de classe 1-5 (actif/bilan), solde = débits - crédits
    // Pour les comptes de classe 6-7 (charges/produits), solde = crédits - débits
    if (compte.startsWith('1') || compte.startsWith('2') || 
        compte.startsWith('3') || compte.startsWith('4') || 
        compte.startsWith('5')) {
      return totalDebits - totalCredits;
    } else {
      return totalCredits - totalDebits;
    }
  }

  /// Obtenir le grand livre d'un compte
  Future<List<EcritureComptableModel>> getGrandLivre({
    required String compte,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final db = await DatabaseInitializer.database;
    
    String where = '(compte_debit = ? OR compte_credit = ?) AND is_valide = 1';
    List<Object?> whereArgs = [compte, compte];
    
    if (dateDebut != null) {
      where = '$where AND date_ecriture >= ?';
      whereArgs.add(dateDebut.toIso8601String());
    }
    
    if (dateFin != null) {
      where = '$where AND date_ecriture <= ?';
      whereArgs.add(dateFin.toIso8601String());
    }
    
    final result = await db.query(
      'ecritures_comptables',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date_ecriture ASC, numero ASC',
    );
    
    return result.map((map) => EcritureComptableModel.fromMap(map)).toList();
  }
}

