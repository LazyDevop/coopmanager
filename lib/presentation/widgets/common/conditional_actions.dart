import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../../services/auth/permission_service.dart';

/// Widget pour afficher des boutons d'action conditionnels selon le rôle
class ConditionalActions extends StatelessWidget {
  final UserModel user;
  final String entity;
  final VoidCallback? onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final bool showAdd;
  final bool showEdit;
  final bool showDelete;
  final bool showView;

  const ConditionalActions({
    super.key,
    required this.user,
    required this.entity,
    this.onAdd,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.showAdd = true,
    this.showEdit = true,
    this.showDelete = true,
    this.showView = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showView && PermissionService.canUpdate(user, entity))
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: 'Voir',
            onPressed: onView,
            color: Colors.blue,
          ),
        if (showAdd && PermissionService.canCreate(user, entity))
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter',
            onPressed: onAdd,
            color: Colors.green,
          ),
        if (showEdit && PermissionService.canUpdate(user, entity))
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: onEdit,
            color: Colors.orange,
          ),
        if (showDelete && PermissionService.canDelete(user, entity))
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Supprimer',
            onPressed: onDelete,
            color: Colors.red,
          ),
      ],
    );
  }
}

/// Widget pour un bouton d'action conditionnel
class ConditionalButton extends StatelessWidget {
  final UserModel user;
  final String entity;
  final String action; // 'create', 'update', 'delete'
  final VoidCallback? onPressed;
  final Widget child;
  final bool enabled;

  const ConditionalButton({
    super.key,
    required this.user,
    required this.entity,
    required this.action,
    this.onPressed,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    bool canPerform = false;

    switch (action) {
      case 'create':
        canPerform = PermissionService.canCreate(user, entity);
        break;
      case 'update':
        canPerform = PermissionService.canUpdate(user, entity);
        break;
      case 'delete':
        canPerform = PermissionService.canDelete(user, entity);
        break;
    }

    if (!canPerform || !enabled) {
      return const SizedBox.shrink();
    }

    return child;
  }
}

/// Widget pour un FloatingActionButton conditionnel
class ConditionalFAB extends StatelessWidget {
  final UserModel user;
  final String entity;
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;

  const ConditionalFAB({
    super.key,
    required this.user,
    required this.entity,
    this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.canCreate(user, entity)) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip ?? 'Ajouter',
      child: Icon(icon),
    );
  }
}
