/// Modèle de données pour une commission
/// Représente une règle métier autonome de commission

class CommissionModel {
  final int? id;
  final String code; // Code unique (ex: "TRANSPORT", "SOCIALE")
  final String libelle; // Libellé descriptif
  final double montantFixe; // Montant fixe en FCFA
  final CommissionTypeApplication typeApplication; // PAR_KG ou PAR_VENTE
  final DateTime dateDebut;
  final DateTime? dateFin; // NULL = permanente
  final bool reconductible;
  final int? periodeReconductionDays; // Nombre de jours pour reconduction
  final CommissionStatut statut;
  final String? description;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? updatedBy;

  CommissionModel({
    this.id,
    required this.code,
    required this.libelle,
    required this.montantFixe,
    required this.typeApplication,
    required this.dateDebut,
    this.dateFin,
    this.reconductible = false,
    this.periodeReconductionDays,
    this.statut = CommissionStatut.active,
    this.description,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.updatedBy,
  });

  /// Vérifier si la commission est applicable à une date donnée
  bool isApplicableAt(DateTime date) {
    if (statut != CommissionStatut.active) return false;
    
    if (date.isBefore(dateDebut)) return false;
    
    if (dateFin != null && date.isAfter(dateFin!)) return false;
    
    return true;
  }

  /// Calculer le montant de la commission pour une vente
  double calculateMontant({
    required double poidsVendu,
    required int nombreVentes,
  }) {
    switch (typeApplication) {
      case CommissionTypeApplication.parKg:
        return poidsVendu * montantFixe;
      case CommissionTypeApplication.parVente:
        return nombreVentes * montantFixe;
    }
  }

  /// Vérifier si la commission doit être reconduite
  bool shouldBeReconduced(DateTime currentDate) {
    if (!reconductible) return false;
    if (dateFin == null) return false; // Permanente, pas de reconduction
    if (periodeReconductionDays == null) return false;
    
    // Vérifier si la date de fin est passée
    return currentDate.isAfter(dateFin!);
  }

  /// Créer une nouvelle commission reconduite
  CommissionModel reconduire() {
    if (!reconductible || dateFin == null || periodeReconductionDays == null) {
      throw Exception('Cette commission ne peut pas être reconduite');
    }

    final nouvelleDateFin = dateFin!.add(Duration(days: periodeReconductionDays!));
    
    return CommissionModel(
      code: code,
      libelle: libelle,
      montantFixe: montantFixe,
      typeApplication: typeApplication,
      dateDebut: dateFin!.add(const Duration(days: 1)),
      dateFin: nouvelleDateFin,
      reconductible: reconductible,
      periodeReconductionDays: periodeReconductionDays,
      statut: statut,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  /// Convertir depuis Map (depuis la base de données)
  factory CommissionModel.fromMap(Map<String, dynamic> map) {
    return CommissionModel(
      id: _getInt(map['id']),
      code: _getString(map['code'])!,
      libelle: _getString(map['libelle'])!,
      montantFixe: _getDouble(map['montant_fixe'])!,
      typeApplication: CommissionTypeApplication.fromString(
        _getString(map['type_application']) ?? 'PAR_KG',
      ),
      dateDebut: _getDateTime(map['date_debut'])!,
      dateFin: _getDateTime(map['date_fin']),
      reconductible: _getBool(map['reconductible']) ?? false,
      periodeReconductionDays: _getInt(map['periode_reconduction_days']),
      statut: CommissionStatut.fromString(
        _getString(map['statut']) ?? 'active',
      ),
      description: _getString(map['description']),
      createdBy: _getInt(map['created_by']),
      createdAt: _getDateTime(map['created_at'])!,
      updatedAt: _getDateTime(map['updated_at']),
      updatedBy: _getInt(map['updated_by']),
    );
  }

  /// Convertir vers Map (pour la base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'libelle': libelle,
      'montant_fixe': montantFixe,
      'type_application': typeApplication.value,
      'date_debut': dateDebut.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'reconductible': reconductible ? 1 : 0,
      'periode_reconduction_days': periodeReconductionDays,
      'statut': statut.value,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  /// Créer une copie avec modifications
  CommissionModel copyWith({
    int? id,
    String? code,
    String? libelle,
    double? montantFixe,
    CommissionTypeApplication? typeApplication,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool? reconductible,
    int? periodeReconductionDays,
    CommissionStatut? statut,
    String? description,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? updatedBy,
  }) {
    return CommissionModel(
      id: id ?? this.id,
      code: code ?? this.code,
      libelle: libelle ?? this.libelle,
      montantFixe: montantFixe ?? this.montantFixe,
      typeApplication: typeApplication ?? this.typeApplication,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      reconductible: reconductible ?? this.reconductible,
      periodeReconductionDays: periodeReconductionDays ?? this.periodeReconductionDays,
      statut: statut ?? this.statut,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
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

  static bool? _getBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
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

/// Type d'application de la commission
enum CommissionTypeApplication {
  parKg('PAR_KG'),
  parVente('PAR_VENTE');

  final String value;
  const CommissionTypeApplication(this.value);

  static CommissionTypeApplication fromString(String value) {
    return CommissionTypeApplication.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CommissionTypeApplication.parKg,
    );
  }
}

/// Statut de la commission
enum CommissionStatut {
  active('active'),
  inactive('inactive');

  final String value;
  const CommissionStatut(this.value);

  static CommissionStatut fromString(String value) {
    return CommissionStatut.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CommissionStatut.active,
    );
  }
}

