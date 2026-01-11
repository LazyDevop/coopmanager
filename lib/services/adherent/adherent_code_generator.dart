/// Service de génération de codes adhérents selon la nomenclature ERP coopérative
/// 
/// Format : [2 lettres coop/site][2 chiffres année][4 alphanumériques séquentiel]
/// Exemple : CE25A9F2, CO24B103, ES26Z7Q8
/// 
/// Contraintes :
/// - Longueur fixe : 8 caractères
/// - Format : alphanumérique (A-Z, 0-9)
/// - Unique au sein de la coopérative
/// - Généré automatiquement par le système
/// - Non modifiable après création

import 'dart:math';
import '../database/db_initializer.dart';
import '../parametres/parametres_service.dart';

class AdherentCodeGenerator {
  final ParametresService _parametresService = ParametresService();
  
  // Caractères alphanumériques utilisables (A-Z, 0-9)
  static const String _alphanumericChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  
  // Caractères alphabétiques uniquement (pour le préfixe coopérative)
  static const String _alphaChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  
  /// Générer un code adhérent unique selon la nouvelle nomenclature
  /// 
  /// Format : [2 lettres coop/site][2 chiffres année][4 alphanumériques]
  /// 
  /// @param dateAdhesion Date d'adhésion de l'adhérent (pour déterminer l'année)
  /// @param siteCooperative Code du site coopérative (optionnel, sinon utilise le code coopérative)
  /// @param maxRetries Nombre maximum de tentatives en cas de collision (défaut: 10)
  /// @return Code adhérent unique de 8 caractères
  Future<String> generateUniqueCode({
    required DateTime dateAdhesion,
    String? siteCooperative,
    int maxRetries = 10,
  }) async {
    try {
      // 1. Récupérer le code coopérative ou site
      final prefix = await _getCooperativePrefix(siteCooperative);
      
      // 2. Extraire l'année (2 derniers chiffres)
      final yearSuffix = _extractYearSuffix(dateAdhesion);
      
      // 3. Générer le code séquentiel (4 caractères alphanumériques)
      String code;
      int attempts = 0;
      
      do {
        // Générer un code séquentiel sécurisé
        final sequentialPart = _generateSequentialPart(prefix, yearSuffix, attempts);
        
        // Construire le code complet
        code = '$prefix$yearSuffix$sequentialPart';
        
        // Vérifier l'unicité
        final exists = await _codeExists(code);
        
        if (!exists) {
          return code;
        }
        
        attempts++;
        
        // Si trop de tentatives, utiliser un timestamp pour garantir l'unicité
        if (attempts >= maxRetries) {
          code = _generateFallbackCode(prefix, yearSuffix);
          // Vérifier une dernière fois
          if (!await _codeExists(code)) {
            return code;
          }
          // En dernier recours, ajouter un suffixe aléatoire
          code = '${code.substring(0, 6)}${_generateRandomSuffix(2)}';
        }
      } while (attempts < maxRetries * 2);
      
      // Si on arrive ici, il y a un problème sérieux
      throw Exception('Impossible de générer un code unique après $attempts tentatives');
    } catch (e) {
      throw Exception('Erreur lors de la génération du code adhérent: $e');
    }
  }
  
  /// Récupérer le préfixe coopérative (2 lettres)
  /// 
  /// Priorité :
  /// 1. Code site coopérative (si fourni et valide)
  /// 2. Code coopérative depuis les paramètres (code_cooperative)
  /// 3. Code par défaut "CO"
  Future<String> _getCooperativePrefix(String? siteCooperative) async {
    // Si un code site est fourni et valide (2 lettres majuscules)
    if (siteCooperative != null && 
        siteCooperative.length == 2 && 
        siteCooperative.toUpperCase() == siteCooperative &&
        _isAlphaOnly(siteCooperative)) {
      return siteCooperative.toUpperCase();
    }
    
    try {
      // Récupérer les paramètres de la coopérative
      final parametres = await _parametresService.getParametres();
      
      // Utiliser le code coopérative configuré si disponible
      if (parametres.codeCooperative != null && 
          parametres.codeCooperative!.isNotEmpty &&
          parametres.codeCooperative!.length == 2 &&
          _isAlphaOnly(parametres.codeCooperative!)) {
        return parametres.codeCooperative!.toUpperCase();
      }
      
      // Sinon, extraire le code coopérative depuis le nom
      if (parametres.nomCooperative.isNotEmpty) {
        final nomUpper = parametres.nomCooperative.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
        if (nomUpper.length >= 2) {
          return nomUpper.substring(0, 2);
        }
      }
    } catch (e) {
      // En cas d'erreur, utiliser le code par défaut
      print('⚠️ Erreur lors de la récupération du code coopérative: $e');
    }
    
    // Code par défaut
    return 'CO';
  }
  
  /// Extraire le suffixe d'année (2 chiffres)
  /// 
  /// Exemple : 2025 -> "25", 2024 -> "24"
  String _extractYearSuffix(DateTime date) {
    final year = date.year;
    final yearStr = year.toString();
    // Prendre les 2 derniers chiffres
    return yearStr.length >= 2 ? yearStr.substring(yearStr.length - 2) : yearStr.padLeft(2, '0');
  }
  
