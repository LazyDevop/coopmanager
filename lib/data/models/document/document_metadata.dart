/// Métadonnées pour les différents types de documents

/// Métadonnées pour une facture de vente
class FactureVenteMetadata {
  final int factureId;
  final int venteId;
  final int adherentId;
  final double montantTotal;
  final DateTime dateVente;

  FactureVenteMetadata({
    required this.factureId,
    required this.venteId,
    required this.adherentId,
    required this.montantTotal,
    required this.dateVente,
  });

  Map<String, dynamic> toMap() {
    return {
      'facture_id': factureId,
      'vente_id': venteId,
      'adherent_id': adherentId,
      'montant_total': montantTotal,
      'date_vente': dateVente.toIso8601String(),
    };
  }

  factory FactureVenteMetadata.fromMap(Map<String, dynamic> map) {
    return FactureVenteMetadata(
      factureId: map['facture_id'] as int,
      venteId: map['vente_id'] as int,
      adherentId: map['adherent_id'] as int,
      montantTotal: (map['montant_total'] as num).toDouble(),
      dateVente: DateTime.parse(map['date_vente'] as String),
    );
  }
}

/// Métadonnées pour un reçu de dépôt
class RecuDepotMetadata {
  final int depotId;
  final int adherentId;
  final double quantite;
  final String qualite;
  final DateTime dateDepot;

  RecuDepotMetadata({
    required this.depotId,
    required this.adherentId,
    required this.quantite,
    required this.qualite,
    required this.dateDepot,
  });

  Map<String, dynamic> toMap() {
    return {
      'depot_id': depotId,
      'adherent_id': adherentId,
      'quantite': quantite,
      'qualite': qualite,
      'date_depot': dateDepot.toIso8601String(),
    };
  }

  factory RecuDepotMetadata.fromMap(Map<String, dynamic> map) {
    return RecuDepotMetadata(
      depotId: map['depot_id'] as int,
      adherentId: map['adherent_id'] as int,
      quantite: (map['quantite'] as num).toDouble(),
      qualite: map['qualite'] as String,
      dateDepot: DateTime.parse(map['date_depot'] as String),
    );
  }
}

/// Métadonnées pour un bordereau de recette
class BordereauRecetteMetadata {
  final int factureId;
  final int adherentId;
  final List<int> recetteIds;
  final double montantBrutTotal;
  final double montantNetTotal;
  final DateTime dateDebut;
  final DateTime dateFin;

  BordereauRecetteMetadata({
    required this.factureId,
    required this.adherentId,
    required this.recetteIds,
    required this.montantBrutTotal,
    required this.montantNetTotal,
    required this.dateDebut,
    required this.dateFin,
  });

  Map<String, dynamic> toMap() {
    return {
      'facture_id': factureId,
      'adherent_id': adherentId,
      'recette_ids': recetteIds,
      'montant_brut_total': montantBrutTotal,
      'montant_net_total': montantNetTotal,
      'date_debut': dateDebut.toIso8601String(),
      'date_fin': dateFin.toIso8601String(),
    };
  }

  factory BordereauRecetteMetadata.fromMap(Map<String, dynamic> map) {
    return BordereauRecetteMetadata(
      factureId: map['facture_id'] as int,
      adherentId: map['adherent_id'] as int,
      recetteIds: List<int>.from(map['recette_ids'] as List),
      montantBrutTotal: (map['montant_brut_total'] as num).toDouble(),
      montantNetTotal: (map['montant_net_total'] as num).toDouble(),
      dateDebut: DateTime.parse(map['date_debut'] as String),
      dateFin: DateTime.parse(map['date_fin'] as String),
    );
  }
}

