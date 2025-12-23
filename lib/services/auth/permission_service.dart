import '../../config/app_config.dart';
import '../../data/models/user_model.dart';

class PermissionService {
  /// Vérifier si un utilisateur a une permission spécifique
  static bool hasPermission(UserModel user, String permission) {
    switch (user.role) {
      case AppConfig.roleAdmin:
        return true; // Admin a tous les droits
      
      case AppConfig.roleGestionnaireStock:
        return _stockPermissions.contains(permission);
      
      case AppConfig.roleCaissier:
        return _caissierPermissions.contains(permission);
      
      case AppConfig.roleConsultation:
        return _consultationPermissions.contains(permission);
      
      case AppConfig.roleComptable:
        return _comptablePermissions.contains(permission);
      
      case AppConfig.roleResponsableSocial:
        return _responsableSocialPermissions.contains(permission);
      
      default:
        return false;
    }
  }

  /// Vérifier si un utilisateur peut accéder à un module
  static bool canAccessModule(UserModel user, String module) {
    switch (module) {
      case 'adherents':
        return hasPermission(user, 'view_adherents') || 
               hasPermission(user, 'manage_adherents');
      
      case 'stock':
        return hasPermission(user, 'view_stock') || 
               hasPermission(user, 'manage_stock');
      
      case 'ventes':
        return hasPermission(user, 'view_ventes') || 
               hasPermission(user, 'manage_ventes');
      
      case 'recettes':
        return hasPermission(user, 'view_recettes') || 
               hasPermission(user, 'manage_recettes');
      
      case 'factures':
        return hasPermission(user, 'view_factures') || 
               hasPermission(user, 'manage_factures');
      
      case 'users':
        return hasPermission(user, 'manage_users');
      
      case 'settings':
        return hasPermission(user, 'manage_settings');
      
      case 'clients':
        return hasPermission(user, 'view_clients') || 
               hasPermission(user, 'manage_clients');
      
      case 'capital':
        return hasPermission(user, 'view_capital') || 
               hasPermission(user, 'manage_capital');
      
      case 'comptabilite':
        return hasPermission(user, 'view_comptabilite') || 
               hasPermission(user, 'manage_comptabilite');
      
      case 'social':
        return hasPermission(user, 'view_social') || 
               hasPermission(user, 'manage_social');
      
      default:
        return false;
    }
  }

  /// Vérifier si un utilisateur peut créer
  static bool canCreate(UserModel user, String entity) {
    return hasPermission(user, 'create_$entity') || 
           hasPermission(user, 'manage_$entity');
  }

  /// Vérifier si un utilisateur peut modifier
  static bool canUpdate(UserModel user, String entity) {
    return hasPermission(user, 'update_$entity') || 
           hasPermission(user, 'manage_$entity');
  }

  /// Vérifier si un utilisateur peut supprimer
  static bool canDelete(UserModel user, String entity) {
    return hasPermission(user, 'delete_$entity') || 
           hasPermission(user, 'manage_$entity');
  }

  // Permissions pour Gestionnaire Stock
  static const List<String> _stockPermissions = [
    'view_adherents',
    'view_stock',
    'manage_stock',
    'create_stock',
    'update_stock',
    'view_ventes',
  ];

  // Permissions pour Caissier
  static const List<String> _caissierPermissions = [
    'view_adherents',
    'view_stock',
    'view_ventes',
    'manage_ventes',
    'create_ventes',
    'update_ventes',
    'view_recettes',
    'manage_recettes',
    'create_recettes',
    'view_factures',
    'manage_factures',
    'create_factures',
    'print_factures',
    'view_clients',
    'manage_clients',
  ];

  // Permissions pour Consultation
  static const List<String> _consultationPermissions = [
    'view_adherents',
    'view_stock',
    'view_ventes',
    'view_recettes',
    'view_factures',
    'view_clients',
    'view_capital',
    'view_comptabilite',
    'view_social',
  ];
  
  // Permissions pour Comptable
  static const List<String> _comptablePermissions = [
    'view_ventes',
    'view_recettes',
    'view_factures',
    'view_comptabilite',
    'manage_comptabilite',
    'view_clients',
  ];
  
  // Permissions pour Responsable Social
  static const List<String> _responsableSocialPermissions = [
    'view_adherents',
    'view_social',
    'manage_social',
    'create_aides_sociales',
    'approve_aides_sociales',
  ];

  /// Obtenir le nom lisible d'un rôle
  static String getRoleDisplayName(String role) {
    switch (role) {
      case AppConfig.roleAdmin:
        return 'Administrateur';
      case AppConfig.roleGestionnaireStock:
        return 'Gestionnaire Stock';
      case AppConfig.roleCaissier:
        return 'Caissier / Comptable';
      case AppConfig.roleConsultation:
        return 'Superviseur / Consultation';
      case AppConfig.roleComptable:
        return 'Comptable';
      case AppConfig.roleResponsableSocial:
        return 'Responsable Social';
      default:
        return role;
    }
  }
}
