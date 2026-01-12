import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/routes.dart';
import '../../../data/models/client_model.dart';
import '../../viewmodels/client_viewmodel.dart';

class ClientDetailScreen extends StatefulWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientViewModel>().loadClientById(widget.clientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00');

    return Consumer<ClientViewModel>(
      builder: (context, vm, child) {
        final client = vm.selectedClient;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      final navigator = Navigator.of(
                        context,
                        rootNavigator: false,
                      );
                      if (navigator.canPop()) {
                        navigator.pop();
                      } else {
                        navigator.pushNamed(AppRoutes.clients);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Détail Client',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Modifier',
                    icon: const Icon(Icons.edit),
                    onPressed: client == null
                        ? null
                        : () {
                            Navigator.of(
                              context,
                              rootNavigator: false,
                            ).pushNamed(
                              AppRoutes.clientEdit,
                              arguments: client.id,
                            );
                          },
                  ),
                ],
              ),
            ),
            Expanded(
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vm.errorMessage != null
                  ? Center(child: Text(vm.errorMessage!))
                  : client == null
                  ? const Center(child: Text('Client introuvable'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCard(
                            title: client.raisonSociale,
                            subtitle:
                                'Code: ${client.codeClient} • ${client.typeClientLabel}',
                            trailing: _buildStatutChip(client.statut),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoGrid([
                            _kv(
                              'Solde',
                              '${numberFormat.format(client.soldeClient)} FCFA',
                            ),
                            _kv('Statut', client.statutLabel),
                            _kv('Téléphone', client.telephone ?? '-'),
                            _kv('Email', client.email ?? '-'),
                            _kv('Ville', client.ville ?? '-'),
                            _kv('Pays', client.pays ?? '-'),
                          ]),
                          const SizedBox(height: 12),
                          _buildInfoGrid([
                            _kv('NRC', client.nrc ?? '-'),
                            _kv('IFU', client.ifu ?? '-'),
                            _kv(
                              'Plafond crédit',
                              client.plafondCredit == null
                                  ? 'Illimité'
                                  : '${numberFormat.format(client.plafondCredit)} FCFA',
                            ),
                            _kv('Responsable', client.nomResponsable ?? '-'),
                          ]),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<MapEntry<String, String>> entries) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        runSpacing: 12,
        spacing: 24,
        children: [
          for (final e in entries)
            SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  MapEntry<String, String> _kv(String k, String v) => MapEntry(k, v);

  Widget _buildStatutChip(String statut) {
    Color bg;
    Color fg;

    switch (statut) {
      case ClientModel.statutActif:
        bg = Colors.green.withOpacity(0.12);
        fg = Colors.green[800]!;
        break;
      case ClientModel.statutSuspendu:
        bg = Colors.orange.withOpacity(0.12);
        fg = Colors.orange[800]!;
        break;
      case ClientModel.statutBloque:
        bg = Colors.red.withOpacity(0.12);
        fg = Colors.red[800]!;
        break;
      default:
        bg = Colors.grey.withOpacity(0.12);
        fg = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statut,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
