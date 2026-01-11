import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget input pour les nombres
class SettingNumberInput extends StatefulWidget {
  final String label;
  final String? description;
  final double? value;
  final ValueChanged<double?>? onChanged;
  final bool enabled;
  final bool required;
  final double? min;
  final double? max;
  final String? suffix;
  final int? decimals;

  const SettingNumberInput({
    super.key,
    required this.label,
    this.description,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.required = false,
    this.min,
    this.max,
    this.suffix,
    this.decimals = 2,
  });

  @override
  State<SettingNumberInput> createState() => _SettingNumberInputState();
}

class _SettingNumberInputState extends State<SettingNumberInput> {
  TextEditingController? _controller;
  FocusNode? _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controller?.dispose();
    _focusNode?.dispose();
    
    _controller = TextEditingController(
      text: widget.value != null 
          ? widget.value!.toStringAsFixed(widget.decimals ?? 2) 
          : '',
    );
    _focusNode = FocusNode();
    _focusNode!.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted && _focusNode != null) {
      setState(() {
        _hasFocus = _focusNode!.hasFocus;
      });
    }
  }

  @override
  void didUpdateWidget(SettingNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Réinitialiser les contrôleurs si nécessaire (hot reload)
    if (_controller == null || _focusNode == null) {
      _initializeControllers();
    }
    
    // Mettre à jour le contrôleur seulement si la valeur a changé depuis l'extérieur
    // et que le champ n'a pas le focus (l'utilisateur n'est pas en train de taper)
    if (oldWidget.value != widget.value && !_hasFocus && _controller != null) {
      final newText = widget.value != null 
          ? widget.value!.toStringAsFixed(widget.decimals ?? 2) 
          : '';
      // Ne mettre à jour que si le texte est différent
      if (_controller!.text != newText) {
        _controller!.text = newText;
        _controller!.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller!.text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _focusNode?.removeListener(_onFocusChange);
    _controller?.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label + (widget.required ? ' *' : ''),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.description != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (_controller == null || _focusNode == null)
          const SizedBox.shrink()
        else
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                // Permettre les nombres avec décimales
                final text = newValue.text;
                if (text.isEmpty) return newValue;
                
                // Vérifier le format des décimales
                final parts = text.split('.');
                if (parts.length > 2) return oldValue; // Plus d'un point
                
                if (parts.length == 2 && parts[1].length > (widget.decimals ?? 2)) {
                  return oldValue; // Trop de décimales
                }
                
                return newValue;
              }),
            ],
            style: TextStyle(
              color: widget.enabled 
                  ? theme.colorScheme.onSurface 
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              suffixText: widget.suffix,
              suffixStyle: TextStyle(
                color: widget.enabled 
                    ? theme.colorScheme.onSurface 
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: widget.enabled
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
            ),
            validator: (value) {
              if (widget.required && (value == null || value.isEmpty)) {
                return 'Ce champ est obligatoire';
              }
              if (value != null && value.isNotEmpty) {
                final numValue = double.tryParse(value);
                if (numValue == null) {
                  return 'Valeur invalide';
                }
                if (widget.min != null && numValue < widget.min!) {
                  return 'La valeur doit être supérieure ou égale à ${widget.min}';
                }
                if (widget.max != null && numValue > widget.max!) {
                  return 'La valeur doit être inférieure ou égale à ${widget.max}';
                }
              }
              return null;
            },
            onChanged: (value) {
              if (value.isEmpty) {
                widget.onChanged?.call(null);
              } else {
                final numValue = double.tryParse(value);
                if (numValue != null) {
                  widget.onChanged?.call(numValue);
                }
              }
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

