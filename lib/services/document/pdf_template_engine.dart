import 'dart:convert';
import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/settings/cooperative_settings_model.dart';
import '../../data/models/settings/document_settings_model.dart';

/// Moteur de template PDF centralisé.
///
/// Objectif: fournir un en-tête + pied de page uniformes et réutilisables pour
/// tous les documents PDF, compatibles `pdf: ^3.x`.
class PdfTemplateEngine {
  const PdfTemplateEngine();

  static String _initials(String value) {
    final v = value.trim();
    if (v.isEmpty) return '';
    final cleaned = v.replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.length <= 2) return cleaned.toUpperCase();
    return cleaned.substring(0, 2).toUpperCase();
  }

  /// Builder à injecter dans `pw.MultiPage(header: ...)`.
  pw.Widget Function(pw.Context) buildHeader(
    CooperativeSettingsModel settings, {
    required String documentTitle,
    Uint8List? logoBytes,
  }) {
    final titre = documentTitle.trim();

    return (pw.Context context) {
      final base = pw.Theme.of(context).defaultTextStyle;
      final bold = base.copyWith(fontWeight: pw.FontWeight.bold);

      final adresse = settings.adresse?.trim();
      final region = settings.region?.trim();
      final departement = settings.departement?.trim();
      final localisation = [
        if (region != null && region.isNotEmpty) region,
        if (departement != null && departement.isNotEmpty) departement,
      ].join(' • ');

      final telephone = settings.telephone?.trim();
      final email = settings.email?.trim();

      return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                
                if (logoBytes != null)
                  pw.Container(
                    width: 48,
                    height: 48,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                  )
                else
                  pw.Container(
                    width: 48,
                    height: 48,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        _initials(settings.sigle ?? settings.raisonSociale),
                        style: bold.copyWith(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ),
                  ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(settings.raisonSociale, style: bold.copyWith(fontSize: 14)),
                      if ((settings.sigle ?? '').trim().isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(settings.sigle!.trim(), style: base.copyWith(fontSize: 10, color: PdfColors.grey700)),
                        ),
                      if (adresse != null && adresse.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(adresse, style: base.copyWith(fontSize: 9, color: PdfColors.grey700)),
                        ),
                      if (localisation.trim().isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(localisation, style: base.copyWith(fontSize: 9, color: PdfColors.grey700)),
                        ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          [
                            if (telephone != null && telephone.isNotEmpty) 'Tél: $telephone',
                            if (email != null && email.isNotEmpty) 'Email: $email',
                          ].join(' • '),
                          style: base.copyWith(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.grey400, thickness: 0.8),
            if (titre.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(
                  titre,
                  style: bold.copyWith(fontSize: 12),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            pw.SizedBox(height: 6),
          ],
        ),
      );
    };
  }

  /// Builder à injecter dans `pw.MultiPage(footer: ...)`.
  pw.Widget Function(pw.Context) buildFooter(
    CooperativeSettingsModel settings, {
    required DocumentSettingsModel documentSettings,
    String? documentReference,
    Map<String, dynamic>? qrData,
    DateTime? generatedAt,
  }) {
    final mentions = (documentSettings.mentionsLegales ?? '').trim();
    final urlBase = (documentSettings.qrCodeUrlBase ?? '').trim();
    final qrEnabled = documentSettings.qrCodeActif;

    String? qrPayload;
    if (qrEnabled) {
      final format = (documentSettings.qrCodeFormat ?? 'url').toLowerCase().trim();
      final dataJson = qrData == null ? null : jsonEncode(qrData);

      if (format == 'json') {
        qrPayload = dataJson;
      } else if (format == 'url') {
        if (urlBase.isNotEmpty && dataJson != null) {
          qrPayload = '$urlBase?data=${Uri.encodeComponent(dataJson)}';
        } else if (urlBase.isNotEmpty && documentReference != null) {
          final base = urlBase.endsWith('/') ? urlBase.substring(0, urlBase.length - 1) : urlBase;
          qrPayload = '$base/$documentReference';
        } else {
          qrPayload = dataJson;
        }
      } else {
        // custom / fallback
        if (urlBase.isNotEmpty && documentReference != null) {
          final base = urlBase.endsWith('/') ? urlBase.substring(0, urlBase.length - 1) : urlBase;
          qrPayload = '$base/$documentReference';
        } else {
          qrPayload = dataJson;
        }
      }

      if (qrPayload != null && qrPayload!.trim().isEmpty) {
        qrPayload = null;
      }
    }

    return (pw.Context context) {
      final base = pw.Theme.of(context).defaultTextStyle;
      final italic = base.copyWith(fontStyle: pw.FontStyle.italic);
      final small = base.copyWith(fontSize: 8, color: PdfColors.grey700);

      final pageLabel = 'Page ${context.pageNumber} / ${context.pagesCount}';

      pw.Widget? qrWidget;
      if (qrEnabled && qrPayload != null) {
        final qrCode = Barcode.qrCode();
        final svg = qrCode.toSvg(qrPayload!, width: 44, height: 44);
        qrWidget = pw.Container(
          width: 46,
          height: 46,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
            color: PdfColors.white,
          ),
          padding: const pw.EdgeInsets.all(3),
          child: pw.SvgImage(svg: svg),
        );
      }

      final gen = generatedAt;
      final generatedText = gen == null
          ? ''
          : 'Généré le: ${gen.toIso8601String().replaceFirst('T', ' ').split('.').first}';

      return pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Divider(color: PdfColors.grey400, thickness: 0.8),
            pw.SizedBox(height: 6),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (mentions.isNotEmpty)
                        pw.Text(mentions, style: italic.copyWith(fontSize: 8, color: PdfColors.grey700)),
                      if (urlBase.isNotEmpty)
                        pw.Text(urlBase, style: small),
                      if ((settings.numeroAgrement ?? '').trim().isNotEmpty)
                        pw.Text('N° Agrément: ${settings.numeroAgrement}', style: small),
                      if (documentReference != null && documentReference.trim().isNotEmpty)
                        pw.Text('Réf: $documentReference', style: small),
                      if (generatedText.isNotEmpty)
                        pw.Text(generatedText, style: small),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Text(pageLabel, style: small),
                if (qrWidget != null) ...[
                  pw.SizedBox(width: 12),
                  qrWidget,
                ],
              ],
            ),
          ],
        ),
      );
    };
  }
}
