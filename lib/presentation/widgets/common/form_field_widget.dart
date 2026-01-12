import 'package:flutter/material.dart';
import '../../../config/theme/app_theme.dart';

/// Champ de formulaire amélioré avec validation et icônes
class FormFieldWidget extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final VoidCallback? onSuffixTap;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const FormFieldWidget({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixWidget,
    this.onSuffixTap,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixWidget ?? (suffixIcon != null
                    ? IconButton(
                        icon: Icon(suffixIcon),
                        onPressed: onSuffixTap,
                      )
                    : null),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
            ),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

/// Champ de formulaire avec indicateur de statut
class FormFieldWithStatus extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool enabled;
  final IconData? prefixIcon;
  final FormFieldStatus status;
  final String? statusMessage;
  final ValueChanged<String>? onChanged;

  const FormFieldWithStatus({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.enabled = true,
    this.prefixIcon,
    this.status = FormFieldStatus.normal,
    this.statusMessage,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData? statusIcon;

    switch (status) {
      case FormFieldStatus.success:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case FormFieldStatus.error:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.error;
        break;
      case FormFieldStatus.warning:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.warning;
        break;
      case FormFieldStatus.normal:
      default:
        statusColor = Colors.transparent;
        statusIcon = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldWidget(
          label: label,
          hint: hint,
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          enabled: enabled,
          prefixIcon: prefixIcon,
          suffixIcon: statusIcon,
          onChanged: onChanged,
        ),
        if (statusMessage != null && status != FormFieldStatus.normal) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

enum FormFieldStatus {
  normal,
  success,
  error,
  warning,
}
