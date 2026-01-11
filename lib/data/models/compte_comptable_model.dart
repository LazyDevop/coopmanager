/// MODÈLE : COMPTE COMPTABLE SIMPLIFIÉ
/// 
/// Représente un compte du plan comptable simplifié

class CompteComptableModel {
  final int? id;
  final String codeCompte; // Ex: '101', '53', '70', '65'
  final String libelle; // Description du compte
  final String type; // 'Actif', 'Passif', 'Produit', 'Charge'
  final double solde; // Solde actuel du compte

  CompteComptableModel({
    this.id,
    required this.codeCompte,
    required this.libelle,
    required this.type,
    this.solde = 0.0,
  });

  // Getters pour faciliter l'utilisation
  bool get isActif => type == 'Actif';
  bool get isPassif => type == 'Passif';
  bool get isProduit => type == 'Produit';
  bool get isCharge => type == 'Charge';

  // Convertir depuis Map (base de données)
  factory CompteComptableModel.fromMap(Map<String, dynamic> map) {
    return CompteComptableModel(
      id: map['id'] as int?,
      codeCompte: map['code_compte'] as String,
      libelle: map['libelle'] as String,
      type: map['type'] as String,
      solde: (map['solde'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Convertir vers Map (pour base de données)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code_compte': codeCompte,
      'libelle': libelle,
      'type': type,
      'solde': solde,
    };
  }

  // Créer une copie avec des modifications
  CompteComptableModel copyWith({
    int? id,
    String? codeCompte,
    String? libelle,
    String? type,
    double? solde,
  }) {
    return CompteComptableModel(
      id: id ?? this.id,
      codeCompte: codeCompte ?? this.codeCompte,
      libelle: libelle ?? this.libelle,
      type: type ?? this.type,
      solde: solde ?? this.solde,
    );
  }
}

/// Plan de comptes simplifié étendu pour la fusion
class PlanComptesFusionne {
  // Classe 1 - Financement
  static const String compteCapitalSouscrit = '1011'; // Capital souscrit
  static const String compteCapitalLibere = '1012'; // Capital libéré
  static const String compteReserves = '106';
  static const String compteFondsSocial = '107';
  
  // Classe 2 - Immobilisations
  static const String compteImmobilisations = '200';
  
  // Classe 3 - Stocks
  static const String compteStockCacao = '310';
  
  // Classe 4 - Tiers
  static const String compteClients = '411';
  static const String compteAdherents = '412';
  static const String compteActionnaires = '413'; // Compte actionnaire individuel
  
  // Classe 5 - Trésorerie
  static const String compteCaisse = '530';
  static const String compteBanque = '512';
  
  // Classe 6 - Charges
  static const String compteAchats = '600';
  static const String compteAidesSociales = '650';
  static const String compteChargesSociales = '651';
  
  // Classe 7 - Produits
  static const String compteVentes = '700';
  static const String compteCommissions = '706';
  
  /// Obtenir le type de compte selon son code
  static String getTypeCompte(String codeCompte) {
    if (codeCompte.startsWith('1') || codeCompte.startsWith('2') || 
        codeCompte.startsWith('3') || codeCompte.startsWith('4') || 
        codeCompte.startsWith('5')) {
      return 'Actif';
    } else if (codeCompte.startsWith('6')) {
      return 'Charge';
    } else if (codeCompte.startsWith('7')) {
      return 'Produit';
    } else {
      return 'Passif';
    }
  }
}

