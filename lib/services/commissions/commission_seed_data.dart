/// Données d'exemple pour les commissions
/// Utilisé pour initialiser le système avec des commissions de base

import '../../data/models/commission_model.dart';

class CommissionSeedData {
  /// Créer les commissions d'exemple
  static List<CommissionModel> getExampleCommissions() {
    final maintenant = DateTime.now();
    final debutAnnee = DateTime(maintenant.year, 1, 1);
    final finPremierSemestre = DateTime(maintenant.year, 6, 30);
    final finAnnee = DateTime(maintenant.year, 12, 31);

    return [
      // Commission transport - permanente
      CommissionModel(
        code: 'TRANSPORT',
        libelle: 'Commission Transport',
        montantFixe: 25.0, // 25 FCFA/kg
        typeApplication: CommissionTypeApplication.parKg,
        dateDebut: debutAnnee,
        dateFin: null, // Permanente
        reconductible: false,
        statut: CommissionStatut.active,
        description: 'Commission pour le transport du cacao',
        createdAt: maintenant,
      ),

      // Commission sociale - temporaire, reconductible
      CommissionModel(
        code: 'SOCIALE',
        libelle: 'Commission Sociale',
        montantFixe: 10.0, // 10 FCFA/kg
        typeApplication: CommissionTypeApplication.parKg,
        dateDebut: debutAnnee,
        dateFin: finPremierSemestre,
        reconductible: true,
        periodeReconductionDays: 183, // 6 mois
        statut: CommissionStatut.active,
        description: 'Commission pour le fonds social (janvier-juin)',
        createdAt: maintenant,
      ),

      // Commission gestion - permanente
      CommissionModel(
        code: 'GESTION',
        libelle: 'Commission Gestion',
        montantFixe: 15.0, // 15 FCFA/kg
        typeApplication: CommissionTypeApplication.parKg,
        dateDebut: debutAnnee,
        dateFin: null, // Permanente
        reconductible: false,
        statut: CommissionStatut.active,
        description: 'Commission pour les frais de gestion',
        createdAt: maintenant,
      ),

      // Commission qualité - par vente
      CommissionModel(
        code: 'QUALITE',
        libelle: 'Commission Contrôle Qualité',
        montantFixe: 500.0, // 500 FCFA par vente
        typeApplication: CommissionTypeApplication.parVente,
        dateDebut: debutAnnee,
        dateFin: finAnnee,
        reconductible: true,
        periodeReconductionDays: 365, // 1 an
        statut: CommissionStatut.active,
        description: 'Commission pour le contrôle qualité (par vente)',
        createdAt: maintenant,
      ),
    ];
  }

  /// Exemple de calcul pour documentation
  static Map<String, dynamic> getExampleCalcul() {
    return {
      'vente': {
        'poids': 1000.0, // kg
        'prix_unitaire': 1500.0, // FCFA/kg
        'date': DateTime.now().toIso8601String(),
      },
      'commissions_actives': [
        {
          'code': 'TRANSPORT',
          'libelle': 'Commission Transport',
          'type': 'PAR_KG',
          'montant_fixe': 25.0,
          'montant_calcule': 25000.0, // 1000 kg × 25 FCFA/kg
        },
        {
          'code': 'SOCIALE',
          'libelle': 'Commission Sociale',
          'type': 'PAR_KG',
          'montant_fixe': 10.0,
          'montant_calcule': 10000.0, // 1000 kg × 10 FCFA/kg
        },
        {
          'code': 'GESTION',
          'libelle': 'Commission Gestion',
          'type': 'PAR_KG',
          'montant_fixe': 15.0,
          'montant_calcule': 15000.0, // 1000 kg × 15 FCFA/kg
        },
        {
          'code': 'QUALITE',
          'libelle': 'Commission Contrôle Qualité',
          'type': 'PAR_VENTE',
          'montant_fixe': 500.0,
          'montant_calcule': 500.0, // 1 vente × 500 FCFA
        },
      ],
      'calcul': {
        'montant_brut': 1500000.0, // 1000 kg × 1500 FCFA/kg
        'total_commissions': 50500.0, // 25000 + 10000 + 15000 + 500
        'montant_net': 1449500.0, // 1500000 - 50500
      },
    };
  }
}

