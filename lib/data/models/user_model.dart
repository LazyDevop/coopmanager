class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String nom;
  final String prenom;
  final String role;
  final String? email;
  final String? phone;
  final bool isActive;
  final DateTime? dernierLogin;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.nom,
    required this.prenom,
    required this.role,
    this.email,
    this.phone,
    this.isActive = true,
    this.dernierLogin,
    required this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$prenom $nom';

  // Convertir depuis Map (base de données)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      nom: map['nom'] as String,
      prenom: map['prenom'] as String,
      role: map['role'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      dernierLogin: map['dernier_login'] != null
          ? DateTime.parse(map['dernier_login'] as String)
          : null,
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
      'username': username,
      'password_hash': passwordHash,
      'nom': nom,
      'prenom': prenom,
      'role': role,
      'email': email,
      'phone': phone,
      'is_active': isActive ? 1 : 0,
      'dernier_login': dernierLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  UserModel copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? nom,
    String? prenom,
    String? role,
    String? email,
    String? phone,
    bool? isActive,
    DateTime? dernierLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      dernierLogin: dernierLogin ?? this.dernierLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
