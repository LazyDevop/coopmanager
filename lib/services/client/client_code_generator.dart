import '../database/db_initializer.dart';

/// Générateur de code Client ERP (SQLite)
///
/// Objectif : produire un code unique et stable sans dépendre d'un ID déjà inséré.
///
/// Format par défaut : `CLI` + 6 chiffres (ex: CLI000123)
/// - Compatible avec les anciens codes (ex: CLI1, CLI12)
/// - Unicité garantie via vérification SQLite sur `clients.code_client`
class ClientCodeGenerator {
  static const String defaultPrefix = 'CLI';
  static const int defaultWidth = 6;

  /// Génère un code client unique.
  ///
  /// La stratégie :
  /// 1) Cherche le plus grand suffixe numérique existant pour le préfixe.
  /// 2) Sinon, se rabat sur (MAX(id)+1).
  /// 3) Vérifie l'unicité; en cas de collision, incrémente.
  Future<String> generateUniqueCode({
    String prefix = defaultPrefix,
    int width = defaultWidth,
    int maxRetries = 50,
  }) async {
    final normalizedPrefix = prefix.trim().toUpperCase();
    if (normalizedPrefix.isEmpty) {
      throw Exception('Préfixe de code client invalide');
    }

    final db = await DatabaseInitializer.database;

    int nextNumber = 1;

    // 1) Tenter de calculer le max suffixe numérique existant.
    try {
      final rows = await db.query(
        'clients',
        columns: ['code_client'],
        where: 'code_client LIKE ?',
        whereArgs: ['$normalizedPrefix%'],
        orderBy: 'id DESC',
        limit: 5000,
      );

      int maxFound = 0;
      for (final row in rows) {
        final code = (row['code_client'] as String?)?.toUpperCase() ?? '';
        if (!code.startsWith(normalizedPrefix)) continue;

        final rawSuffix = code.substring(normalizedPrefix.length);
        final digitsOnly = rawSuffix.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.isEmpty) continue;

        final value = int.tryParse(digitsOnly);
        if (value == null) continue;
        if (value > maxFound) maxFound = value;
      }

      if (maxFound > 0) {
        nextNumber = maxFound + 1;
      }
    } catch (_) {
      // On continue avec le fallback ci-dessous.
    }

    // 2) Fallback : MAX(id)+1
    if (nextNumber <= 1) {
      try {
        final maxIdResult = await db.rawQuery('SELECT MAX(id) as max_id FROM clients');
        final maxId = (maxIdResult.first['max_id'] as int?) ?? 0;
        nextNumber = maxId + 1;
      } catch (_) {
        nextNumber = 1;
      }
    }

    // 3) Construire le code + garantir l'unicité.
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final candidate = _formatCode(normalizedPrefix, nextNumber, width);
      final exists = await _codeExists(candidate);
      if (!exists) return candidate;
      nextNumber++;
    }

    // Dernier recours : timestamp (toujours vérifié)
    final fallback = '$normalizedPrefix${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    if (!await _codeExists(fallback)) return fallback;

    throw Exception('Impossible de générer un code client unique');
  }

  static String _formatCode(String prefix, int number, int width) {
    final padded = number.toString().padLeft(width, '0');
    return '$prefix$padded';
  }

  Future<bool> _codeExists(String codeClient) async {
    final db = await DatabaseInitializer.database;
    final result = await db.query(
      'clients',
      columns: ['id'],
      where: 'code_client = ?',
      whereArgs: [codeClient],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Valide et normalise un code client.
  ///
  /// Retourne le code en majuscules, ou `null` si invalide.
  static String? validateAndNormalize(String codeClient) {
    final normalized = codeClient.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    // Accepter lettres/chiffres/traits d'union, pour compatibilité.
    if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(normalized)) return null;
    return normalized;
  }
}
