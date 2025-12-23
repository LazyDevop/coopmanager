import 'package:flutter/material.dart';
import '../../config/routes/routes.dart';
import 'main_layout.dart';

/// Wrapper pour envelopper les écrans avec le layout principal
class ScreenWrapper extends StatelessWidget {
  final Widget child;
  final String? currentRoute;

  const ScreenWrapper({
    super.key,
    required this.child,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final route = currentRoute ?? ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;
    
    return MainLayout(
      currentRoute: route,
      child: child,
    );
  }
}
