import 'package:flutter/material.dart';

/// Container pour les formulaires avec largeur maximale et centrage
/// Améliore le design en limitant la largeur des champs
class FormContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const FormContainer({
    super.key,
    required this.child,
    this.maxWidth = 700,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: child,
        ),
      ),
    );
  }
}
