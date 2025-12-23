import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../data/models/client_model.dart';
import '../../services/database/db_initializer.dart';
import '../../config/app_config.dart';
import '../auth/audit_service.dart';

/// Service pour la gestion des clients (acheteurs)
class ClientService {
  final AuditService _auditService = AuditService();

  /// Générer un code client unique
  Future<String> generateClientCode() async {
    final db = await DatabaseInitializer.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clients',
    );
    final count = result.first['count'] as int;
    return 'CLI-${DateTime.now().year}-${(count + 1).toString().padLeft(4, '0')}';
  }

  /// Créer un nouveau client
  Future<ClientModel> createClient({
    required String nom,
    required String type,
    String? telephone,
    String? email,
    String? adresse,
    String? ville,
    String? pays,
    String? siret,
    required int createdBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    // Générer le code
    final code = await generateClientCode();
    
    final client = ClientModel(
      code: code,
      nom: nom,
      type: type,
      telephone: telephone,
      email: email,
      adresse: adresse,
      ville: ville,
      pays: pays ?? 'Cameroun',
      siret: siret,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final id = await db.insert('clients', client.toMap());
    
    // Audit
    await _auditService.logAction(
      userId: createdBy,
      action: 'create_client',
      entityType: 'client',
      entityId: id,
      details: 'Création du client: $nom',
    );

    return client.copyWith(id: id);
  }

  /// Récupérer tous les clients
  Future<List<ClientModel>> getAllClients({bool? activeOnly}) async {
    final db = await DatabaseInitializer.database;
    
    String? where;
    List<Object?>? whereArgs;
    
    if (activeOnly == true) {
      where = 'is_active = ?';
      whereArgs = [1];
    }
    
    final result = await db.query(
      'clients',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'nom ASC',
    );
    
    return result.map((map) => ClientModel.fromMap(map)).toList();
  }

  /// Récupérer un client par ID
  Future<ClientModel?> getClientById(int id) async {
    final db = await DatabaseInitializer.database;
    final result = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return ClientModel.fromMap(result.first);
  }

  /// Récupérer un client par code
  Future<ClientModel?> getClientByCode(String code) async {
    final db = await DatabaseInitializer.database;
    final result = await db.query(
      'clients',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return ClientModel.fromMap(result.first);
  }

  /// Mettre à jour un client
  Future<ClientModel> updateClient({
    required int id,
    String? nom,
    String? type,
    String? telephone,
    String? email,
    String? adresse,
    String? ville,
    String? pays,
    String? siret,
    bool? isActive,
    required int updatedBy,
  }) async {
    final db = await DatabaseInitializer.database;
    
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (nom != null) updates['nom'] = nom;
    if (type != null) updates['type'] = type;
    if (telephone != null) updates['telephone'] = telephone;
    if (email != null) updates['email'] = email;
    if (adresse != null) updates['adresse'] = adresse;
    if (ville != null) updates['ville'] = ville;
    if (pays != null) updates['pays'] = pays;
    if (siret != null) updates['siret'] = siret;
    if (isActive != null) updates['is_active'] = isActive ? 1 : 0;
    
    await db.update(
      'clients',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Audit
    await _auditService.logAction(
      userId: updatedBy,
      action: 'update_client',
      entityType: 'client',
      entityId: id,
      details: 'Mise à jour du client ID: $id',
    );
    
    return (await getClientById(id))!;
  }

  /// Supprimer (désactiver) un client
  Future<void> deleteClient(int id, int deletedBy) async {
    await updateClient(
      id: id,
      isActive: false,
      updatedBy: deletedBy,
    );
  }

  /// Rechercher des clients
  Future<List<ClientModel>> searchClients(String query) async {
    final db = await DatabaseInitializer.database;
    final result = await db.query(
      'clients',
      where: 'nom LIKE ? OR code LIKE ? OR telephone LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'nom ASC',
    );
    
    return result.map((map) => ClientModel.fromMap(map)).toList();
  }

  /// Obtenir les statistiques des clients
  Future<ClientStatistics> getStatistics() async {
    final db = await DatabaseInitializer.database;
    
    final total = await db.rawQuery('SELECT COUNT(*) as count FROM clients');
    final actifs = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clients WHERE is_active = 1',
    );
    final entreprises = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clients WHERE type = ?',
      [AppConfig.clientTypeEntreprise],
    );
    final particuliers = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clients WHERE type = ?',
      [AppConfig.clientTypeParticulier],
    );
    
    return ClientStatistics(
      total: total.first['count'] as int,
      actifs: actifs.first['count'] as int,
      entreprises: entreprises.first['count'] as int,
      particuliers: particuliers.first['count'] as int,
    );
  }
}

/// Statistiques des clients
class ClientStatistics {
  final int total;
  final int actifs;
  final int entreprises;
  final int particuliers;

  ClientStatistics({
    required this.total,
    required this.actifs,
    required this.entreprises,
    required this.particuliers,
  });
}

