import '../document_generator_service.dart';
import '../../../data/models/document/document_model.dart';
import 'package:pdf/widgets.dart' as pw;

/// Exemple d'utilisation du DocumentGeneratorService pour générer une facture
class FactureDocumentExample {
  final DocumentGeneratorService _documentService;

  FactureDocumentExample({DocumentGeneratorService? documentService})
    : _documentService = documentService ?? DocumentGeneratorService();

  /// Générer une facture de vente
  Future<DocumentModel> generateFactureVente({
    required String factureReference,
    required int cooperativeId,
    required int generatedBy,
    required Map<String, dynamic> factureData,
  }) async {
    return await _documentService.generateDocument(
      documentType: DocumentType.factureVente,
      documentReference: factureReference,
      cooperativeId: cooperativeId,
      generatedBy: generatedBy,
      documentTitle: 'FACTURE DE VENTE',
      buildContent: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Informations client
            _buildSection(
              title: 'Informations client',
              content: [
                _buildInfoRow('Nom', factureData['client_nom'] ?? ''),
                _buildInfoRow('Adresse', factureData['client_adresse'] ?? ''),
                _buildInfoRow(
                  'Téléphone',
                  factureData['client_telephone'] ?? '',
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            // Détails de la facture
            _buildSection(
              title: 'Détails de la facture',
              content: [
                _buildInfoRow('Référence', factureReference),
                _buildInfoRow('Date', factureData['date'] ?? ''),
                _buildInfoRow(
                  'Montant total',
                  '${factureData['montant_total']} FCFA',
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            // Tableau des articles
            if (factureData['articles'] != null)
              _buildArticlesTable(factureData['articles'] as List),
          ],
        );
      },
      contentData: factureData,
      additionalMetadata: {
        'facture_id': factureData['facture_id'],
        'vente_id': factureData['vente_id'],
      },
    );
  }

  pw.Widget _buildSection({
    required String title,
    required List<pw.Widget> content,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...content,
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildArticlesTable(List<dynamic> articles) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Article', isHeader: true),
            _buildTableCell('Quantité', isHeader: true),
            _buildTableCell('Prix unit.', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Lignes
        ...articles.map(
          (article) => pw.TableRow(
            children: [
              _buildTableCell(article['nom'] ?? ''),
              _buildTableCell('${article['quantite']}'),
              _buildTableCell('${article['prix']} FCFA'),
              _buildTableCell('${article['total']} FCFA'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
