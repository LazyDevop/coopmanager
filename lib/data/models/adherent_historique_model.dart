class AdherentHistoriqueModel {
  final int? id;
  final int adherentId;
  final String typeOperation; // 'depot', 'vente', 'recette', 'modification'
  final int? operationId; // ID de l'opération liée (depot_id, vente_id, etc.)
  final String description;
  final double? montant;
  final double? quantite;
  final DateTime dateOperation;
  final int? createdBy;
  final DateTime createdAt;

  AdherentHistoriqueModel({
    this.id,
    required this.adherentId,
    required this.typeOperation,
    this.operationId,
    required this.description,
    this.montant,
    this.quantite,
    required this.dateOperation,
    this.createdBy,
    required this.createdAt,
  });

  // Convertir depuis Map (base de données)
  factory AdherentHistoriqueModel.fromMap(Map<String, dynamic> map) {
    return AdherentHistoriqueModel(
      id: map['id'] as int?,
      adherentId: map['adherent_id'] as int,
      typeOperation: map['type_operation'] as String,
      operationId: map['operation_id'] as int?,
      description: map['description'] as String,
      montant: map['montant'] != null ? (map['montant'] as num).toDouble() : null,
      quantite: map['quantite'] != null ? (map['quantite'] as num).toDouble() : null,
      dateOperation: DateTime.parse(map['date_operation'] as String),
      createdBy: map['created_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adherent_id': adherentId,
      'type_operation': typeOperation,
      'operation_id': operationId,
      'description': description,
      'montant': montant,
      'quantite': quantite,
      'date_operation': dateOperation.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
