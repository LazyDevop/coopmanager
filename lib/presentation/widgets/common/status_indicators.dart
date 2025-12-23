import 'package:flutter/material.dart';

/// Widget pour afficher un indicateur de statut avec icône
class StatusIndicator extends StatelessWidget {
  final String status;
  final IconData icon;
  final Color color;
  final String? label;

  const StatusIndicator({
    super.key,
    required this.status,
    required this.icon,
    required this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label!,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widgets prédéfinis pour les statuts courants
class StatusIndicators {
  static Widget stockLow() {
    return const StatusIndicator(
      status: 'low',
      icon: Icons.warning,
      color: Colors.red,
      label: 'Stock faible',
    );
  }

  static Widget stockOk() {
    return const StatusIndicator(
      status: 'ok',
      icon: Icons.check_circle,
      color: Colors.green,
      label: 'Stock OK',
    );
  }

  static Widget venteValidee() {
    return const StatusIndicator(
      status: 'validated',
      icon: Icons.check_circle,
      color: Colors.green,
      label: 'Validée',
    );
  }

  static Widget recetteCalculee() {
    return const StatusIndicator(
      status: 'calculated',
      icon: Icons.attach_money,
      color: Colors.green,
      label: 'Calculée',
    );
  }

  static Widget depotEnAttente() {
    return const StatusIndicator(
      status: 'pending',
      icon: Icons.hourglass_empty,
      color: Colors.orange,
      label: 'En attente',
    );
  }

  static Widget depotValide() {
    return const StatusIndicator(
      status: 'validated',
      icon: Icons.check_circle,
      color: Colors.green,
      label: 'Validé',
    );
  }
}
