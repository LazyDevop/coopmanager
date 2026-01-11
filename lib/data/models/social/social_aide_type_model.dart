/// Modèle pour un type d'aide sociale (table maîtresse)
class SocialAideTypeModel {
  final int? id;
  final String code;
  final String libelle;
  final String categorie; // FINANCIERE, MATERIELLE, SOCIALE, TECHNIQUE
  final bool estRemboursable; // true = prêt/avance, false = don
  final double? plafondMontant;
  final int? dureeMaxMois;
  final String? modeRemboursement; // RETENUE_RECETTE, MANUEL, AUCUN
  final bool activation; // true = actif, false = inactif
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? createdBy;
  final int? updatedBy;

  SocialAideTypeModel({
    this.id,
    required this.code,
    required this.libelle,
    required this.categorie,
    this.estRemboursable = false,
    this.plafondMontant,
    this.dureeMaxMois,
    this.modeRemboursement,
    this.activation = true,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  bool get isActif => activation;
  bool get isRemboursable => estRemboursable;
  bool get isFinanciere => categorie == 'FINANCIERE';
  bool get isMaterielle => categorie == 'MATERIELLE';
  bool get isSociale => categorie == 'SOCIALE';
  bool get isTechnique => categorie == 'TECHNIQUE';
  bool get hasRetenueAutomatique => modeRemboursement == 'RETENUE_RECETTE';

  factory SocialAideTypeModel.fromMap(Map<String, dynamic> map) {
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
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

    String _parseStringRequired(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      return value.toString();
    }

    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return SocialAideTypeModel(
      id: _parseInt(map['id']),
      code: _parseStringRequired(map['code'], ''),
      libelle: _parseStringRequired(map['libelle'], ''),
      categorie: _parseStringRequired(map['categorie'], 'SOCIALE'),
      estRemboursable: _parseBool(map['est_remboursable'], defaultValue: false),
      plafondMontant: _parseDouble(map['plafond_montant']),
      dureeMaxMois: _parseInt(map['duree_max_mois']),
      modeRemboursement: map['mode_remboursement']?.toString(),
      activation: _parseBool(map['activation'], defaultValue: true),
      description: map['description']?.toString(),
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updated_at']),
      createdBy: _parseInt(map['created_by']),
      updatedBy: _parseInt(map['updated_by']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'libelle': libelle,
      'categorie': categorie,
      'est_remboursable': estRemboursable ? 1 : 0,
      if (plafondMontant != null) 'plafond_montant': plafondMontant,
      if (dureeMaxMois != null) 'duree_max_mois': dureeMaxMois,
      if (modeRemboursement != null) 'mode_remboursement': modeRemboursement,
      'activation': activation ? 1 : 0,
      if (description != null) 'description': description,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
    };
  }

  SocialAideTypeModel copyWith({
    int? id,
    String? code,
    String? libelle,
    String? categorie,
    bool? estRemboursable,
    double? plafondMontant,
    int? dureeMaxMois,
    String? modeRemboursement,
    bool? activation,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    int? updatedBy,
  }) {
    return SocialAideTypeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      libelle: libelle ?? this.libelle,
      categorie: categorie ?? this.categorie,
      estRemboursable: estRemboursable ?? this.estRemboursable,
      plafondMontant: plafondMontant ?? this.plafondMontant,
      dureeMaxMois: dureeMaxMois ?? this.dureeMaxMois,
      modeRemboursement: modeRemboursement ?? this.modeRemboursement,
      activation: activation ?? this.activation,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

