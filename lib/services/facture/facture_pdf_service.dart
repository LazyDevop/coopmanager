import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/adherent_model.dart';
import '../../data/models/facture_model.dart';
import '../../data/models/recette_model.dart';
import '../../data/models/vente_detail_model.dart';
import '../../data/models/vente_model.dart';
import '../document/pdf_engine.dart';
import '../document/pdf_utils.dart';

class FacturePdfService {
  /// Générer une facture PDF pour une vente.
  /// Retourne le chemin du fichier PDF généré.
  Future<String> generateFactureVente({
    required FactureModel facture,
    required AdherentModel adherent,
    required VenteModel vente,
    List<VenteDetailModel>? venteDetails,
  }) async {
    final baseFont = await PdfUtils.loadBaseFont();
    final boldFont = await PdfUtils.loadBoldFont();
    final italicFont = await PdfUtils.loadItalicFont();

    final engine = PdfEngine(
      baseFont: baseFont,
      boldFont: boldFont,
      italicFont: italicFont,
    );
    final settings = await PdfUtils.loadCooperativeSettings();
    final meta = await PdfUtils.loadDocumentMeta(
      facture.numero,
      facture.qrCodeHash ?? '',
    );

    final client = adherent.fullName.trim().isEmpty
        ? 'Adhérent #${adherent.id ?? ''}'
        : adherent.fullName;

    final data = FactureData(
      client: client,
      lignes: [
        FactureLigne(
          designation:
              'Vente cacao (Qté: ${vente.quantiteTotal.toStringAsFixed(2)} kg)',
          qte: 1,
          pu: vente.montantTotal,
        ),
      ],
    );

    final builder = FacturePdfBuilder(data);
    final pdfBytes = await engine.generate(
      document: builder,
      settings: settings,
      meta: meta,
    );

    final exportDir = await PdfUtils.getExportDirectory('factures');
    final safeNumero = facture.numero.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final fileName =
        'facture_vente_${safeNumero}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Générer une facture PDF pour une recette.
  /// Retourne le chemin du fichier PDF généré.
  Future<String> generateFactureRecette({
    required FactureModel facture,
    required AdherentModel adherent,
    required RecetteModel recette,
  }) async {
    final baseFont = await PdfUtils.loadBaseFont();
    final boldFont = await PdfUtils.loadBoldFont();
    final italicFont = await PdfUtils.loadItalicFont();

    final engine = PdfEngine(
      baseFont: baseFont,
      boldFont: boldFont,
      italicFont: italicFont,
    );
    final settings = await PdfUtils.loadCooperativeSettings();
    final meta = await PdfUtils.loadDocumentMeta(
      facture.numero,
      facture.qrCodeHash ?? '',
    );

    final client = adherent.fullName.trim().isEmpty
        ? 'Adhérent #${adherent.id ?? ''}'
        : adherent.fullName;

    final data = FactureData(
      client: client,
      lignes: [
        FactureLigne(
          designation: 'Recette #${recette.id ?? ''} (Net)',
          qte: 1,
          pu: recette.montantNet,
        ),
      ],
    );

    final builder = FacturePdfBuilder(data);
    final pdfBytes = await engine.generate(
      document: builder,
      settings: settings,
      meta: meta,
    );

    final exportDir = await PdfUtils.getExportDirectory('factures');
    final safeNumero = facture.numero.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final fileName =
        'facture_recette_${safeNumero}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Générer un bordereau PDF pour plusieurs recettes.
  /// Retourne le chemin du fichier PDF généré.
  Future<String> generateBordereauRecettes({
    required FactureModel facture,
    required AdherentModel adherent,
    required List<RecetteModel> recettes,
  }) async {
    final baseFont = await PdfUtils.loadBaseFont();
    final boldFont = await PdfUtils.loadBoldFont();
    final italicFont = await PdfUtils.loadItalicFont();

    final engine = PdfEngine(
      baseFont: baseFont,
      boldFont: boldFont,
      italicFont: italicFont,
    );
    final settings = await PdfUtils.loadCooperativeSettings();
    final meta = await PdfUtils.loadDocumentMeta(
      facture.numero,
      facture.qrCodeHash ?? '',
    );

    final builder = BordereauRecettesPdfBuilder(
      facture: facture,
      adherent: adherent,
      recettes: recettes,
    );

    final pdfBytes = await engine.generate(
      document: builder,
      settings: settings,
      meta: meta,
    );

    final exportDir = await PdfUtils.getExportDirectory('factures');
    final safeNumero = facture.numero.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final fileName =
        'bordereau_recettes_${safeNumero}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }
}

class BordereauRecettesPdfBuilder implements PdfDocumentBuilder {
  final FactureModel facture;
  final AdherentModel adherent;
  final List<RecetteModel> recettes;

  BordereauRecettesPdfBuilder({
    required this.facture,
    required this.adherent,
    required this.recettes,
  });

  @override
  String get title => 'BORDEREAU RECETTES ${facture.numero}';

  @override
  pw.Widget buildBody(pw.Context context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');
    final font =
        pw.Theme.of(context).defaultTextStyle.font ?? pw.Font.helvetica();

    final totalBrut = recettes.fold<double>(
      0.0,
      (sum, r) => sum + r.montantBrut,
    );
    final totalCommission = recettes.fold<double>(
      0.0,
      (sum, r) => sum + r.commissionAmount,
    );
    final totalNet = recettes.fold<double>(0.0, (sum, r) => sum + r.montantNet);

    final rows = recettes
        .map(
          (r) => <String>[
            dateFormat.format(r.dateRecette),
            numberFormat.format(r.montantBrut),
            numberFormat.format(r.commissionAmount),
            '${(r.commissionRate * 100).toStringAsFixed(2)}%',
            numberFormat.format(r.montantNet),
          ],
        )
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          'Adhérent: ${adherent.fullName} (${adherent.code})',
          style: pw.TextStyle(
            font: font,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Facture: ${facture.numero}',
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
        pw.Text(
          'Date: ${dateFormat.format(facture.dateFacture)}',
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
        pw.SizedBox(height: 12),
        PdfTableBuilder.build(
          headers: const ['Date', 'Brut', 'Commission', 'Taux', 'Net'],
          rows: rows,
          font: font,
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Total brut: ${numberFormat.format(totalBrut)}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
                pw.Text(
                  'Total commission: ${numberFormat.format(totalCommission)}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
                pw.Text(
                  'Total net: ${numberFormat.format(totalNet)}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
