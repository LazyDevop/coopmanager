/// Script utilitaire pour forcer la migration du module Social
/// À utiliser si les tables sociales n'existent pas après redémarrage

import '../db_initializer.dart';
import 'social_module_migration.dart';

class ForceSocialMigration {
  /// Forcer la création des tables sociales (utilitaire de dépannage)
  static Future<bool> forceCreateSocialTables() async {
    try {
      print('🔄 Forçage de la création des tables sociales...');
      final db = await DatabaseInitializer.database;
      
      // Vérifier d'abord si les tables existent
      final existingTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('social_aide_types', 'social_aides', 'social_remboursements', 'social_aide_history')",
      );
      
      if (existingTables.length == 4) {
        print('✅ Toutes les tables sociales existent déjà');
        return true;
      }
      
      print('⚠️ Tables manquantes détectées. Création en cours...');
      await SocialModuleMigration.createSocialTables(db);
      
      // Vérifier à nouveau
      final verification = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('social_aide_types', 'social_aides', 'social_remboursements', 'social_aide_history')",
      );
      
      if (verification.length == 4) {
        print('✅ Tables sociales créées avec succès');
        return true;
      } else {
        print('❌ Échec: Seulement ${verification.length}/4 tables créées');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Erreur lors du forçage de la migration: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
}

