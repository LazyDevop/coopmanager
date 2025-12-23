import 'package:flutter/material.dart';

/// Wrapper qui intercepte les navigations et les route vers le Navigator interne
class NavigatorWrapper extends StatelessWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const NavigatorWrapper({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        // Intercepter toutes les routes et les gérer ici
        return MaterialPageRoute(
          builder: (context) => child,
          settings: settings,
        );
      },
      child: child,
    );
  }
}

