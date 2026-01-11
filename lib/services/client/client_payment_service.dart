import '../database/db_initializer.dart';
import '../../data/models/client_model.dart';
import '../auth/audit_service.dart';
import '../comptabilite/comptabilite_service.dart';
import '../document/document_service.dart';
import '../qrcode/document_security_service.dart';

/// Service pour la gestion des paiements clients
class ClientPaymentService {
  final AuditService _auditService = AuditService();
  final ComptabiliteService _comptabiliteService = ComptabiliteService();
  final DocumentService _documentService = DocumentService();

  /// Enregistrer un paiement client
  /// 
  /// Met à jour automatiquement :
  /// - Le solde du client
  /// - Le statut de paiement de la vente
  /// - Génère un reçu PDF avec QR Code
  /// - Crée une écriture comptable
  Future<PaiementClientModel> enregistrerPaiement({
    required int clientId,
    required double montant,
    int? venteId, // null si paiement global
    required String modePaiement,
    String? reference,
    String? notes,
    required int createdBy,
    bool generateRecu = true,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      await db.execute('BEGIN TRANSACTION');
      
      try {
        // 1. Vérifier le client
        final clientResult = await db.query(
          'clients',
          where: 'id = ?',
          whereArgs: [clientId],
          limit: 1,
        );
        
        if (clientResult.isEmpty) {
          throw Exception('Client non trouvé');
        }
        
        // 2. Créer le paiement
        final paiement = PaiementClientModel(
          clientId: clientId,
          venteId: venteId,
          montant: montant,
          modePaiement: modePaiement,
          reference: reference,
          datePaiement: DateTime.now(),
          notes: notes,
          createdBy: createdBy,
          createdAt: DateTime.now(),
        );
        
        final paiementId = await db.insert('paiements_clients', paiement.toMap());
        
        // 3. Générer QR Code hash
        final qrCodeHash = await DocumentSecurityService.generateQRCodeHash(
          type: 'paiement_client',
          id: paiementId,
          adherentId: 0, // Pas d'adhérent pour paiement client
          montant: montant,
        );
        
        await db.update(
          'paiements_clients',
          {'qr_code_hash': qrCodeHash},
          where: 'id = ?',
          whereArgs: [paiementId],
        );
        
        // 4. Mettre à jour le solde du client
        await db.rawUpdate('''
          UPDATE clients
          SET solde_client = solde_client - ?,
              updated_at = ?
          WHERE id = ?
        ''', [montant, DateTime.now().toIso8601String(), clientId]);
        
        // 5. Si paiement lié à une vente, mettre à jour ventes_clients
        if (venteId != null) {
          await _updateVenteClientPaiement(venteId, montant);
        }
        
        // 6. Générer écriture comptable
        try {
          final ecritureId = await _comptabiliteService.generateEcritureForPaiementClient(
            paiementId: paiementId,
            montant: montant,
            createdBy: createdBy,
          );
          
          await db.update(
            'paiements_clients',
            {'ecriture_comptable_id': ecritureId},
            where: 'id = ?',
            whereArgs: [paiementId],
          );
        } catch (e) {
          print('Erreur lors de la génération de l\'écriture comptable: $e');
        }
        
        // 7. Générer reçu PDF si demandé
        if (generateRecu) {
          try {
            final recuPath = await _genererRecuPDF(paiementId, clientId, montant, qrCodeHash);
            await db.update(
              'paiements_clients',
              {'recu_pdf_path': recuPath},
              where: 'id = ?',
              whereArgs: [paiementId],
            );
          } catch (e) {
            print('Erreur lors de la génération du reçu PDF: $e');
          }
        }
        
        // 8. Journaliser
        await _auditService.logAction(
          userId: createdBy,
          action: 'CREATE_PAIEMENT_CLIENT',
          entityType: 'paiements_clients',
          entityId: paiementId,
          details: 'Paiement de $montant FCFA pour client $clientId',
        );
        
        await db.execute('COMMIT');
        
        return paiement.copyWith(id: paiementId, qrCodeHash: qrCodeHash);
      } catch (e) {
        await db.execute('ROLLBACK');
        rethrow;
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement du paiement: $e');
    }
  }

  /// Mettre à jour le statut de paiement d'une vente client
  Future<void> _updateVenteClientPaiement(int venteId, double montantPaiement) async {
    final db = await DatabaseInitializer.database;
    
    // Récupérer la vente client
    final venteClientResult = await db.query(
      'ventes_clients',
      where: 'vente_id = ?',
      whereArgs: [venteId],
      limit: 1,
    );
    
    if (venteClientResult.isEmpty) return;
    
    final venteClient = VenteClientModel.fromMap(venteClientResult.first);
    final nouveauMontantPaye = venteClient.montantPaye + montantPaiement;
    final nouveauSoldeRestant = venteClient.montantTotal - nouveauMontantPaye;
    
    String nouveauStatut;
    if (nouveauSoldeRestant <= 0) {
      nouveauStatut = 'paye';
    } else if (nouveauMontantPaye > 0) {
      nouveauStatut = 'partiel';
    } else {
      nouveauStatut = 'impaye';
    }
    
    await db.update(
      'ventes_clients',
      {
        'montant_paye': nouveauMontantPaye,
        'solde_restant': nouveauSoldeRestant,
        'statut_paiement': nouveauStatut,
      },
      where: 'vente_id = ?',
      whereArgs: [venteId],
    );
  }

  /// Obtenir tous les paiements d'un client
  Future<List<PaiementClientModel>> getPaiementsByClient(int clientId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'paiements_clients',
        where: 'client_id = ?',
        whereArgs: [clientId],
        orderBy: 'date_paiement DESC',
      );
      
      return result.map((map) => PaiementClientModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Obtenir les ventes d'un client
  Future<List<VenteClientModel>> getVentesByClient(int clientId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'ventes_clients',
        where: 'client_id = ?',
        whereArgs: [clientId],
        orderBy: 'date_vente DESC',
      );
      
      return result.map((map) => VenteClientModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Générer le reçu PDF (placeholder)
  Future<String> _genererRecuPDF(int paiementId, int clientId, double montant, String qrCodeHash) async {
    // TODO: Implémenter avec PdfGeneratorService
    return 'recus/paiement_client_$paiementId.pdf';
  }
}
