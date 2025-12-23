import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';

class ExportNotificationService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _numberFormat = NumberFormat('#,##0.00');

  /// Exporter les notifications en PDF
  Future<bool> exportNotifications({
    required List<NotificationModel> notifications,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildSummary(notifications),
              pw.SizedBox(height: 20),
              _buildNotificationsList(notifications),
              pw.SizedBox(height: 20),
              _buildFooter(),
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

      final fileName = 'notifications_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'HISTORIQUE DES NOTIFICATIONS',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Date d\'édition: ${_dateFormat.format(DateTime.now())}',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummary(List<NotificationModel> notifications) {
    final total = notifications.length;
    final unread = notifications.where((n) => n.isUnread).length;
    final byType = <String, int>{};
    final byModule = <String, int>{};

    for (final notification in notifications) {
      byType[notification.type] = (byType[notification.type] ?? 0) + 1;
      if (notification.module != null) {
        byModule[notification.module!] = (byModule[notification.module!] ?? 0) + 1;
      }
    }

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
            'Résumé',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Total: $total notifications'),
          pw.Text('Non lues: $unread'),
          if (byType.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Par type:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...byType.entries.map((e) => pw.Text('  ${e.key}: ${e.value}')),
          ],
          if (byModule.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Par module:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...byModule.entries.map((e) => pw.Text('  ${e.key}: ${e.value}')),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildNotificationsList(List<NotificationModel> notifications) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Détails des notifications',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(3),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Type', isHeader: true),
                _buildTableCell('Titre / Message', isHeader: true),
                _buildTableCell('Module', isHeader: true),
                _buildTableCell('Statut', isHeader: true),
              ],
            ),
            ...notifications.map((notification) {
              return pw.TableRow(
                children: [
                  _buildTableCell(_dateFormat.format(notification.createdAt)),
                  _buildTableCell(notification.type),
                  _buildTableCell('${notification.titre}\n${notification.message}'),
                  _buildTableCell(notification.module ?? '-'),
                  _buildTableCell(notification.isRead ? 'Lue' : 'Non lue'),
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
        style: pw.TextStyle(
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
}
