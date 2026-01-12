/// Widget wrapper pour contrôler l'affichage selon les permissions
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/permission_provider.dart';

/// Widget qui affiche son enfant seulement si l'utilisateur a la permission
class PermissionWrapper extends StatelessWidget {
  final String permissionCode;
  final Widget child;
  final Widget? fallback;

  const PermissionWrapper({
    super.key,
    required this.permissionCode,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final permissionProvider = context.watch<PermissionProvider>();
    
    if (permissionProvider.hasPermission(permissionCode)) {
      return child;
    }
    
    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget qui affiche son enfant seulement si l'utilisateur peut accéder à la vue UI
class UIViewAccessWrapper extends StatelessWidget {
  final String uiViewCode;
  final Widget child;
  final Widget? fallback;

  const UIViewAccessWrapper({
    super.key,
    required this.uiViewCode,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<PermissionProvider>().canAccess(uiViewCode),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget qui affiche son enfant seulement si l'utilisateur peut écrire
class WritePermissionWrapper extends StatelessWidget {
  final String uiViewCode;
  final Widget child;
  final Widget? fallback;

  const WritePermissionWrapper({
    super.key,
    required this.uiViewCode,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<PermissionProvider>().canWrite(uiViewCode),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget qui affiche son enfant seulement si l'utilisateur peut supprimer
class DeletePermissionWrapper extends StatelessWidget {
  final String uiViewCode;
  final Widget child;
  final Widget? fallback;

  const DeletePermissionWrapper({
    super.key,
    required this.uiViewCode,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<PermissionProvider>().canDelete(uiViewCode),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Helper pour créer des boutons avec permissions
class PermissionButton {
  /// Créer un bouton "Créer" avec vérification de permission
  static Widget createButton({
    required BuildContext context,
    required String uiViewCode,
    required VoidCallback onPressed,
    required String label,
    IconData? icon,
  }) {
    return WritePermissionWrapper(
      uiViewCode: uiViewCode,
      fallback: const SizedBox.shrink(),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const Icon(Icons.add),
        label: Text(label),
      ),
    );
  }

  /// Créer un bouton "Modifier" avec vérification de permission
  static Widget editButton({
    required BuildContext context,
    required String uiViewCode,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return WritePermissionWrapper(
      uiViewCode: uiViewCode,
      fallback: const SizedBox.shrink(),
      child: IconButton(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const Icon(Icons.edit),
        tooltip: 'Modifier',
      ),
    );
  }

  /// Créer un bouton "Supprimer" avec vérification de permission
  static Widget deleteButton({
    required BuildContext context,
    required String uiViewCode,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return DeletePermissionWrapper(
      uiViewCode: uiViewCode,
      fallback: const SizedBox.shrink(),
      child: IconButton(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const Icon(Icons.delete),
        tooltip: 'Supprimer',
        color: Colors.red,
      ),
    );
  }
}

