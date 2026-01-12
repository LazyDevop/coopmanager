import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../screens/login_screen.dart';
import '../../services/database/db_initializer.dart';
import 'main_app_shell.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialiser la base de données
    try {
      await DatabaseInitializer.database;
    } catch (e) {
      print('Erreur lors de l\'initialisation de la base de données: $e');
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        if (authViewModel.isAuthenticated && authViewModel.currentUser != null) {
          // Utiliser MainAppShell qui maintient la sidebar fixe
          // Utiliser une clé unique pour éviter les problèmes de GlobalKey dupliquée
          return const MainAppShell(key: ValueKey('main_app_shell'));
        } else {
          return const LoginScreen(key: ValueKey('login_screen'));
        }
      },
    );
  }
}

