import 'package:flutter/material.dart';

/// Extension pour faciliter la navigation avec le Navigator interne
extension NavigationExtension on BuildContext {
  /// Naviguer vers une route en utilisant le Navigator interne (garde la sidebar)
  Future<T?> navigateTo<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(this, rootNavigator: false).pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Remplacer la route actuelle par une nouvelle route (garde la sidebar)
  Future<T?> navigateReplace<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return Navigator.of(this, rootNavigator: false).pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  /// Retourner à l'écran précédent
  void navigateBack<T extends Object?>([T? result]) {
    Navigator.of(this, rootNavigator: false).pop<T>(result);
  }
}

