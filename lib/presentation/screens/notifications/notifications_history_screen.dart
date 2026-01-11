import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/notification_model.dart';
import '../../../services/notification/export_notification_service.dart';

class NotificationsHistoryScreen extends StatefulWidget {
  const NotificationsHistoryScreen({super.key});

  @override
  State<NotificationsHistoryScreen> createState() => _NotificationsHistoryScreenState();
}

class _NotificationsHistoryScreenState extends State<NotificationsHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le MainAppShell gère déjà le layout avec sidebar, donc on retourne seulement le contenu
    return Column(
      children: [
        // Barre d'actions en haut (remplace l'AppBar)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text(
                'Historique des Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const Spacer(),
              // Actions
              Consumer<NotificationViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.unreadCount > 0) {
                    return IconButton(
                      icon: Badge(
                        label: Text('${viewModel.unreadCount}'),
                        child: const Icon(Icons.notifications),
                      ),
                      tooltip: '${viewModel.unreadCount} notification(s) non lue(s)',
                      onPressed: () {
                        viewModel.setFilterIsRead(false);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 18),
                        SizedBox(width: 8),
                        Text('Tout marquer comme lu'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_read',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, size: 18),
                        SizedBox(width: 8),
                        Text('Supprimer les lues'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('Exporter'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Contenu
        Expanded(
          child: Consumer<NotificationViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading && viewModel.notifications.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        viewModel.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => viewModel.loadNotifications(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  _buildFiltersAndSearch(context, viewModel),
                  Expanded(
                    child: viewModel.filteredNotifications.isEmpty
                        ? _buildEmptyState(context)
                        : _buildNotificationsList(context, viewModel),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersAndSearch(BuildContext context, NotificationViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher dans les notifications...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.searchNotifications('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              viewModel.searchNotifications(value);
            },
          ),
          const SizedBox(height: 12),
          // Filtres
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: viewModel.filterType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                    DropdownMenuItem<String?>(value: 'info', child: Text('Information')),
                    DropdownMenuItem<String?>(value: 'success', child: Text('Succès')),
                    DropdownMenuItem<String?>(value: 'warning', child: Text('Avertissement')),
                    DropdownMenuItem<String?>(value: 'error', child: Text('Erreur')),
                    DropdownMenuItem<String?>(value: 'critical', child: Text('Critique')),
                  ],
                  onChanged: (value) {
                    viewModel.setFilterType(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: viewModel.filterModule,
                  decoration: InputDecoration(
                    labelText: 'Module',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                    DropdownMenuItem<String?>(value: 'stock', child: Text('Stock')),
                    DropdownMenuItem<String?>(value: 'ventes', child: Text('Ventes')),
                    DropdownMenuItem<String?>(value: 'recettes', child: Text('Recettes')),
                    DropdownMenuItem<String?>(value: 'factures', child: Text('Factures')),
                    DropdownMenuItem<String?>(value: 'auth', child: Text('Authentification')),
                    DropdownMenuItem<String?>(value: 'settings', child: Text('Paramètres')),
                  ],
                  onChanged: (value) {
                    viewModel.setFilterModule(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<bool?>(
                  value: viewModel.filterIsRead,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem<bool?>(value: null, child: Text('Tous')),
                    DropdownMenuItem<bool?>(value: false, child: Text('Non lues')),
                    DropdownMenuItem<bool?>(value: true, child: Text('Lues')),
                  ],
                  onChanged: (value) {
                    viewModel.setFilterIsRead(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.filter_alt_off),
                tooltip: 'Réinitialiser les filtres',
                onPressed: () {
                  viewModel.resetFilters();
                  _searchController.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucune notification trouvée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context, NotificationViewModel viewModel) {
    final notifications = viewModel.filteredNotifications;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: notification.isUnread ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: notification.isUnread
                ? BorderSide(color: _getTypeColor(notification.type), width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: SizedBox(
              width: 40,
              child: CircleAvatar(
                backgroundColor: _getTypeColor(notification.type).withOpacity(0.2),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    notification.titre,
                    style: TextStyle(
                      fontWeight: notification.isUnread
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (notification.isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(notification.message),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(notification.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    if (notification.module != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notification.module!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleNotificationAction(
                context,
                value,
                notification,
                viewModel,
              ),
              itemBuilder: (context) => [
                if (notification.isUnread)
                  const PopupMenuItem(
                    value: 'read',
                    child: Row(
                      children: [
                        Icon(Icons.done, size: 18),
                        SizedBox(width: 8),
                        Text('Marquer comme lu'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              if (notification.isUnread) {
                viewModel.markAsRead(notification.id!);
              }
              // TODO: Naviguer vers l'entité associée si entityId existe
            },
          ),
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'error':
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'error':
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
      default:
        return Icons.info;
    }
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    String action,
  ) async {
    final viewModel = context.read<NotificationViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    switch (action) {
      case 'mark_all_read':
        final success = await viewModel.markAllAsRead(
          userId: currentUser?.id,
        );
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Toutes les notifications ont été marquées comme lues'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        break;
      case 'delete_read':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer les notifications lues'),
            content: const Text(
              'Voulez-vous supprimer toutes les notifications lues ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final success = await viewModel.deleteReadNotifications(
            userId: currentUser?.id,
          );
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications lues supprimées'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
        break;
      case 'export':
        await _exportNotifications(context, viewModel);
        break;
    }
  }

  Future<void> _handleNotificationAction(
    BuildContext context,
    String action,
    NotificationModel notification,
    NotificationViewModel viewModel,
  ) async {
    switch (action) {
      case 'read':
        await viewModel.markAsRead(notification.id!);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer la notification'),
            content: const Text('Voulez-vous supprimer cette notification ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final success = await viewModel.deleteNotification(notification.id!);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification supprimée'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
        break;
    }
  }

  Future<void> _exportNotifications(
    BuildContext context,
    NotificationViewModel viewModel,
  ) async {
    try {
      final exportService = ExportNotificationService();
      final success = await exportService.exportNotifications(
        notifications: viewModel.notifications,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications exportées avec succès'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: ${e.toString()}'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
