import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/facture_model.dart';
import '../../data/models/adherent_model.dart';
import '../../data/models/vente_model.dart';
import '../../data/models/recette_model.dart';
import '../../data/models/vente_detail_model.dart';
import '../database/db_initializer.dart';

class FacturePdfService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _numberFormat = NumberFormat('#,##0.00');

  /// Obtenir les informations de la coopérative
  Future<Map<String, dynamic>> _getCoopSettings() async {
    try {
      final db = await DatabaseInitializer.database;
      final result = await db.query('coop_settings', limit: 1);

      if (result.isNotEmpty) {
        return result.first;
      }

      return {
        'nom_cooperative': 'Coopérative de Cacaoculteurs',
        'adresse': '',
        'telephone': '',
        'email': '',
      };
    } catch (e) {
      return {
        'nom_cooperative': 'Coopérative de Cacaoculteurs',
        'adresse': '',
        'telephone': '',
        'email': '',
      };
    }
  }

  /// Générer une facture PDF pour une vente
  Future<String> generateFactureVente({
    required FactureModel facture,
    required AdherentModel adherent,
    required VenteModel vente,
    List<VenteDetailModel>? venteDetails,
  }) async {
    try {
      final pdf = pw.Document();
      final coopSettings = await _getCoopSettings();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              _buildHeader(coopSettings),
              pw.SizedBox(height: 30),
              _buildClientInfo(adherent),
              pw.SizedBox(height: 20),
              _buildFactureInfo(facture),
              pw.SizedBox(height: 20),
              _buildVenteDetails(vente, venteDetails),
              pw.SizedBox(height: 20),
              _buildTotals(vente.montantTotal),
              pw.SizedBox(height: 30),
              _buildFooter(coopSettings),
            ];
          },
        ),
      );

      return await _savePdf(pdf, facture.numero);
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  /// Générer une facture PDF pour une recette
  Future<String> generateFactureRecette({
    required FactureModel facture,
    required AdherentModel adherent,
    required RecetteModel recette,
  }) async {
    try {
      final pdf = pw.Document();
      final coopSettings = await _getCoopSettings();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              _buildHeader(coopSettings),
              pw.SizedBox(height: 30),
              _buildClientInfo(adherent),
              pw.SizedBox(height: 20),
              _buildFactureInfo(facture),
              pw.SizedBox(height: 20),
              _buildRecetteDetails(recette),
              pw.SizedBox(height: 20),
              _buildTotals(recette.montantNet),
              pw.SizedBox(height: 30),
              _buildFooter(coopSettings),
            ];
          },
        ),
      );

      return await _savePdf(pdf, facture.numero);
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  /// Générer un bordereau de recettes (plusieurs recettes)
  Future<String> generateBordereauRecettes({
    required FactureModel facture,
    required AdherentModel adherent,
    required List<RecetteModel> recettes,
  }) async {
    try {
      final pdf = pw.Document();
      final coopSettings = await _getCoopSettings();

      final totalBrut = recettes.fold<double>(0.0, (sum, r) => sum + r.montantBrut);
      final totalCommission = recettes.fold<double>(0.0, (sum, r) => sum + r.commissionAmount);
      final totalNet = recettes.fold<double>(0.0, (sum, r) => sum + r.montantNet);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              _buildHeader(coopSettings),
              pw.SizedBox(height: 30),
              _buildClientInfo(adherent),
              pw.SizedBox(height: 20),
              _buildFactureInfo(facture),
              pw.SizedBox(height: 20),
              _buildBordereauDetails(recettes),
              pw.SizedBox(height: 20),
              _buildBordereauTotals(totalBrut, totalCommission, totalNet),
              pw.SizedBox(height: 30),
              _buildFooter(coopSettings),
            ];
          },
        ),
      );

      return await _savePdf(pdf, facture.numero);
    } catch (e) {
      throw Exception('Erreur lors de la génération du bordereau: $e');
    }
  }

  pw.Widget _buildHeader(Map<String, dynamic> coopSettings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  coopSettings['nom_cooperative'] as String? ?? 'Coopérative de Cacaoculteurs',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (coopSettings['adresse'] != null && (coopSettings['adresse'] as String).isNotEmpty)
                  pw.Text(
                    coopSettings['adresse'] as String,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                if (coopSettings['telephone'] != null && (coopSettings['telephone'] as String).isNotEmpty)
                  pw.Text(
                    'Tél: ${coopSettings['telephone']}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                if (coopSettings['email'] != null && (coopSettings['email'] as String).isNotEmpty)
                  pw.Text(
                    'Email: ${coopSettings['email']}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                'FACTURE',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildClientInfo(AdherentModel adherent) {
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
            'CLIENT',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('${adherent.prenom} ${adherent.nom}'),
          pw.Text('Code: ${adherent.code}'),
          if (adherent.village != null) pw.Text('Village: ${adherent.village}'),
          if (adherent.telephone != null) pw.Text('Téléphone: ${adherent.telephone}'),
          if (adherent.email != null) pw.Text('Email: ${adherent.email}'),
        ],
      ),
    );
  }

  pw.Widget _buildFactureInfo(FactureModel facture) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'N° Facture: ${facture.numero}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text('Date: ${_dateFormat.format(facture.dateFacture)}'),
            if (facture.dateEcheance != null)
              pw.Text('Échéance: ${_dateFormat.format(facture.dateEcheance!)}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _getStatutColor(facture.statut),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Text(
                _getStatutLabel(facture.statut),
                style: const pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildVenteDetails(VenteModel vente, List<VenteDetailModel>? details) {
    if (vente.isGroupee && details != null && details.isNotEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Détails de la vente',
            style: pw.TextStyle(
              fontSize: 14,
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
                  _buildTableCell('Quantité (kg)', isHeader: true),
                  _buildTableCell('Prix unitaire', isHeader: true),
                  _buildTableCell('Montant', isHeader: true),
                ],
              ),
              ...details.map((detail) {
                return pw.TableRow(
                  children: [
                    _buildTableCell('Adhérent #${detail.adherentId}'),
                    _buildTableCell(_numberFormat.format(detail.quantite)),
                    _buildTableCell('${_numberFormat.format(detail.prixUnitaire)} FCFA'),
                    _buildTableCell('${_numberFormat.format(detail.montant)} FCFA'),
                  ],
                );
              }),
            ],
          ),
        ],
      );
    } else {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Détails de la vente',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              children: [
                _buildInfoRow('Date de vente', _dateFormat.format(vente.dateVente)),
                _buildInfoRow('Quantité', '${_numberFormat.format(vente.quantiteTotal)} kg'),
                _buildInfoRow('Prix unitaire', '${_numberFormat.format(vente.prixUnitaire)} FCFA/kg'),
                if (vente.acheteur != null)
                  _buildInfoRow('Acheteur', vente.acheteur!),
                if (vente.modePaiement != null)
                  _buildInfoRow('Mode de paiement', _getModePaiementLabel(vente.modePaiement!)),
              ],
            ),
          ),
        ],
      );
    }
  }

  pw.Widget _buildRecetteDetails(RecetteModel recette) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Détails de la recette',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            children: [
              _buildInfoRow('Date de recette', _dateFormat.format(recette.dateRecette)),
              _buildInfoRow('Montant brut', '${_numberFormat.format(recette.montantBrut)} FCFA'),
              _buildInfoRow(
                'Taux de commission',
                '${(recette.commissionRate * 100).toStringAsFixed(2)}%',
              ),
              _buildInfoRow(
                'Commission',
                '${_numberFormat.format(recette.commissionAmount)} FCFA',
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildBordereauDetails(List<RecetteModel> recettes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Détails des recettes',
          style: pw.TextStyle(
            fontSize: 14,
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
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Montant brut', isHeader: true),
                _buildTableCell('Commission', isHeader: true),
                _buildTableCell('Taux', isHeader: true),
                _buildTableCell('Montant net', isHeader: true),
              ],
            ),
            ...recettes.map((recette) {
              return pw.TableRow(
                children: [
                  _buildTableCell(_dateFormat.format(recette.dateRecette)),
                  _buildTableCell('${_numberFormat.format(recette.montantBrut)} FCFA'),
                  _buildTableCell('${_numberFormat.format(recette.commissionAmount)} FCFA'),
                  _buildTableCell('${(recette.commissionRate * 100).toStringAsFixed(2)}%'),
                  _buildTableCell('${_numberFormat.format(recette.montantNet)} FCFA'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTotals(double montantTotal) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'MONTANT TOTAL',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            '${_numberFormat.format(montantTotal)} FCFA',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBordereauTotals(
    double totalBrut,
    double totalCommission,
    double totalNet,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total brut:', style: const pw.TextStyle(fontSize: 12)),
              pw.Text(
                '${_numberFormat.format(totalBrut)} FCFA',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total commission:', style: const pw.TextStyle(fontSize: 12)),
              pw.Text(
                '${_numberFormat.format(totalCommission)} FCFA',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'MONTANT NET TOTAL',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${_numberFormat.format(totalNet)} FCFA',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(Map<String, dynamic> coopSettings) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        'Document généré le ${_dateFormat.format(DateTime.now())} par CoopManager\n'
        '${coopSettings['nom_cooperative'] as String? ?? 'Coopérative de Cacaoculteurs'}',
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey700,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(value),
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

  PdfColor _getStatutColor(String statut) {
    switch (statut) {
      case 'payee':
        return PdfColors.green;
      case 'annulee':
        return PdfColors.red;
      case 'validee':
        return PdfColors.blue;
      default:
        return PdfColors.grey;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'payee':
        return 'PAYÉE';
      case 'annulee':
        return 'ANNULÉE';
      case 'validee':
        return 'VALIDÉE';
      case 'brouillon':
        return 'BROUILLON';
      default:
        return statut.toUpperCase();
    }
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

  Future<String> _savePdf(pw.Document pdf, String numero) async {
    final directory = await getApplicationDocumentsDirectory();
    final facturesDir = Directory('${directory.path}/factures');
    if (!await facturesDir.exists()) {
      await facturesDir.create(recursive: true);
    }

    final fileName = 'facture_${numero.replaceAll('/', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${facturesDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Imprimer une facture
  Future<void> printFacture(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => await pdf.save(),
    );
  }
}
