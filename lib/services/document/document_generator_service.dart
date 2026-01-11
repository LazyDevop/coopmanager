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
import '../parametres/central_settings_service.dart';
import 'qrcode_service.dart';
import 'repositories/document_repository.dart';

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
  })  : _settingsService = settingsService ?? CentralSettingsService(),
        _qrCodeService = qrCodeService ?? QRCodeService(),
        _documentRepository = documentRepository ?? DocumentRepository();

  /// Charger les paramètres de la coopérative
  Future<CooperativeSettingsModel> _loadCooperativeSettings() async {
    try {
      final settings = await _settingsService.getCooperativeSettings();
      if (settings == null) {
        throw Exception('Aucune coopérative active configurée');
      }
      return settings;
    } catch (e) {
      throw Exception('Erreur lors du chargement des paramètres coopérative: $e');
    }
  }

  /// Construire l'en-tête commun pour tous les documents
  Future<pw.Widget> _buildHeader({
    required CooperativeSettingsModel coopSettings,
    required String documentTitle,
  }) async {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey800, width: 2),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo
              if (coopSettings.logoPath != null)
                pw.Container(
                  width: 80,
                  height: 80,
                  margin: const pw.EdgeInsets.only(right: 20),
                  child: pw.Image(
                    pw.MemoryImage(
                      await _loadImageBytes(coopSettings.logoPath!),
                    ),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              // Informations coopérative
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      coopSettings.raisonSociale,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    if (coopSettings.sigle != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Sigle: ${coopSettings.sigle}',
                        style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                    if (coopSettings.adresse != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        coopSettings.adresse!,
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                    ],
                    pw.Row(
                      children: [
                        if (coopSettings.region != null || coopSettings.departement != null)
                          pw.Text(
                            [
                              if (coopSettings.region != null) coopSettings.region,
                              if (coopSettings.departement != null) coopSettings.departement,
                            ].where((e) => e != null).join(' - '),
                            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                          ),
                        if (coopSettings.telephone != null) ...[
                          pw.SizedBox(width: 10),
                          pw.Text(
                            'Tél: ${coopSettings.telephone}',
                            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                          ),
                        ],
                      ],
                    ),
                    if (coopSettings.email != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Email: ${coopSettings.email}',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                    ],
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Devise: ${coopSettings.devise}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              documentTitle,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Construire le pied de page commun avec QR code et agrément
  pw.Widget _buildFooter({
    required CooperativeSettingsModel coopSettings,
    required String documentReference,
    required String hash,
    required DateTime generatedAt,
    required String qrCodeData,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 30),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey800, width: 2),
        ),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Numéro d'agrément
          if (coopSettings.numeroAgrement != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                'N° Agrément: ${coopSettings.numeroAgrement}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ),
          // QR Code et informations
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // QR Code (sera généré comme image)
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  color: PdfColors.white,
                ),
                child: pw.FutureBuilder<Uint8List>(
                  future: _generateQRCodeImage(qrCodeData),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return pw.Image(
                        pw.MemoryImage(snapshot.data!),
                        fit: pw.BoxFit.contain,
                      );
                    }
                    return pw.Center(
                      child: pw.Text(
                        'QR\nCode',
                        style: pw.TextStyle(fontSize: 8),
                        textAlign: pw.TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
              pw.SizedBox(width: 15),
              // Informations de vérification
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Référence: $documentReference',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Code: ${hash.substring(0, 16)}...',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Généré le ${_dateTimeFormat.format(generatedAt)}',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          // Mention légale
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Document généré par le système CoopManager – Toute falsification est interdite',
              style: pw.TextStyle(
                fontSize: 8,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

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
      
      // Vérifier que la coopérative correspond
      if (coopSettings.id != cooperativeId) {
        throw Exception('La coopérative active ne correspond pas à celle du document');
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
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.FutureBuilder<pw.Widget>(
                future: _buildHeader(
                  coopSettings: coopSettings,
                  documentTitle: documentTitle,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!;
                  }
                  return pw.SizedBox();
                },
              ),
              pw.SizedBox(height: 20),
              // Contenu spécifique au type de document
              buildContent(context),
              pw.SizedBox(height: 20),
              // Pied de page
              _buildFooter(
                coopSettings: coopSettings,
                documentReference: documentReference,
                hash: hash,
                generatedAt: generatedAt,
                qrCodeData: qrCodeData,
              ),
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
      final filePath = '${documentsDir.path}/${sanitizedFileName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
                style: pw.TextStyle(fontSize: 8),
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

