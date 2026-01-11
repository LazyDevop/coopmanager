import '../database/db_initializer.dart';
import '../../data/models/adherent_model.dart';
import '../../data/models/adherent_historique_model.dart';
import '../auth/audit_service.dart';
import '../../config/app_config.dart';
import 'capital_social_service.dart';
import 'adherent_code_generator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AdherentService {
  final AuditService _auditService = AuditService();
  final AdherentCodeGenerator _codeGenerator = AdherentCodeGenerator();

  /// Créer un nouvel adhérent
  Future<AdherentModel> createAdherent({
    String? code,
    required String nom,
    required String prenom,
    String? telephone,
    String? email,
    String? village,
    String? adresse,
    String? cnib,
    DateTime? dateNaissance,
    required DateTime dateAdhesion,
    required int createdBy,
    // Nouveaux champs - Identification
    String? categorie,
    String? statut,
    String? siteCooperative,
    String? section,
    // Nouveaux champs - Identité personnelle
    String? sexe,
    String? lieuNaissance,
    String? nationalite,
    String? typePiece,
    String? numeroPiece,
    // Nouveaux champs - Situation familiale
    String? nomPere,
    String? nomMere,
    String? conjoint,
    int? nombreEnfants,
    // Nouveaux champs - Indicateurs agricoles
    double? superficieTotaleCultivee,
    int? nombreChamps,
    double? rendementMoyenHa,
    double? tonnageTotalProduit,
    double? tonnageTotalVendu,
    // Photo de profil
    String? photoPath,
  }) async {
    try {
      // Générer automatiquement le code selon la nouvelle nomenclature s'il n'est pas fourni
      String finalCode;
      
      if (code != null) {
        // Valider le format du code fourni
        final normalizedCode = AdherentCodeGenerator.validateAndNormalize(code);
        if (normalizedCode == null) {
          throw Exception('Format de code invalide. Le code doit respecter le format: [2 lettres][2 chiffres][4 alphanumériques] (ex: CE25A9F2)');
        }
        finalCode = normalizedCode;
        
        // Vérifier si le code existe déjà
        if (await codeExists(finalCode)) {
          throw Exception('Ce code adhérent existe déjà');
        }
      } else {
        // Générer un nouveau code selon la nomenclature ERP
        finalCode = await _codeGenerator.generateUniqueCode(
          dateAdhesion: dateAdhesion,
          siteCooperative: siteCooperative,
        );
      }

      final db = await DatabaseInitializer.database;
      
      // S'assurer que la colonne photo_path existe avant l'insertion
      await _ensurePhotoPathColumn(db);
      
      final adherent = AdherentModel(
        code: finalCode,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email,
        village: village,
        adresse: adresse,
        cnib: cnib,
        dateNaissance: dateNaissance,
        dateAdhesion: dateAdhesion,
        isActive: true,
        createdAt: DateTime.now(),
        // V2: Catégorisation
        categorie: categorie ?? AppConfig.categorieProducteur,
        statut: statut ?? 'actif',
        dateStatut: DateTime.now(),
        // Nouveaux champs - Identification
        siteCooperative: siteCooperative,
        section: section,
        // Nouveaux champs - Identité personnelle
        sexe: sexe,
        lieuNaissance: lieuNaissance,
        nationalite: nationalite,
        typePiece: typePiece,
        numeroPiece: numeroPiece,
        // Nouveaux champs - Situation familiale
        nomPere: nomPere,
        nomMere: nomMere,
        conjoint: conjoint,
        nombreEnfants: nombreEnfants,
        // Nouveaux champs - Indicateurs agricoles
        superficieTotaleCultivee: superficieTotaleCultivee,
        nombreChamps: nombreChamps,
        rendementMoyenHa: rendementMoyenHa,
        tonnageTotalProduit: tonnageTotalProduit,
        tonnageTotalVendu: tonnageTotalVendu,
        // Photo de profil
        photoPath: photoPath,
      );

      final dataToInsert = adherent.toMap();
      
      // Retirer les valeurs null pour éviter les erreurs SQLite
      dataToInsert.removeWhere((key, value) => value == null);

      final id = await db.insert('adherents', dataToInsert);

      // Enregistrer dans l'historique
      await _addHistorique(
        adherentId: id,
        typeOperation: 'creation',
        description: 'Création de l\'adhérent',
        createdBy: createdBy,
      );

      await _auditService.logAction(
        userId: createdBy,
        action: 'CREATE_ADHERENT',
        entityType: 'adherents',
        entityId: id,
        details: 'Création de l\'adhérent: $finalCode - $nom $prenom',
      );

      return adherent.copyWith(id: id);
    } catch (e) {
      print('Erreur détaillée lors de la création de l\'adhérent: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Erreur lors de la création de l\'adhérent: $e');
    }
  }

  /// Mettre à jour un adhérent
  Future<AdherentModel> updateAdherent({
    required int id,
    String? code,
    String? nom,
    String? prenom,
    String? telephone,
    String? email,
    String? village,
    String? adresse,
    String? cnib,
    DateTime? dateNaissance,
    DateTime? dateAdhesion,
    required int updatedBy,
    // Nouveaux champs - Identification
    String? categorie,
    String? statut,
    String? siteCooperative,
    String? section,
    // Nouveaux champs - Identité personnelle
    String? sexe,
    String? lieuNaissance,
    String? nationalite,
    String? typePiece,
    String? numeroPiece,
    // Nouveaux champs - Situation familiale
    String? nomPere,
    String? nomMere,
    String? conjoint,
    int? nombreEnfants,
    // Nouveaux champs - Indicateurs agricoles
    double? superficieTotaleCultivee,
    int? nombreChamps,
    double? rendementMoyenHa,
    double? tonnageTotalProduit,
    double? tonnageTotalVendu,
    // Photo de profil
    String? photoPath,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer l'adhérent actuel
      final currentResult = await db.query(
        'adherents',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (currentResult.isEmpty) {
        throw Exception('Adhérent non trouvé');
      }

      final currentAdherent = AdherentModel.fromMap(currentResult.first);
      
      // Le code ne peut pas être modifié après création
      if (code != null && code != currentAdherent.code) {
        throw Exception('Le code adhérent ne peut pas être modifié après création');
      }
      
      // Valider le format du code existant si nécessaire
      if (code != null) {
        final normalizedCode = AdherentCodeGenerator.validateAndNormalize(code);
        if (normalizedCode == null) {
          throw Exception('Format de code invalide. Le code doit respecter le format: [2 lettres][2 chiffres][4 alphanumériques] (ex: CE25A9F2)');
        }
      }

      // Préparer les données à mettre à jour
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (code != null) updateData['code'] = code;
      if (nom != null) updateData['nom'] = nom;
      if (prenom != null) updateData['prenom'] = prenom;
      if (telephone != null) updateData['telephone'] = telephone;
      if (email != null) updateData['email'] = email;
      if (village != null) updateData['village'] = village;
      if (adresse != null) updateData['adresse'] = adresse;
      if (cnib != null) updateData['cnib'] = cnib;
      if (dateNaissance != null) updateData['date_naissance'] = dateNaissance.toIso8601String();
      if (dateAdhesion != null) updateData['date_adhesion'] = dateAdhesion.toIso8601String();
      // Nouveaux champs - Identification
      if (categorie != null) updateData['categorie'] = categorie;
      if (statut != null) updateData['statut'] = statut;
      if (siteCooperative != null) updateData['site_cooperative'] = siteCooperative;
      if (section != null) updateData['section'] = section;
      // Nouveaux champs - Identité personnelle
      if (sexe != null) updateData['sexe'] = sexe;
      if (lieuNaissance != null) updateData['lieu_naissance'] = lieuNaissance;
      if (nationalite != null) updateData['nationalite'] = nationalite;
      if (typePiece != null) updateData['type_piece'] = typePiece;
      if (numeroPiece != null) updateData['numero_piece'] = numeroPiece;
      // Nouveaux champs - Situation familiale
      if (nomPere != null) updateData['nom_pere'] = nomPere;
      if (nomMere != null) updateData['nom_mere'] = nomMere;
      if (conjoint != null) updateData['conjoint'] = conjoint;
      if (nombreEnfants != null) updateData['nombre_enfants'] = nombreEnfants;
      // Nouveaux champs - Indicateurs agricoles
      if (superficieTotaleCultivee != null) updateData['superficie_totale_cultivee'] = superficieTotaleCultivee;
      if (nombreChamps != null) updateData['nombre_champs'] = nombreChamps;
      if (rendementMoyenHa != null) updateData['rendement_moyen_ha'] = rendementMoyenHa;
      if (tonnageTotalProduit != null) updateData['tonnage_total_produit'] = tonnageTotalProduit;
      if (tonnageTotalVendu != null) updateData['tonnage_total_vendu'] = tonnageTotalVendu;
      // Photo de profil
      if (photoPath != null) updateData['photo_path'] = photoPath;

      await db.update(
        'adherents',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );

      // Enregistrer dans l'historique
      await _addHistorique(
        adherentId: id,
        typeOperation: 'modification',
        description: 'Modification des informations de l\'adhérent',
        createdBy: updatedBy,
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: 'UPDATE_ADHERENT',
        entityType: 'adherents',
        entityId: id,
        details: 'Mise à jour de l\'adhérent: ${currentAdherent.code}',
      );

      // Récupérer l'adhérent mis à jour
      final updatedResult = await db.query(
        'adherents',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return AdherentModel.fromMap(updatedResult.first);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Activer/Désactiver un adhérent
  Future<bool> toggleAdherentStatus(int id, bool isActive, int updatedBy) async {
    try {
      final db = await DatabaseInitializer.database;
      
      await db.update(
        'adherents',
        {
          'is_active': isActive ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // Enregistrer dans l'historique
      await _addHistorique(
        adherentId: id,
        typeOperation: isActive ? 'reactivation' : 'desactivation',
        description: isActive ? 'Réactivation de l\'adhérent' : 'Désactivation de l\'adhérent',
        createdBy: updatedBy,
      );

      await _auditService.logAction(
        userId: updatedBy,
        action: isActive ? 'ACTIVATE_ADHERENT' : 'DEACTIVATE_ADHERENT',
        entityType: 'adherents',
        entityId: id,
        details: isActive ? 'Réactivation de l\'adhérent' : 'Désactivation de l\'adhérent',
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors du changement de statut: $e');
    }
  }

  /// Récupérer tous les adhérents
  Future<List<AdherentModel>> getAllAdherents({
    bool? isActive,
    String? village,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (isActive != null) {
        where += ' AND is_active = ?';
        whereArgs.add(isActive ? 1 : 0);
      }

      if (village != null && village.isNotEmpty) {
        where += ' AND village = ?';
        whereArgs.add(village);
      }

      final result = await db.query(
        'adherents',
        where: where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'nom, prenom',
      );

      return result.map((map) => AdherentModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des adhérents: $e');
    }
  }

  /// Récupérer un adhérent par ID
  Future<AdherentModel?> getAdherentById(int id) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'adherents',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return AdherentModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'adhérent: $e');
    }
  }

  /// Récupérer un adhérent par code
  Future<AdherentModel?> getAdherentByCode(String code) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'adherents',
        where: 'code = ?',
        whereArgs: [code],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return AdherentModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'adhérent: $e');
    }
  }

  /// Rechercher des adhérents
  Future<List<AdherentModel>> searchAdherents(String query) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'adherents',
        where: '''
          (code LIKE ? OR nom LIKE ? OR prenom LIKE ? OR telephone LIKE ? OR email LIKE ?)
        ''',
        whereArgs: [
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
        ],
        orderBy: 'nom, prenom',
      );

      return result.map((map) => AdherentModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Vérifier si un code existe déjà
  Future<bool> codeExists(String code, {int? excludeId}) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String where = 'code = ?';
      List<dynamic> whereArgs = [code];
      
      if (excludeId != null) {
        where += ' AND id != ?';
        whereArgs.add(excludeId);
      }

      final result = await db.query(
        'adherents',
        where: where,
        whereArgs: whereArgs,
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification du code: $e');
    }
  }

  /// Générer automatiquement le prochain code adhérent disponible
  /// 
  /// ⚠️ DÉPRÉCIÉ : Utilisez AdherentCodeGenerator.generateUniqueCode() à la place
  /// Cette méthode est conservée pour compatibilité avec l'ancien format
  /// 
  /// Format ancien: ADH001, ADH002, ADH003, etc.
  /// Format nouveau: CE25A9F2, CO24B103, ES26Z7Q8 (via AdherentCodeGenerator)
  @Deprecated('Utilisez AdherentCodeGenerator.generateUniqueCode() pour la nouvelle nomenclature ERP')
  Future<String> generateNextCode() async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer tous les codes existants qui commencent par "ADH"
      final result = await db.rawQuery(
        "SELECT code FROM adherents WHERE code LIKE 'ADH%' ORDER BY code DESC LIMIT 1",
      );

      if (result.isEmpty) {
        // Aucun code existant, commencer à ADH001
        return 'ADH001';
      }

      final lastCode = result.first['code'] as String;
      
      // Extraire le numéro du dernier code (ex: "ADH001" -> 1)
      final match = RegExp(r'ADH(\d+)').firstMatch(lastCode);
      if (match != null) {
        final lastNumber = int.parse(match.group(1)!);
        final nextNumber = lastNumber + 1;
        // Formater avec 3 chiffres minimum (ADH001, ADH002, etc.)
        return 'ADH${nextNumber.toString().padLeft(3, '0')}';
      }

      // Si le format n'est pas reconnu, commencer à ADH001
      return 'ADH001';
    } catch (e) {
      throw Exception('Erreur lors de la génération du code: $e');
    }
  }

  /// Obtenir tous les villages distincts
  Future<List<String>> getAllVillages() async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.rawQuery(
        'SELECT DISTINCT village FROM adherents WHERE village IS NOT NULL AND village != "" ORDER BY village',
      );

      return result.map((map) => map['village'] as String).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des villages: $e');
    }
  }

  // ========== GESTION DE L'HISTORIQUE ==========

  /// Ajouter une entrée à l'historique
  Future<void> _addHistorique({
    required int adherentId,
    required String typeOperation,
    required String description,
    int? operationId,
    double? montant,
    double? quantite,
    DateTime? dateOperation,
    int? createdBy,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final historique = AdherentHistoriqueModel(
        adherentId: adherentId,
        typeOperation: typeOperation,
        operationId: operationId,
        description: description,
        montant: montant,
        quantite: quantite,
        dateOperation: dateOperation ?? DateTime.now(),
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      await db.insert('adherent_historique', historique.toMap());
    } catch (e) {
      print('Erreur lors de l\'ajout à l\'historique: $e');
    }
  }

  /// Enregistrer un dépôt dans l'historique
  Future<void> logDepot({
    required int adherentId,
    required int depotId,
    required double quantite,
    required double montant,
    required DateTime dateDepot,
    int? createdBy,
  }) async {
    await _addHistorique(
      adherentId: adherentId,
      typeOperation: 'depot',
      operationId: depotId,
      description: 'Dépôt de ${quantite.toStringAsFixed(2)} kg - ${montant.toStringAsFixed(0)} FCFA',
      montant: montant,
      quantite: quantite,
      dateOperation: dateDepot,
      createdBy: createdBy,
    );
  }

  /// Enregistrer une vente dans l'historique
  Future<void> logVente({
    required int adherentId,
    required int venteId,
    required double quantite,
    required double montant,
    required DateTime dateVente,
    int? createdBy,
  }) async {
    await _addHistorique(
      adherentId: adherentId,
      typeOperation: 'vente',
      operationId: venteId,
      description: 'Vente de ${quantite.toStringAsFixed(2)} kg - ${montant.toStringAsFixed(0)} FCFA',
      montant: montant,
      quantite: quantite,
      dateOperation: dateVente,
      createdBy: createdBy,
    );
  }

  /// Enregistrer une recette dans l'historique
  Future<void> logRecette({
    required int adherentId,
    required int recetteId,
    required double montantNet,
    required DateTime dateRecette,
    int? createdBy,
  }) async {
    await _addHistorique(
      adherentId: adherentId,
      typeOperation: 'recette',
      operationId: recetteId,
      description: 'Paiement reçu: ${montantNet.toStringAsFixed(0)} FCFA',
      montant: montantNet,
      dateOperation: dateRecette,
      createdBy: createdBy,
    );
  }

  /// Récupérer l'historique d'un adhérent
  Future<List<AdherentHistoriqueModel>> getHistorique({
    required int adherentId,
    String? typeOperation,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      String where = 'adherent_id = ?';
      List<dynamic> whereArgs = [adherentId];

      if (typeOperation != null) {
        where += ' AND type_operation = ?';
        whereArgs.add(typeOperation);
      }

      if (startDate != null) {
        where += ' AND date_operation >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where += ' AND date_operation <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.query(
        'adherent_historique',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'date_operation DESC, created_at DESC',
        limit: limit,
      );

      return result.map((map) => AdherentHistoriqueModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'historique: $e');
    }
  }

  /// Récupérer les dépôts d'un adhérent
  Future<List<Map<String, dynamic>>> getDepots(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'stock_depots',
        where: 'adherent_id = ?',
        whereArgs: [adherentId],
        orderBy: 'date_depot DESC',
      );

      return result;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des dépôts: $e');
    }
  }

  /// Récupérer les ventes d'un adhérent
  Future<List<Map<String, dynamic>>> getVentes(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Récupérer les ventes individuelles (où adherent_id correspond directement)
      final ventesIndividuelles = await db.query(
        'ventes',
        where: 'adherent_id = ? AND statut = ?',
        whereArgs: [adherentId, 'valide'],
        orderBy: 'date_vente DESC, created_at DESC',
      );

      // Récupérer les ventes groupées (via vente_details)
      final detailsResult = await db.query(
        'vente_details',
        where: 'adherent_id = ?',
        whereArgs: [adherentId],
      );
      
      final venteIdsFromDetails = detailsResult.map((d) => d['vente_id'] as int).toSet();
      
      List<Map<String, dynamic>> ventesGroupees = [];
      if (venteIdsFromDetails.isNotEmpty) {
        final placeholders = venteIdsFromDetails.map((_) => '?').join(',');
        final ventesGroupeesRaw = await db.query(
          'ventes',
          where: 'id IN ($placeholders) AND statut = ?',
          whereArgs: [...venteIdsFromDetails, 'valide'],
          orderBy: 'date_vente DESC, created_at DESC',
        );
        
        // Enrichir les ventes groupées avec les détails spécifiques à l'adhérent
        // Créer des copies modifiables car les Maps SQLite sont en lecture seule
        for (var venteRaw in ventesGroupeesRaw) {
          final vente = Map<String, dynamic>.from(venteRaw); // Copie modifiable
          final detail = detailsResult.firstWhere(
            (d) => d['vente_id'] == vente['id'],
            orElse: () => <String, dynamic>{},
          );
          
          if (detail.isNotEmpty) {
            // Ajouter les informations spécifiques de l'adhérent pour cette vente groupée
            vente['quantite'] = detail['quantite'];
            vente['montant'] = detail['montant'];
            vente['prix_unitaire'] = detail['prix_unitaire'];
            // Garder aussi les valeurs totales pour référence
            vente['quantite_total'] = vente['quantite_total'];
            vente['montant_total'] = vente['montant_total'];
          }
          ventesGroupees.add(vente);
        }
      }

      // Combiner les deux listes et supprimer les doublons (au cas où)
      // Créer des copies modifiables pour toutes les ventes
      final allVentes = <int, Map<String, dynamic>>{};
      
      for (var venteRaw in ventesIndividuelles) {
        final vente = Map<String, dynamic>.from(venteRaw); // Copie modifiable
        allVentes[vente['id'] as int] = vente;
      }
      
      for (var vente in ventesGroupees) {
        // Déjà une copie modifiable, pas besoin de recopier
        allVentes[vente['id'] as int] = vente;
      }

      // Trier par date de vente (plus récent en premier)
      final sortedVentes = allVentes.values.toList();
      sortedVentes.sort((a, b) {
        final dateA = a['date_vente'] != null 
            ? DateTime.parse(a['date_vente'] as String)
            : DateTime.parse(a['created_at'] as String);
        final dateB = b['date_vente'] != null
            ? DateTime.parse(b['date_vente'] as String)
            : DateTime.parse(b['created_at'] as String);
        return dateB.compareTo(dateA);
      });

      return sortedVentes;
    } catch (e) {
      print('❌ Erreur lors de la récupération des ventes: $e');
      throw Exception('Erreur lors de la récupération des ventes: $e');
    }
  }

  /// Récupérer les recettes d'un adhérent
  Future<List<Map<String, dynamic>>> getRecettes(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'recettes',
        where: 'adherent_id = ?',
        whereArgs: [adherentId],
        orderBy: 'date_recette DESC',
      );

      return result;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des recettes: $e');
    }
  }

  // ========== INTÉGRATION MODULE VENTES ==========

  /// Récupérer le stock disponible d'un adhérent par campagne
  /// Retourne le stock disponible en kg pour une campagne donnée
  Future<double> getStockByCampagne({
    required int adherentId,
    int? campagneId,
  }) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Si pas de campagne spécifiée, retourner le stock total
      if (campagneId == null) {
        return await _getStockTotal(adherentId);
      }
      
      // Récupérer les dépôts (note: campagne_id peut ne pas exister dans stock_depots)
      // On récupère tous les dépôts et on filtre par campagne via les ventes
      final depotsResult = await db.rawQuery('''
        SELECT COALESCE(SUM(poids_net), SUM(quantite), 0) as total
        FROM stock_depots
        WHERE adherent_id = ?
      ''', [adherentId]);
      
      final totalDepots = (depotsResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // Récupérer les mouvements de vente liés à cette campagne
      final mouvementsResult = await db.rawQuery('''
        SELECT COALESCE(SUM(sm.quantite), 0) as total
        FROM stock_mouvements sm
        INNER JOIN ventes v ON v.id = sm.vente_id
        WHERE sm.adherent_id = ? 
        AND v.campagne_id = ?
        AND sm.type IN ('vente', 'ajustement')
      ''', [adherentId, campagneId]);
      
      final totalMouvements = (mouvementsResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      return totalDepots + totalMouvements;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du stock par campagne: $e');
    }
  }

  /// Récupérer le stock total d'un adhérent (méthode helper)
  Future<double> _getStockTotal(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final depotsResult = await db.rawQuery('''
        SELECT COALESCE(SUM(poids_net), SUM(quantite), 0) as total
        FROM stock_depots
        WHERE adherent_id = ?
      ''', [adherentId]);
      
      final totalDepots = (depotsResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      final mouvementsResult = await db.rawQuery('''
        SELECT COALESCE(SUM(quantite), 0) as total
        FROM stock_mouvements
        WHERE adherent_id = ? AND type IN ('vente', 'ajustement')
      ''', [adherentId]);
      
      final totalMouvements = (mouvementsResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      return totalDepots + totalMouvements;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du stock total: $e');
    }
  }

  /// Récupérer le taux de commission applicable pour un adhérent
  /// Selon sa catégorie (producteur/adherent/actionnaire)
  Future<double> getCommissionRateForAdherent(int adherentId) async {
    try {
      final adherent = await getAdherentById(adherentId);
      if (adherent == null) {
        throw Exception('Adhérent non trouvé');
      }
      
      final db = await DatabaseInitializer.database;
      final parametres = await db.query('coop_settings', limit: 1);
      
      if (parametres.isEmpty) {
        return AppConfig.defaultCommissionRate;
      }
      
      final settings = parametres.first;
      
      // Commission différenciée selon catégorie
      if (adherent.isActionnaire) {
        final rate = settings['commission_rate_actionnaire'] as num?;
        return rate?.toDouble() ?? settings['commission_rate'] as double;
      } else if (adherent.isProducteur) {
        final rate = settings['commission_rate_producteur'] as num?;
        return rate?.toDouble() ?? settings['commission_rate'] as double;
      } else {
        // Adhérent simple : commission standard
        return (settings['commission_rate'] as num).toDouble();
      }
    } catch (e) {
      print('Erreur lors de la récupération du taux de commission: $e');
      return AppConfig.defaultCommissionRate;
    }
  }

  /// Vérifier si un adhérent est actif et peut vendre
  Future<bool> canAdherentSell(int adherentId) async {
    try {
      final adherent = await getAdherentById(adherentId);
      if (adherent == null) return false;
      
      // Vérifier si actif ET statut actif
      return adherent.isActive && adherent.isStatutActif;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer les campagnes actives d'un adhérent
  /// (basé sur les dépôts effectués)
  Future<List<int>> getCampagnesActives(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.rawQuery('''
        SELECT DISTINCT campagne_id
        FROM stock_depots
        WHERE adherent_id = ? AND campagne_id IS NOT NULL
      ''', [adherentId]);
      
      return result.map((row) => row['campagne_id'] as int).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des campagnes actives: $e');
    }
  }

  /// Récupérer le solde financier d'un adhérent
  /// Retourne le montant dû à l'adhérent (recettes - paiements)
  Future<double> getSoldeFinancier(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // Montant total des ventes (montant net après commission)
      final ventesResult = await db.rawQuery('''
        SELECT COALESCE(SUM(montant_net), 0) as total
        FROM ventes
        WHERE adherent_id = ? AND statut = 'valide'
      ''', [adherentId]);
      
      final montantVentes = (ventesResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // Montant total payé (recettes)
      final recettesResult = await db.rawQuery('''
        SELECT COALESCE(SUM(montant_net), 0) as total
        FROM recettes
        WHERE adherent_id = ?
      ''', [adherentId]);
      
      final montantPaye = (recettesResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      return montantVentes - montantPaye;
    } catch (e) {
      throw Exception('Erreur lors du calcul du solde financier: $e');
    }
  }

  /// Récupérer les ventes d'un adhérent avec détails complets
  Future<List<Map<String, dynamic>>> getVentesWithDetails(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.rawQuery('''
        SELECT 
          v.*,
          va.poids_utilise,
          va.montant_brut,
          va.commission_rate,
          va.commission_amount,
          va.montant_net as montant_net_adherent,
          va.campagne_id,
          va.qualite
        FROM ventes v
        LEFT JOIN vente_adherents va ON va.vente_id = v.id AND va.adherent_id = ?
        WHERE v.adherent_id = ? OR va.adherent_id = ?
        ORDER BY v.date_vente DESC
      ''', [adherentId, adherentId, adherentId]);
      
      return result;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des ventes avec détails: $e');
    }
  }

  /// Calculer les indicateurs expert pour un adhérent
  /// Retourne un Map avec tous les indicateurs calculés
  Future<Map<String, double>> calculateExpertIndicators(int adherentId) async {
    try {
      final db = await DatabaseInitializer.database;
      
      // 1. Tonnage total produit (somme des dépôts en tonnes)
      final depotsResult = await db.rawQuery('''
        SELECT COALESCE(SUM(poids_net), SUM(quantite), 0) as total
        FROM stock_depots
        WHERE adherent_id = ?
      ''', [adherentId]);
      final tonnageTotalProduit = ((depotsResult.first['total'] as num?)?.toDouble() ?? 0.0) / 1000.0; // Convertir kg en tonnes
      
      // 2. Tonnage total vendu (somme des ventes en tonnes)
      final ventesResult = await db.rawQuery('''
        SELECT COALESCE(SUM(quantite_total), 0) as total
        FROM ventes
        WHERE adherent_id = ? AND statut = 'valide'
      ''', [adherentId]);
      final tonnageTotalVendu = ((ventesResult.first['total'] as num?)?.toDouble() ?? 0.0) / 1000.0; // Convertir kg en tonnes
      
      // 3. Stock disponible (stock actuel en tonnes)
      // Utiliser la même logique que StockService.getStockActuel
      final depotsStockResult = await db.rawQuery('''
        SELECT COALESCE(SUM(poids_net), SUM(quantite), 0) as total
        FROM stock_depots
        WHERE adherent_id = ?
      ''', [adherentId]);
      final totalDepotsStock = (depotsStockResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      final mouvementsStockResult = await db.rawQuery('''
        SELECT COALESCE(SUM(quantite), 0) as total
        FROM stock_mouvements
        WHERE adherent_id = ? AND type IN ('vente', 'ajustement')
      ''', [adherentId]);
      final totalMouvementsStock = (mouvementsStockResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      final tonnageDisponibleStock = (totalDepotsStock + totalMouvementsStock) / 1000.0; // Convertir kg en tonnes
      
      // 4. Montant total des ventes
      final montantVentesResult = await db.rawQuery('''
        SELECT COALESCE(SUM(montant_total), 0) as total
        FROM ventes
        WHERE adherent_id = ? AND statut = 'valide'
      ''', [adherentId]);
      final montantTotalVentes = (montantVentesResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // 5. Montant total payé (somme des recettes nettes)
      final recettesResult = await db.rawQuery('''
        SELECT COALESCE(SUM(montant_net), 0) as total
        FROM recettes
        WHERE adherent_id = ?
      ''', [adherentId]);
      final montantTotalPaye = (recettesResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // 6. Solde créditeur (montant dû à l'adhérent)
      final soldeCrediteur = montantTotalVentes - montantTotalPaye;
      
      // 7. Solde débiteur (somme des crédits sociaux non remboursés)
      final creditsResult = await db.rawQuery('''
        SELECT COALESCE(SUM(solde_restant), 0) as total
        FROM social_credits
        WHERE adherent_id = ? AND statut_remboursement != 'annule'
      ''', [adherentId]);
      final soldeDebiteur = (creditsResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // 8. Capital social (calculé depuis capital_social_expert)
      final capitalSocialService = CapitalSocialService();
      final capitalStats = await capitalSocialService.getCapitalSocialStats(adherentId);
      final capitalSocialSouscrit = capitalStats['capitalSocialSouscrit'] ?? 0.0;
      final capitalSocialLibere = capitalStats['capitalSocialLibere'] ?? 0.0;
      final capitalSocialRestant = capitalStats['capitalSocialRestant'] ?? 0.0;
      
      // 9. Récupérer la superficie totale cultivée pour calculer le rendement
      final adherentResult = await db.query(
        'adherents',
        where: 'id = ?',
        whereArgs: [adherentId],
        limit: 1,
      );
      final superficieTotaleCultivee = adherentResult.isNotEmpty
          ? (adherentResult.first['superficie_totale_cultivee'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      
      // 10. Rendement moyen par hectare
      final rendementMoyenHa = superficieTotaleCultivee > 0
          ? tonnageTotalProduit / superficieTotaleCultivee
          : 0.0;
      
      return {
        'tonnageTotalProduit': tonnageTotalProduit,
        'tonnageTotalVendu': tonnageTotalVendu,
        'tonnageDisponibleStock': tonnageDisponibleStock,
        'montantTotalVentes': montantTotalVentes,
        'montantTotalPaye': montantTotalPaye,
        'soldeCrediteur': soldeCrediteur > 0 ? soldeCrediteur : 0.0,
        'soldeDebiteur': soldeDebiteur,
        'capitalSocialSouscrit': capitalSocialSouscrit,
        'capitalSocialLibere': capitalSocialLibere,
        'capitalSocialRestant': capitalSocialRestant,
        'rendementMoyenHa': rendementMoyenHa,
      };
    } catch (e) {
      print('Erreur lors du calcul des indicateurs: $e');
      // Retourner des valeurs par défaut en cas d'erreur
      return {
        'tonnageTotalProduit': 0.0,
        'tonnageTotalVendu': 0.0,
        'tonnageDisponibleStock': 0.0,
        'montantTotalVentes': 0.0,
        'montantTotalPaye': 0.0,
        'soldeCrediteur': 0.0,
        'soldeDebiteur': 0.0,
        'capitalSocialSouscrit': 0.0,
        'capitalSocialLibere': 0.0,
        'capitalSocialRestant': 0.0,
        'rendementMoyenHa': 0.0,
      };
    }
  }
  
  /// S'assurer que la colonne photo_path existe dans la table adherents
  /// Cette méthode est appelée avant chaque insertion pour garantir la compatibilité
  Future<void> _ensurePhotoPathColumn(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(adherents)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      if (!columnNames.contains('photo_path')) {
        try {
          await db.execute('ALTER TABLE adherents ADD COLUMN photo_path TEXT');
          print('✅ Colonne photo_path ajoutée à adherents (vérification runtime)');
        } catch (e) {
          // Ignorer si la colonne existe déjà (cas de race condition)
          if (!e.toString().contains('duplicate column') && 
              !e.toString().contains('already exists')) {
            print('⚠️ Erreur lors de l\'ajout de photo_path: $e');
            // Ne pas faire échouer l'opération, mais logger l'erreur
          }
        }
      }
    } catch (e) {
      print('⚠️ Erreur lors de la vérification de photo_path: $e');
      // Ne pas faire échouer l'opération
    }
  }
}
