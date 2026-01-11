import '../../config/app_config.dart';
import '../../data/models/adherent_model.dart';
import '../api/adherent_api_service.dart';
import 'adherent_service.dart';

/// Wrapper hybride pour le service Adhérents
/// Utilise les APIs REST si configuré, sinon SQLite local
class AdherentServiceApiWrapper {
  final AdherentApiService _apiService = AdherentApiService();
  final AdherentService _localService = AdherentService();

  bool get _useApi => AppConfig.useApi;

  /// Récupérer tous les adhérents
  Future<List<AdherentModel>> getAllAdherents({
    bool? isActive,
    String? village,
  }) async {
    if (_useApi) {
      return await _apiService.getAllAdherents(
        isActive: isActive,
        village: village,
      );
    } else {
      return await _localService.getAllAdherents(
        isActive: isActive,
        village: village,
      );
    }
  }

  /// Récupérer un adhérent par ID
  Future<AdherentModel?> getAdherentById(int id) async {
    if (_useApi) {
      return await _apiService.getAdherentById(id);
    } else {
      return await _localService.getAdherentById(id);
    }
  }

  /// Créer un adhérent
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
    String? categorie,
    String? statut,
    String? siteCooperative,
    String? section,
    String? sexe,
    String? lieuNaissance,
    String? nationalite,
    String? typePiece,
    String? numeroPiece,
    String? nomPere,
    String? nomMere,
    String? conjoint,
    int? nombreEnfants,
    double? superficieTotaleCultivee,
    int? nombreChamps,
    double? rendementMoyenHa,
    double? tonnageTotalProduit,
    double? tonnageTotalVendu,
  }) async {
    if (_useApi) {
      final data = {
        if (code != null) 'code': code,
        'nom': nom,
        'prenom': prenom,
        if (telephone != null) 'telephone': telephone,
        if (email != null) 'email': email,
        if (village != null) 'village': village,
        if (adresse != null) 'adresse': adresse,
        if (cnib != null) 'cnib': cnib,
        if (dateNaissance != null) 'date_naissance': dateNaissance.toIso8601String(),
        'date_adhesion': dateAdhesion.toIso8601String(),
        'created_by': createdBy,
        if (categorie != null) 'categorie': categorie,
        if (statut != null) 'statut': statut,
        if (siteCooperative != null) 'site_cooperative': siteCooperative,
        if (section != null) 'section': section,
        if (sexe != null) 'sexe': sexe,
        if (lieuNaissance != null) 'lieu_naissance': lieuNaissance,
        if (nationalite != null) 'nationalite': nationalite,
        if (typePiece != null) 'type_piece': typePiece,
        if (numeroPiece != null) 'numero_piece': numeroPiece,
        if (nomPere != null) 'nom_pere': nomPere,
        if (nomMere != null) 'nom_mere': nomMere,
        if (conjoint != null) 'conjoint': conjoint,
        if (nombreEnfants != null) 'nombre_enfants': nombreEnfants,
        if (superficieTotaleCultivee != null) 'superficie_totale_cultivee': superficieTotaleCultivee,
        if (nombreChamps != null) 'nombre_champs': nombreChamps,
        if (rendementMoyenHa != null) 'rendement_moyen_ha': rendementMoyenHa,
        if (tonnageTotalProduit != null) 'tonnage_total_produit': tonnageTotalProduit,
        if (tonnageTotalVendu != null) 'tonnage_total_vendu': tonnageTotalVendu,
      };
      return await _apiService.createAdherent(data);
    } else {
      return await _localService.createAdherent(
        code: code,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email,
        village: village,
        adresse: adresse,
        cnib: cnib,
        dateNaissance: dateNaissance,
        dateAdhesion: dateAdhesion,
        createdBy: createdBy,
        categorie: categorie,
        statut: statut,
        siteCooperative: siteCooperative,
        section: section,
        sexe: sexe,
        lieuNaissance: lieuNaissance,
        nationalite: nationalite,
        typePiece: typePiece,
        numeroPiece: numeroPiece,
        nomPere: nomPere,
        nomMere: nomMere,
        conjoint: conjoint,
        nombreEnfants: nombreEnfants,
        superficieTotaleCultivee: superficieTotaleCultivee,
        nombreChamps: nombreChamps,
        rendementMoyenHa: rendementMoyenHa,
        tonnageTotalProduit: tonnageTotalProduit,
        tonnageTotalVendu: tonnageTotalVendu,
      );
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
    String? categorie,
    String? statut,
    String? siteCooperative,
    String? section,
    String? sexe,
    String? lieuNaissance,
    String? nationalite,
    String? typePiece,
    String? numeroPiece,
    String? nomPere,
    String? nomMere,
    String? conjoint,
    int? nombreEnfants,
    double? superficieTotaleCultivee,
    int? nombreChamps,
    double? rendementMoyenHa,
    double? tonnageTotalProduit,
    double? tonnageTotalVendu,
  }) async {
    if (_useApi) {
      final data = <String, dynamic>{
        'updated_by': updatedBy,
      };
      if (code != null) data['code'] = code;
      if (nom != null) data['nom'] = nom;
      if (prenom != null) data['prenom'] = prenom;
      if (telephone != null) data['telephone'] = telephone;
      if (email != null) data['email'] = email;
      if (village != null) data['village'] = village;
      if (adresse != null) data['adresse'] = adresse;
      if (cnib != null) data['cnib'] = cnib;
      if (dateNaissance != null) data['date_naissance'] = dateNaissance.toIso8601String();
      if (dateAdhesion != null) data['date_adhesion'] = dateAdhesion.toIso8601String();
      if (categorie != null) data['categorie'] = categorie;
      if (statut != null) data['statut'] = statut;
      if (siteCooperative != null) data['site_cooperative'] = siteCooperative;
      if (section != null) data['section'] = section;
      if (sexe != null) data['sexe'] = sexe;
      if (lieuNaissance != null) data['lieu_naissance'] = lieuNaissance;
      if (nationalite != null) data['nationalite'] = nationalite;
      if (typePiece != null) data['type_piece'] = typePiece;
      if (numeroPiece != null) data['numero_piece'] = numeroPiece;
      if (nomPere != null) data['nom_pere'] = nomPere;
      if (nomMere != null) data['nom_mere'] = nomMere;
      if (conjoint != null) data['conjoint'] = conjoint;
      if (nombreEnfants != null) data['nombre_enfants'] = nombreEnfants;
      if (superficieTotaleCultivee != null) data['superficie_totale_cultivee'] = superficieTotaleCultivee;
      if (nombreChamps != null) data['nombre_champs'] = nombreChamps;
      if (rendementMoyenHa != null) data['rendement_moyen_ha'] = rendementMoyenHa;
      if (tonnageTotalProduit != null) data['tonnage_total_produit'] = tonnageTotalProduit;
      if (tonnageTotalVendu != null) data['tonnage_total_vendu'] = tonnageTotalVendu;

      return await _apiService.updateAdherent(id, data);
    } else {
      return await _localService.updateAdherent(
        id: id,
        code: code,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email,
        village: village,
        adresse: adresse,
        cnib: cnib,
        dateNaissance: dateNaissance,
        dateAdhesion: dateAdhesion,
        updatedBy: updatedBy,
        categorie: categorie,
        statut: statut,
        siteCooperative: siteCooperative,
        section: section,
        sexe: sexe,
        lieuNaissance: lieuNaissance,
        nationalite: nationalite,
        typePiece: typePiece,
        numeroPiece: numeroPiece,
        nomPere: nomPere,
        nomMere: nomMere,
        conjoint: conjoint,
        nombreEnfants: nombreEnfants,
        superficieTotaleCultivee: superficieTotaleCultivee,
        nombreChamps: nombreChamps,
        rendementMoyenHa: rendementMoyenHa,
        tonnageTotalProduit: tonnageTotalProduit,
        tonnageTotalVendu: tonnageTotalVendu,
      );
    }
  }

  /// Activer/Désactiver un adhérent
  Future<bool> toggleAdherentStatus(int id, bool isActive, int updatedBy) async {
    if (_useApi) {
      return await _apiService.toggleAdherentStatus(id, isActive);
    } else {
      return await _localService.toggleAdherentStatus(id, isActive, updatedBy);
    }
  }

  /// Rechercher des adhérents
  Future<List<AdherentModel>> searchAdherents(String query) async {
    if (_useApi) {
      return await _apiService.searchAdherents(query);
    } else {
      return await _localService.searchAdherents(query);
    }
  }

  /// Obtenir tous les villages
  Future<List<String>> getAllVillages() async {
    if (_useApi) {
      return await _apiService.getAllVillages();
    } else {
      return await _localService.getAllVillages();
    }
  }

  /// Vérifier si un code existe
  Future<bool> codeExists(String code, {int? excludeId}) async {
    if (_useApi) {
      return await _apiService.codeExists(code, excludeId: excludeId);
    } else {
      return await _localService.codeExists(code, excludeId: excludeId);
    }
  }

  /// Générer le prochain code
  Future<String> generateNextCode() async {
    if (_useApi) {
      return await _apiService.generateNextCode();
    } else {
      return await _localService.generateNextCode();
    }
  }

  /// Récupérer l'historique
  Future<List<Map<String, dynamic>>> getHistorique(int adherentId) async {
    if (_useApi) {
      return await _apiService.getHistorique(adherentId);
    } else {
      // Utiliser le service local pour l'historique
      final historique = await _localService.getHistorique(adherentId: adherentId);
      return historique.map((h) => h.toMap()).toList();
    }
  }

  /// Récupérer les dépôts
  Future<List<Map<String, dynamic>>> getDepots(int adherentId) async {
    if (_useApi) {
      return await _apiService.getDepots(adherentId);
    } else {
      return await _localService.getDepots(adherentId);
    }
  }

  /// Récupérer les ventes
  Future<List<Map<String, dynamic>>> getVentes(int adherentId) async {
    if (_useApi) {
      return await _apiService.getVentes(adherentId);
    } else {
      return await _localService.getVentes(adherentId);
    }
  }

  /// Récupérer les recettes
  Future<List<Map<String, dynamic>>> getRecettes(int adherentId) async {
    if (_useApi) {
      return await _apiService.getRecettes(adherentId);
    } else {
      return await _localService.getRecettes(adherentId);
    }
  }

  /// Calculer les indicateurs expert
  Future<Map<String, double>> calculateExpertIndicators(int adherentId) async {
    // Pour l'instant, utiliser le service local pour les calculs complexes
    return await _localService.calculateExpertIndicators(adherentId);
  }
}

















