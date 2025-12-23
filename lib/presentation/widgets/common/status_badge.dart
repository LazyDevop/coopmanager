import 'package:flutter/material.dart';
import '../../../config/theme/app_theme.dart';

/// Badge de statut avec icône et couleur
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: isSmall ? 12 : 16,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badges prédéfinis pour les statuts courants
class StatusBadges {
  static Widget success(String label, {bool isSmall = false}) {
    return StatusBadge(
      label: label,
      color: AppTheme.successColor,
      icon: Icons.check_circle,
      isSmall: isSmall,
    );
  }

  static Widget error(String label, {bool isSmall = false}) {
    return StatusBadge(
      label: label,
      color: AppTheme.errorColor,
      icon: Icons.error,
      isSmall: isSmall,
    );
  }

  static Widget warning(String label, {bool isSmall = false}) {
    return StatusBadge(
      label: label,
      color: AppTheme.warningColor,
      icon: Icons.warning,
      isSmall: isSmall,
    );
  }

  static Widget info(String label, {bool isSmall = false}) {
    return StatusBadge(
      label: label,
      color: AppTheme.infoColor,
      icon: Icons.info,
      isSmall: isSmall,
    );
  }

  static Widget pending(String label, {bool isSmall = false}) {
    return StatusBadge(
      label: label,
      color: AppTheme.warningColor,
      icon: Icons.hourglass_empty,
      isSmall: isSmall,
    );
  }

  static Widget stockLow({bool isSmall = false}) {
    return StatusBadge(
      label: 'Stock faible',
      color: AppTheme.warningColor,
      icon: Icons.warning,
      isSmall: isSmall,
    );
  }

  static Widget stockCritical({bool isSmall = false}) {
    return StatusBadge(
      label: 'Stock critique',
      color: AppTheme.errorColor,
      icon: Icons.error,
      isSmall: isSmall,
    );
  }

  static Widget validated({bool isSmall = false}) {
    return StatusBadge(
      label: 'Validé',
      color: AppTheme.successColor,
      icon: Icons.check_circle,
      isSmall: isSmall,
    );
  }

  static Widget cancelled({bool isSmall = false}) {
    return StatusBadge(
      label: 'Annulé',
      color: AppTheme.errorColor,
      icon: Icons.cancel,
      isSmall: isSmall,
    );
  }
}
