// Classe de génération de template PDF professionnel pour CoopManager
// Utilise la librairie pdf (dart_pdf)
// Support Unicode, QR Code, en-tête/pied dynamiques, compatible A4

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';

class PdfTemplateService {
  final pw.Font baseFont;
  final pw.Font boldFont;
  final pw.Font italicFont;

  PdfTemplateService({required this.baseFont, required this.boldFont, required this.italicFont});

  // Génère l'en-tête du document
  pw.Widget buildHeader({
    required Uint8List? logoBytes,
    required String raisonSociale,
    required String sigle,
    required String adresse,
    required String telephone,
    required String email,
    required String region,
    required String departement,
    required String titreDocument,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoBytes != null)
              pw.Container(
                width: 60,
                height: 60,
                child: pw.Image(pw.MemoryImage(logoBytes)),
              ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(raisonSociale, style: pw.TextStyle(font: boldFont, fontSize: 16)),
                  pw.Text(sigle, style: pw.TextStyle(font: baseFont, fontSize: 12)),
                  pw.Text(adresse, style: pw.TextStyle(font: baseFont, fontSize: 10)),
                  pw.Text('Tél: $telephone', style: pw.TextStyle(font: baseFont, fontSize: 10)),
                  pw.Text('Email: $email', style: pw.TextStyle(font: baseFont, fontSize: 10)),
                  pw.Text('Région: $region / Département: $departement', style: pw.TextStyle(font: baseFont, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1),
        pw.Center(
          child: pw.Text(
            titreDocument,
            style: pw.TextStyle(font: boldFont, fontSize: 15),
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  // Génère le pied de page du document
  pw.Widget buildFooter({
    required String mentionLegale,
    required String numeroAgrement,
    required String dateGeneration,
    required String referenceDocument,
    required Map<String, dynamic> qrData,
    required double width,
  }) {
    final qrCode = Barcode.qrCode();
    final qrSvg = qrCode.toSvg(qrData.toString(), width: 60, height: 60);
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(mentionLegale, style: pw.TextStyle(font: italicFont, fontSize: 8)),
              pw.Text('N° Agrément: $numeroAgrement', style: pw.TextStyle(font: baseFont, fontSize: 8)),
              pw.Text('Généré le: $dateGeneration', style: pw.TextStyle(font: baseFont, fontSize: 8)),
              pw.Text('Réf: $referenceDocument', style: pw.TextStyle(font: boldFont, fontSize: 8)),
            ],
          ),
          pw.Container(
            width: 60,
            height: 60,
            child: pw.SvgImage(svg: qrSvg),
          ),
        ],
      ),
    );
  }

  // Génère le corps du document (zone dynamique)
  pw.Widget buildBody({
    required List<pw.Widget> contentWidgets,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: contentWidgets,
    );
  }

  // Génère le PDF complet
  Future<Uint8List> generatePdf({
    required String titreDocument,
    required Uint8List? logoBytes,
    required String raisonSociale,
    required String sigle,
    required String adresse,
    required String telephone,
    required String email,
    required String region,
    required String departement,
    required List<pw.Widget> bodyContent,
    required String mentionLegale,
    required String numeroAgrement,
    required String dateGeneration,
    required String referenceDocument,
    required Map<String, dynamic> qrData,
    int pageCount = 1,
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
        header: (context) => buildHeader(
          logoBytes: logoBytes,
          raisonSociale: raisonSociale,
          sigle: sigle,
          adresse: adresse,
          telephone: telephone,
          email: email,
          region: region,
          departement: departement,
          titreDocument: titreDocument,
        ),
        footer: (context) => buildFooter(
          mentionLegale: mentionLegale,
          numeroAgrement: numeroAgrement,
          dateGeneration: dateGeneration,
          referenceDocument: referenceDocument,
          qrData: qrData,
          width: PdfPageFormat.a4.width,
        ),
        build: (context) => [buildBody(contentWidgets: bodyContent)],
      ),
    );
    return pdf.save();
  }
}

// Exemple d'utilisation
// (À placer dans un fichier de test ou d'exemple Flutter)
/*
Future<void> exempleFacture() async {
  final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
  final italicFontData = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');
  final baseFont = pw.Font.ttf(fontData);
  final boldFont = pw.Font.ttf(boldFontData);
  final italicFont = pw.Font.ttf(italicFontData);

  final pdfService = PdfTemplateService(
    baseFont: baseFont,
    boldFont: boldFont,
    italicFont: italicFont,
  );

  final pdfBytes = await pdfService.generatePdf(
    titreDocument: 'FACTURE',
    logoBytes: await loadLogoBytes(),
    raisonSociale: 'COOP EST',
    sigle: 'COOPEST',
    adresse: '01 BP 123 Abidjan',
    telephone: '+225 01 23 45 67',
    email: 'contact@coopest.ci',
    region: 'Sud-Comoé',
    departement: 'Aboisso',
    bodyContent: [
      pw.Text('Données de la facture ici'),
      // ... tableaux, etc.
    ],
    mentionLegale: 'Document généré par CoopManager',
    numeroAgrement: 'AGR-2025-001',
    dateGeneration: '2026-01-15 10:30',
    referenceDocument: 'FAC-2025-0012',
    qrData: {
      'document': 'FACTURE',
      'reference': 'FAC-2025-0012',
      'cooperative': 'COOP EST',
      'hash': 'SHA256',
      'date': '2026-01-15',
    },
  );
  // Enregistrer ou afficher le PDF
}
*/
