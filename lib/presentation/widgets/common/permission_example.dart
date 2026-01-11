/// Exemples d'utilisation des widgets de permission
/// 
/// Ce fichier montre comment utiliser les wrappers de permission
/// dans vos écrans pour contrôler l'affichage des éléments UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/permission_provider.dart';
import 'permission_wrapper.dart';

/// Exemple d'écran avec contrôle des permissions
class ExampleScreenWithPermissions extends StatelessWidget {
  const ExampleScreenWithPermissions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemple avec Permissions'),
      ),
      body: Column(
        children: [
          // Exemple 1 : Bouton "Créer" avec permission d'écriture
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: WritePermissionWrapper(
              uiViewCode: 'adherents',
              child: ElevatedButton.icon(
                onPressed: () {
                  // Action de création
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvel adhérent'),
              ),
              fallback: const SizedBox.shrink(), // Masquer si pas de permission
            ),
          ),
          
          // Exemple 2 : Liste avec boutons conditionnels
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Élément $index'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouton modifier (affiché seulement si permission)
                      WritePermissionWrapper(
                        uiViewCode: 'adherents',
                        child: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // Action de modification
                          },
                        ),
                      ),
                      // Bouton supprimer (affiché seulement si permission)
                      DeletePermissionWrapper(
                        uiViewCode: 'adherents',
                        child: IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () {
                            // Action de suppression
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Exemple 3 : FloatingActionButton avec permission
      floatingActionButton: WritePermissionWrapper(
        uiViewCode: 'adherents',
        child: FloatingActionButton(
          onPressed: () {
            // Action de création
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/// Exemple d'utilisation des helpers PermissionButton
class ExampleWithPermissionHelpers extends StatelessWidget {
  const ExampleWithPermissionHelpers({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemple avec Helpers'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bouton créer avec helper
            PermissionButton.createButton(
              context: context,
              uiViewCode: 'ventes',
              onPressed: () {
                // Créer une vente
              },
              label: 'Nouvelle vente',
              icon: Icons.add_shopping_cart,
            ),
            
            const SizedBox(height: 16),
            
            // Bouton modifier avec helper
            PermissionButton.editButton(
              context: context,
              uiViewCode: 'ventes',
              onPressed: () {
                // Modifier une vente
              },
            ),
            
            const SizedBox(height: 16),
            
            // Bouton supprimer avec helper
            PermissionButton.deleteButton(
              context: context,
              uiViewCode: 'ventes',
              onPressed: () {
                // Supprimer une vente
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Exemple de vérification programmatique des permissions
class ExampleProgrammaticCheck extends StatelessWidget {
  const ExampleProgrammaticCheck({super.key});

  Future<void> _handleAction(BuildContext context) async {
    final permissionProvider = context.read<PermissionProvider>();
    
    // Vérifier si l'utilisateur peut écrire
    final canWrite = await permissionProvider.canWrite('adherents');
    
    if (!canWrite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous n\'avez pas la permission d\'effectuer cette action'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Exécuter l'action
    // ...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification programmatique'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _handleAction(context),
          child: const Text('Action avec vérification'),
        ),
      ),
    );
  }
}

