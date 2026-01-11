import 'package:flutter/material.dart';

/// Widget select pour les paramètres avec choix multiples
class SettingSelect<T> extends StatelessWidget {
  final String label;
  final String? description;
  final T? value;
  final List<SettingSelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  final bool enabled;
  final bool required;

  const SettingSelect({
    super.key,
    required this.label,
    this.description,
    this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: options.map((option) {
            return DropdownMenuItem<T>(
              value: option.value,
              child: Text(option.label),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: enabled
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class SettingSelectOption<T> {
  final T value;
  final String label;

  SettingSelectOption({
    required this.value,
    required this.label,
  });
}

