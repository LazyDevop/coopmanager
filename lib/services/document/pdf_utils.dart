import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/parametrage_models.dart';
import '../../data/models/settings/cooperative_settings_model.dart';
import '../../data/models/settings/document_settings_model.dart';
import '../parametres/parametrage_complet_service.dart';
import '../parametres/central_settings_service.dart';
import 'pdf_engine.dart';

/// Utilitaires centralisés pour la génération PDF modulaire CoopManager
class PdfUtils {
  /// Charge la police de base (Roboto-Regular.ttf)
  static Future<pw.Font> loadBaseFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      return pw.Font.ttf(data);
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  /// Charge la police grasse (Roboto-Bold.ttf)
  static Future<pw.Font> loadBoldFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      return pw.Font.ttf(data);
    } catch (_) {
      return pw.Font.helveticaBold();
    }
  }

  /// Charge la police italique (Roboto-Italic.ttf)
  static Future<pw.Font> loadItalicFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');
      return pw.Font.ttf(data);
    } catch (_) {
      return pw.Font.helveticaOblique();
    }
  }

  static Future<CooperativeSettingsModel> loadCooperativeSettings() async {
    // Source 1: settings centralisés (table `settings`).
    CooperativeSettingsModel base;
    try {
      final service = CentralSettingsService();
      base = await service.getCooperativeSettings();
    } catch (_) {
      base = CooperativeSettingsModel(
        raisonSociale: 'Coopérative de Cacaoculteurs',
        devise: 'XAF',
        langue: 'FR',
      );
    }

    // Source 2 (fallback/override): module Paramétrage complet (table `cooperative_entity`).
    // Objectif: utiliser les infos réellement configurées dans l'écran Paramétrage,
    // même si elles ne sont pas encore synchronisées vers la table `settings`.
    try {
      final entity = await ParametrageCompletService().getCooperativeEntity();
      if (entity == null) return base;

      String? nonEmpty(String? v) {
        final t = v?.trim();
        return (t == null || t.isEmpty) ? null : t;
      }

      String deviseToCode() {
        switch (entity.devisePrincipale) {
          case Devise.xaf:
            return 'XAF';
          case Devise.eur:
            return 'EUR';
          case Devise.usd:
            return 'USD';
          case Devise.cfa:
            return 'CFA';
        }
      }

      String langueToCode() {
        switch (entity.langueParDefaut) {
          case Langue.fr:
            return 'FR';
          case Langue.en:
            return 'EN';
        }
      }

      return base.copyWith(
        raisonSociale: entity.raisonSociale.trim().isNotEmpty
            ? entity.raisonSociale.trim()
            : base.raisonSociale,
        sigle: nonEmpty(entity.sigle) ?? base.sigle,
        formeJuridique: entity.formeJuridique.name.toUpperCase(),
        numeroAgrement: nonEmpty(entity.numeroAgrement) ?? base.numeroAgrement,
        rccm: nonEmpty(entity.registreCommerce) ?? base.rccm,
        dateCreation: entity.dateCreation ?? base.dateCreation,
        adresse: nonEmpty(entity.adresse) ?? base.adresse,
        region: nonEmpty(entity.region) ?? base.region,
        departement: nonEmpty(entity.departement) ?? base.departement,
        telephone: nonEmpty(entity.telephone) ?? base.telephone,
        email: nonEmpty(entity.email) ?? base.email,
        devise: deviseToCode(),
        langue: langueToCode(),
        logoPath: nonEmpty(entity.logoPath) ?? base.logoPath,
        updatedAt: entity.updatedAt ?? base.updatedAt,
      );
    } catch (_) {
      return base;
    }
  }

  static Future<DocumentSettingsModel> loadDocumentSettings() async {
    final service = CentralSettingsService();
    return service.getDocumentSettings();
  }

  /// Charge les métadonnées du document (à adapter selon votre logique)
  static Future<DocumentMeta> loadDocumentMeta(dynamic ref, String qrHash) async {
    final generatedAt = DateTime.now();
    final coopSettings = await loadCooperativeSettings();
    final documentSettings = await loadDocumentSettings();

    Uint8List? logoBytes;
    final logoPath = (coopSettings.logoPath ?? '').trim();
    if (logoPath.isNotEmpty) {
      try {
        final file = File(logoPath);
        if (await file.exists()) {
          logoBytes = await file.readAsBytes();
        }
      } catch (_) {
        // ignore
      }
    }

    final reference = ref.toString();
    return DocumentMeta(
      logoBytes: logoBytes,
      generatedAt: generatedAt,
      referenceDocument: reference,
      documentSettings: documentSettings,
      qrData: {
        'type': 'DOC',
        'reference': reference,
        if (qrHash.trim().isNotEmpty) 'hash': qrHash,
        'generated_at': generatedAt.toIso8601String(),
      },
    );
  }

  /// Retourne le répertoire d'export PDF
  static Future<Directory> getExportDirectory([String subdir = 'exports']) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/$subdir');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }
}
