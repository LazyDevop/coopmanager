import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/settings/setting_history_model.dart';

/// Dialog pour afficher l'historique des modifications
class SettingHistoryDialog extends StatelessWidget {
  final List<SettingHistoryModel> history;
  final String category;
  final String? settingKey;

  const SettingHistoryDialog({
    super.key,
    required this.history,
    required this.category,
    this.settingKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.history, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Historique des modifications',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun historique disponible',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.edit,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              item.userName ?? 'Utilisateur #${item.userId}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                if (item.oldValue != null && item.newValue != null)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.errorContainer.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Ancien: ${item.oldValue}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onErrorContainer,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Nouveau: ${item.newValue}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (item.reason != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Raison: ${item.reason}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  dateFormat.format(item.changedAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

