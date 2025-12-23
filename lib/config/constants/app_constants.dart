class AppConstants {
  // Formats de date
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  
  // Formats numériques
  static const int decimalPlaces = 2;
  
  // Limites
  static const int maxAdherents = 10000;
  static const int maxStockEntries = 100000;
  
  // Messages
  static const String confirmDelete = 'Êtes-vous sûr de vouloir supprimer cet élément ?';
  static const String saveSuccess = 'Enregistrement réussi';
  static const String saveError = 'Erreur lors de l\'enregistrement';
  static const String deleteSuccess = 'Suppression réussie';
  static const String deleteError = 'Erreur lors de la suppression';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 100;
}
