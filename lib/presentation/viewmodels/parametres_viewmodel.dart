import 'package:flutter/foundation.dart';
import '../../data/models/parametres_cooperative_model.dart';
import '../../services/parametres/parametres_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ParametresViewModel extends ChangeNotifier {
  final ParametresService _parametresService = ParametresService();
  
  ParametresCooperativeModel? _parametres;
  List<CampagneModel> _campagnes = [];
  List<BaremeQualiteModel> _baremes = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  File? _selectedLogoFile;
  
  // Getters
  ParametresCooperativeModel? get parametres => _parametres;
  List<CampagneModel> get campagnes => _campagnes;
  List<BaremeQualiteModel> get baremes => _baremes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  File? get selectedLogoFile => _selectedLogoFile;
  
  /// Charger les paramètres
  Future<void> loadParametres() async {
    if (_isLoading) return; // Éviter les chargements multiples
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _parametres = await _parametresService.getParametres();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des paramètres: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow; // Permettre à l'appelant de gérer l'erreur
    }
  }
  
  /// Charger les campagnes
  Future<void> loadCampagnes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _campagnes = await _parametresService.getAllCampagnes();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des campagnes: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Charger les barèmes
  Future<void> loadBaremes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _baremes = await _parametresService.getAllBaremesQualite();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des barèmes: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Sélectionner un fichier logo
  Future<void> pickLogo() async {
    try {
      _errorMessage = null;
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (await file.exists()) {
          _selectedLogoFile = file;
          notifyListeners();
        } else {
          _errorMessage = 'Le fichier sélectionné n\'existe plus';
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la sélection du logo: ${e.toString()}';
      notifyListeners();
    }
  }
  
  /// Sauvegarder les paramètres
  Future<bool> saveParametres({
    String? nomCooperative,
    String? logoPath,
    String? adresse,
    String? telephone,
    String? email,
    double? commissionRate,
    int? periodeCampagneDays,
    DateTime? dateDebutCampagne,
    DateTime? dateFinCampagne,
    required int updatedBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Copier le logo si un fichier a été sélectionné
      String? finalLogoPath = logoPath;
      if (_selectedLogoFile != null) {
        finalLogoPath = await _copyLogoFile(_selectedLogoFile!);
      }
      
      _parametres = await _parametresService.updateParametres(
        nomCooperative: nomCooperative,
        logoPath: finalLogoPath,
        adresse: adresse,
        telephone: telephone,
        email: email,
        commissionRate: commissionRate,
        periodeCampagneDays: periodeCampagneDays,
        dateDebutCampagne: dateDebutCampagne,
        dateFinCampagne: dateFinCampagne,
        updatedBy: updatedBy,
      );
      
      _selectedLogoFile = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Copier le fichier logo vers le répertoire de l'application
  Future<String> _copyLogoFile(File sourceFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logoDir = Directory('${directory.path}/logos');
      if (!await logoDir.exists()) {
        await logoDir.create(recursive: true);
      }
      
      final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.png';
      final destFile = File('${logoDir.path}/$fileName');
      await sourceFile.copy(destFile.path);
      
      return destFile.path;
    } catch (e) {
      throw Exception('Erreur lors de la copie du logo: $e');
    }
  }
  
  /// Créer une campagne
  Future<bool> createCampagne({
    required String nom,
    required DateTime dateDebut,
    required DateTime dateFin,
    String? description,
    required int createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _parametresService.createCampagne(
        nom: nom,
        dateDebut: dateDebut,
        dateFin: dateFin,
        description: description,
        createdBy: createdBy,
      );
      
      await loadCampagnes();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Mettre à jour une campagne
  Future<bool> updateCampagne({
    required int id,
    String? nom,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? description,
    bool? isActive,
    required int updatedBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _parametresService.updateCampagne(
        id: id,
        nom: nom,
        dateDebut: dateDebut,
        dateFin: dateFin,
        description: description,
        isActive: isActive,
        updatedBy: updatedBy,
      );
      
      await loadCampagnes();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Sauvegarder un barème
  Future<bool> saveBareme({
    required String qualite,
    double? prixMin,
    double? prixMax,
    double? commissionRate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _parametresService.saveBaremeQualite(
        qualite: qualite,
        prixMin: prixMin,
        prixMax: prixMax,
        commissionRate: commissionRate,
      );
      
      await loadBaremes();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Supprimer une campagne
  Future<bool> deleteCampagne(int id, int deletedBy) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _parametresService.deleteCampagne(id, deletedBy);
      await loadCampagnes();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Réinitialiser le fichier logo sélectionné
  void clearSelectedLogo() {
    _selectedLogoFile = null;
    notifyListeners();
  }
}

