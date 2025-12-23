class AppRoutes {
  // Routes principales
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  
  // Modules
  static const String adherents = '/adherents';
  static const String adherentDetail = '/adherents/detail';
  static const String adherentExpertDetail = '/adherents/expert/detail';
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
  static const String venteDetail = '/ventes/detail';
  
  static const String recettes = '/recettes';
  static const String recetteDetail = '/recettes/detail';
  static const String recetteBordereau = '/recettes/bordereau';
  static const String recetteExport = '/recettes/export';
  
  static const String factures = '/factures';
  static const String factureDetail = '/factures/detail';
  static const String factureAdd = '/factures/add';
  
  static const String users = '/users';
  static const String userAdd = '/users/add';
  static const String userEdit = '/users/edit';
  
  static const String settings = '/settings';
  static const String parametrage = '/settings/parametrage';
  static const String backup = '/settings/backup';
  static const String parametresInfo = '/parametres/info';
  static const String parametresFinances = '/parametres/finances';
  static const String parametresCampagnes = '/parametres/campagnes';
  static const String campagneForm = '/parametres/campagne/form';
  
  static const String notifications = '/notifications';
  
  // V2: Nouvelles routes
  static const String clients = '/clients';
  static const String clientDetail = '/clients/detail';
  static const String clientAdd = '/clients/add';
  static const String clientEdit = '/clients/edit';
  
  static const String capital = '/capital';
  static const String partsSociales = '/capital/parts';
  static const String partSocialeAdd = '/capital/parts/add';
  
  static const String comptabilite = '/comptabilite';
  static const String grandLivre = '/comptabilite/grand-livre';
  static const String etatsFinanciers = '/comptabilite/etats';
  
  static const String social = '/social';
  static const String aidesSociales = '/social/aides';
  static const String aideSocialeAdd = '/social/aides/add';
  static const String aideSocialeDetail = '/social/aides/detail';
}
