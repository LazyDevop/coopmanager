/// Modèle de données pour un Client (Acheteur)
class ClientModel {
  final int? id;
  final String code;
  final String nom;
  final String type; // 'entreprise', 'particulier', 'cooperative'
  final String? telephone;
  final String? email;
  final String? adresse;
  final String? ville;
  final String pays;
  final String? siret; // Pour entreprises
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClientModel({
    this.id,
    required this.code,
    required this.nom,
    required this.type,
    this.telephone,
    this.email,
    this.adresse,
    this.ville,
    this.pays = 'Cameroun',
    this.siret,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  String get displayName => nom;
  bool get isEntreprise => type == 'entreprise';
  bool get isParticulier => type == 'particulier';
  bool get isCooperative => type == 'cooperative';

  // Convertir depuis Map (base de données)
  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as int?,
      code: map['code'] as String,
      nom: map['nom'] as String,
      type: map['type'] as String,
      telephone: map['telephone'] as String?,
      email: map['email'] as String?,
      adresse: map['adresse'] as String?,
      ville: map['ville'] as String?,
      pays: map['pays'] as String? ?? 'Cameroun',
      siret: map['siret'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'nom': nom,
      'type': type,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'ville': ville,
      'pays': pays,
      'siret': siret,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  ClientModel copyWith({
    int? id,
    String? code,
    String? nom,
    String? type,
    String? telephone,
    String? email,
    String? adresse,
    String? ville,
    String? pays,
    String? siret,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      code: code ?? this.code,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      pays: pays ?? this.pays,
      siret: siret ?? this.siret,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

