class VenteMensuelleStatsModel {
  final DateTime mois; // Premier jour du mois
  final int nombreVentes;
  final double quantiteTotale;
  final double montantTotal;

  const VenteMensuelleStatsModel({
    required this.mois,
    required this.nombreVentes,
    required this.quantiteTotale,
    required this.montantTotal,
  });

  static DateTime _parseMoisKey(String key) {
    // key attendu: YYYY-MM
    final parts = key.split('-');
    if (parts.length != 2) {
      return DateTime.now();
    }
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    return DateTime(year, month, 1);
  }

  factory VenteMensuelleStatsModel.fromDbRow(Map<String, Object?> row) {
    final moisKey = (row['mois'] as String?) ?? '';

    return VenteMensuelleStatsModel(
      mois: _parseMoisKey(moisKey),
      nombreVentes: (row['nombre_ventes'] as int?) ?? 0,
      quantiteTotale: (row['quantite_totale'] as num?)?.toDouble() ?? 0.0,
      montantTotal: (row['montant_total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
