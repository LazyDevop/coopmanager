class AppRoutes {
  // Routes principales
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  
  // Modules
  static const String adherents = '/adherents';
  static const String adherentDetail = '/adherents/detail';
  static const String adherentExpertDetail = '/adherents/expert/detail';
  static const String champsMap = '/champs/map';
  static const String adherentAdd = '/adherents/add';
  static const String adherentEdit = '/adherents/edit';
  
  static const String stock = '/stock';
  static const String stockDepot = '/stock/depot';
  static const String stockMouvements = '/stock/mouvements';
  static const String stockHistory = '/stock/history';
  static const String stockAdjustment = '/stock/adjustment';
  static const String stockExport = '/stock/export';
  
  static const String ventes = '/ventes';
  static const String venteIndividuelle = '/ventes/individuelle';
  static const String venteGroupee = '/ventes/groupee';
  static const String venteV1 = '/ventes/v1'; // Nouvelle route V1
  static const String venteDetail = '/ventes/detail';
  static const String ventesStatistiques = '/ventes/statistiques'; // V1: Statistiques
  
  // V2: Routes Ventes V2
  static const String simulationVente = '/ventes/v2/simulation';
  static const String lotsVente = '/ventes/v2/lots';
  static const String creancesClients = '/ventes/v2/creances';
  static const String validationWorkflow = '/ventes/v2/workflow';
  static const String fondsSocial = '/ventes/v2/fonds-social';
  static const String analysePrix = '/ventes/v2/analyse';
  
  static const String recettes = '/recettes';
  static const String recetteDetail = '/recettes/detail';
  static const String recetteBordereau = '/recettes/bordereau';
  static const String recetteExport = '/recettes/export';
  static const String compteFinancierAdherent = '/recettes/compte';
  static const String paiementForm = '/recettes/paiement';
  
  // Module Commissions
  static const String commissions = '/commissions';
  static const String commissionForm = '/commissions/form';
  
  static const String factures = '/factures';
  static const String factureDetail = '/factures/detail';
  static const String factureAdd = '/factures/add';
  
  static const String users = '/users';
  static const String userAdd = '/users/add';
  static const String userEdit = '/users/edit';
  
  static const String settings = '/settings';
  static const String parametrage = '/settings/parametrage';
  static const String settingsMain = '/settings/main';
  static const String backup = '/settings/backup';
  static const String parametresInfo = '/parametres/info';
  static const String parametresFinances = '/parametres/finances';
  static const String parametresCampagnes = '/parametres/campagnes';
  static const String campagneForm = '/parametres/campagne/form';
  
  static const String notifications = '/notifications';
  
  // Module Documents Officiels
  static const String documents = '/documents';
  static const String documentDetail = '/documents/detail';
  static const String documentVerification = '/documents/verification';
  
  // V2: Nouvelles routes
  static const String clients = '/clients';
  static const String clientDetail = '/clients/detail';
  static const String clientAdd = '/clients/add';
  static const String clientEdit = '/clients/edit';
  static const String clientsImpayes = '/clients/impayes';
  
  // Module Capital Social
  static const String capital = '/capital';
  static const String capitalActionnaireDetail = '/capital/actionnaire/detail';
  static const String capitalSouscription = '/capital/souscription';
  static const String capitalLiberation = '/capital/liberation';
  static const String capitalEtat = '/capital/etat';
  static const String partSocialeAdd = '/capital/parts/add';
  
  static const String comptabilite = '/comptabilite';
  static const String grandLivre = '/comptabilite/grand-livre';
  static const String etatsFinanciers = '/comptabilite/etats';
  
  static const String social = '/social';
  static const String aidesSociales = '/social/aides';
  static const String aideSocialeAdd = '/social/aides/add';
  static const String aideSocialeDetail = '/social/aides/detail';
}
