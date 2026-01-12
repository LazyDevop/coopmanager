import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/routes.dart';
import '../../../data/models/client_model.dart';
import '../../viewmodels/client_viewmodel.dart';

class ClientsImpayesScreen extends StatefulWidget {
  const ClientsImpayesScreen({super.key});

  @override
  State<ClientsImpayesScreen> createState() => _ClientsImpayesScreenState();
}

class _ClientsImpayesScreenState extends State<ClientsImpayesScreen> {
  final _minAmountController = TextEditingController();
  double? _minAmount;

  @override
  void dispose() {
    _minAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClientViewModel>();
    final numberFormat = NumberFormat('#,##0.00');

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
                  final navigator = Navigator.of(context, rootNavigator: false);
                  if (navigator.canPop()) {
                    navigator.pop();
                  } else {
                    navigator.pushNamed(AppRoutes.clients);
                  }
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Clients impayés',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Rafraîchir',
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() {}),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _minAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Montant minimum (FCFA)',
                    hintText: 'ex: 100000',
                    prefixIcon: Icon(Icons.filter_alt_outlined),
                  ),
                  onSubmitted: (_) => _applyMin(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _applyMin,
                icon: const Icon(Icons.search),
                label: const Text('Filtrer'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  _minAmountController.clear();
                  setState(() => _minAmount = null);
                },
                child: const Text('Réinitialiser'),
              ),
              const Spacer(),
              if (vm.errorMessage != null)
                Text(
                  vm.errorMessage!,
                  style: TextStyle(color: Colors.red[700]),
                ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<ClientModel>>(
            future: vm.getClientsImpayes(montantMinimum: _minAmount),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final clients = snapshot.data ?? [];

              if (clients.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun client impayé',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final c = clients[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                      title: Text('${c.raisonSociale} (${c.codeClient})'),
                      subtitle: Text(c.typeClientLabel),
                      trailing: Text(
                        '${numberFormat.format(c.soldeClient)} FCFA',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: c.id == null
                          ? null
                          : () {
                              Navigator.of(context, rootNavigator: false)
                                  .pushNamed(
                                    AppRoutes.clientDetail,
                                    arguments: c.id,
                                  )
                                  .then((_) => setState(() {}));
                            },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _applyMin() {
    final raw = _minAmountController.text.trim();
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    setState(() => _minAmount = parsed);
  }
}
