import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/document_model.dart';
import '../../viewmodels/document_viewmodel.dart';
import '../../../config/routes/routes.dart';

class DocumentsListScreen extends StatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  State<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends State<DocumentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;
  String? _selectedStatut;

  // Helper functions to get shade colors from Color
  Color _getShade50(Color color) {
    return color.withOpacity(0.1);
  }

  Color _getShade700(Color color) {
    return Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1.0,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentViewModel>().loadDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête
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
              const Text(
                'Documents Officiels',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Vérifier un document',
                onPressed: () {
                  Navigator.of(context, rootNavigator: false).pushNamed(
                    AppRoutes.documentVerification,
                  );
                },
              ),
            ],
          ),
        ),
        // Filtres et recherche
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            children: [
              // Barre de recherche
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par numéro, adhérent...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<DocumentViewModel>().searchDocuments('');
                            setState(() {});
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
                  setState(() {});
                  context.read<DocumentViewModel>().searchDocuments(value);
                },
              ),
              const SizedBox(height: 12),
              // Filtres
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Type de document',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tous')),
                        DropdownMenuItem(
                          value: DocumentModel.typeRecuDepot,
                          child: const Text('Reçu de dépôt'),
                        ),
                        DropdownMenuItem(
                          value: DocumentModel.typeBordereauPesee,
                          child: const Text('Bordereau de pesée'),
                        ),
                        DropdownMenuItem(
                          value: DocumentModel.typeFactureClient,
                          child: const Text('Facture client'),
                        ),
                        DropdownMenuItem(
                          value: DocumentModel.typeBonLivraison,
                          child: const Text('Bon de livraison'),
                        ),
                        DropdownMenuItem(
                          value: DocumentModel.typeBordereauPaiement,
                          child: const Text('Bordereau de paiement'),
                        ),
                        DropdownMenuItem(
                          value: DocumentModel.typeRecuPaiement,
                          child: const Text('Reçu de paiement'),
                        ),
                        DropdownMenuItem(
                          value: DocumentModel.typeEtatCompte,
                          child: const Text('État de compte'),
                        ),
                        DropdownMenuItem(
                          value: DocumentModel.typeEtatParticipation,
                          child: const Text('État de participation'),
                        ),
                        DropdownMenuItem(
                          value: DocumentModel.typeJournalVentes,
                          child: const Text('Journal des ventes'),
                        ),
                        DropdownMenuItem(
                          value: DocumentModel.typeJournalCaisse,
                          child: const Text('Journal de caisse'),
                        ),
                        DropdownMenuItem(
                          value: DocumentModel.typeJournalPaiements,
                          child: const Text('Journal des paiements'),
                        ),
                        DropdownMenuItem(
                          value: DocumentModel.typeRapportSocial,
                          child: const Text('Rapport social'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                        context.read<DocumentViewModel>().setFilterType(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatut,
                      decoration: InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tous')),
                        DropdownMenuItem(value: 'brouillon', child: Text('Brouillon')),
                        DropdownMenuItem(value: 'genere', child: Text('Généré')),
                        DropdownMenuItem(value: 'annule', child: Text('Annulé')),
                        DropdownMenuItem(value: 'regularise', child: Text('Régularisé')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatut = value;
                        });
                        context.read<DocumentViewModel>().setFilterStatut(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedType = null;
                        _selectedStatut = null;
                        _searchController.clear();
                      });
                      context.read<DocumentViewModel>().resetFilters();
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Réinitialiser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Liste des documents
        Expanded(
          child: Consumer<DocumentViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading && viewModel.documents.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(viewModel.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => viewModel.loadDocuments(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }

              if (viewModel.filteredDocuments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun document trouvé',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => viewModel.loadDocuments(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.filteredDocuments.length,
                  itemBuilder: (context, index) {
                    final document = viewModel.filteredDocuments[index];
                    return _buildDocumentCard(context, document);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(BuildContext context, DocumentModel document) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context, rootNavigator: false).pushNamed(
            AppRoutes.documentDetail,
            arguments: document.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône type
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getShade50(document.typeColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  document.typeIcon,
                  color: _getShade700(document.typeColor),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.typeLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatutBadge(document.statut),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'N° ${document.numero}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(document.dateGeneration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  if (document.qrCodeHash != null)
                    IconButton(
                      icon: const Icon(Icons.qr_code),
                      tooltip: 'Vérifier QR Code',
                      onPressed: () {
                        Navigator.of(context, rootNavigator: false).pushNamed(
                          AppRoutes.documentVerification,
                          arguments: document.id,
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: 'Voir le PDF',
                    onPressed: () {
                      Navigator.of(context, rootNavigator: false).pushNamed(
                        AppRoutes.documentDetail,
                        arguments: document.id,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatutBadge(String statut) {
    Color color;
    String label;
    
    switch (statut) {
      case 'genere':
        color = Colors.green;
        label = 'Généré';
        break;
      case 'annule':
        color = Colors.red;
        label = 'Annulé';
        break;
      case 'regularise':
        color = Colors.orange;
        label = 'Régularisé';
        break;
      default:
        color = Colors.grey;
        label = 'Brouillon';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getShade50(color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getShade700(color),
        ),
      ),
    );
  }
}

