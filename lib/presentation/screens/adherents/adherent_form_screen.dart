import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../viewmodels/adherent_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../data/models/adherent_model.dart';
import '../../widgets/common/form_field_widget.dart';

class AdherentFormScreen extends StatefulWidget {
  final AdherentModel? adherent;

  const AdherentFormScreen({super.key, this.adherent});

  @override
  State<AdherentFormScreen> createState() => _AdherentFormScreenState();
}

class _AdherentFormScreenState extends State<AdherentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _villageController = TextEditingController();
  final _adresseController = TextEditingController();
  final _cnibController = TextEditingController();
  
  // Nouveaux contrôleurs - Identification
  final _siteCooperativeController = TextEditingController();
  final _sectionController = TextEditingController();
  
  // Nouveaux contrôleurs - Identité personnelle
  String? _sexe;
  final _lieuNaissanceController = TextEditingController();
  final _nationaliteController = TextEditingController();
  String? _typePiece;
  final _numeroPieceController = TextEditingController();
  
  // Nouveaux contrôleurs - Situation familiale
  final _nomPereController = TextEditingController();
  final _nomMereController = TextEditingController();
  final _conjointController = TextEditingController();
  final _nombreEnfantsController = TextEditingController();
  
  // Nouveaux contrôleurs - Indicateurs agricoles
  final _superficieTotaleController = TextEditingController();
  final _nombreChampsController = TextEditingController();
  final _rendementMoyenController = TextEditingController();
  final _tonnageTotalProduitController = TextEditingController();
  final _tonnageTotalVenduController = TextEditingController();

  DateTime? _dateNaissance;
  DateTime? _dateAdhesion;
  String? _categorie; // type_personne
  String? _statut;
  bool _isCodeGenerating = false;
  String? _existingPhotoPath;

  @override
  void initState() {
    super.initState();
    if (widget.adherent != null) {
      _populateForm(widget.adherent!);
    } else {
      _dateAdhesion = DateTime.now();
      // Générer automatiquement le code pour un nouvel adhérent après que le widget soit construit
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateCode();
      });
    }
  }

  /// Générer automatiquement le code adhérent
  Future<void> _generateCode() async {
    if (!mounted) return;
    
    setState(() => _isCodeGenerating = true);
    try {
      final viewModel = context.read<AdherentViewModel>();
      final code = await viewModel.generateNextCode();
      if (mounted) {
        _codeController.text = code;
        setState(() => _isCodeGenerating = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCodeGenerating = false);
        // En cas d'erreur, utiliser un code par défaut
        _codeController.text = 'ADH001';
      }
    }
  }

  void _populateForm(AdherentModel adherent) {
    _codeController.text = adherent.code;
    _nomController.text = adherent.nom;
    _prenomController.text = adherent.prenom;
    _telephoneController.text = adherent.telephone ?? '';
    _emailController.text = adherent.email ?? '';
    _villageController.text = adherent.village ?? '';
    _adresseController.text = adherent.adresse ?? '';
    _cnibController.text = adherent.cnib ?? '';
    _dateNaissance = adherent.dateNaissance;
    _dateAdhesion = adherent.dateAdhesion;
    _categorie = adherent.categorie;
    _statut = adherent.statut;
    _existingPhotoPath = adherent.photoPath;
    
    // Nouveaux champs
    _siteCooperativeController.text = adherent.siteCooperative ?? '';
    _sectionController.text = adherent.section ?? '';
    _sexe = adherent.sexe;
    _lieuNaissanceController.text = adherent.lieuNaissance ?? '';
    _nationaliteController.text = adherent.nationalite ?? '';
    _typePiece = adherent.typePiece;
    _numeroPieceController.text = adherent.numeroPiece ?? '';
    _nomPereController.text = adherent.nomPere ?? '';
    _nomMereController.text = adherent.nomMere ?? '';
    _conjointController.text = adherent.conjoint ?? '';
    _nombreEnfantsController.text = adherent.nombreEnfants?.toString() ?? '';
    _superficieTotaleController.text = adherent.superficieTotaleCultivee?.toString() ?? '';
    _nombreChampsController.text = adherent.nombreChamps?.toString() ?? '';
    _rendementMoyenController.text = adherent.rendementMoyenHa?.toString() ?? '';
    _tonnageTotalProduitController.text = adherent.tonnageTotalProduit?.toString() ?? '';
    _tonnageTotalVenduController.text = adherent.tonnageTotalVendu?.toString() ?? '';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _villageController.dispose();
    _adresseController.dispose();
    _cnibController.dispose();
    _siteCooperativeController.dispose();
    _sectionController.dispose();
    _lieuNaissanceController.dispose();
    _nationaliteController.dispose();
    _numeroPieceController.dispose();
    _nomPereController.dispose();
    _nomMereController.dispose();
    _conjointController.dispose();
    _nombreEnfantsController.dispose();
    _superficieTotaleController.dispose();
    _nombreChampsController.dispose();
    _rendementMoyenController.dispose();
    _tonnageTotalProduitController.dispose();
    _tonnageTotalVenduController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.adherent != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier l\'adhérent' : 'Nouvel adhérent'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Container pour limiter la largeur et centrer le formulaire
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
          padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECTION 1: IDENTIFICATION
            _buildSectionTitle('Identification'),
            const SizedBox(height: 12),
            _buildCodeField(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTypePersonneField()),
                const SizedBox(width: 12),
                Expanded(child: _buildStatutField()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSiteCooperativeField()),
                const SizedBox(width: 12),
                Expanded(child: _buildSectionField()),
              ],
            ),
            const SizedBox(height: 16),
            _buildDateAdhesionField(),
            
            // SECTION 2: IDENTITÉ PERSONNELLE
            const SizedBox(height: 24),
            _buildSectionTitle('Identité personnelle'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildNomField()),
                const SizedBox(width: 12),
                Expanded(child: _buildPrenomField()),
              ],
            ),
            const SizedBox(height: 16),
            _buildPhotoField(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSexeField()),
                const SizedBox(width: 12),
                Expanded(child: _buildDateNaissanceField()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildLieuNaissanceField()),
                const SizedBox(width: 12),
                Expanded(child: _buildNationaliteField()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTypePieceField()),
                const SizedBox(width: 12),
                Expanded(child: _buildNumeroPieceField()),
              ],
            ),
            const SizedBox(height: 16),
            _buildTelephoneField(),
            const SizedBox(height: 16),
            _buildEmailField(),
            
            // SECTION 3: LOCALISATION
            const SizedBox(height: 24),
            _buildSectionTitle('Localisation'),
            const SizedBox(height: 12),
            _buildVillageField(),
            const SizedBox(height: 16),
            _buildAdresseField(),
            
            // SECTION 4: SITUATION FAMILIALE / FILIATION
            const SizedBox(height: 24),
            _buildSectionTitle('Situation familiale / Filiation'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildNomPereField()),
                const SizedBox(width: 12),
                Expanded(child: _buildNomMereField()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildConjointField()),
                const SizedBox(width: 12),
                Expanded(child: _buildNombreEnfantsField()),
              ],
            ),
            
            // SECTION 5: INDICATEURS AGRICOLES GLOBAUX
            const SizedBox(height: 24),
            _buildSectionTitle('Indicateurs agricoles globaux'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSuperficieTotaleField()),
                const SizedBox(width: 12),
                Expanded(child: _buildNombreChampsField()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildRendementMoyenField()),
                const SizedBox(width: 12),
                Expanded(child: _buildTonnageTotalProduitField()),
              ],
            ),
            const SizedBox(height: 16),
            _buildTonnageTotalVenduField(),
            
            // SECTION 6: INFORMATIONS COMPLÉMENTAIRES (ancien CNIB)
            const SizedBox(height: 24),
            _buildSectionTitle('Informations complémentaires'),
            const SizedBox(height: 12),
            _buildCnibField(),
            
            const SizedBox(height: 32),
            _buildSubmitButton(isEdit),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.brown.shade700,
      ),
    );
  }

  Widget _buildCodeField() {
    final isEdit = widget.adherent != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Code adhérent *',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade700,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _codeController,
                enabled: false, // Lecture seule
                decoration: InputDecoration(
                  hintText: isEdit ? 'Code existant' : 'Génération automatique...',
                  prefixIcon: const Icon(Icons.badge),
                  suffixIcon: _isCodeGenerating
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le code adhérent est obligatoire';
                  }
                  return null;
                },
              ),
            ),
            if (!isEdit && !_isCodeGenerating) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _generateCode,
                tooltip: 'Régénérer le code',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.brown.shade100,
                  foregroundColor: Colors.brown.shade700,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNomField() {
    return FormFieldWidget(
      label: 'Nom *',
      controller: _nomController,
      prefixIcon: Icons.person,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Le nom est obligatoire';
        }
        return null;
      },
    );
  }

  Widget _buildPrenomField() {
    return FormFieldWidget(
      label: 'Prénom *',
      controller: _prenomController,
      prefixIcon: Icons.person_outline,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Le prénom est obligatoire';
        }
        return null;
      },
    );
  }

  Widget _buildTelephoneField() {
    return FormFieldWidget(
      label: 'Téléphone',
      hint: 'Ex: +237 6XX XXX XXX',
      controller: _telephoneController,
      prefixIcon: Icons.phone,
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildEmailField() {
    return FormFieldWidget(
      label: 'Email',
      hint: 'Ex: exemple@email.com',
      controller: _emailController,
      prefixIcon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (!value.contains('@') || !value.contains('.')) {
            return 'Email invalide';
          }
        }
        return null;
      },
    );
  }

  Widget _buildVillageField() {
    return FormFieldWidget(
      label: 'Village / Localisation',
      controller: _villageController,
      prefixIcon: Icons.location_on,
    );
  }

  Widget _buildAdresseField() {
    return FormFieldWidget(
      label: 'Adresse complète',
      controller: _adresseController,
      prefixIcon: Icons.home,
      maxLines: 2,
    );
  }

  Widget _buildCnibField() {
    return FormFieldWidget(
      label: 'Numéro CNIB',
      hint: 'Optionnel',
      controller: _cnibController,
      prefixIcon: Icons.credit_card,
    );
  }

  Widget _buildDateNaissanceField() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dateNaissance ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _dateNaissance = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de naissance',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _dateNaissance != null
              ? DateFormat('dd/MM/yyyy').format(_dateNaissance!)
              : 'Sélectionner une date',
          style: TextStyle(
            color: _dateNaissance != null ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildDateAdhesionField() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dateAdhesion ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _dateAdhesion = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date d\'adhésion *',
          prefixIcon: const Icon(Icons.event),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _dateAdhesion != null
              ? DateFormat('dd/MM/yyyy').format(_dateAdhesion!)
              : 'Sélectionner une date',
          style: TextStyle(
            color: _dateAdhesion != null ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
  
  // Nouveaux champs - Identification
  Widget _buildTypePersonneField() {
    return DropdownButtonFormField<String>(
      value: _categorie,
      decoration: InputDecoration(
        labelText: 'Type de personne *',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'producteur', child: Text('Producteur')),
        DropdownMenuItem(value: 'adherent', child: Text('Adhérent')),
        DropdownMenuItem(value: 'adherent_actionnaire', child: Text('Adhérent Actionnaire')),
      ],
      onChanged: (value) => setState(() => _categorie = value),
      validator: (value) => value == null ? 'Sélectionner un type' : null,
    );
  }
  
  Widget _buildStatutField() {
    return DropdownButtonFormField<String>(
      value: _statut ?? 'actif',
      decoration: InputDecoration(
        labelText: 'Statut *',
        prefixIcon: const Icon(Icons.info_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'actif', child: Text('Actif')),
        DropdownMenuItem(value: 'suspendu', child: Text('Suspendu')),
        DropdownMenuItem(value: 'radie', child: Text('Radié')),
      ],
      onChanged: (value) => setState(() => _statut = value),
    );
  }
  
  Widget _buildSiteCooperativeField() {
    return FormFieldWidget(
      label: 'Site coopérative',
      controller: _siteCooperativeController,
      prefixIcon: Icons.business,
    );
  }
  
  Widget _buildSectionField() {
    return FormFieldWidget(
      label: 'Section',
      controller: _sectionController,
      prefixIcon: Icons.map,
    );
  }
  
  // Nouveaux champs - Identité personnelle
  Widget _buildSexeField() {
    return DropdownButtonFormField<String>(
      value: _sexe,
      decoration: InputDecoration(
        labelText: 'Sexe',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'M', child: Text('Masculin')),
        DropdownMenuItem(value: 'F', child: Text('Féminin')),
        DropdownMenuItem(value: 'Autre', child: Text('Autre')),
      ],
      onChanged: (value) => setState(() => _sexe = value),
    );
  }
  
  Widget _buildLieuNaissanceField() {
    return FormFieldWidget(
      label: 'Lieu de naissance',
      controller: _lieuNaissanceController,
      prefixIcon: Icons.place,
    );
  }
  
  Widget _buildNationaliteField() {
    return FormFieldWidget(
      label: 'Nationalité',
      hint: 'Ex: Camerounais',
      controller: _nationaliteController,
      prefixIcon: Icons.flag,
    );
  }
  
  Widget _buildTypePieceField() {
    return DropdownButtonFormField<String>(
      value: _typePiece,
      decoration: InputDecoration(
        labelText: 'Type de pièce',
        prefixIcon: const Icon(Icons.credit_card),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'CNIB', child: Text('CNIB')),
        DropdownMenuItem(value: 'PASSEPORT', child: Text('Passeport')),
        DropdownMenuItem(value: 'CARTE_CONSULAIRE', child: Text('Carte consulaire')),
        DropdownMenuItem(value: 'AUTRE', child: Text('Autre')),
      ],
      onChanged: (value) => setState(() => _typePiece = value),
    );
  }
  
  Widget _buildNumeroPieceField() {
    return FormFieldWidget(
      label: 'Numéro de pièce',
      controller: _numeroPieceController,
      prefixIcon: Icons.badge_outlined,
    );
  }
  
  // Nouveaux champs - Situation familiale
  Widget _buildNomPereField() {
    return FormFieldWidget(
      label: 'Nom du père',
      controller: _nomPereController,
      prefixIcon: Icons.person_outline,
    );
  }
  
  Widget _buildNomMereField() {
    return FormFieldWidget(
      label: 'Nom de la mère',
      controller: _nomMereController,
      prefixIcon: Icons.person_outline,
    );
  }
  
  Widget _buildConjointField() {
    return FormFieldWidget(
      label: 'Conjoint(e)',
      controller: _conjointController,
      prefixIcon: Icons.favorite,
    );
  }
  
  Widget _buildNombreEnfantsField() {
    return FormFieldWidget(
      label: 'Nombre d\'enfants',
      controller: _nombreEnfantsController,
      prefixIcon: Icons.child_care,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final num = int.tryParse(value);
          if (num == null || num < 0) {
            return 'Nombre invalide';
          }
        }
        return null;
      },
    );
  }
  
  // Nouveaux champs - Indicateurs agricoles
  Widget _buildSuperficieTotaleField() {
    return FormFieldWidget(
      label: 'Superficie totale cultivée (ha)',
      controller: _superficieTotaleController,
      prefixIcon: Icons.landscape,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final num = double.tryParse(value);
          if (num == null || num < 0) {
            return 'Superficie invalide';
          }
        }
        return null;
      },
    );
  }
  
  Widget _buildNombreChampsField() {
    return FormFieldWidget(
      label: 'Nombre de champs',
      controller: _nombreChampsController,
      prefixIcon: Icons.grid_view,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final num = int.tryParse(value);
          if (num == null || num < 0) {
            return 'Nombre invalide';
          }
        }
        return null;
      },
    );
  }
  
  Widget _buildRendementMoyenField() {
    return FormFieldWidget(
      label: 'Rendement moyen (t/ha)',
      controller: _rendementMoyenController,
      prefixIcon: Icons.trending_up,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final num = double.tryParse(value);
          if (num == null || num < 0) {
            return 'Rendement invalide';
          }
        }
        return null;
      },
    );
  }
  
  Widget _buildTonnageTotalProduitField() {
    return FormFieldWidget(
      label: 'Tonnage total produit (t)',
      controller: _tonnageTotalProduitController,
      prefixIcon: Icons.inventory,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final num = double.tryParse(value);
          if (num == null || num < 0) {
            return 'Tonnage invalide';
          }
        }
        return null;
      },
    );
  }
  
  Widget _buildTonnageTotalVenduField() {
    return FormFieldWidget(
      label: 'Tonnage total vendu (t)',
      controller: _tonnageTotalVenduController,
      prefixIcon: Icons.shopping_cart,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final num = double.tryParse(value);
          if (num == null || num < 0) {
            return 'Tonnage invalide';
          }
        }
        return null;
      },
    );
  }

  Widget _buildPhotoField() {
    final viewModel = context.watch<AdherentViewModel>();
    final selectedPhoto = viewModel.selectedPhotoFile;
    final existingPhoto = _existingPhotoPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo de profil',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade700,
              ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: selectedPhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          selectedPhoto,
                          fit: BoxFit.cover,
                        ),
                      )
                    : existingPhoto != null && File(existingPhoto).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(existingPhoto),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
              ),
              if (selectedPhoto != null || existingPhoto != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _existingPhotoPath = null;
                      });
                      viewModel.clearSelectedPhoto();
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: () async {
              await viewModel.pickPhoto();
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('Sélectionner une photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isEdit) {
    return Consumer<AdherentViewModel>(
      builder: (context, viewModel, child) {
        return ElevatedButton(
          onPressed: viewModel.isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: viewModel.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  isEdit ? 'Enregistrer les modifications' : 'Créer l\'adhérent',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateAdhesion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date d\'adhésion'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final viewModel = context.read<AdherentViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: utilisateur non connecté'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Convertir les valeurs numériques
    final nombreEnfants = _nombreEnfantsController.text.trim().isEmpty
        ? null
        : int.tryParse(_nombreEnfantsController.text.trim());
    final superficieTotale = _superficieTotaleController.text.trim().isEmpty
        ? null
        : double.tryParse(_superficieTotaleController.text.trim());
    final nombreChamps = _nombreChampsController.text.trim().isEmpty
        ? null
        : int.tryParse(_nombreChampsController.text.trim());
    final rendementMoyen = _rendementMoyenController.text.trim().isEmpty
        ? null
        : double.tryParse(_rendementMoyenController.text.trim());
    final tonnageProduit = _tonnageTotalProduitController.text.trim().isEmpty
        ? null
        : double.tryParse(_tonnageTotalProduitController.text.trim());
    final tonnageVendu = _tonnageTotalVenduController.text.trim().isEmpty
        ? null
        : double.tryParse(_tonnageTotalVenduController.text.trim());

    final success = widget.adherent == null
        ? await viewModel.createAdherent(
            code: null, // Code auto-généré par le service
            nom: _nomController.text.trim(),
            prenom: _prenomController.text.trim(),
            telephone: _telephoneController.text.trim().isEmpty
                ? null
                : _telephoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            village: _villageController.text.trim().isEmpty
                ? null
                : _villageController.text.trim(),
            adresse: _adresseController.text.trim().isEmpty
                ? null
                : _adresseController.text.trim(),
            cnib: _cnibController.text.trim().isEmpty
                ? null
                : _cnibController.text.trim(),
            dateNaissance: _dateNaissance,
            dateAdhesion: _dateAdhesion!,
            createdBy: currentUser.id!,
            categorie: _categorie,
            statut: _statut ?? 'actif',
            siteCooperative: _siteCooperativeController.text.trim().isEmpty
                ? null
                : _siteCooperativeController.text.trim(),
            section: _sectionController.text.trim().isEmpty
                ? null
                : _sectionController.text.trim(),
            sexe: _sexe,
            lieuNaissance: _lieuNaissanceController.text.trim().isEmpty
                ? null
                : _lieuNaissanceController.text.trim(),
            nationalite: _nationaliteController.text.trim().isEmpty
                ? null
                : _nationaliteController.text.trim(),
            typePiece: _typePiece,
            numeroPiece: _numeroPieceController.text.trim().isEmpty
                ? null
                : _numeroPieceController.text.trim(),
            nomPere: _nomPereController.text.trim().isEmpty
                ? null
                : _nomPereController.text.trim(),
            nomMere: _nomMereController.text.trim().isEmpty
                ? null
                : _nomMereController.text.trim(),
            conjoint: _conjointController.text.trim().isEmpty
                ? null
                : _conjointController.text.trim(),
            nombreEnfants: nombreEnfants,
            superficieTotaleCultivee: superficieTotale,
            nombreChamps: nombreChamps,
            rendementMoyenHa: rendementMoyen,
            tonnageTotalProduit: tonnageProduit,
            tonnageTotalVendu: tonnageVendu,
          )
        : await viewModel.updateAdherent(
            id: widget.adherent!.id!,
            code: _codeController.text.trim(),
            nom: _nomController.text.trim(),
            prenom: _prenomController.text.trim(),
            telephone: _telephoneController.text.trim().isEmpty
                ? null
                : _telephoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            village: _villageController.text.trim().isEmpty
                ? null
                : _villageController.text.trim(),
            adresse: _adresseController.text.trim().isEmpty
                ? null
                : _adresseController.text.trim(),
            cnib: _cnibController.text.trim().isEmpty
                ? null
                : _cnibController.text.trim(),
            dateNaissance: _dateNaissance,
            dateAdhesion: _dateAdhesion,
            updatedBy: currentUser.id!,
            categorie: _categorie,
            statut: _statut,
            siteCooperative: _siteCooperativeController.text.trim().isEmpty
                ? null
                : _siteCooperativeController.text.trim(),
            section: _sectionController.text.trim().isEmpty
                ? null
                : _sectionController.text.trim(),
            sexe: _sexe,
            lieuNaissance: _lieuNaissanceController.text.trim().isEmpty
                ? null
                : _lieuNaissanceController.text.trim(),
            nationalite: _nationaliteController.text.trim().isEmpty
                ? null
                : _nationaliteController.text.trim(),
            typePiece: _typePiece,
            numeroPiece: _numeroPieceController.text.trim().isEmpty
                ? null
                : _numeroPieceController.text.trim(),
            nomPere: _nomPereController.text.trim().isEmpty
                ? null
                : _nomPereController.text.trim(),
            nomMere: _nomMereController.text.trim().isEmpty
                ? null
                : _nomMereController.text.trim(),
            conjoint: _conjointController.text.trim().isEmpty
                ? null
                : _conjointController.text.trim(),
            nombreEnfants: nombreEnfants,
            superficieTotaleCultivee: superficieTotale,
            nombreChamps: nombreChamps,
            rendementMoyenHa: rendementMoyen,
            tonnageTotalProduit: tonnageProduit,
            tonnageTotalVendu: tonnageVendu,
          );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.adherent == null
                ? 'Adhérent créé avec succès'
                : 'Adhérent modifié avec succès',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else if (context.mounted) {
      final errorMsg = viewModel.errorMessage ?? 'Une erreur est survenue lors de la création de l\'adhérent';
      print('Erreur lors de la création: $errorMsg');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Détails',
            textColor: Colors.white,
            onPressed: () {
              // Afficher une boîte de dialogue avec plus de détails
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Erreur'),
                  content: Text(errorMsg),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
  }
}
