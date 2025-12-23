import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Overlay de chargement global pour l'application
/// 
/// Affiche un indicateur de chargement par-dessus tout le contenu
/// lorsque l'application est en cours de chargement.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        // Afficher le loader uniquement si l'authentification est en cours
        if (authViewModel.isLoading) {
          return Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

