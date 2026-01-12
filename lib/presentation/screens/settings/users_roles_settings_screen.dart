import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../widgets/settings/setting_section_card.dart';
import '../../../services/auth/permission_service.dart';
import '../../../data/models/user_model.dart';
import '../../../config/app_config.dart';
import 'user_form_screen.dart';

class UsersRolesSettingsScreen extends StatefulWidget {
  const UsersRolesSettingsScreen({super.key});

  @override
  State<UsersRolesSettingsScreen> createState() => _UsersRolesSettingsScreenState();
}

class _UsersRolesSettingsScreenState extends State<UsersRolesSettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final userViewModel = context.read<UserViewModel>();
    await userViewModel.loadUsers(includeInactive: _showInactive);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
          // Barre de recherche et filtres
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un utilisateur...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _loadUsers();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        _loadUsers();
                      } else {
                        context.read<UserViewModel>().searchUsers(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Inactifs'),
                  selected: _showInactive,
                  onSelected: (selected) {
                    setState(() {
                      _showInactive = selected;
                    });
                    _loadUsers();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Liste des utilisateurs
          Expanded(
            child: Consumer<UserViewModel>(
              builder: (context, userViewModel, _) {
                if (userViewModel.isLoading && userViewModel.users.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userViewModel.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          userViewModel.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            userViewModel.clearError();
                            _loadUsers();
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (userViewModel.users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun utilisateur trouvé',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showInactive
                              ? 'Aucun utilisateur inactif'
                              : 'Commencez par créer un nouvel utilisateur',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: userViewModel.users.length,
                    itemBuilder: (context, index) {
                      final user = userViewModel.users[index];
                      return _buildUserCard(context, user, userViewModel);
                    },
                  ),
                );
              },
            ),
          ),
        ],
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user, UserViewModel userViewModel) {
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    final canEdit = currentUser?.id != user.id; // Ne pas permettre l'auto-modification

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green.shade100 : Colors.grey.shade300,
          child: Icon(
            Icons.person,
            color: user.isActive ? Colors.green.shade700 : Colors.grey.shade600,
          ),
        ),
        title: Text(
          user.fullName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: user.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    PermissionService.getRoleDisplayName(user.role),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                  labelStyle: TextStyle(color: _getRoleColor(user.role)),
                ),
                if (!user.isActive) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text(
                      'Inactif',
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.red.shade100,
                    labelStyle: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ],
            ),
            if (user.email != null) ...[
              const SizedBox(height: 4),
              Text('📧 ${user.email}'),
            ],
            if (user.phone != null) ...[
              const SizedBox(height: 4),
              Text('📱 ${user.phone}'),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (currentUser?.id == null) return;

            switch (value) {
              case 'edit':
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserFormScreen(user: user),
                  ),
                );
                _loadUsers();
                break;
              case 'toggle':
                final success = await userViewModel.toggleUserStatus(
                  user.id!,
                  !user.isActive,
                  currentUser!.id!,
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        user.isActive
                            ? 'Utilisateur désactivé'
                            : 'Utilisateur activé',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                break;
              case 'delete':
                // Vérifier les permissions de suppression
                if (!PermissionService.canDeleteUser(currentUser!, user)) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          user.role == AppConfig.roleSuperAdmin
                              ? 'Vous ne pouvez pas supprimer un Super Administrateur'
                              : 'Vous n\'avez pas les permissions pour supprimer cet utilisateur',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  break;
                }
                
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmer la suppression'),
                    content: Text(
                      'Êtes-vous sûr de vouloir supprimer l\'utilisateur "${user.fullName}" ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final success = await userViewModel.deleteUser(
                    user.id!,
                    currentUser.id!,
                  );
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Utilisateur supprimé'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (mounted && userViewModel.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(userViewModel.errorMessage!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                break;
            }
          },
          itemBuilder: (context) => [
            if (canEdit)
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    user.isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'Désactiver' : 'Activer'),
                ],
              ),
            ),
            if (canEdit)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case AppConfig.roleAdmin:
        return Colors.purple;
      case AppConfig.roleGestionnaireStock:
        return Colors.orange;
      case AppConfig.roleCaissier:
        return Colors.blue;
      case AppConfig.roleConsultation:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showAddUserDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UserFormScreen(),
      ),
    ).then((_) => _loadUsers());
  }
}
