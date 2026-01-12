class VenteTopClientStatsModel {
  final String clientKey;
  final String clientNom;
  final int nombreVentes;
  final double quantiteTotale;
  final double montantTotal;

  const VenteTopClientStatsModel({
    required this.clientKey,
    required this.clientNom,
    required this.nombreVentes,
    required this.quantiteTotale,
    required this.montantTotal,
  });

  factory VenteTopClientStatsModel.fromDbRow(Map<String, Object?> row) {
    return VenteTopClientStatsModel(
      clientKey: (row['client_key'] as String?) ?? '',
      clientNom: (row['client_nom'] as String?) ?? 'Inconnu',
      nombreVentes: (row['nombre_ventes'] as int?) ?? 0,
      quantiteTotale: (row['quantite_totale'] as num?)?.toDouble() ?? 0.0,
      montantTotal: (row['montant_total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
