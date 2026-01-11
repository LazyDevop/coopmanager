/// Modèles spécialisés pour les paramètres métier
import 'package:uuid/uuid.dart';

/// Paramètres du capital social
class CapitalSettingsModel {
  final String id;
  final String cooperativeId;
  final double valeurPart;
  final int partsMin;
  final int? partsMax;
  final bool liberationObligatoire;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CapitalSettingsModel({
    String? id,
    required this.cooperativeId,
    required this.valeurPart,
    required this.partsMin,
    this.partsMax,
    this.liberationObligatoire = false,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory CapitalSettingsModel.fromMap(Map<String, dynamic> map) {
    return CapitalSettingsModel(
      id: map['id'] as String,
      cooperativeId: map['cooperative_id'] as String,
      valeurPart: (map['valeur_part'] as num).toDouble(),
      partsMin: map['parts_min'] as int,
      partsMax: map['parts_max'] as int?,
      liberationObligatoire: (map['liberation_obligatoire'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cooperative_id': cooperativeId,
      'valeur_part': valeurPart,
      'parts_min': partsMin,
      if (partsMax != null) 'parts_max': partsMax,
      'liberation_obligatoire': liberationObligatoire ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

/// Paramètres comptables
class AccountingSettingsModel {
  final String id;
  final String cooperativeId;
  final int exerciceActif;
  final String planComptable;
  final double tauxReserve;
  final double tauxFraisGestion;
  final String? compteCaisse;
  final String? compteBanque;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AccountingSettingsModel({
    String? id,
    required this.cooperativeId,
    required this.exerciceActif,
    this.planComptable = 'SYSCOHADA',
    this.tauxReserve = 0.0,
    this.tauxFraisGestion = 0.0,
    this.compteCaisse,
    this.compteBanque,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory AccountingSettingsModel.fromMap(Map<String, dynamic> map) {
    return AccountingSettingsModel(
      id: map['id'] as String,
      cooperativeId: map['cooperative_id'] as String,
      exerciceActif: map['exercice_actif'] as int,
      planComptable: map['plan_comptable'] as String? ?? 'SYSCOHADA',
      tauxReserve: (map['taux_reserve'] as num? ?? 0).toDouble(),
      tauxFraisGestion: (map['taux_frais_gestion'] as num? ?? 0).toDouble(),
      compteCaisse: map['compte_caisse'] as String?,
      compteBanque: map['compte_banque'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cooperative_id': cooperativeId,
      'exercice_actif': exerciceActif,
      'plan_comptable': planComptable,
      'taux_reserve': tauxReserve,
      'taux_frais_gestion': tauxFraisGestion,
      if (compteCaisse != null) 'compte_caisse': compteCaisse,
      if (compteBanque != null) 'compte_banque': compteBanque,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

/// Paramètres de documents
enum DocumentType { facture, recu, vente, bordereau, autre }

class DocumentSettingsModel {
  final String id;
  final String cooperativeId;
  final DocumentType typeDocument;
  final String prefix;
  final String formatNumero;
  final String? piedPage;
  final bool signatureAuto;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DocumentSettingsModel({
    String? id,
    required this.cooperativeId,
    required this.typeDocument,
    required this.prefix,
    required this.formatNumero,
    this.piedPage,
    this.signatureAuto = false,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory DocumentSettingsModel.fromMap(Map<String, dynamic> map) {
    return DocumentSettingsModel(
      id: map['id'] as String,
      cooperativeId: map['cooperative_id'] as String,
      typeDocument: DocumentType.values.firstWhere(
        (e) => e.name == map['type_document'],
        orElse: () => DocumentType.facture,
      ),
      prefix: map['prefix'] as String,
      formatNumero: map['format_numero'] as String,
      piedPage: map['pied_page'] as String?,
      signatureAuto: (map['signature_auto'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cooperative_id': cooperativeId,
      'type_document': typeDocument.name,
      'prefix': prefix,
      'format_numero': formatNumero,
      if (piedPage != null) 'pied_page': piedPage,
      'signature_auto': signatureAuto ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Générer un numéro de document selon le format
  String generateNumero(int sequence) {
    final now = DateTime.now();
    return formatNumero
        .replaceAll('{PREFIX}', prefix)
        .replaceAll('{YEAR}', now.year.toString())
        .replaceAll('{MONTH}', now.month.toString().padLeft(2, '0'))
        .replaceAll('{NUM}', sequence.toString().padLeft(4, '0'));
  }
}

