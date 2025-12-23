import 'package:flutter/material.dart';

/// Widget pour afficher un loader local
/// 
/// Utilisé pour les chargements spécifiques à une section
/// (tableaux, formulaires, etc.)
class LocalLoader extends StatelessWidget {
  final String? message;

  const LocalLoader({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

