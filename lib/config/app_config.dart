class AppConfig {
  // Version de l'application
  static const String appVersion = '2.0.0';
  static const int buildNumber = 2;
  
  // Nom de l'application
  static const String appName = 'CoopManager';
  static const String appDescription = 'Gestion de coopérative de cacaoculteurs';
  
  // Configuration de la base de données
  static const String databaseName = 'coop_manager.db';
  static const int databaseVersion = 11; // Ajout des champs humidite et photo_path pour stock_depots
  
  // Qualités de cacao
  static const List<String> qualitesCacao = ['standard', 'premium', 'bio'];
  
  // Configuration par défaut de la coopérative
  static const double defaultCommissionRate = 0.05; // 5% par défaut
  
  // Rôles utilisateurs
  static const String roleAdmin = 'admin';
  static const String roleGestionnaireStock = 'gestionnaire_stock';
  static const String roleCaissier = 'caissier';
  static const String roleComptable = 'comptable';
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
}
