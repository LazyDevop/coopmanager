import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../../data/models/user_model.dart';
import '../../../config/app_config.dart';
import '../../../services/auth/permission_service.dart';
import '../../../services/auth/user_service.dart';

class UserFormScreen extends StatefulWidget {
  final UserModel? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedRole = AppConfig.roleAdmin;
  bool _obscurePassword = true;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _usernameController.text = widget.user!.username;
      _nomController.text = widget.user!.nom;
      _prenomController.text = widget.user!.prenom;
      _emailController.text = widget.user!.email ?? '';
      _phoneController.text = widget.user!.phone ?? '';
      _selectedRole = widget.user!.role;
      _changePassword = false;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final userViewModel = context.read<UserViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Utilisateur non connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = widget.user == null
        ? await userViewModel.createUser(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            nom: _nomController.text.trim(),
            prenom: _prenomController.text.trim(),
            role: _selectedRole,
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            createdBy: currentUser.id!,
          )
        : await userViewModel.updateUser(
            id: widget.user!.id!,
            nom: _nomController.text.trim(),
            prenom: _prenomController.text.trim(),
            role: _selectedRole,
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            updatedBy: currentUser.id!,
          );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.user == null
                ? 'Utilisateur créé avec succès'
                : 'Utilisateur modifié avec succès',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted && userViewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userViewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    
    // Obtenir les rôles disponibles selon l'utilisateur connecté
    final userService = UserService();
    final availableRoles = userService.getAvailableRolesForUser(currentUser);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'Nouvel utilisateur' : 'Modifier utilisateur'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom d'utilisateur
              TextFormField(
                controller: _usernameController,
                enabled: widget.user == null, // Ne pas permettre la modification du username
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom d\'utilisateur est requis';
                  }
                  if (value.length < 3) {
                    return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mot de passe (seulement pour nouveau utilisateur ou si changement demandé)
              if (widget.user == null || _changePassword) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: widget.user == null
                        ? 'Mot de passe *'
                        : 'Nouveau mot de passe *',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le mot de passe est requis';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ] else ...[
                CheckboxListTile(
                  title: const Text('Changer le mot de passe'),
                  value: _changePassword,
                  onChanged: (value) {
                    setState(() {
                      _changePassword = value ?? false;
                      if (!_changePassword) {
                        _passwordController.clear();
                      }
                    });
                  },
                ),
              ],

              // Prénom
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom *',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le prénom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nom
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Téléphone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Rôle
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle *',
                  prefixIcon: Icon(Icons.verified_user),
                  border: OutlineInputBorder(),
                ),
                items: availableRoles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(PermissionService.getRoleDisplayName(role)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // Bouton Enregistrer
              ElevatedButton(
                onPressed: userViewModel.isLoading ? null : _saveUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: userViewModel.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.user == null ? 'Créer' : 'Enregistrer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

