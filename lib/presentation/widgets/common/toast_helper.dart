import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

class ToastHelper {
  /// Afficher un toast de succès
  static void showSuccess(String message, {BuildContext? context}) {
    if (context != null && context.mounted) {
      _showSnackBar(
        context,
        message,
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );
    }
  }

  /// Afficher un toast d'erreur
  static void showError(String message, {BuildContext? context}) {
    if (context != null && context.mounted) {
      _showSnackBar(
        context,
        message,
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }

  /// Afficher un toast d'avertissement
  static void showWarning(String message, {BuildContext? context}) {
    if (context != null && context.mounted) {
      _showSnackBar(
        context,
        message,
        backgroundColor: Colors.orange,
        icon: Icons.warning,
      );
    }
  }

  /// Afficher un toast d'information
  static void showInfo(String message, {BuildContext? context}) {
    if (context != null && context.mounted) {
      _showSnackBar(
        context,
        message,
        backgroundColor: Colors.blue,
        icon: Icons.info,
      );
    }
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Afficher un SnackBar avec action undo
  static void showSnackBarWithUndo(
    BuildContext context,
    String message, {
    VoidCallback? onUndo,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.grey[800],
        duration: duration,
        action: onUndo != null
            ? SnackBarAction(
                label: 'Annuler',
                textColor: Colors.blue[300],
                onPressed: onUndo,
              )
            : null,
      ),
    );
  }

  /// Afficher un SnackBar de succès
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Afficher un SnackBar d'erreur
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
