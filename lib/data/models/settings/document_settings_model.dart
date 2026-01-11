/// Modèle pour les paramètres de documents et QR Code
class DocumentSettingsModel {
  final Map<String, DocumentTypeConfig> typesDocuments;
  final String? mentionsLegales;
  final bool signatureAutomatique;
  final bool qrCodeActif;
  final String? qrCodeFormat; // 'url', 'json', 'custom'
  final String? qrCodeUrlBase;

  DocumentSettingsModel({
    this.typesDocuments = const {},
    this.mentionsLegales,
    this.signatureAutomatique = false,
    this.qrCodeActif = false,
    this.qrCodeFormat = 'url',
    this.qrCodeUrlBase,
  });

  factory DocumentSettingsModel.fromMap(Map<String, dynamic> map) {
    // Helper functions for safe type conversion
    String? _parseString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    String _parseStringRequired(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      return value.toString();
    }

    bool _parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        if (value.toLowerCase() == 'true' || value == '1') return true;
        if (value.toLowerCase() == 'false' || value == '0') return false;
        return defaultValue;
      }
      return defaultValue;
    }

    final typesDocs = <String, DocumentTypeConfig>{};
    if (map['types_documents'] != null && map['types_documents'] is Map) {
      final docsMap = map['types_documents'] as Map<String, dynamic>;
      docsMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          typesDocs[key] = DocumentTypeConfig.fromMap(value);
        }
      });
    }

    return DocumentSettingsModel(
      typesDocuments: typesDocs,
      mentionsLegales: _parseString(map['mentions_legales']),
      signatureAutomatique: _parseBool(map['signature_automatique']),
      qrCodeActif: _parseBool(map['qr_code_actif']),
      qrCodeFormat: _parseStringRequired(map['qr_code_format'], 'url'),
      qrCodeUrlBase: _parseString(map['qr_code_url_base']),
    );
  }

  Map<String, dynamic> toMap() {
    final typesDocsMap = <String, dynamic>{};
    typesDocuments.forEach((key, value) {
      typesDocsMap[key] = value.toMap();
    });

    return {
      'types_documents': typesDocsMap,
      if (mentionsLegales != null) 'mentions_legales': mentionsLegales,
      'signature_automatique': signatureAutomatique ? 1 : 0,
      'qr_code_actif': qrCodeActif ? 1 : 0,
      'qr_code_format': qrCodeFormat,
      if (qrCodeUrlBase != null) 'qr_code_url_base': qrCodeUrlBase,
    };
  }

  DocumentSettingsModel copyWith({
    Map<String, DocumentTypeConfig>? typesDocuments,
    String? mentionsLegales,
    bool? signatureAutomatique,
    bool? qrCodeActif,
    String? qrCodeFormat,
    String? qrCodeUrlBase,
  }) {
    return DocumentSettingsModel(
      typesDocuments: typesDocuments ?? this.typesDocuments,
      mentionsLegales: mentionsLegales ?? this.mentionsLegales,
      signatureAutomatique: signatureAutomatique ?? this.signatureAutomatique,
      qrCodeActif: qrCodeActif ?? this.qrCodeActif,
      qrCodeFormat: qrCodeFormat ?? this.qrCodeFormat,
      qrCodeUrlBase: qrCodeUrlBase ?? this.qrCodeUrlBase,
    );
  }
}

/// Configuration pour un type de document
class DocumentTypeConfig {
  final String prefixe;
  final String formatNumero; // 'YYYY-NNNN', 'NNNN', etc.
  final bool actif;
  final String? template;

  DocumentTypeConfig({
    required this.prefixe,
    required this.formatNumero,
    this.actif = true,
    this.template,
  });

  factory DocumentTypeConfig.fromMap(Map<String, dynamic> map) {
    // Helper functions for safe type conversion
    String _parseStringRequired(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      return value.toString();
    }

    String? _parseString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    bool _parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        if (value.toLowerCase() == 'true' || value == '1') return true;
        if (value.toLowerCase() == 'false' || value == '0') return false;
        return defaultValue;
      }
      return defaultValue;
    }

    return DocumentTypeConfig(
      prefixe: _parseStringRequired(map['prefixe'], ''),
      formatNumero: _parseStringRequired(map['format_numero'], ''),
      actif: _parseBool(map['actif'], defaultValue: true),
      template: _parseString(map['template']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prefixe': prefixe,
      'format_numero': formatNumero,
      'actif': actif ? 1 : 0,
      if (template != null) 'template': template,
    };
  }
}

