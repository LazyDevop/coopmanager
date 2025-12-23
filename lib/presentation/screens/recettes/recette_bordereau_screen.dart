import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../viewmodels/recette_viewmodel.dart';
import '../../../services/recette/recette_service.dart';
import '../../../services/adherent/adherent_service.dart';
import '../../../data/models/adherent_model.dart';

class RecetteBordereauScreen extends StatefulWidget {
  final int adherentId;
  final DateTime? startDate;
  final DateTime? endDate;

  const RecetteBordereauScreen({
    super.key,
    required this.adherentId,
    this.startDate,
    this.endDate,
  });

  @override
  State<RecetteBordereauScreen> createState() => _RecetteBordereauScreenState();
}

class _RecetteBordereauScreenState extends State<RecetteBordereauScreen> {
  bool _isGenerating = false;
  AdherentModel? _adherent;
  final RecetteService _recetteService = RecetteService();
  final AdherentService _adherentService = AdherentService();

  @override
  void initState() {
    super.initState();
    _loadAdherent();
  }

  Future<void> _loadAdherent() async {
    final adherent = await _adherentService.getAdherentById(widget.adherentId);
    setState(() {
      _adherent = adherent;
    });
  }

  Future<void> _generateBordereau() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      if (_adherent == null) {
        throw Exception('Adhérent non trouvé');
      }

      // Charger les ventes et recettes
      final ventes = await _recetteService.getVentesForBordereau(
        widget.adherentId,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      final recettes = await _recetteService.getRecettesByAdherent(widget.adherentId);
      final filteredRecettes = widget.startDate != null || widget.endDate != null
          ? recettes.where((r) {
              if (widget.startDate != null && r.dateRecette.isBefore(widget.startDate!)) {
                return false;
              }
              if (widget.endDate != null && r.dateRecette.isAfter(widget.endDate!)) {
                return false;
              }
              return true;
            }).toList()
          : recettes;

      // Calculer les totaux
      final totalBrut = filteredRecettes.fold(0.0, (sum, r) => sum + r.montantBrut);
      final totalCommission = filteredRecettes.fold(0.0, (sum, r) => sum + r.commissionAmount);
      final totalNet = filteredRecettes.fold(0.0, (sum, r) => sum + r.montantNet);

      // Obtenir le taux de commission
      final commissionRate = await _recetteService.getCommissionRate();

      // Créer le PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                pw.Header(
                  level: 0,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BORDEREAU DE RECETTE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Coopérative de Cacaoculteurs',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Informations adhérent
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Adhérent: ${_adherent!.fullName}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Code: ${_adherent!.code}'),
                      if (_adherent!.telephone != null)
                        pw.Text('Téléphone: ${_adherent!.telephone}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Détails des ventes
                if (ventes.isNotEmpty) ...[
                  pw.Text(
                    'Détails des ventes',
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
                          _buildTableCell('Montant brut', isHeader: true),
                        ],
                      ),
                      ...ventes.map((vente) {
                        final dateVente = DateTime.parse(vente['date_vente'] as String);
                        final quantite = (vente['quantite_total'] as num).toDouble();
                        final prixUnitaire = (vente['prix_unitaire'] as num).toDouble();
                        final montantBrut = (vente['montant_total'] as num).toDouble();

                        return pw.TableRow(
                          children: [
                            _buildTableCell(DateFormat('dd/MM/yyyy').format(dateVente)),
                            _buildTableCell(quantite.toStringAsFixed(2)),
                            _buildTableCell('${NumberFormat('#,##0').format(prixUnitaire)} FCFA'),
                            _buildTableCell('${NumberFormat('#,##0').format(montantBrut)} FCFA'),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                ],

                // Résumé des recettes
                pw.Text(
                  'Résumé des recettes',
                  style: pw.TextStyle(
                    fontSize: 16,
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
                      _buildSummaryRow('Montant brut total:', totalBrut),
                      _buildSummaryRow('Taux de commission:', commissionRate * 100, isPercent: true),
                      _buildSummaryRow('Commission totale:', totalCommission, isNegative: true),
                      pw.Divider(),
                      _buildSummaryRow('Montant net à payer:', totalNet, isTotal: true),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Afficher le PDF
      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
        );
      }

      setState(() {
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, double value, {bool isNegative = false, bool isPercent = false, bool isTotal = false}) {
    final formattedValue = isPercent
        ? '${value.toStringAsFixed(1)}%'
        : '${NumberFormat('#,##0').format(value)} FCFA';
    
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 16 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            isNegative ? '-$formattedValue' : formattedValue,
            style: pw.TextStyle(
              fontSize: isTotal ? 18 : 12,
              fontWeight: pw.FontWeight.bold,
              color: isNegative ? PdfColors.red : (isTotal ? PdfColors.teal : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bordereau de Recette'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_adherent != null) ...[
              Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 24,
                    child: const Icon(Icons.person),
                  ),
                  title: Text(_adherent!.fullName),
                  subtitle: Text('Code: ${_adherent!.code}'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            if (widget.startDate != null || widget.endDate != null)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Période sélectionnée:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (widget.startDate != null)
                        Text('Début: ${DateFormat('dd/MM/yyyy').format(widget.startDate!)}'),
                      if (widget.endDate != null)
                        Text('Fin: ${DateFormat('dd/MM/yyyy').format(widget.endDate!)}'),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateBordereau,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isGenerating ? 'Génération...' : 'Générer et Imprimer le Bordereau'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