  /// Générer la partie séquentielle (4 caractères alphanumériques)
  /// 
  /// Cette méthode génère un code séquentiel basé sur :
  /// - Le nombre d'adhérents existants avec le même préfixe et année
  /// - Un offset aléatoire pour éviter les collisions
  String _generateSequentialPart(String prefix, String yearSuffix, int offset) {
    // Base : compter les adhérents existants avec ce préfixe et cette année
    // Pour simplifier, on génère un code aléatoire sécurisé
    // En production, on pourrait utiliser un compteur séquentiel
    
    // Générer 4 caractères alphanumériques
    final random = Random();
    final buffer = StringBuffer();
    
    for (int i = 0; i < 4; i++) {
      final index = random.nextInt(_alphanumericChars.length);
      buffer.write(_alphanumericChars[index]);
    }
    
    return buffer.toString();
  }
  
  /// Générer un code de secours en cas de collision multiple
  /// Utilise un timestamp pour garantir l'unicité
  String _generateFallbackCode(String prefix, String yearSuffix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Convertir le timestamp en base 36 (0-9, A-Z)
    final base36 = timestamp.toRadixString(36).toUpperCase();
    // Prendre les 4 derniers caractères
    final suffix = base36.length >= 4 
        ? base36.substring(base36.length - 4)
        : base36.padLeft(4, '0');
    
    // S'assurer que c'est bien alphanumérique
    final cleanSuffix = suffix.replaceAll(RegExp(r'[^A-Z0-9]'), '0').padRight(4, '0').substring(0, 4);
    
    return '$prefix$yearSuffix$cleanSuffix';
  }
  
  /// Générer un suffixe aléatoire de longueur donnée
  String _generateRandomSuffix(int length) {
    final random = Random();
    final buffer = StringBuffer();
    
    for (int i = 0; i < length; i++) {
      final index = random.nextInt(_alphanumericChars.length);
      buffer.write(_alphanumericChars[index]);
    }
    
    return buffer.toString();
  }
  
  /// Vérifier si un code existe déjà en base de données
  Future<bool> _codeExists(String code) async {
    try {
      final db = await DatabaseInitializer.database;
      
      final result = await db.query(
        'adherents',
        where: 'code = ?',
        whereArgs: [code],
        limit: 1,
      );
      
      return result.isNotEmpty;
    } catch (e) {
      // En cas d'erreur, considérer que le code existe pour éviter les collisions
      print('⚠️ Erreur lors de la vérification du code: $e');
      return true;
    }
  }
  
  /// Vérifier si une chaîne contient uniquement des lettres
  bool _isAlphaOnly(String str) {
    return str.runes.every((rune) => _alphaChars.contains(String.fromCharCode(rune)));
  }
  
  /// Valider le format d'un code adhérent
  /// 
  /// Vérifie que le code respecte la nomenclature :
  /// - Longueur exacte : 8 caractères
  /// - Format : [2 lettres][2 chiffres][4 alphanumériques]
  /// 
  /// @param code Code à valider
  /// @return true si le code est valide, false sinon
  static bool isValidFormat(String code) {
    if (code.length != 8) {
      return false;
    }
    
    // Vérifier le format avec une expression régulière
    final pattern = RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]{4}$');
    return pattern.hasMatch(code.toUpperCase());
  }
  
  /// Valider et normaliser un code adhérent
  /// 
  /// Convertit le code en majuscules et vérifie le format
  /// 
  /// @param code Code à valider
  /// @return Code normalisé ou null si invalide
  static String? validateAndNormalize(String code) {
    final normalized = code.toUpperCase().trim();
    
    if (isValidFormat(normalized)) {
      return normalized;
    }
    
    return null;
  }
  
  /// Extraire les informations d'un code adhérent
  /// 
  /// @param code Code adhérent
  /// @return Map avec les informations extraites (prefix, year, sequential)
  static Map<String, String>? parseCode(String code) {
    if (!isValidFormat(code)) {
      return null;
    }
    
    final normalized = code.toUpperCase();
    
    return {
      'prefix': normalized.substring(0, 2),      // Code coopérative/site
      'year': normalized.substring(2, 4),         // Année (2 chiffres)
      'sequential': normalized.substring(4, 8),    // Partie séquentielle
    };
  }
  
  /// Obtenir l'année complète depuis un code adhérent
  /// 
  /// @param code Code adhérent
  /// @return Année complète (ex: 2025) ou null si invalide
  static int? extractFullYear(String code) {
    final parsed = parseCode(code);
    if (parsed == null) return null;
    
    final yearSuffix = int.tryParse(parsed['year']!);
    if (yearSuffix == null) return null;
    
    // Déterminer le siècle (assume 2000-2099)
    final currentYear = DateTime.now().year;
    final currentCentury = (currentYear ~/ 100) * 100;
    final currentSuffix = currentYear % 100;
    
    // Si le suffixe est proche de l'année actuelle, utiliser le siècle actuel
    // Sinon, utiliser le siècle précédent (pour les années 00-99)
    if (yearSuffix <= currentSuffix + 10) {
      return currentCentury + yearSuffix;
    } else {
      return (currentCentury - 100) + yearSuffix;
    }
  }
}

