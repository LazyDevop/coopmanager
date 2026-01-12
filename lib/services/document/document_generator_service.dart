import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
// Note: QR code generation will be handled separately
import '../../data/models/document/document_model.dart';
import '../../data/models/document/document_metadata.dart';
import '../../data/models/settings/cooperative_settings_model.dart';
import '../../data/models/settings/document_settings_model.dart';
import '../parametres/central_settings_service.dart';
import 'qrcode_service.dart';
import 'repositories/document_repository.dart';
import 'pdf_template_engine.dart';
import 'pdf_utils.dart';

/// Service centralisé pour la génération de tous les documents PDF
class DocumentGeneratorService {
  final CentralSettingsService _settingsService;
  final QRCodeService _qrCodeService;
  final DocumentRepository _documentRepository;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy à HH:mm');
  final NumberFormat _numberFormat = NumberFormat('#,##0.00');

  DocumentGeneratorService({
    CentralSettingsService? settingsService,
    QRCodeService? qrCodeService,
    DocumentRepository? documentRepository,
  }) : _settingsService = settingsService ?? CentralSettingsService(),
       _qrCodeService = qrCodeService ?? QRCodeService(),
       _documentRepository = documentRepository ?? DocumentRepository();

  /// Charger les paramètres de la coopérative
  Future<CooperativeSettingsModel> _loadCooperativeSettings() async {
    try {
      final settings = await _settingsService.getCooperativeSettings();
      return settings;
    } catch (e) {
      throw Exception(
        'Erreur lors du chargement des paramètres coopérative: $e',
      );
    }
  }

  // NOTE: l'en-tête et le pied de page sont désormais gérés par PdfTemplateEngine
  // via `pw.MultiPage(header: ..., footer: ...)`.

  /// Générer un document PDF complet
  Future<DocumentModel> generateDocument({
    required DocumentType documentType,
    required String documentReference,
    required int cooperativeId,
    required int generatedBy,
    required String documentTitle,
    required pw.Widget Function(pw.Context) buildContent,
    required Map<String, dynamic> contentData,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      // Charger les paramètres de la coopérative
      final coopSettings = await _loadCooperativeSettings();

      // Charger les paramètres documents (mentions légales, QR, base URL...)
      final DocumentSettingsModel documentSettings = await _settingsService
          .getDocumentSettings();

      // Vérifier que la coopérative correspond
      if (coopSettings.id != cooperativeId) {
        throw Exception(
          'La coopérative active ne correspond pas à celle du document',
        );
      }

      final generatedAt = DateTime.now();

      // Générer le hash du document
      final hash = _qrCodeService.generateHash(
        documentType: documentType.code,
        documentId: documentReference,
        cooperativeId: cooperativeId,
        generatedAt: generatedAt,
        content: contentData,
      );

      // Générer les données du QR code
      final qrCodeData = _qrCodeService.generateQRCodeData(
        documentType: documentType,
        documentId: documentReference,
        cooperativeId: cooperativeId,
        hash: hash,
        generatedAt: generatedAt,
        additionalData: additionalMetadata,
      );

      // Construire le PDF
      final pdf = pw.Document();

      final baseFont = await PdfUtils.loadBaseFont();
      final boldFont = await PdfUtils.loadBoldFont();
      final italicFont = await PdfUtils.loadItalicFont();

      Uint8List? logoBytes;
      if (coopSettings.logoPath != null &&
          coopSettings.logoPath!.trim().isNotEmpty) {
        try {
          logoBytes = await _loadImageBytes(coopSettings.logoPath!);
        } catch (_) {
          logoBytes = null;
        }
      }

      final qrData = _qrCodeService.parseQRCodeData(qrCodeData);
      const templateEngine = PdfTemplateEngine();

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
            documentTitle: documentTitle,
            logoBytes: logoBytes,
          ),
          footer: templateEngine.buildFooter(
            coopSettings,
            documentSettings: documentSettings,
            documentReference: documentReference,
            qrData: qrData,
            generatedAt: generatedAt,
          ),
          build: (pw.Context context) {
            return [
              // Contenu spécifique au type de document
              buildContent(context),
            ];
          },
        ),
      );

      // Sauvegarder le PDF
      final filePath = await _savePdf(pdf, documentReference);

      // Créer le modèle de document
      final document = DocumentModel(
        type: documentType.code,
        reference: documentReference,
        cooperativeId: cooperativeId,
        hash: hash,
        generatedAt: generatedAt,
        generatedBy: generatedBy,
        filePath: filePath,
        metadata: {
          'title': documentTitle,
          ...contentData,
          if (additionalMetadata != null) ...additionalMetadata,
        },
        qrCodeData: qrCodeData,
      );

      // Sauvegarder en base de données
      final savedDocument = await _documentRepository.create(document);

      return savedDocument;
    } catch (e) {
      throw Exception('Erreur lors de la génération du document: $e');
    }
  }

  /// Sauvegarder le PDF sur le système de fichiers
  Future<String> _savePdf(pw.Document pdf, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${directory.path}/documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      final sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
      final filePath =
          '${documentsDir.path}/${sanitizedFileName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du PDF: $e');
    }
  }

  /// Charger les bytes d'une image depuis le chemin
  Future<Uint8List> _loadImageBytes(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      throw Exception('Image non trouvée: $imagePath');
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'image: $e');
    }
  }

  /// Générer une image QR code depuis les données JSON
  /// Note: Cette méthode doit être implémentée avec une bibliothèque QR code
  /// Pour l'instant, on retourne un placeholder
  Future<Uint8List> _generateQRCodeImage(String qrCodeData) async {
    try {
      // TODO: Implémenter la génération réelle du QR code avec qr_flutter ou qr.dart
      // Pour l'instant, on crée un placeholder simple
      // Dans un vrai projet, vous utiliseriez:
      // final qrCode = QrCode.fromData(data: qrCodeData, errorCorrectLevel: QrErrorCorrectLevel.M);
      // return qrCode.toImage().toBytes();

      // Placeholder: créer une image simple avec le texte
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'QR\n${qrCodeData.substring(0, 20)}...',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            );
          },
        ),
      );
      return await pdf.save();
    } catch (e) {
      throw Exception('Erreur lors de la génération du QR code: $e');
    }
  }
}
