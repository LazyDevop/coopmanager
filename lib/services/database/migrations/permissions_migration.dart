/// Migration pour le système de rôles et permissions
/// Version 22 - Gestion des rôles, permissions et vues UI

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PermissionsMigration {
  /// Migrer vers la version 22 - Système de rôles et permissions
  static Future<void> migrateToV22(Database db) async {
    try {
      print('🔄 Migration vers la version 22 (Système de rôles et permissions)...');

      // 1. Table roles
      await db.execute('''
        CREATE TABLE IF NOT EXISTS roles (
          id TEXT PRIMARY KEY,
          code TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          is_system INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 2. Table permissions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS permissions (
          id TEXT PRIMARY KEY,
          code TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          category TEXT NOT NULL,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 3. Table ui_views (vues/interfaces de l'application)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ui_views (
          id TEXT PRIMARY KEY,
          code TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          route TEXT NOT NULL,
          icon TEXT,
          category TEXT,
          requires_read INTEGER DEFAULT 1,
          requires_write INTEGER DEFAULT 0,
          parent_view_id TEXT,
          display_order INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (parent_view_id) REFERENCES ui_views(id) ON DELETE SET NULL
        )
      ''');

      // 4. Table role_permissions (liaison rôle-permission)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS role_permissions (
          id TEXT PRIMARY KEY,
          role_id TEXT NOT NULL,
          permission_id TEXT NOT NULL,
          granted INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
          FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
          UNIQUE (role_id, permission_id)
        )
      ''');

      // 5. Table role_ui_views (liaison rôle-vue UI)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS role_ui_views (
          id TEXT PRIMARY KEY,
          role_id TEXT NOT NULL,
          ui_view_id TEXT NOT NULL,
          can_read INTEGER DEFAULT 1,
          can_write INTEGER DEFAULT 0,
          can_delete INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
          FOREIGN KEY (ui_view_id) REFERENCES ui_views(id) ON DELETE CASCADE,
          UNIQUE (role_id, ui_view_id)
        )
      ''');

      // 6. Table user_roles (liaison utilisateur-rôle)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_roles (
          id TEXT PRIMARY KEY,
          user_id INTEGER NOT NULL,
          role_id TEXT NOT NULL,
          is_primary INTEGER DEFAULT 0,
          granted_at TEXT NOT NULL,
          granted_by INTEGER,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
          FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE SET NULL,
          UNIQUE (user_id, role_id)
        )
      ''');

      // Créer les index pour optimiser les performances
      await db.execute('CREATE INDEX IF NOT EXISTS idx_roles_code ON roles(code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_roles_active ON roles(is_active)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_permissions_code ON permissions(code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_permissions_category ON permissions(category)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ui_views_code ON ui_views(code)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ui_views_route ON ui_views(route)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ui_views_category ON ui_views(category)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_role_permissions_role ON role_permissions(role_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_role_permissions_permission ON role_permissions(permission_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_role_ui_views_role ON role_ui_views(role_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_role_ui_views_view ON role_ui_views(ui_view_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_user_roles_user ON user_roles(user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_user_roles_primary ON user_roles(user_id, is_primary)');

      // Insérer les rôles par défaut
      await _insertDefaultRoles(db);

      // Insérer les permissions par défaut
      await _insertDefaultPermissions(db);

      // Insérer les vues UI par défaut
      await _insertDefaultUIViews(db);

      // Configurer les permissions par défaut pour chaque rôle
      await _configureDefaultRolePermissions(db);

      print('✅ Migration vers la version 22 terminée avec succès');
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la migration vers la version 22: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Insérer les rôles par défaut
  static Future<void> _insertDefaultRoles(Database db) async {
    final roles = [
      {
        'id': 'role-admin',
        'code': 'admin',
        'name': 'Administrateur',
        'description': 'Accès complet à toutes les fonctionnalités',
        'is_system': 1,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'role-caissier',
        'code': 'caissier',
        'name': 'Caissier',
        'description': 'Gestion des paiements et recettes',
        'is_system': 1,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'role-magasinier',
        'code': 'magasinier',
        'name': 'Magasinier',
        'description': 'Gestion des dépôts et du stock',
        'is_system': 1,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'role-comptable',
        'code': 'comptable',
        'name': 'Comptable',
        'description': 'Gestion de la comptabilité',
        'is_system': 1,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'role-consultation',
        'code': 'consultation',
        'name': 'Consultation',
        'description': 'Accès en lecture seule',
        'is_system': 1,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final role in roles) {
      try {
        await db.insert('roles', role, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        print('⚠️ Erreur lors de l\'insertion du rôle ${role['code']}: $e');
      }
    }
  }

  /// Insérer les permissions par défaut
  static Future<void> _insertDefaultPermissions(Database db) async {
    final permissions = [
      // Permissions générales
      {'code': 'manage_users', 'name': 'Gérer les utilisateurs', 'category': 'system'},
      {'code': 'manage_roles', 'name': 'Gérer les rôles', 'category': 'system'},
      {'code': 'manage_settings', 'name': 'Gérer les paramètres', 'category': 'system'},
      {'code': 'view_reports', 'name': 'Voir les rapports', 'category': 'system'},
      
      // Permissions adhérents
      {'code': 'view_adherents', 'name': 'Voir les adhérents', 'category': 'adherents'},
      {'code': 'create_adherents', 'name': 'Créer des adhérents', 'category': 'adherents'},
      {'code': 'edit_adherents', 'name': 'Modifier les adhérents', 'category': 'adherents'},
      {'code': 'delete_adherents', 'name': 'Supprimer des adhérents', 'category': 'adherents'},
      
      // Permissions stock
      {'code': 'view_stock', 'name': 'Voir le stock', 'category': 'stock'},
      {'code': 'create_stock', 'name': 'Créer des dépôts', 'category': 'stock'},
      {'code': 'edit_stock', 'name': 'Modifier le stock', 'category': 'stock'},
      {'code': 'delete_stock', 'name': 'Supprimer du stock', 'category': 'stock'},
      
      // Permissions ventes
      {'code': 'view_ventes', 'name': 'Voir les ventes', 'category': 'ventes'},
      {'code': 'create_ventes', 'name': 'Créer des ventes', 'category': 'ventes'},
      {'code': 'edit_ventes', 'name': 'Modifier les ventes', 'category': 'ventes'},
      {'code': 'delete_ventes', 'name': 'Supprimer des ventes', 'category': 'ventes'},
      
      // Permissions recettes
      {'code': 'view_recettes', 'name': 'Voir les recettes', 'category': 'recettes'},
      {'code': 'create_recettes', 'name': 'Créer des recettes', 'category': 'recettes'},
      {'code': 'edit_recettes', 'name': 'Modifier les recettes', 'category': 'recettes'},
      
      // Permissions facturation
      {'code': 'view_factures', 'name': 'Voir les factures', 'category': 'facturation'},
      {'code': 'create_factures', 'name': 'Créer des factures', 'category': 'facturation'},
      {'code': 'edit_factures', 'name': 'Modifier les factures', 'category': 'facturation'},
      
      // Permissions paiements
      {'code': 'view_paiements', 'name': 'Voir les paiements', 'category': 'paiements'},
      {'code': 'create_paiements', 'name': 'Enregistrer des paiements', 'category': 'paiements'},
      {'code': 'edit_paiements', 'name': 'Modifier les paiements', 'category': 'paiements'},
      
      // Permissions comptabilité
      {'code': 'view_comptabilite', 'name': 'Voir la comptabilité', 'category': 'comptabilite'},
      {'code': 'create_comptabilite', 'name': 'Créer des écritures', 'category': 'comptabilite'},
      {'code': 'edit_comptabilite', 'name': 'Modifier la comptabilité', 'category': 'comptabilite'},
    ];

    for (final perm in permissions) {
      try {
        await db.insert('permissions', {
          'id': 'perm-${perm['code']}',
          'code': perm['code'],
          'name': perm['name'],
          'description': perm['name'],
          'category': perm['category'],
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        print('⚠️ Erreur lors de l\'insertion de la permission ${perm['code']}: $e');
      }
    }
  }

  /// Insérer les vues UI par défaut
  static Future<void> _insertDefaultUIViews(Database db) async {
    final views = [
      {'code': 'dashboard', 'name': 'Tableau de bord', 'route': '/dashboard', 'icon': 'dashboard', 'category': 'main', 'requires_read': 1, 'requires_write': 0, 'order': 1},
      {'code': 'adherents', 'name': 'Adhérents', 'route': '/adherents', 'icon': 'people', 'category': 'main', 'requires_read': 1, 'requires_write': 1, 'order': 2},
      {'code': 'stock', 'name': 'Stock', 'route': '/stock', 'icon': 'inventory', 'category': 'main', 'requires_read': 1, 'requires_write': 1, 'order': 3},
      {'code': 'ventes', 'name': 'Ventes', 'route': '/ventes', 'icon': 'shopping_cart', 'category': 'main', 'requires_read': 1, 'requires_write': 1, 'order': 4},
      {'code': 'recettes', 'name': 'Recettes', 'route': '/recettes', 'icon': 'payments', 'category': 'main', 'requires_read': 1, 'requires_write': 1, 'order': 5},
      {'code': 'factures', 'name': 'Factures', 'route': '/factures', 'icon': 'receipt', 'category': 'main', 'requires_read': 1, 'requires_write': 1, 'order': 6},
      {'code': 'paiements', 'name': 'Paiements', 'route': '/paiements', 'icon': 'credit_card', 'category': 'main', 'requires_read': 1, 'requires_write': 1, 'order': 7},
      {'code': 'comptabilite', 'name': 'Comptabilité', 'route': '/comptabilite', 'icon': 'account_balance', 'category': 'main', 'requires_read': 1, 'requires_write': 1, 'order': 8},
      {'code': 'settings', 'name': 'Paramétrage', 'route': '/settings/main', 'icon': 'settings', 'category': 'admin', 'requires_read': 1, 'requires_write': 1, 'order': 9},
      {'code': 'reports', 'name': 'Rapports', 'route': '/reports', 'icon': 'assessment', 'category': 'main', 'requires_read': 1, 'requires_write': 0, 'order': 10},
    ];

    for (final view in views) {
      try {
        await db.insert('ui_views', {
          'id': 'view-${view['code']}',
          'code': view['code'],
          'name': view['name'],
          'description': view['name'],
          'route': view['route'],
          'icon': view['icon'],
          'category': view['category'],
          'requires_read': view['requires_read'],
          'requires_write': view['requires_write'],
          'display_order': view['order'],
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        print('⚠️ Erreur lors de l\'insertion de la vue ${view['code']}: $e');
      }
    }
  }

  /// Configurer les permissions par défaut pour chaque rôle
  static Future<void> _configureDefaultRolePermissions(Database db) async {
    // Administrateur : toutes les permissions
    await _grantAllPermissionsToRole(db, 'role-admin');

    // Caissier : paiements, recettes, lecture ventes
    await _grantPermissionsToRole(db, 'role-caissier', [
      'view_adherents',
      'view_ventes',
      'view_recettes',
      'create_recettes',
      'view_paiements',
      'create_paiements',
      'edit_paiements',
      'view_factures',
    ]);

    // Magasinier : stock uniquement, pas de montants financiers
    await _grantPermissionsToRole(db, 'role-magasinier', [
      'view_adherents',
      'view_stock',
      'create_stock',
      'edit_stock',
    ]);

    // Comptable : comptabilité et facturation
    await _grantPermissionsToRole(db, 'role-comptable', [
      'view_adherents',
      'view_ventes',
      'view_recettes',
      'view_factures',
      'create_factures',
      'edit_factures',
      'view_comptabilite',
      'create_comptabilite',
      'edit_comptabilite',
      'view_reports',
    ]);

    // Consultation : lecture seule
    await _grantPermissionsToRole(db, 'role-consultation', [
      'view_adherents',
      'view_stock',
      'view_ventes',
      'view_recettes',
      'view_factures',
      'view_reports',
    ]);

    // Configurer les vues UI pour chaque rôle
    await _configureRoleUIViews(db);
  }

  /// Accorder toutes les permissions à un rôle
  static Future<void> _grantAllPermissionsToRole(Database db, String roleId) async {
    final permissions = await db.query('permissions', where: 'is_active = 1');
    for (final perm in permissions) {
      try {
        await db.insert('role_permissions', {
          'id': 'rp-${roleId}-${perm['id']}',
          'role_id': roleId,
          'permission_id': perm['id'] as String,
          'granted': 1,
          'created_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        // Ignorer les doublons
      }
    }
  }

  /// Accorder des permissions spécifiques à un rôle
  static Future<void> _grantPermissionsToRole(Database db, String roleId, List<String> permissionCodes) async {
    for (final code in permissionCodes) {
      try {
        final perm = await db.query('permissions', where: 'code = ?', whereArgs: [code], limit: 1);
        if (perm.isNotEmpty) {
          await db.insert('role_permissions', {
            'id': 'rp-${roleId}-${perm.first['id']}',
            'role_id': roleId,
            'permission_id': perm.first['id'] as String,
            'granted': 1,
            'created_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      } catch (e) {
        print('⚠️ Erreur lors de l\'attribution de la permission $code: $e');
      }
    }
  }

  /// Configurer les vues UI pour chaque rôle
  static Future<void> _configureRoleUIViews(Database db) async {
    // Administrateur : toutes les vues avec droits complets
    await _grantAllUIViewsToRole(db, 'role-admin', canRead: true, canWrite: true, canDelete: true);

    // Caissier : paiements, recettes, factures (lecture ventes)
    await _grantUIViewsToRole(db, 'role-caissier', [
      'dashboard',
      'adherents',
      'ventes',
      'recettes',
      'paiements',
      'factures',
    ], canRead: true, canWrite: true, canDelete: false);

    // Magasinier : stock uniquement
    await _grantUIViewsToRole(db, 'role-magasinier', [
      'dashboard',
      'adherents',
      'stock',
    ], canRead: true, canWrite: true, canDelete: false);

    // Comptable : comptabilité, facturation, rapports
    await _grantUIViewsToRole(db, 'role-comptable', [
      'dashboard',
      'adherents',
      'ventes',
      'recettes',
      'factures',
      'comptabilite',
      'reports',
    ], canRead: true, canWrite: true, canDelete: false);

    // Consultation : toutes les vues en lecture seule
    await _grantAllUIViewsToRole(db, 'role-consultation', canRead: true, canWrite: false, canDelete: false);
  }

  /// Accorder toutes les vues UI à un rôle
  static Future<void> _grantAllUIViewsToRole(Database db, String roleId, {required bool canRead, required bool canWrite, required bool canDelete}) async {
    final views = await db.query('ui_views', where: 'is_active = 1');
    for (final view in views) {
      try {
        await db.insert('role_ui_views', {
          'id': 'ruv-${roleId}-${view['id']}',
          'role_id': roleId,
          'ui_view_id': view['id'] as String,
          'can_read': canRead ? 1 : 0,
          'can_write': canWrite ? 1 : 0,
          'can_delete': canDelete ? 1 : 0,
          'created_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        // Ignorer les doublons
      }
    }
  }

  /// Accorder des vues UI spécifiques à un rôle
  static Future<void> _grantUIViewsToRole(Database db, String roleId, List<String> viewCodes, {required bool canRead, required bool canWrite, required bool canDelete}) async {
    for (final code in viewCodes) {
      try {
        final view = await db.query('ui_views', where: 'code = ?', whereArgs: [code], limit: 1);
        if (view.isNotEmpty) {
          await db.insert('role_ui_views', {
            'id': 'ruv-${roleId}-${view.first['id']}',
            'role_id': roleId,
            'ui_view_id': view.first['id'] as String,
            'can_read': canRead ? 1 : 0,
            'can_write': canWrite ? 1 : 0,
            'can_delete': canDelete ? 1 : 0,
            'created_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      } catch (e) {
        print('⚠️ Erreur lors de l\'attribution de la vue $code: $e');
      }
    }
  }
}

