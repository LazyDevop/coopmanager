// Moteur PDF modulaire pour CoopManager (Flutter + dart_pdf)
// Architecture professionnelle, extensible, Unicode, QR, A4

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/settings/cooperative_settings_model.dart';
import '../../data/models/settings/document_settings_model.dart';
import 'pdf_template_engine.dart';

// --- INTERFACE COMMUNE ---
abstract class PdfDocumentBuilder {
  String get title;
  pw.Widget buildBody(pw.Context context);
}

// --- CLASSE CENTRALE ---
class PdfEngine {
  final pw.Font baseFont;
  final pw.Font boldFont;
  final pw.Font italicFont;
  final PdfTemplateEngine _templateEngine;

  PdfEngine({
    required this.baseFont,
    required this.boldFont,
    required this.italicFont,
    PdfTemplateEngine? templateEngine,
  }) : _templateEngine = templateEngine ?? const PdfTemplateEngine();

  Future<Uint8List> generate({
    required PdfDocumentBuilder document,
    required CooperativeSettingsModel settings,
    required DocumentMeta meta,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          italic: italicFont,
        ),
        header: _templateEngine.buildHeader(
          settings,
          documentTitle: document.title,
          logoBytes: meta.logoBytes,
        ),
        footer: _templateEngine.buildFooter(
          settings,
          documentSettings: meta.documentSettings,
          documentReference: meta.referenceDocument,
          qrData: meta.qrData,
          generatedAt: meta.generatedAt,
        ),
        build: (context) => [document.buildBody(context)],
      ),
    );
    return pdf.save();
  }
}

// --- MODULE TABLE (exemple) ---
class PdfTableBuilder {
  static pw.Widget build({
    required List<String> headers,
    required List<List<String>> rows,
    required pw.Font font,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
      children: [
        pw.TableRow(
          children: headers.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(h, style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
          )).toList(),
        ),
        ...rows.map((row) => pw.TableRow(
          children: row.map((cell) => pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(cell, style: pw.TextStyle(font: font)),
          )).toList(),
        )),
      ],
    );
  }
}

// --- EXEMPLE DE BUILDER DOCUMENT ---
class FacturePdfBuilder implements PdfDocumentBuilder {
  final FactureData data;
  FacturePdfBuilder(this.data);
  @override
  String get title => 'FACTURE';
  @override
  pw.Widget buildBody(pw.Context context) {
    final font = pw.Theme.of(context).defaultTextStyle.font ?? pw.Font.helvetica();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text('Client: ${data.client}', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 8),
        PdfTableBuilder.build(
          headers: ['Désignation', 'Qté', 'PU', 'Total'],
          rows: data.lignes.map((l) => [l.designation, l.qte.toString(), l.pu.toStringAsFixed(0), l.total.toStringAsFixed(0)]).toList(),
          font: font,
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('Total: ${data.total.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

// --- EXEMPLE DE BUILDER DOCUMENT ---
class RecuDepotPdfBuilder implements PdfDocumentBuilder {
  final RecuDepotData data;
  RecuDepotPdfBuilder(this.data);
  @override
  String get title => 'REÇU DE DÉPÔT';
  @override
  pw.Widget buildBody(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text('Déposant: ${data.deposant}', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 8),
        pw.Text('Montant: ${data.montant.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Date: ${data.date}', style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }
}

// --- MÉTADONNÉES DOCUMENT ---
class DocumentMeta {
  final Uint8List? logoBytes;
  final DateTime generatedAt;
  final String referenceDocument;
  final Map<String, dynamic>? qrData;
  final DocumentSettingsModel documentSettings;

  DocumentMeta({
    this.logoBytes,
    required this.generatedAt,
    required this.referenceDocument,
    required this.documentSettings,
    this.qrData,
  });
}

class FactureData {
  final String client;
  final List<FactureLigne> lignes;
  double get total => lignes.fold(0, (sum, l) => sum + l.total);
  FactureData({required this.client, required this.lignes});
}
class FactureLigne {
  final String designation;
  final int qte;
  final double pu;
  double get total => qte * pu;
  FactureLigne({required this.designation, required this.qte, required this.pu});
}
class RecuDepotData {
  final String deposant;
  final double montant;
  final String date;
  RecuDepotData({required this.deposant, required this.montant, required this.date});
}

// --- EXEMPLE D'APPEL DU MOTEUR ---
/*
Future<void> exemplePdf() async {
  final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
  final italicFontData = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');
  final baseFont = pw.Font.ttf(fontData);
  final boldFont = pw.Font.ttf(boldFontData);
  final italicFont = pw.Font.ttf(italicFontData);

  final engine = PdfEngine(baseFont: baseFont, boldFont: boldFont, italicFont: italicFont);
  final settings = CooperativeSettings(
    raisonSociale: 'COOP EST',
    sigle: 'COOPEST',
    adresse: '01 BP 123 Abidjan',
    telephone: '+225 01 23 45 67',
    email: 'contact@coopest.ci',
    region: 'Sud-Comoé',
    departement: 'Aboisso',
    mentionLegale: 'Document généré par CoopManager',
    numeroAgrement: 'AGR-2025-001',
  );
  final meta = DocumentMeta(
    logoBytes: await loadLogoBytes(),
    dateGeneration: '2026-01-15 10:30',
    referenceDocument: 'FAC-2025-0012',
    qrData: {
      'type': 'FACTURE',
      'reference': 'FAC-2025-0012',
      'cooperative': 'COOP EST',
      'hash': 'SHA256',
      'date': '2026-01-15',
    },
  );
  final facture = FacturePdfBuilder(FactureData(
    client: 'M. KOUASSI',
    lignes: [
      FactureLigne(designation: 'Cacao', qte: 10, pu: 1200),
      FactureLigne(designation: 'Frais', qte: 1, pu: 500),
    ],
  ));
  final pdfBytes = await engine.generate(document: facture, settings: settings, meta: meta);
  // Enregistrer ou afficher le PDF
}
*/
