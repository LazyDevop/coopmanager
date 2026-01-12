import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/adherent_model.dart';
import '../../data/models/adherent_historique_model.dart';
import '../document/pdf_template_engine.dart';
import '../document/pdf_utils.dart';

class ExportService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _numberFormat = NumberFormat('#,##0.00');

  /// Exporter l'historique d'un adhérent en PDF
  Future<bool> exportAdherentHistorique({
    required AdherentModel adherent,
    required List<AdherentHistoriqueModel> historique,
    required List<Map<String, dynamic>> depots,
    required List<Map<String, dynamic>> ventes,
    required List<Map<String, dynamic>> recettes,
  }) async {
    try {
      final baseFont = await PdfUtils.loadBaseFont();
      final boldFont = await PdfUtils.loadBoldFont();
      final italicFont = await PdfUtils.loadItalicFont();
      final coopSettings = await PdfUtils.loadCooperativeSettings();
      final meta = await PdfUtils.loadDocumentMeta(
        'historique_${adherent.code}_${DateTime.now().millisecondsSinceEpoch}',
        '',
      );
      const templateEngine = PdfTemplateEngine();

      final pdf = pw.Document();

      // En-tête
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(
            base: baseFont,
            bold: boldFont,
            italic: italicFont,
          ),
          header: templateEngine.buildHeader(
            coopSettings,
            documentTitle: 'HISTORIQUE DES OPÉRATIONS',
            logoBytes: meta.logoBytes,
          ),
          footer: templateEngine.buildFooter(
            coopSettings,
            documentSettings: meta.documentSettings,
            documentReference: meta.referenceDocument,
            qrData: meta.qrData,
            generatedAt: meta.generatedAt,
          ),
          build: (pw.Context context) {
            return [
              _buildInformationsSection(adherent),
              pw.SizedBox(height: 20),
              _buildHistoriqueSection(historique),
              pw.SizedBox(height: 20),
              _buildDepotsSection(depots),
              pw.SizedBox(height: 20),
              _buildVentesSection(ventes),
              pw.SizedBox(height: 20),
              _buildRecettesSection(recettes),
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

      final fileName = 'historique_${adherent.code}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

  pw.Widget _buildHeader(AdherentModel adherent) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'HISTORIQUE DES OPÉRATIONS',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Adhérent: ${adherent.fullName}',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'Code: ${adherent.code}',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.Text(
          'Date d\'édition: ${_dateFormat.format(DateTime.now())}',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInformationsSection(AdherentModel adherent) {
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
            'Informations personnelles',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow('Nom', adherent.nom),
          _buildInfoRow('Prénom', adherent.prenom),
          if (adherent.telephone != null)
            _buildInfoRow('Téléphone', adherent.telephone!),
          if (adherent.email != null)
            _buildInfoRow('Email', adherent.email!),
          if (adherent.village != null)
            _buildInfoRow('Village', adherent.village!),
          _buildInfoRow(
            'Date d\'adhésion',
            _dateFormat.format(adherent.dateAdhesion),
          ),
          _buildInfoRow('Statut', adherent.isActive ? 'Actif' : 'Inactif'),
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
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHistoriqueSection(List<AdherentHistoriqueModel> historique) {
    if (historique.isEmpty) {
      return pw.Text(
        'Aucun historique disponible',
        style: const pw.TextStyle(color: PdfColors.grey700),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Historique des opérations',
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
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Type', isHeader: true),
                _buildTableCell('Description', isHeader: true),
                _buildTableCell('Montant', isHeader: true),
              ],
            ),
            ...historique.take(50).map((item) {
              return pw.TableRow(
                children: [
                  _buildTableCell(_dateFormat.format(item.dateOperation)),
                  _buildTableCell(_getTypeLabel(item.typeOperation)),
                  _buildTableCell(item.description),
                  _buildTableCell(
                    item.montant != null
                        ? '${_numberFormat.format(item.montant!)} FCFA'
                        : '-',
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDepotsSection(List<Map<String, dynamic>> depots) {
    if (depots.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Dépôts de cacao',
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
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Quantité (kg)', isHeader: true),
                _buildTableCell('Prix unitaire', isHeader: true),
                _buildTableCell('Montant total', isHeader: true),
              ],
            ),
            ...depots.map((depot) {
              final quantite = depot['quantite'] as double;
              final prixUnitaire = depot['prix_unitaire'] as double;
              final montant = quantite * prixUnitaire;
              final dateDepot = DateTime.parse(depot['date_depot'] as String);

              return pw.TableRow(
                children: [
                  _buildTableCell(_dateFormat.format(dateDepot)),
                  _buildTableCell(_numberFormat.format(quantite)),
                  _buildTableCell('${_numberFormat.format(prixUnitaire)} FCFA'),
                  _buildTableCell('${_numberFormat.format(montant)} FCFA'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildVentesSection(List<Map<String, dynamic>> ventes) {
    if (ventes.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Ventes',
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
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Quantité (kg)', isHeader: true),
                _buildTableCell('Montant total', isHeader: true),
              ],
            ),
            ...ventes.map((vente) {
              final quantite = vente['quantite_total'] as double;
              final montantTotal = vente['montant_total'] as double;
              final dateVente = DateTime.parse(vente['date_vente'] as String);

              return pw.TableRow(
                children: [
                  _buildTableCell(_dateFormat.format(dateVente)),
                  _buildTableCell(_numberFormat.format(quantite)),
                  _buildTableCell('${_numberFormat.format(montantTotal)} FCFA'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildRecettesSection(List<Map<String, dynamic>> recettes) {
    if (recettes.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recettes et paiements',
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
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Montant brut', isHeader: true),
                _buildTableCell('Commission', isHeader: true),
                _buildTableCell('Montant net', isHeader: true),
              ],
            ),
            ...recettes.map((recette) {
              final montantBrut = recette['montant_brut'] as double;
              final commissionAmount = recette['commission_amount'] as double;
              final montantNet = recette['montant_net'] as double;
              final dateRecette = DateTime.parse(recette['date_recette'] as String);

              return pw.TableRow(
                children: [
                  _buildTableCell(_dateFormat.format(dateRecette)),
                  _buildTableCell('${_numberFormat.format(montantBrut)} FCFA'),
                  _buildTableCell('${_numberFormat.format(commissionAmount)} FCFA'),
                  _buildTableCell('${_numberFormat.format(montantNet)} FCFA'),
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
        style: const pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey700,
        ),
        textAlign: pw.TextAlign.center,
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'creation':
        return 'Création';
      case 'modification':
        return 'Modification';
      case 'depot':
        return 'Dépôt';
      case 'vente':
        return 'Vente';
      case 'recette':
        return 'Recette';
      case 'desactivation':
        return 'Désactivation';
      case 'reactivation':
        return 'Réactivation';
      default:
        return type;
    }
  }
}
