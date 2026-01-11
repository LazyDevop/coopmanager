/// MODÈLE : ÉCRITURE CAPITAL (LIAISON)
/// 
/// Lie une opération de capital à une écriture comptable

class EcritureCapitalModel {
  final int? id;
  final int actionnaireId; // FK vers adherents
  final String typeOperation; // 'Souscription', 'Liberation'
  final double montant;
  final String compteDebit; // Compte débité
  final String compteCredit; // Compte crédité
  final int journalId; // FK vers journal_comptable
  final DateTime date;
  final String? reference; // Référence externe
  final String? notes;
  final int? createdBy;
  final DateTime createdAt;

  EcritureCapitalModel({
    this.id,
    required this.actionnaireId,
    required this.typeOperation,
    required this.montant,
    required this.compteDebit,
    required this.compteCredit,
    required this.journalId,
    required this.date,
    this.reference,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  // Getters pour faciliter l'utilisation
  bool get isSouscription => typeOperation == 'Souscription';
  bool get isLiberation => typeOperation == 'Liberation';

  // Convertir depuis Map (base de données)
  factory EcritureCapitalModel.fromMap(Map<String, dynamic> map) {
    return EcritureCapitalModel(
      id: map['id'] as int?,
      actionnaireId: map['actionnaire_id'] as int,
      typeOperation: map['type_operation'] as String,
      montant: (map['montant'] as num).toDouble(),
      compteDebit: map['compte_debit'] as String,
      compteCredit: map['compte_credit'] as String,
      journalId: map['journal_id'] as int,
      date: DateTime.parse(map['date'] as String),
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'actionnaire_id': actionnaireId,
      'type_operation': typeOperation,
      'montant': montant,
      'compte_debit': compteDebit,
      'compte_credit': compteCredit,
      'journal_id': journalId,
      'date': date.toIso8601String(),
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  EcritureCapitalModel copyWith({
    int? id,
    int? actionnaireId,
    String? typeOperation,
    double? montant,
    String? compteDebit,
    String? compteCredit,
    int? journalId,
    DateTime? date,
    String? reference,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return EcritureCapitalModel(
      id: id ?? this.id,
      actionnaireId: actionnaireId ?? this.actionnaireId,
      typeOperation: typeOperation ?? this.typeOperation,
      montant: montant ?? this.montant,
      compteDebit: compteDebit ?? this.compteDebit,
      compteCredit: compteCredit ?? this.compteCredit,
      journalId: journalId ?? this.journalId,
      date: date ?? this.date,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

