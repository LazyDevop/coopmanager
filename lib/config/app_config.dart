class AppConfig {
  // Version de l'application
  static const String appVersion = '2.0.0';
  static const int buildNumber = 2;
  
  // Nom de l'application
  static const String appName = 'CoopManager';
  static const String appDescription = 'Gestion de coopérative de cacaoculteurs';
  
  // Configuration API REST
  // TODO: Modifier cette URL selon votre environnement (dev, staging, production)
  static const String apiBaseUrl = 'http://localhost:8000/api'; // Exemple: 'https://api.coopmanager.com/api'
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Mode de fonctionnement: 'api' pour utiliser les APIs REST, 'local' pour SQLite
  // Par défaut, utiliser 'api' pour connecter aux vraies APIs
  static const String dataSourceMode = 'api'; // 'api' ou 'local'
  
  // Configuration de la base de données
  static const String databaseName = 'coop_manager.db';
  static const int databaseVersion = 23; // Module Social complet
  
  // Qualités de cacao
  static const List<String> qualitesCacao = ['Grade 1', 'Grade 2', 'Hors standard'];
  
  // Configuration par défaut de la coopérative
  static const double defaultCommissionRate = 0.05; // 5% par défaut
  
  // Rôles utilisateurs
  static const String roleSuperAdmin = 'super_admin';
  static const String roleAdmin = 'admin';
  static const String roleComptable = 'comptable';
  static const String roleCaissier = 'caissier';
  static const String roleMagasinier = 'magasinier'; // Anciennement gestionnaire_stock
  
  // Rôles obsolètes (pour compatibilité)
  static const String roleGestionnaireStock = 'gestionnaire_stock'; // Alias pour magasinier
  static const String roleResponsableSocial = 'responsable_social';
  static const String roleConsultation = 'consultation';
  
  // Catégories d'adhérents
  static const String categorieProducteur = 'producteur';
  static const String categorieAdherent = 'adherent';
  static const String categorieActionnaire = 'actionnaire';
  
  // Types de clients
  static const String clientTypeEntreprise = 'entreprise';
  static const String clientTypeParticulier = 'particulier';
  static const String clientTypeCooperative = 'cooperative';
  
  // Types d'aides sociales
  static const String aideTypeSante = 'sante';
  static const String aideTypeEducation = 'education';
  static const String aideTypeUrgence = 'urgence';
  static const String aideTypeAutre = 'autre';
  
  // Chemins de sauvegarde
  static const String backupFolder = 'backups';
  static const String exportFolder = 'exports';
  
  // Configuration de l'impression
  static const String defaultPrinterName = 'default';
  
  // Période de campagne par défaut (en jours)
  static const int defaultCampaignPeriod = 365;
  
  // Vérifier si on utilise les APIs
  static bool get useApi => dataSourceMode == 'api';
}
