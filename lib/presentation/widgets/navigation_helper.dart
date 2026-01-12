import 'package:flutter/material.dart';

/// Helper pour la navigation qui utilise toujours le Navigator interne du MainAppShell
class NavigationHelper {
  /// Naviguer vers une route en utilisant le Navigator le plus proche (celui du MainAppShell)
  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context, rootNavigator: false).pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Remplacer la route actuelle par une nouvelle route
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return Navigator.of(context, rootNavigator: false).pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  /// Retourner à l'écran précédent
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context, rootNavigator: false).pop<T>(result);
  }

  /// Retourner à l'écran précédent si possible
  static bool maybePop<T extends Object?>(BuildContext context, [T? result]) {
    return Navigator.of(context, rootNavigator: false).maybePop<T>(result);
  }
}

