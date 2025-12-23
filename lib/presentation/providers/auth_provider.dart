import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class AuthProvider extends ChangeNotifierProvider<AuthViewModel> {
  AuthProvider({super.key, required super.child}) 
      : super(create: (_) => AuthViewModel());
}

