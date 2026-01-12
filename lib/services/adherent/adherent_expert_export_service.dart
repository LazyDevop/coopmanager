import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/adherent_model.dart';
import '../../data/models/adherent_expert/adherent_expert_model.dart';
import '../../data/models/adherent_expert/ayant_droit_model.dart';
import '../../data/models/adherent_expert/champ_parcelle_model.dart';
import '../../data/models/adherent_expert/traitement_agricole_model.dart';
import '../../data/models/adherent_expert/production_model.dart';
import '../../data/models/adherent_expert/capital_social_model.dart';
import '../../data/models/adherent_expert/credit_social_model.dart';
import '../../data/models/stock_model.dart';
import '../../data/models/vente_model.dart';
import '../../data/models/recette_model.dart';
import '../database/db_initializer.dart';
import '../document/pdf_template_engine.dart';
import '../document/pdf_utils.dart';

/// Service d'export complet du dossier expert d'un adhérent
class AdherentExpertExportService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _numberFormat = NumberFormat('#,##0.00');
  
  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) {
      return '0.00';
    }
    return _numberFormat.format(value);
  }

  /// Exporter le dossier complet d'un adhérent expert en PDF
  Future<bool> exportDossierExpert({
    required AdherentModel adherent,
    required AdherentExpertModel expertModel,
    required List<AyantDroitModel> ayantsDroit,
    required List<ChampParcelleModel> champs,
    required List<TraitementAgricoleModel> traitements,
    required List<ProductionModel> productions,
    required List<StockDepotModel> depotsStock,
    required List<VenteModel> ventes,
    required List<RecetteModel> recettes,
    required List<CapitalSocialModel> souscriptionsCapital,
    required List<CreditSocialModel> creditsSociaux,
  }) async {
    try {
      final pdf = pw.Document();
      final baseFont = await PdfUtils.loadBaseFont();
      final boldFont = await PdfUtils.loadBoldFont();
      final italicFont = await PdfUtils.loadItalicFont();

      final coopSettings = await PdfUtils.loadCooperativeSettings();
      final meta = await PdfUtils.loadDocumentMeta(
        'dossier_${adherent.code}_${DateTime.now().millisecondsSinceEpoch}',
        '',
      );
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
            documentTitle: 'DOSSIER ADHÉRENT (EXPERT)',
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
              pw.Text(
                'Adhérent: ${adherent.fullName} (${adherent.code})',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              _buildIndicateursSection(expertModel),
              pw.SizedBox(height: 20),
              _buildInformationsPersonnellesSection(adherent),
              if (ayantsDroit.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildAyantsDroitSection(ayantsDroit),
              ],
              if (champs.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildChampsSection(champs),
              ],
              if (traitements.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildTraitementsSection(traitements),
              ],
              if (productions.isNotEmpty || depotsStock.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildProductionStockSection(productions, depotsStock, expertModel),
              ],
              if (ventes.isNotEmpty || recettes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildVentesPaiementsSection(ventes, recettes, expertModel),
              ],
              if (souscriptionsCapital.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildCapitalSocialSection(souscriptionsCapital, expertModel),
              ],
              if (creditsSociaux.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildCreditsSociauxSection(creditsSociaux),
              ],
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

      final fileName = 'dossier_${adherent.code}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${exportDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Ouvrir le dialogue d'impression/aperçu
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => await pdf.save(),
      );

      return true;
    } catch (e) {
      print('Erreur lors de l\'export du dossier expert: $e');
      return false;
    }
  }

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

  pw.Widget _buildHeader(AdherentModel adherent, Map<String, dynamic> coopSettings) {
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
                  coopSettings['nom_cooperative'] ?? 'Coopérative de Cacaoculteurs',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (coopSettings['adresse'] != null && coopSettings['adresse'].toString().isNotEmpty)
                  pw.Text(
                    coopSettings['adresse'].toString(),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                if (coopSettings['telephone'] != null && coopSettings['telephone'].toString().isNotEmpty)
                  pw.Text(
                    'Tél: ${coopSettings['telephone']}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'DOSSIER ADHÉRENT',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown700,
                  ),
                ),
                pw.Text(
                  'Code: ${adherent.code}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Date: ${_dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          adherent.fullName,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildIndicateursSection(AdherentExpertModel expert) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.brown300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.brown50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INDICATEURS CLÉS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicatorItem('Capital Social', '${_numberFormat.format(expert.capitalSocialSouscrit)} FCFA'),
              _buildIndicatorItem('Stock Disponible', '${_numberFormat.format(expert.tonnageDisponibleStock)} T'),
              _buildIndicatorItem('Solde Créditeur', '${_numberFormat.format(expert.soldeCrediteur)} FCFA'),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicatorItem('Solde Débiteur', '${_numberFormat.format(expert.soldeDebiteur)} FCFA'),
              _buildIndicatorItem('Ventes Total', '${_numberFormat.format(expert.montantTotalVentes)} FCFA'),
              _buildIndicatorItem('Paiements Total', '${_numberFormat.format(expert.montantTotalPaye)} FCFA'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildIndicatorItem(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInformationsPersonnellesSection(AdherentModel adherent) {
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
            'INFORMATIONS PERSONNELLES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Nom', adherent.nom),
                    _buildInfoRow('Prénom', adherent.prenom),
                    if (adherent.telephone != null)
                      _buildInfoRow('Téléphone', adherent.telephone!),
                    if (adherent.email != null)
                      _buildInfoRow('Email', adherent.email!),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (adherent.village != null)
                      _buildInfoRow('Village', adherent.village!),
                    if (adherent.adresse != null)
                      _buildInfoRow('Adresse', adherent.adresse!),
                    _buildInfoRow(
                      'Date d\'adhésion',
                      _dateFormat.format(adherent.dateAdhesion),
                    ),
                    _buildInfoRow('Statut', adherent.isActive ? 'Actif' : 'Inactif'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value ?? '-',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAyantsDroitSection(List<AyantDroitModel> ayantsDroit) {
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
            'AYANTS DROIT (${ayantsDroit.length})',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Nom Complet', isHeader: true),
                  _buildTableCell('Lien Familial', isHeader: true),
                  _buildTableCell('Date Naissance', isHeader: true),
                  _buildTableCell('Contact', isHeader: true),
                ],
              ),
              ...ayantsDroit.map((ayant) => pw.TableRow(
                children: [
                  _buildTableCell(ayant.nomComplet),
                  _buildTableCell(ayant.lienFamilial),
                  _buildTableCell(ayant.dateNaissance != null 
                      ? _dateFormat.format(ayant.dateNaissance!) 
                      : '-'),
                  _buildTableCell(ayant.contact ?? '-'),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildChampsSection(List<ChampParcelleModel> champs) {
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
            'CHAMPS & SUPERFICIES (${champs.length})',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Code', isHeader: true),
                  _buildTableCell('Nom', isHeader: true),
                  _buildTableCell('Superficie (ha)', isHeader: true),
                  _buildTableCell('Localisation', isHeader: true),
                  _buildTableCell('État', isHeader: true),
                ],
              ),
              ...champs.map((champ) => pw.TableRow(
                children: [
                  _buildTableCell(champ.codeChamp),
                  _buildTableCell(champ.nomChamp ?? '-'),
                  _buildTableCell(_numberFormat.format(champ.superficie)),
                  _buildTableCell(champ.localisation ?? '-'),
                  _buildTableCell(champ.etatChamp ?? '-'),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTraitementsSection(List<TraitementAgricoleModel> traitements) {
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
            'TRAITEMENTS AGRICOLES (${traitements.length})',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Date', isHeader: true),
                  _buildTableCell('Type', isHeader: true),
                  _buildTableCell('Produit', isHeader: true),
                  _buildTableCell('Quantité', isHeader: true),
                  _buildTableCell('Coût', isHeader: true),
                ],
              ),
              ...traitements.map((traitement) => pw.TableRow(
                children: [
                  _buildTableCell(_dateFormat.format(traitement.dateTraitement)),
                  _buildTableCell(traitement.typeTraitement),
                  _buildTableCell(traitement.produitUtilise),
                  _buildTableCell('${_numberFormat.format(traitement.quantite)} ${traitement.uniteQuantite}'),
                  _buildTableCell('${_numberFormat.format(traitement.coutTraitement)} FCFA'),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProductionStockSection(
    List<ProductionModel> productions,
    List<StockDepotModel> depotsStock,
    AdherentExpertModel expert,
  ) {
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
            'PRODUCTION & STOCK',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicatorItem('Tonnage Total Produit', '${_numberFormat.format(expert.tonnageTotalProduit)} T'),
              _buildIndicatorItem('Stock Disponible', '${_numberFormat.format(expert.tonnageDisponibleStock)} T'),
            ],
          ),
          if (productions.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Productions (${productions.length})',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Campagne', isHeader: true),
                    _buildTableCell('Tonnage Brut', isHeader: true),
                    _buildTableCell('Tonnage Net', isHeader: true),
                    _buildTableCell('Date Récolte', isHeader: true),
                    _buildTableCell('Qualité', isHeader: true),
                  ],
                ),
                ...productions.map((prod) => pw.TableRow(
                  children: [
                    _buildTableCell(prod.campagne),
                    _buildTableCell('${_numberFormat.format(prod.tonnageBrut)} T'),
                    _buildTableCell('${_numberFormat.format(prod.tonnageNet)} T'),
                    _buildTableCell(_dateFormat.format(prod.dateRecolte)),
                    _buildTableCell(prod.qualite ?? '-'),
                  ],
                )),
              ],
            ),
          ],
          if (depotsStock.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Dépôts Stock (${depotsStock.length})',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Date Dépôt', isHeader: true),
                    _buildTableCell('Poids Net (kg)', isHeader: true),
                    _buildTableCell('Qualité', isHeader: true),
                    _buildTableCell('Humidité', isHeader: true),
                  ],
                ),
                ...depotsStock.map((depot) => pw.TableRow(
                  children: [
                    _buildTableCell(_dateFormat.format(depot.dateDepot)),
                    _buildTableCell(_numberFormat.format(depot.poidsNet)),
                    _buildTableCell(depot.qualite ?? '-'),
                    _buildTableCell(depot.humidite != null 
                        ? '${_numberFormat.format(depot.humidite!)}%' 
                        : '-'),
                  ],
                )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildVentesPaiementsSection(
    List<VenteModel> ventes,
    List<RecetteModel> recettes,
    AdherentExpertModel expert,
  ) {
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
            'VENTES & PAIEMENTS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicatorItem('Montant Total Ventes', '${_numberFormat.format(expert.montantTotalVentes)} FCFA'),
              _buildIndicatorItem('Montant Total Payé', '${_numberFormat.format(expert.montantTotalPaye)} FCFA'),
              _buildIndicatorItem('Solde Créditeur', '${_numberFormat.format(expert.soldeCrediteur)} FCFA'),
            ],
          ),
          if (ventes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Ventes (${ventes.length})',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Date', isHeader: true),
                    _buildTableCell('Quantité (kg)', isHeader: true),
                    _buildTableCell('Prix Unitaire', isHeader: true),
                    _buildTableCell('Montant Total', isHeader: true),
                  ],
                ),
                ...ventes.take(10).map((vente) => pw.TableRow(
                  children: [
                    _buildTableCell(_dateFormat.format(vente.dateVente)),
                    _buildTableCell(_numberFormat.format(vente.quantiteTotal)),
                    _buildTableCell('${_numberFormat.format(vente.prixUnitaire)} FCFA'),
                    _buildTableCell('${_numberFormat.format(vente.montantTotal)} FCFA'),
                  ],
                )),
              ],
            ),
            if (ventes.length > 10)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  '... et ${ventes.length - 10} autres ventes',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
          ],
          if (recettes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Paiements (${recettes.length})',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Date', isHeader: true),
                    _buildTableCell('Montant Brut', isHeader: true),
                    _buildTableCell('Commission', isHeader: true),
                    _buildTableCell('Montant Net', isHeader: true),
                  ],
                ),
                ...recettes.take(10).map((recette) => pw.TableRow(
                  children: [
                    _buildTableCell(_dateFormat.format(recette.dateRecette)),
                    _buildTableCell('${_numberFormat.format(recette.montantBrut)} FCFA'),
                    _buildTableCell('${_numberFormat.format(recette.commissionAmount)} FCFA'),
                    _buildTableCell('${_numberFormat.format(recette.montantNet)} FCFA'),
                  ],
                )),
              ],
            ),
            if (recettes.length > 10)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  '... et ${recettes.length - 10} autres paiements',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildCapitalSocialSection(
    List<CapitalSocialModel> souscriptions,
    AdherentExpertModel expert,
  ) {
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
            'CAPITAL SOCIAL',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicatorItem('Capital Souscrit', '${_numberFormat.format(expert.capitalSocialSouscrit)} FCFA'),
              _buildIndicatorItem('Capital Libéré', '${_numberFormat.format(expert.capitalSocialLibere)} FCFA'),
              _buildIndicatorItem('Capital Restant', '${_numberFormat.format(expert.capitalSocialRestant)} FCFA'),
            ],
          ),
          if (souscriptions.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Date', isHeader: true),
                    _buildTableCell('Parts', isHeader: true),
                    _buildTableCell('Valeur Part', isHeader: true),
                    _buildTableCell('Capital Total', isHeader: true),
                    _buildTableCell('Statut', isHeader: true),
                  ],
                ),
                ...souscriptions.map((souscription) => pw.TableRow(
                  children: [
                    _buildTableCell(_dateFormat.format(souscription.dateSouscription)),
                    _buildTableCell('${souscription.nombrePartsSouscrites}'),
                    _buildTableCell('${_numberFormat.format(souscription.valeurPart)} FCFA'),
                    _buildTableCell('${_numberFormat.format(souscription.capitalTotal)} FCFA'),
                    _buildTableCell(souscription.statut),
                  ],
                )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildCreditsSociauxSection(List<CreditSocialModel> credits) {
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
            'CRÉDITS SOCIAUX (${credits.length})',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Date', isHeader: true),
                  _buildTableCell('Type', isHeader: true),
                  _buildTableCell('Montant', isHeader: true),
                  _buildTableCell('Remboursé', isHeader: true),
                  _buildTableCell('Solde Restant', isHeader: true),
                  _buildTableCell('Statut', isHeader: true),
                ],
              ),
              ...credits.map((credit) => pw.TableRow(
                children: [
                  _buildTableCell(_dateFormat.format(credit.dateOctroi)),
                  _buildTableCell(credit.isCreditProduit ? 'Produit' : 'Argent'),
                  _buildTableCell('${_numberFormat.format(credit.montant)} FCFA'),
                  _buildTableCell('${_numberFormat.format(credit.montantRembourse)} FCFA'),
                  _buildTableCell('${_numberFormat.format(credit.soldeRestant)} FCFA'),
                  _buildTableCell(credit.statutRemboursement),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String? text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text ?? '-',
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
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
      child: pw.Column(
        children: [
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Document généré le ${_dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            coopSettings['nom_cooperative'] ?? 'Coopérative de Cacaoculteurs',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }
}

