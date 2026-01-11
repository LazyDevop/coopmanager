import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/routes.dart';
import '../../../data/models/user_model.dart';
import '../../../services/auth/permission_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../widgets/common/toast_helper.dart';

/// Header fixe de l'application Admin Dashboard
/// 
/// Contient :
/// - Barre de recherche globale
/// - Bouton de notifications avec badge
/// - Profil utilisateur avec menu déroulant
class AppHeader extends StatelessWidget {
  final UserModel user;
  final NotificationViewModel notificationViewModel;

  const AppHeader({
    super.key,
    required this.user,
    required this.notificationViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Barre de recherche globale
          Expanded(
            child: _buildSearchBar(context),
          ),
          const SizedBox(width: 16),
          // Bouton notifications
          _buildNotificationButton(context),
          const SizedBox(width: 16),
          // Profil utilisateur
          _buildUserProfile(context),
        ],
      ),
    );
  }

  /// Barre de recherche globale
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onSubmitted: (value) {
          // TODO: Implémenter la recherche globale
          if (value.isNotEmpty) {
            ToastHelper.showInfo('Recherche: $value');
          }
        },
      ),
    );
  }

  /// Bouton de notifications avec badge
  Widget _buildNotificationButton(BuildContext context) {
    return Consumer<NotificationViewModel>(
      builder: (context, viewModel, _) {
        final unreadCount = viewModel.unreadCount;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 28),
              onPressed: () {
                Navigator.of(context, rootNavigator: false).pushNamed(AppRoutes.notifications);
              },
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Profil utilisateur avec menu déroulant
  Widget _buildUserProfile(BuildContext context) {
    return PopupMenuButton<String>(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.brown.shade700,
            child: Text(
              user.prenom[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                PermissionService.getRoleDisplayName(user.role),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
      onSelected: (value) {
        if (value == 'logout') {
          _handleLogout(context);
        } else if (value == 'profile') {
          ToastHelper.showInfo('Profil utilisateur (à venir)');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email ?? 'Aucun email',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Déconnexion', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  /// Gère la déconnexion
  Future<void> _handleLogout(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.logout();
    // Ne pas naviguer manuellement, AuthWrapper gère automatiquement la transition
    // via le Consumer qui écoute les changements d'état
  }
}

