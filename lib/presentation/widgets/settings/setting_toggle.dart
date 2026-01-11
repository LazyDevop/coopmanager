import 'package:flutter/material.dart';

/// Widget toggle pour les paramètres booléens
class SettingToggle extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const SettingToggle({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      enabled: enabled,
      title: Text(label),
      subtitle: description != null
          ? Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
      onTap: enabled ? () => onChanged(!value) : null,
    );
  }
}

