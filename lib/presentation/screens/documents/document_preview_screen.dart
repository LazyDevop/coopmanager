import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../providers/document_provider.dart';
import '../../../data/models/document/document_model.dart';
import 'package:intl/intl.dart';

/// Écran de prévisualisation et gestion d'un document PDF
class DocumentPreviewScreen extends StatelessWidget {
  final DocumentModel document;

  const DocumentPreviewScreen({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document: ${document.reference}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadDocument(context),
            tooltip: 'Télécharger',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printDocument(context),
            tooltip: 'Imprimer',
          ),
          IconButton(
            icon: const Icon(Icons.verified_user),
            onPressed: () => _verifyDocument(context),
            tooltip: 'Vérifier',
          ),
        ],
      ),
      body: Column(
        children: [
          // Informations du document
          _buildDocumentInfo(context),
          const Divider(),
          // Aperçu PDF
          Expanded(
            child: _buildPdfPreview(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentInfo(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getDocumentIcon(document.type),
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getDocumentTypeLabel(document.type),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Référence', document.reference),
          _buildInfoRow('Type', document.type),
          _buildInfoRow(
            'Généré le',
            dateFormat.format(document.generatedAt),
          ),
          if (document.isVerified) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.verified,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Document vérifié',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hash: ${document.hash.substring(0, 16)}...',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview(BuildContext context) {
    if (document.filePath == null) {
      return const Center(
        child: Text('Aucun fichier PDF disponible'),
      );
    }

    final file = File(document.filePath!);

    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text('Aucune donnée disponible'),
          );
        }

        // Utiliser Pdfx pour l'aperçu
        return PdfViewPinch.data(
          snapshot.data!,
          onDocumentError: (error) {
            return Center(
              child: Text('Erreur lors du chargement du PDF: $error'),
            );
          },
        );
      },
    );
  }

  Future<void> _downloadDocument(BuildContext context) async {
    if (document.filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun fichier disponible')),
      );
      return;
    }

    try {
      final file = File(document.filePath!);
      final bytes = await file.readAsBytes();

      // Utiliser file_picker pour permettre à l'utilisateur de choisir l'emplacement
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le document',
        fileName: '${document.reference}.pdf',
        bytes: bytes,
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document enregistré: $result'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du téléchargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printDocument(BuildContext context) async {
    if (document.filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun fichier disponible')),
      );
      return;
    }

    try {
      final file = File(document.filePath!);
      final bytes = await file.readAsBytes();

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'impression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyDocument(BuildContext context) async {
    final provider = context.read<DocumentProvider>();
    
    // TODO: Récupérer l'ID de l'utilisateur actuel depuis AuthViewModel
    // final authViewModel = context.read<AuthViewModel>();
    // final userId = authViewModel.currentUser?.id ?? 1;
    final userId = 1; // À remplacer par l'ID réel

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vérifier le document'),
        content: const Text(
          'Voulez-vous marquer ce document comme vérifié ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Vérifier'),
          ),
        ],
      ),
    );

    if (confirmed == true && document.id != null) {
      final success = await provider.verifyDocument(
        document.id!,
        userId,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document vérifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  IconData _getDocumentIcon(String type) {
    switch (type) {
      case 'FACTURE_VENTE':
      case 'FACTURE_RECETTE':
        return Icons.receipt;
      case 'RECU_DEPOT':
      case 'RECU_PAIEMENT_ADHERENT':
      case 'RECU_PAIEMENT_CLIENT':
        return Icons.payment;
      case 'BORDEREAU_RECETTE':
        return Icons.description;
      case 'JOURNAL_CAISSE':
        return Icons.account_balance_wallet;
      case 'ETAT_COMPTE_ADHERENT':
        return Icons.account_circle;
      case 'ETAT_CAPITAL_SOCIAL':
        return Icons.account_balance;
      case 'FICHE_ACTIONNAIRE':
        return Icons.person;
      case 'RAPPORT_SOCIAL':
        return Icons.people;
      default:
        return Icons.description;
    }
  }

  String _getDocumentTypeLabel(String type) {
    switch (type) {
      case 'FACTURE_VENTE':
        return 'Facture de vente';
      case 'FACTURE_RECETTE':
        return 'Facture de recette';
      case 'RECU_DEPOT':
        return 'Reçu de dépôt';
      case 'RECU_PAIEMENT_ADHERENT':
        return 'Reçu de paiement adhérent';
      case 'RECU_PAIEMENT_CLIENT':
        return 'Reçu de paiement client';
      case 'BORDEREAU_RECETTE':
        return 'Bordereau de recette';
      case 'JOURNAL_CAISSE':
        return 'Journal de caisse';
      case 'ETAT_COMPTE_ADHERENT':
        return 'État de compte adhérent';
      case 'ETAT_CAPITAL_SOCIAL':
        return 'État du capital social';
      case 'FICHE_ACTIONNAIRE':
        return 'Fiche actionnaire';
      case 'RAPPORT_SOCIAL':
        return 'Rapport social';
      default:
        return type;
    }
  }
}

