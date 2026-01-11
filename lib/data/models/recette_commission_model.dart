/// Modèle de données pour une commission appliquée à une recette
/// Snapshot qui garantit que les recettes passées ne changent jamais

import 'commission_model.dart';

class RecetteCommissionModel {
  final int? id;
  final int recetteId;
  final String commissionCode;
  final String commissionLibelle;
  final double montantApplique;
  final CommissionTypeApplication typeApplication;
  final double? poidsVendu;
  final double montantFixeUtilise;
  final DateTime dateApplication;
  final DateTime createdAt;

  RecetteCommissionModel({
    this.id,
    required this.recetteId,
    required this.commissionCode,
    required this.commissionLibelle,
    required this.montantApplique,
    required this.typeApplication,
    this.poidsVendu,
    required this.montantFixeUtilise,
    required this.dateApplication,
    required this.createdAt,
  });

  /// Convertir depuis Map (depuis la base de données)
  factory RecetteCommissionModel.fromMap(Map<String, dynamic> map) {
    return RecetteCommissionModel(
      id: _getInt(map['id']),
      recetteId: _getInt(map['recette_id'])!,
      commissionCode: _getString(map['commission_code'])!,
      commissionLibelle: _getString(map['commission_libelle'])!,
      montantApplique: _getDouble(map['montant_applique'])!,
      typeApplication: CommissionTypeApplication.fromString(
        _getString(map['type_application']) ?? 'PAR_KG',
      ),
      poidsVendu: _getDouble(map['poids_vendu']),
      montantFixeUtilise: _getDouble(map['montant_fixe_utilise'])!,
      dateApplication: _getDateTime(map['date_application'])!,
      createdAt: _getDateTime(map['created_at'])!,
    );
  }

  /// Convertir vers Map (pour la base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'recette_id': recetteId,
      'commission_code': commissionCode,
      'commission_libelle': commissionLibelle,
      'montant_applique': montantApplique,
      'type_application': typeApplication.value,
      'poids_vendu': poidsVendu,
      'montant_fixe_utilise': montantFixeUtilise,
      'date_application': dateApplication.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helpers pour parsing sécurisé
  static int? _getInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _getDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _getString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static DateTime? _getDateTime(dynamic value) {
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
}

