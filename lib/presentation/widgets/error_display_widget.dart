import 'package:flutter/material.dart';

/// Widget réutilisable pour afficher les erreurs de manière cohérente
class ErrorDisplayWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color? color;

  const ErrorDisplayWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null || errorMessage!.isEmpty) {
      return const SizedBox.shrink();
    }

    final errorColor = color ?? Colors.red.shade700;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: errorColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: TextStyle(
                    color: errorColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

