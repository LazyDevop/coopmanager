import '../../config/app_config.dart';
import '../../data/models/user_model.dart';

class PermissionService {
  /// Vérifier si un utilisateur a une permission spécifique
  static bool hasPermission(UserModel user, String permission) {
    switch (user.role) {
      case AppConfig.roleSuperAdmin:
        return true; // SuperAdmin a tous les droits absolus
      
      case AppConfig.roleAdmin:
        // Admin a tous les droits sauf gestion SuperAdmin
        if (permission.startsWith('manage_super_admin') || 
            permission.startsWith('delete_super_admin')) {
          return false;
        }
        return true;
      
      case AppConfig.roleComptable:
        return _comptablePermissions.contains(permission);
      
      case AppConfig.roleCaissier:
        return _caissierPermissions.contains(permission);
      
      case AppConfig.roleMagasinier:
      case AppConfig.roleGestionnaireStock: // Compatibilité
        return _magasinierPermissions.contains(permission);
      
      // Rôles obsolètes (pour compatibilité)
      case AppConfig.roleConsultation:
        return _consultationPermissions.contains(permission);
      
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

  // ========== SUPER ADMINISTRATEUR ==========
  // Toutes les permissions (géré dans hasPermission avec return true)
  
  // ========== ADMINISTRATEUR ==========
  // Toutes les permissions sauf gestion SuperAdmin (géré dans hasPermission)
  
  // ========== COMPTABLE ==========
  static const List<String> _comptablePermissions = [
    // Lecture complète
    'view_ventes',
    'view_recettes',
    'view_paiements',
    'view_factures',
    'view_clients',
    'view_adherents', // Pour consultation
    'view_capital',
    'view_comptabilite',
    
    // Gestion des journaux
    'manage_journal_caisse',
    'manage_journal_ventes',
    'manage_journal_charges',
    
    // Génération de rapports
    'generate_etats_financiers',
    'generate_rapports_mensuels',
    'export_pdf',
    'export_excel',
    
    // Consultation uniquement
    'view_stock', // Lecture seule pour contexte
  ];
  
  // ========== CAISSIER ==========
  static const List<String> _caissierPermissions = [
    // VENTES - Le caissier peut vendre
    'view_ventes',
    'manage_ventes',
    'create_ventes',
    'update_ventes',
    
    // FACTURATION - Le caissier peut facturer et imprimer
    'view_factures',
    'manage_factures',
    'create_factures',
    'update_factures',
    'generate_factures',
    'print_factures',
    
    // Enregistrement des paiements
    'create_paiements_adherents',
    'create_paiements_clients',
    'manage_paiements',
    
    // Consultation
    'view_recettes',
    // NOTE: Le caissier ne peut PAS voir ni manipuler les adhérents
    // Il peut seulement sélectionner un adhérent lors d'une vente via la liste déroulante
    'view_clients', // Pour identifier les clients
    'view_stock', // Lecture seule pour vérifier les disponibilités
    
    // Génération de documents
    'generate_recus_paiement',
    'print_recus',
    
    // Journal de caisse (écriture)
    'manage_journal_caisse',
    'create_journal_caisse',
    'update_journal_caisse',
  ];
  
  // ========== MAGASINIER ==========
  static const List<String> _magasinierPermissions = [
    // Enregistrement des dépôts
    'create_depots_cacao',
    'manage_depots',
    'update_depots',
    
    // Mouvements de stock
    'create_mouvements_stock',
    'manage_mouvements_stock',
    'update_mouvements_stock',
    
    // Consultation
    'view_stock',
    'view_adherents', // Lecture seule pour identifier les producteurs
    
    // Impression
    'print_recus_depot',
    'generate_recus_depot',
  ];
  
  // ========== RÔLES OBSOLÈTES (pour compatibilité) ==========
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
      case AppConfig.roleSuperAdmin:
        return 'Super Administrateur';
      case AppConfig.roleAdmin:
        return 'Administrateur';
      case AppConfig.roleComptable:
        return 'Comptable';
      case AppConfig.roleCaissier:
        return 'Caissier';
      case AppConfig.roleMagasinier:
      case AppConfig.roleGestionnaireStock: // Compatibilité
        return 'Magasinier';
      case AppConfig.roleConsultation:
        return 'Superviseur / Consultation';
      case AppConfig.roleResponsableSocial:
        return 'Responsable Social';
      default:
        return role;
    }
  }
  
  /// Vérifier si un utilisateur est SuperAdmin
  static bool isSuperAdmin(UserModel user) {
    return user.role == AppConfig.roleSuperAdmin;
  }
  
  /// Vérifier si un utilisateur peut gérer les SuperAdmins
  static bool canManageSuperAdmin(UserModel user) {
    return user.role == AppConfig.roleSuperAdmin;
  }
  
  /// Vérifier si un utilisateur peut supprimer un autre utilisateur
  static bool canDeleteUser(UserModel currentUser, UserModel targetUser) {
    // SuperAdmin peut supprimer tout le monde sauf lui-même
    if (isSuperAdmin(currentUser)) {
      return currentUser.id != targetUser.id;
    }
    // Admin peut supprimer tout le monde sauf SuperAdmin et lui-même
    if (currentUser.role == AppConfig.roleAdmin) {
      return targetUser.role != AppConfig.roleSuperAdmin && 
             currentUser.id != targetUser.id;
    }
    return false;
  }
}
