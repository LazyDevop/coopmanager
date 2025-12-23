import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../viewmodels/stock_viewmodel.dart';
import '../../data/models/stock_movement_model.dart';
import '../../data/models/stock_model.dart';

class StockExportScreen extends StatefulWidget {
  const StockExportScreen({super.key});

  @override
  State<StockExportScreen> createState() => _StockExportScreenState();
}

class _StockExportScreenState extends State<StockExportScreen> {
  bool _isExporting = false;
  String? _exportPath;

  Future<void> _exportToPDF() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final stockViewModel = context.read<StockViewModel>();
      await stockViewModel.loadStocks();
      await stockViewModel.loadMouvements();

      final pdf = pw.Document();

      // Page 1: Résumé des stocks
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Rapport des Stocks - CoopManager',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Stock Total Global: ${stockViewModel.totalStockGlobal.toStringAsFixed(2)} kg',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Nombre d\'adhérents avec stock: ${stockViewModel.nombreAdherentsAvecStock}',
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Alertes (stock critique): ${stockViewModel.nombreAdherentsStockCritique}',
            ),
            pw.SizedBox(height: 30),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Code', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Adhérent', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Stock (kg)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Statut', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...stockViewModel.stocks.map((stock) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(stock.adherentCode),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(stock.adherentFullName),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(stock.stockTotal.toStringAsFixed(2)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(stock.status.label),
                        ),
                      ],
                    )),
              ],
            ),
          ],
        ),
      );

      // Page 2: Historique des mouvements
      if (stockViewModel.mouvements.isNotEmpty) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Historique des Mouvements',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Quantité (kg)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Note', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...stockViewModel.mouvements.take(50).map((mouvement) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(mouvement.dateMouvement)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(mouvement.typeLabel),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              mouvement.quantite.toStringAsFixed(2),
                              style: pw.TextStyle(
                                color: mouvement.quantite > 0 ? PdfColors.green : PdfColors.red,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(mouvement.commentaire ?? '-'),
                          ),
                        ],
                      )),
                ],
              ),
            ],
          ),
        );
      }

      // Sauvegarder le PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/rapport_stocks_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
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
    // Pour l'export Excel, on génère un CSV (format simple et compatible)
    setState(() {
      _isExporting = true;
    });

    try {
      final stockViewModel = context.read<StockViewModel>();
      await stockViewModel.loadStocks();
      await stockViewModel.loadMouvements();

      final csv = StringBuffer();
      
      // En-têtes
      csv.writeln('Code,Adhérent,Stock (kg),Statut');
      
      // Données stocks
      for (final stock in stockViewModel.stocks) {
        csv.writeln('${stock.adherentCode},"${stock.adherentFullName}",${stock.stockTotal.toStringAsFixed(2)},${stock.status.label}');
      }
      
      csv.writeln('');
      csv.writeln('Historique des Mouvements');
      csv.writeln('Date,Type,Quantité (kg),Note');
      
      // Données mouvements
      for (final mouvement in stockViewModel.mouvements) {
        csv.writeln('${DateFormat('dd/MM/yyyy HH:mm').format(mouvement.dateMouvement)},${mouvement.typeLabel},${mouvement.quantite.toStringAsFixed(2)},"${mouvement.commentaire ?? ''}"');
      }

      // Sauvegarder le CSV
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/rapport_stocks_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exporter les Données'),
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

