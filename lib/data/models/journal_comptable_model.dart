/// MODÈLE : JOURNAL COMPTABLE UNIFIÉ
/// 
/// Journal unique, typé, pour toutes les opérations financières
/// Fusion Capital Social + Comptabilité Simplifiée

class JournalComptableModel {
  final int? id;
  final DateTime dateOperation;
  final String typeJournal; // 'Capital', 'Vente', 'Paiement', 'Social', 'Charge'
  final String reference; // Code unique
  final String libelle; // Description
  final double debit;
  final double credit;
  final double soldeApres; // Solde après l'opération
  final String sourceModule; // 'Capital', 'Vente', 'Paiement', 'Recette', etc.
  final int? sourceId; // ID de l'opération métier
  final int? createdBy;
  final DateTime createdAt;

  JournalComptableModel({
    this.id,
    required this.dateOperation,
    required this.typeJournal,
    required this.reference,
    required this.libelle,
    required this.debit,
    required this.credit,
    required this.soldeApres,
    required this.sourceModule,
    this.sourceId,
    this.createdBy,
    required this.createdAt,
  });

  // Getters pour faciliter l'utilisation
  bool get isCapital => typeJournal == 'Capital';
  bool get isVente => typeJournal == 'Vente';
  bool get isPaiement => typeJournal == 'Paiement';
  bool get isSocial => typeJournal == 'Social';
  bool get isCharge => typeJournal == 'Charge';

  // Convertir depuis Map (base de données)
  factory JournalComptableModel.fromMap(Map<String, dynamic> map) {
    return JournalComptableModel(
      id: map['id'] as int?,
      dateOperation: DateTime.parse(map['date_operation'] as String),
      typeJournal: map['type_journal'] as String,
      reference: map['reference'] as String,
      libelle: map['libelle'] as String,
      debit: (map['debit'] as num).toDouble(),
      credit: (map['credit'] as num).toDouble(),
      soldeApres: (map['solde_apres'] as num).toDouble(),
      sourceModule: map['source_module'] as String,
      sourceId: map['source_id'] as int?,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date_operation': dateOperation.toIso8601String(),
      'type_journal': typeJournal,
      'reference': reference,
      'libelle': libelle,
      'debit': debit,
      'credit': credit,
      'solde_apres': soldeApres,
      'source_module': sourceModule,
      if (sourceId != null) 'source_id': sourceId,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  JournalComptableModel copyWith({
    int? id,
    DateTime? dateOperation,
    String? typeJournal,
    String? reference,
    String? libelle,
    double? debit,
    double? credit,
    double? soldeApres,
    String? sourceModule,
    int? sourceId,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return JournalComptableModel(
      id: id ?? this.id,
      dateOperation: dateOperation ?? this.dateOperation,
      typeJournal: typeJournal ?? this.typeJournal,
      reference: reference ?? this.reference,
      libelle: libelle ?? this.libelle,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      soldeApres: soldeApres ?? this.soldeApres,
      sourceModule: sourceModule ?? this.sourceModule,
      sourceId: sourceId ?? this.sourceId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

