/// Modèle de données pour une Écriture Comptable
class EcritureComptableModel {
  final int? id;
  final String numero;
  final DateTime dateEcriture;
  final String typeOperation; // 'vente', 'recette', 'aide_sociale', 'capital'
  final int? operationId; // ID de l'opération source
  final String compteDebit;
  final String compteCredit;
  final double montant;
  final String libelle;
  final String? reference;
  final bool isValide;
  final int? createdBy;
  final DateTime createdAt;

  EcritureComptableModel({
    this.id,
    required this.numero,
    required this.dateEcriture,
    required this.typeOperation,
    this.operationId,
    required this.compteDebit,
    required this.compteCredit,
    required this.montant,
    required this.libelle,
    this.reference,
    this.isValide = true,
    this.createdBy,
    required this.createdAt,
  });

  bool get isVente => typeOperation == 'vente';
  bool get isRecette => typeOperation == 'recette';
  bool get isAideSociale => typeOperation == 'aide_sociale';
  bool get isCapital => typeOperation == 'capital';

  // Convertir depuis Map (base de données)
  factory EcritureComptableModel.fromMap(Map<String, dynamic> map) {
    return EcritureComptableModel(
      id: map['id'] as int?,
      numero: map['numero'] as String,
      dateEcriture: DateTime.parse(map['date_ecriture'] as String),
      typeOperation: map['type_operation'] as String,
      operationId: map['operation_id'] as int?,
      compteDebit: map['compte_debit'] as String,
      compteCredit: map['compte_credit'] as String,
      montant: (map['montant'] as num).toDouble(),
      libelle: map['libelle'] as String,
      reference: map['reference'] as String?,
      isValide: (map['is_valide'] as int? ?? 1) == 1,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numero': numero,
      'date_ecriture': dateEcriture.toIso8601String(),
      'type_operation': typeOperation,
      'operation_id': operationId,
      'compte_debit': compteDebit,
      'compte_credit': compteCredit,
      'montant': montant,
      'libelle': libelle,
      'reference': reference,
      'is_valide': isValide ? 1 : 0,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  EcritureComptableModel copyWith({
    int? id,
    String? numero,
    DateTime? dateEcriture,
    String? typeOperation,
    int? operationId,
    String? compteDebit,
    String? compteCredit,
    double? montant,
    String? libelle,
    String? reference,
    bool? isValide,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return EcritureComptableModel(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      dateEcriture: dateEcriture ?? this.dateEcriture,
      typeOperation: typeOperation ?? this.typeOperation,
      operationId: operationId ?? this.operationId,
      compteDebit: compteDebit ?? this.compteDebit,
      compteCredit: compteCredit ?? this.compteCredit,
      montant: montant ?? this.montant,
      libelle: libelle ?? this.libelle,
      reference: reference ?? this.reference,
      isValide: isValide ?? this.isValide,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Plan de comptes simplifié
class PlanComptes {
  // Comptes de classe 1 - Financement
  static const String compteCapital = '101';
  static const String compteReserves = '106';
  static const String compteFondsSocial = '107'; // V2: Fonds social
  
  // Comptes de classe 2 - Immobilisations
  static const String compteImmobilisations = '200';
  
  // Comptes de classe 3 - Stocks
  static const String compteStockCacao = '310';
  
  // Comptes de classe 4 - Tiers
  static const String compteClients = '411';
  static const String compteAdherents = '412';
  
  // Comptes de classe 5 - Trésorerie
  static const String compteCaisse = '530';
  static const String compteBanque = '512';
  
  // Comptes de classe 6 - Charges
  static const String compteAchats = '600';
  static const String compteAidesSociales = '650';
  
  // Comptes de classe 7 - Produits
  static const String compteVentes = '700';
  static const String compteCommissions = '706';
}

