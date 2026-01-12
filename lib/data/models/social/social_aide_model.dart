import 'social_aide_type_model.dart';

/// Modèle pour une aide sociale accordée
class SocialAideModel {
  final int? id;
  final int aideTypeId;
  final int adherentId;
  final double montant;
  final DateTime dateOctroi;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String statut; // accordee, en_cours, remboursée, annulée
  final String? observations;
  final int createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Relations (chargées séparément)
  SocialAideTypeModel? aideType;
  String? adherentNom;
  String? adherentCode;

  SocialAideModel({
    this.id,
    required this.aideTypeId,
    required this.adherentId,
    required this.montant,
    required this.dateOctroi,
    this.dateDebut,
    this.dateFin,
    this.statut = 'accordee',
    this.observations,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.aideType,
    this.adherentNom,
    this.adherentCode,
  });

  bool get isAccordee => statut == 'accordee';
  bool get isEnCours => statut == 'en_cours';
  bool get isRemboursee => statut == 'remboursée';
  bool get isAnnulee => statut == 'annulée';
  bool get isRemboursable => aideType?.estRemboursable ?? false;
  bool get canBeRembourse => isEnCours && isRemboursable;

  factory SocialAideModel.fromMap(Map<String, dynamic> map) {
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

    return SocialAideModel(
      id: parseInt(map['id']),
      aideTypeId: parseInt(map['aide_type_id']) ?? 0,
      adherentId: parseInt(map['adherent_id']) ?? 0,
      montant: parseDouble(map['montant']),
      dateOctroi: parseDateTime(map['date_octroi']) ?? DateTime.now(),
      dateDebut: parseDateTime(map['date_debut']),
      dateFin: parseDateTime(map['date_fin']),
      statut: parseStringRequired(map['statut'], 'accordee'),
      observations: map['observations']?.toString(),
      createdBy: parseInt(map['created_by']) ?? 0,
      createdAt: parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'aide_type_id': aideTypeId,
      'adherent_id': adherentId,
      'montant': montant,
      'date_octroi': dateOctroi.toIso8601String(),
      if (dateDebut != null) 'date_debut': dateDebut!.toIso8601String(),
      if (dateFin != null) 'date_fin': dateFin!.toIso8601String(),
      'statut': statut,
      if (observations != null) 'observations': observations,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  SocialAideModel copyWith({
    int? id,
    int? aideTypeId,
    int? adherentId,
    double? montant,
    DateTime? dateOctroi,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? statut,
    String? observations,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    SocialAideTypeModel? aideType,
    String? adherentNom,
    String? adherentCode,
  }) {
    return SocialAideModel(
      id: id ?? this.id,
      aideTypeId: aideTypeId ?? this.aideTypeId,
      adherentId: adherentId ?? this.adherentId,
      montant: montant ?? this.montant,
      dateOctroi: dateOctroi ?? this.dateOctroi,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      statut: statut ?? this.statut,
      observations: observations ?? this.observations,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aideType: aideType ?? this.aideType,
      adherentNom: adherentNom ?? this.adherentNom,
      adherentCode: adherentCode ?? this.adherentCode,
    );
  }
}

