import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../viewmodels/recette_viewmodel.dart';

class RecetteExportScreen extends StatefulWidget {
  const RecetteExportScreen({super.key});

  @override
  State<RecetteExportScreen> createState() => _RecetteExportScreenState();
}

class _RecetteExportScreenState extends State<RecetteExportScreen> {
  bool _isExporting = false;
  String? _exportPath;

  Future<void> _exportToPDF() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final recetteViewModel = context.read<RecetteViewModel>();
      await recetteViewModel.loadRecettesSummary();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Rapport des Recettes - CoopManager',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            
            // Statistiques globales
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
                    'Résumé Global',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  _buildSummaryRow(
                    'Total montant brut:',
                    recetteViewModel.recettesSummary.fold(0.0, (sum, s) => sum + s.totalMontantBrut),
                  ),
                  _buildSummaryRow(
                    'Total commission:',
                    recetteViewModel.recettesSummary.fold(0.0, (sum, s) => sum + s.totalCommission),
                    isNegative: true,
                  ),
                  _buildSummaryRow(
                    'Total montant net:',
                    recetteViewModel.recettesSummary.fold(0.0, (sum, s) => sum + s.totalMontantNet),
                    isTotal: true,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            
            // Tableau des recettes
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Code', isHeader: true),
                    _buildTableCell('Adhérent', isHeader: true),
                    _buildTableCell('Nb Recettes', isHeader: true),
                    _buildTableCell('Montant Brut', isHeader: true),
                    _buildTableCell('Commission', isHeader: true),
                    _buildTableCell('Montant Net', isHeader: true),
                  ],
                ),
                ...recetteViewModel.recettesSummary.map((summary) => pw.TableRow(
                      children: [
                        _buildTableCell(summary.adherentCode),
                        _buildTableCell(summary.adherentFullName),
                        _buildTableCell(summary.nombreRecettes.toString()),
                        _buildTableCell('${NumberFormat('#,##0').format(summary.totalMontantBrut)} FCFA'),
                        _buildTableCell('${NumberFormat('#,##0').format(summary.totalCommission)} FCFA'),
                        _buildTableCell('${NumberFormat('#,##0').format(summary.totalMontantNet)} FCFA'),
                      ],
                    )),
              ],
            ),
          ],
        ),
      );

      // Sauvegarder le PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/rapport_recettes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _isExporting = false;
        _exportPath = file.path;
      });

      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exporté avec succès: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final recetteViewModel = context.read<RecetteViewModel>();
      await recetteViewModel.loadRecettesSummary();

      final csv = StringBuffer();
      
      // En-têtes
      csv.writeln('Code,Adhérent,Nombre Recettes,Montant Brut,Commission,Montant Net');
      
      // Données
      for (final summary in recetteViewModel.recettesSummary) {
        csv.writeln('${summary.adherentCode},"${summary.adherentFullName}",${summary.nombreRecettes},${summary.totalMontantBrut.toStringAsFixed(2)},${summary.totalCommission.toStringAsFixed(2)},${summary.totalMontantNet.toStringAsFixed(2)}');
      }
      
      csv.writeln('');
      csv.writeln('Résumé Global');
      csv.writeln('Total Montant Brut,Total Commission,Total Montant Net');
      final totalBrut = recetteViewModel.recettesSummary.fold(0.0, (sum, s) => sum + s.totalMontantBrut);
      final totalCommission = recetteViewModel.recettesSummary.fold(0.0, (sum, s) => sum + s.totalCommission);
      final totalNet = recetteViewModel.recettesSummary.fold(0.0, (sum, s) => sum + s.totalMontantNet);
      csv.writeln('${totalBrut.toStringAsFixed(2)},${totalCommission.toStringAsFixed(2)},${totalNet.toStringAsFixed(2)}');

      // Sauvegarder le CSV
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/rapport_recettes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv');
      await file.writeAsString(csv.toString());

      setState(() {
        _isExporting = false;
        _exportPath = file.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exporté avec succès: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
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

  pw.Widget _buildSummaryRow(String label, double value, {bool isNegative = false, bool isTotal = false}) {
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
            isNegative ? '-${NumberFormat('#,##0').format(value)} FCFA' : '${NumberFormat('#,##0').format(value)} FCFA',
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
        title: const Text('Exporter les Recettes'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choisissez le format d\'export:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportToPDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exporter en PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportToExcel,
              icon: const Icon(Icons.table_chart),
              label: const Text('Exporter en CSV (Excel)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            if (_isExporting) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text('Export en cours...')),
            ],
            
            if (_exportPath != null && !_isExporting) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Export réussi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Fichier: $_exportPath'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

