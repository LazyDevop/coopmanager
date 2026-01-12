import 'social_aide_model.dart';

/// Modèle pour un remboursement d'aide sociale
class SocialRemboursementModel {
  final int? id;
  final int aideId;
  final double montant;
  final DateTime dateRemboursement;
  final String source; // RETENUE_RECETTE, CAISSE
  final int? recetteId;
  final String? notes;
  final DateTime createdAt;
  final int? createdBy;

  // Relations (chargées séparément)
  SocialAideModel? aide;
  String? recetteNumero;

  SocialRemboursementModel({
    this.id,
    required this.aideId,
    required this.montant,
    required this.dateRemboursement,
    required this.source,
    this.recetteId,
    this.notes,
    required this.createdAt,
    this.createdBy,
    this.aide,
    this.recetteNumero,
  });

  bool get isRetenueRecette => source == 'RETENUE_RECETTE';
  bool get isCaisse => source == 'CAISSE';

  factory SocialRemboursementModel.fromMap(Map<String, dynamic> map) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    String parseStringRequired(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      return value.toString();
    }

    DateTime? parseDateTime(dynamic value) {
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

    return SocialRemboursementModel(
      id: parseInt(map['id']),
      aideId: parseInt(map['aide_id']) ?? 0,
      montant: parseDouble(map['montant']),
      dateRemboursement: parseDateTime(map['date_remboursement']) ?? DateTime.now(),
      source: parseStringRequired(map['source'], 'CAISSE'),
      recetteId: parseInt(map['recette_id']),
      notes: map['notes']?.toString(),
      createdAt: parseDateTime(map['created_at']) ?? DateTime.now(),
      createdBy: parseInt(map['created_by']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'aide_id': aideId,
      'montant': montant,
      'date_remboursement': dateRemboursement.toIso8601String(),
      'source': source,
      if (recetteId != null) 'recette_id': recetteId,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  SocialRemboursementModel copyWith({
    int? id,
    int? aideId,
    double? montant,
    DateTime? dateRemboursement,
    String? source,
    int? recetteId,
    String? notes,
    DateTime? createdAt,
    int? createdBy,
    SocialAideModel? aide,
    String? recetteNumero,
  }) {
    return SocialRemboursementModel(
      id: id ?? this.id,
      aideId: aideId ?? this.aideId,
      montant: montant ?? this.montant,
      dateRemboursement: dateRemboursement ?? this.dateRemboursement,
      source: source ?? this.source,
      recetteId: recetteId ?? this.recetteId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      aide: aide ?? this.aide,
      recetteNumero: recetteNumero ?? this.recetteNumero,
    );
  }
}

