import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/vente_model.dart';
import '../../data/models/vente_detail_model.dart';
import '../../data/models/adherent_model.dart';

class ExportService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _numberFormat = NumberFormat('#,##0.00');

  /// Exporter une vente en PDF
  Future<bool> exportVente({
    required VenteModel vente,
    required List<VenteDetailModel> details,
    required List<AdherentModel> adherents,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              _buildHeader(vente),
              pw.SizedBox(height: 20),
              _buildVenteInfo(vente),
              if (vente.isGroupee) ...[
                pw.SizedBox(height: 20),
                _buildDetailsSection(details, adherents),
              ],
              pw.SizedBox(height: 20),
              _buildFooter(),
            ];
          },
        ),
      );

      // Sauvegarder le PDF
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final fileName = 'vente_${vente.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${exportDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Ouvrir le dialogue d'impression/aperçu
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => await pdf.save(),
      );

      return true;
    } catch (e) {
      print('Erreur lors de l\'export PDF: $e');
      return false;
    }
  }

  pw.Widget _buildHeader(VenteModel vente) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BORDEREAU DE VENTE',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'N° ${vente.id}',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'Date d\'édition: ${_dateFormat.format(DateTime.now())}',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildVenteInfo(VenteModel vente) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Informations de la vente',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow('Type', vente.isIndividuelle ? 'Individuelle' : 'Groupée'),
          _buildInfoRow('Date', _dateFormat.format(vente.dateVente)),
          _buildInfoRow('Quantité totale', '${_numberFormat.format(vente.quantiteTotal)} kg'),
          _buildInfoRow('Prix unitaire', '${_numberFormat.format(vente.prixUnitaire)} FCFA/kg'),
          _buildInfoRow(
            'Montant total',
            '${_numberFormat.format(vente.montantTotal)} FCFA',
            isBold: true,
          ),
          if (vente.acheteur != null)
            _buildInfoRow('Acheteur', vente.acheteur!),
          if (vente.modePaiement != null)
            _buildInfoRow('Mode de paiement', _getModePaiementLabel(vente.modePaiement!)),
          if (vente.notes != null)
            _buildInfoRow('Observations', vente.notes!),
          _buildInfoRow('Statut', vente.isValide ? 'Valide' : 'Annulée'),
        ],
      ),
    );
  }

  pw.Widget _buildDetailsSection(
    List<VenteDetailModel> details,
    List<AdherentModel> adherents,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Détails par adhérent',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Adhérent', isHeader: true),
                _buildTableCell('Code', isHeader: true),
                _buildTableCell('Quantité (kg)', isHeader: true),
                _buildTableCell('Montant (FCFA)', isHeader: true),
              ],
            ),
            ...details.map((detail) {
              final adherent = adherents
                  .where((a) => a.id == detail.adherentId)
                  .firstOrNull;

              return pw.TableRow(
                children: [
                  _buildTableCell(adherent?.fullName ?? 'N/A'),
                  _buildTableCell(adherent?.code ?? 'N/A'),
                  _buildTableCell(_numberFormat.format(detail.quantite)),
                  _buildTableCell(_numberFormat.format(detail.montant)),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        'Document généré le ${_dateFormat.format(DateTime.now())} par CoopManager',
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey700,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _getModePaiementLabel(String mode) {
    switch (mode) {
      case 'especes':
        return 'Espèces';
      case 'mobile_money':
        return 'Mobile Money';
      case 'virement':
        return 'Virement';
      default:
        return mode;
    }
  }
}
