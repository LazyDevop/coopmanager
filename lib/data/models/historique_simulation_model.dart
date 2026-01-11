/// Modèle de données pour l'Historique des Simulations (V2)
/// 
/// Conserve l'historique des simulations pour analyse et comparaison
class HistoriqueSimulationModel {
  final int? id;
  final int simulationId;
  final String action; // 'create', 'update', 'validate', 'reject'
  final Map<String, dynamic> donneesAvant; // État avant modification
  final Map<String, dynamic> donneesApres; // État après modification
  final String? commentaire;
  final int? userId;
  final DateTime createdAt;

  HistoriqueSimulationModel({
    this.id,
    required this.simulationId,
    required this.action,
    required this.donneesAvant,
    required this.donneesApres,
    this.commentaire,
    this.userId,
    required this.createdAt,
  });

  factory HistoriqueSimulationModel.fromMap(Map<String, dynamic> map) {
    return HistoriqueSimulationModel(
      id: map['id'] as int?,
      simulationId: map['simulation_id'] as int,
      action: map['action'] as String,
      donneesAvant: map['donnees_avant'] as Map<String, dynamic>? ?? {},
      donneesApres: map['donnees_apres'] as Map<String, dynamic>? ?? {},
      commentaire: map['commentaire'] as String?,
      userId: map['user_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'simulation_id': simulationId,
      'action': action,
      'donnees_avant': donneesAvant.toString(), // Stocker comme JSON string
      'donnees_apres': donneesApres.toString(), // Stocker comme JSON string
      'commentaire': commentaire,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  HistoriqueSimulationModel copyWith({
    int? id,
    int? simulationId,
    String? action,
    Map<String, dynamic>? donneesAvant,
    Map<String, dynamic>? donneesApres,
    String? commentaire,
    int? userId,
    DateTime? createdAt,
  }) {
    return HistoriqueSimulationModel(
      id: id ?? this.id,
      simulationId: simulationId ?? this.simulationId,
      action: action ?? this.action,
      donneesAvant: donneesAvant ?? this.donneesAvant,
      donneesApres: donneesApres ?? this.donneesApres,
      commentaire: commentaire ?? this.commentaire,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

