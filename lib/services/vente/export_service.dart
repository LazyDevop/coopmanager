import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/adherent_model.dart';
import '../../data/models/vente_detail_model.dart';
import '../../data/models/vente_model.dart';
import '../document/pdf_engine.dart';
import '../document/pdf_utils.dart';

class ExportService {
  /// Exporter une vente en PDF (Bordereau) avec le moteur modulaire ERP.
  /// Retourne `true` si le fichier a été généré et écrit.
  Future<bool> exportVente({
    required VenteModel vente,
    required List<VenteDetailModel> details,
    required List<AdherentModel> adherents,
  }) async {
    try {
      final baseFont = await PdfUtils.loadBaseFont();
      final boldFont = await PdfUtils.loadBoldFont();
      final italicFont = await PdfUtils.loadItalicFont();
      final pdfEngine = PdfEngine(baseFont: baseFont, boldFont: boldFont, italicFont: italicFont);
      final settings = await PdfUtils.loadCooperativeSettings();
      final meta = await PdfUtils.loadDocumentMeta(vente.id, '');

      final builder = BordereauPdfBuilder(
        vente: vente,
        details: details,
        adherents: adherents,
      );

      final pdfBytes = await pdfEngine.generate(document: builder, settings: settings, meta: meta);

      final exportDir = await PdfUtils.getExportDirectory('exports');
      final fileName = 'vente_${vente.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${exportDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Erreur lors de l\'export PDF: $e');
      return false;
    }
  }
}

class BordereauPdfBuilder implements PdfDocumentBuilder {
  final VenteModel vente;
  final List<VenteDetailModel> details;
  final List<AdherentModel> adherents;

  BordereauPdfBuilder({
    required this.vente,
    required this.details,
    required this.adherents,
  });

  @override
  String get title => 'BORDEREAU VENTE #${vente.id ?? ''}';

  @override
  pw.Widget buildBody(pw.Context context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');
    final font = pw.Theme.of(context).defaultTextStyle.font ?? pw.Font.helvetica();

    final rows = details.map((d) {
      final adherent = adherents.where((a) => a.id == d.adherentId).cast<AdherentModel?>().firstWhere(
            (a) => a != null,
            orElse: () => null,
          );
      return <String>[
        adherent?.fullName ?? 'Adhérent #${d.adherentId}',
        adherent?.code ?? '-',
        numberFormat.format(d.quantite),
        numberFormat.format(d.montant),
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          vente.isIndividuelle ? 'Vente individuelle' : 'Vente groupée',
          style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text('Date: ${dateFormat.format(vente.dateVente)}', style: pw.TextStyle(font: font, fontSize: 10)),
        pw.Text('Quantité totale: ${numberFormat.format(vente.quantiteTotal)} kg', style: pw.TextStyle(font: font, fontSize: 10)),
        pw.Text('Montant total: ${numberFormat.format(vente.montantTotal)} FCFA', style: pw.TextStyle(font: font, fontSize: 10)),
        pw.SizedBox(height: 12),
        if (rows.isNotEmpty)
          PdfTableBuilder.build(
            headers: const ['Adhérent', 'Code', 'Quantité (kg)', 'Montant (FCFA)'],
            rows: rows,
            font: font,
          )
        else
          pw.Text('Aucun détail disponible.', style: pw.TextStyle(font: font, fontSize: 10)),
      ],
    );
  }
}
