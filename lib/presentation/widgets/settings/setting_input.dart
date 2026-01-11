import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget input pour les paramètres texte/nombre
class SettingInput extends StatelessWidget {
  final String label;
  final String? hint;
  final String? description;
  final String? value;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool required;
  final String? Function(String?)? validator;
  final int? maxLines;
  final IconData? prefixIcon;

  const SettingInput({
    super.key,
    required this.label,
    this.hint,
    this.description,
    this.value,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.required = false,
    this.validator,
    this.maxLines = 1,
    this.prefixIcon,
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
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          enabled: enabled,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
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

