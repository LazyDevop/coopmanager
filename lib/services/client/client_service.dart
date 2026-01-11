import '../database/db_initializer.dart';
import '../../data/models/client_model.dart';
import '../auth/audit_service.dart';
import '../notification/notification_service.dart';

/// Service principal pour la gestion des clients (acheteurs)
class ClientService {
  final AuditService _auditService = AuditService();
  final NotificationService _notificationService = NotificationService();

  /// Créer un nouveau client
  Future<ClientModel> createClient({
    required String codeClient,
    required String typeClient,
    required String raisonSociale,
    String? nomResponsable,
    String? telephone,
    String? email,
    String? adresse,
    String? pays,
    String? ville,
    String? nrc,
    String? ifu,
    double? plafondCredit,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      // Vérifier l'unicité du code client
      final existing = await db.query(
        'clients',
        where: 'code_client = ?',
        whereArgs: [codeClient],
        limit: 1,
      );
      
      if (existing.isNotEmpty) {
        throw Exception('Un client avec le code $codeClient existe déjà');
      }
      
      final client = ClientModel(
        codeClient: codeClient,
        typeClient: typeClient,
        raisonSociale: raisonSociale,
        nomResponsable: nomResponsable,
        telephone: telephone,
        email: email,
        adresse: adresse,
        pays: pays,
        ville: ville,
        nrc: nrc,
        ifu: ifu,
        plafondCredit: plafondCredit,
        soldeClient: 0.0,
        statut: ClientModel.statutActif,
        dateCreation: DateTime.now(),
        createdBy: createdBy,
      );
      
      final id = await db.insert('clients', client.toMap());
      
      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_CLIENT',
        entityType: 'clients',
        entityId: id,
        details: 'Client créé: $raisonSociale ($codeClient)',
      );
      
      return client.copyWith(id: id);
    } catch (e) {
      throw Exception('Erreur lors de la création du client: $e');
    }
  }

  /// Mettre à jour un client
  Future<ClientModel> updateClient({
    required int id,
    String? codeClient,
    String? typeClient,
    String? raisonSociale,
    String? nomResponsable,
    String? telephone,
    String? email,
    String? adresse,
    String? pays,
    String? ville,
    String? nrc,
    String? ifu,
    double? plafondCredit,
    required int updatedBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      // Récupérer le client actuel
      final current = await getClientById(id);
      if (current == null) {
        throw Exception('Client non trouvé');
      }
      
      // Vérifier l'unicité du code si modifié
      if (codeClient != null && codeClient != current.codeClient) {
        final existing = await db.query(
          'clients',
          where: 'code_client = ? AND id != ?',
          whereArgs: [codeClient, id],
          limit: 1,
        );
        
        if (existing.isNotEmpty) {
          throw Exception('Un client avec le code $codeClient existe déjà');
        }
      }
      
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': updatedBy,
      };
      
      if (codeClient != null) updates['code_client'] = codeClient;
      if (typeClient != null) updates['type_client'] = typeClient;
      if (raisonSociale != null) updates['raison_sociale'] = raisonSociale;
      if (nomResponsable != null) updates['nom_responsable'] = nomResponsable;
      if (telephone != null) updates['telephone'] = telephone;
      if (email != null) updates['email'] = email;
      if (adresse != null) updates['adresse'] = adresse;
      if (pays != null) updates['pays'] = pays;
      if (ville != null) updates['ville'] = ville;
      if (nrc != null) updates['nrc'] = nrc;
      if (ifu != null) updates['ifu'] = ifu;
      if (plafondCredit != null) updates['plafond_credit'] = plafondCredit;
      
      await db.update('clients', updates, where: 'id = ?', whereArgs: [id]);
      
      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_CLIENT',
        entityType: 'clients',
        entityId: id,
        details: 'Client mis à jour',
      );
      
      return (await getClientById(id))!;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Bloquer un client
  Future<ClientModel> bloquerClient({
    required int id,
    required String raison,
    required int blockedBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      await db.update(
        'clients',
        {
          'statut': ClientModel.statutBloque,
          'date_blocage': DateTime.now().toIso8601String(),
          'raison_blocage': raison,
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': blockedBy,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      await _auditService.logAction(
        userId: blockedBy,
        action: 'BLOCK_CLIENT',
        entityType: 'clients',
        entityId: id,
        details: 'Client bloqué: $raison',
      );
      
      return (await getClientById(id))!;
    } catch (e) {
      throw Exception('Erreur lors du blocage: $e');
    }
  }

  /// Suspendre un client
  Future<ClientModel> suspendreClient({
    required int id,
    required String raison,
    required int suspendedBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      await db.update(
        'clients',
        {
          'statut': ClientModel.statutSuspendu,
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': suspendedBy,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      await _auditService.logAction(
        userId: suspendedBy,
        action: 'SUSPEND_CLIENT',
        entityType: 'clients',
        entityId: id,
        details: 'Client suspendu: $raison',
      );
      
      return (await getClientById(id))!;
    } catch (e) {
      throw Exception('Erreur lors de la suspension: $e');
    }
  }

  /// Réactiver un client
  Future<ClientModel> reactiverClient({
    required int id,
    required int reactivatedBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    try {
      await db.update(
        'clients',
        {
          'statut': ClientModel.statutActif,
          'date_blocage': null,
          'raison_blocage': null,
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': reactivatedBy,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      await _auditService.logAction(
        userId: reactivatedBy,
        action: 'REACTIVATE_CLIENT',
        entityType: 'clients',
        entityId: id,
        details: 'Client réactivé',
      );
      
      return (await getClientById(id))!;
    } catch (e) {
      throw Exception('Erreur lors de la réactivation: $e');
    }
  }

  /// Obtenir un client par ID
  Future<ClientModel?> getClientById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'clients',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      // Calculer les statistiques
      final stats = await _calculateClientStats(id);
      
      return ClientModel.fromMap({
        ...result.first,
        ...stats,
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Obtenir un client par code
  Future<ClientModel?> getClientByCode(String codeClient) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'clients',
        where: 'code_client = ?',
        whereArgs: [codeClient],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      final id = result.first['id'] as int;
      final stats = await _calculateClientStats(id);
      
      return ClientModel.fromMap({
        ...result.first,
        ...stats,
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Obtenir tous les clients avec filtres
  Future<List<ClientModel>> getAllClients({
    String? typeClient,
    String? statut,
    String? searchQuery,
    int limit = 1000,
  }) async {
    return getClients(
      typeClient: typeClient,
      statut: statut,
      searchQuery: searchQuery,
      limit: limit,
    );
  }

  /// Obtenir tous les clients avec filtres
  Future<List<ClientModel>> getClients({
    String? typeClient,
    String? statut,
    String? searchQuery,
    int limit = 1000,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String where = '1=1';
      List<dynamic> whereArgs = [];
      
      if (typeClient != null) {
        where += ' AND type_client = ?';
        whereArgs.add(typeClient);
      }
      
      if (statut != null) {
        where += ' AND statut = ?';
        whereArgs.add(statut);
      }
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Vérifier si les colonnes existent avant de les utiliser dans la recherche
        final columns = await db.rawQuery('PRAGMA table_info(clients)');
        final columnNames = columns.map((c) => c['name'] as String).toList();
        
        final searchConditions = <String>[];
        final query = '%$searchQuery%';
        
        if (columnNames.contains('raison_sociale')) {
          searchConditions.add('raison_sociale LIKE ?');
          whereArgs.add(query);
        }
        if (columnNames.contains('code_client')) {
          searchConditions.add('code_client LIKE ?');
          whereArgs.add(query);
        }
        if (columnNames.contains('nom_responsable')) {
          searchConditions.add('nom_responsable LIKE ?');
          whereArgs.add(query);
        }
        
        if (searchConditions.isNotEmpty) {
          where += ' AND (${searchConditions.join(' OR ')})';
        }
      }
      
      // Déterminer la colonne de tri en fonction de ce qui existe
      String orderBy = 'id ASC'; // Fallback par défaut
      try {
        final columns = await db.rawQuery('PRAGMA table_info(clients)');
        final columnNames = columns.map((c) => c['name'] as String).toList();
        
        if (columnNames.contains('raison_sociale')) {
          orderBy = 'raison_sociale ASC';
        } else if (columnNames.contains('code_client')) {
          orderBy = 'code_client ASC';
        }
      } catch (e) {
        // En cas d'erreur, utiliser l'ordre par défaut
        print('⚠️ Erreur lors de la vérification des colonnes pour ORDER BY: $e');
      }
      
      final result = await db.query(
        'clients',
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      );
      
      // Calculer les statistiques pour chaque client
      final clients = <ClientModel>[];
      for (final row in result) {
        final id = row['id'] as int;
        final stats = await _calculateClientStats(id);
        clients.add(ClientModel.fromMap({
          ...row,
          ...stats,
        }));
      }
      
      return clients;
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Calculer les statistiques d'un client
  Future<Map<String, dynamic>> _calculateClientStats(int clientId) async {
    final db = await DatabaseInitializer.database;
    
    // Nombre de ventes et total
    final ventesResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as nombre_ventes,
        COALESCE(SUM(montant_total), 0) as total_ventes,
        MAX(date_vente) as derniere_vente
      FROM ventes_clients
      WHERE client_id = ?
    ''', [clientId]);
    
    final nombreVentes = ventesResult.first['nombre_ventes'] as int? ?? 0;
    final totalVentes = (ventesResult.first['total_ventes'] as num?)?.toDouble() ?? 0.0;
    final derniereVente = ventesResult.first['derniere_vente'] as String?;
    
    // Total paiements
    final paiementsResult = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(montant), 0) as total_paiements,
        MAX(date_paiement) as dernier_paiement
      FROM paiements_clients
      WHERE client_id = ?
    ''', [clientId]);
    
    final totalPaiements = (paiementsResult.first['total_paiements'] as num?)?.toDouble() ?? 0.0;
    final dernierPaiement = paiementsResult.first['dernier_paiement'] as String?;
    
    // Mettre à jour le solde dans la table clients
    final soldeClient = totalVentes - totalPaiements;
    await db.update(
      'clients',
      {'solde_client': soldeClient},
      where: 'id = ?',
      whereArgs: [clientId],
    );
    
    return {
      'nombre_ventes': nombreVentes,
      'total_ventes': totalVentes,
      'total_paiements': totalPaiements,
      'derniere_vente': derniereVente,
      'dernier_paiement': dernierPaiement,
    };
  }

  /// Vérifier si un client peut effectuer une vente
  Future<bool> peutClientVendre(int clientId, double montantVente) async {
    final client = await getClientById(clientId);
    if (client == null) return false;
    
    // Vérifier le statut
    if (!client.peutVendre) return false;
    
    // Vérifier le plafond de crédit
    if (client.plafondCredit != null) {
      final nouveauSolde = client.soldeClient + montantVente;
      if (nouveauSolde > client.plafondCredit!) {
        return false;
      }
    }
    
    return true;
  }

  /// Obtenir les clients avec solde impayé
  Future<List<ClientModel>> getClientsImpayes({
    double? montantMinimum,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String where = 'solde_client > 0';
      List<dynamic> whereArgs = [];
      
      if (montantMinimum != null) {
        where += ' AND solde_client >= ?';
        whereArgs.add(montantMinimum);
      }
      
      final result = await db.query(
        'clients',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'solde_client DESC',
      );
      
      final clients = <ClientModel>[];
      for (final row in result) {
        final id = row['id'] as int;
        final stats = await _calculateClientStats(id);
        clients.add(ClientModel.fromMap({
          ...row,
          ...stats,
        }));
      }
      
      return clients;
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }
}
