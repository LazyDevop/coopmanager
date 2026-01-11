/// Script de seed pour initialiser les données par défaut
import '../../../data/models/backend/cooperative_model.dart';
import '../../../data/models/backend/setting_model.dart';
import '../../../data/models/backend/specialized_settings_models.dart';
import 'settings_service.dart';
import 'cooperative_service.dart';
import '../repositories/specialized_settings_repository.dart';

class ParametrageSeedData {
  final CooperativeService _coopService;
  final SettingsService _settingsService;
  final CapitalSettingsRepository _capitalRepo;
  final AccountingSettingsRepository _accountingRepo;
  final DocumentSettingsRepository _docRepo;

  ParametrageSeedData({
    CooperativeService? coopService,
    SettingsService? settingsService,
    CapitalSettingsRepository? capitalRepo,
    AccountingSettingsRepository? accountingRepo,
    DocumentSettingsRepository? docRepo,
  })  : _coopService = coopService ?? CooperativeService(),
        _settingsService = settingsService ?? SettingsService(),
        _capitalRepo = capitalRepo ?? CapitalSettingsRepository(),
        _accountingRepo = accountingRepo ?? AccountingSettingsRepository(),
        _docRepo = docRepo ?? DocumentSettingsRepository();

  /// Créer une coopérative par défaut avec tous ses paramètres
  Future<String> seedDefaultCooperative({required int userId}) async {
    // 1. Créer la coopérative
    final cooperative = CooperativeModel(
      raisonSociale: 'Coopérative de Cacaoculteurs',
      sigle: 'COOP-CACAO',
      formeJuridique: 'SCOOPS',
      devise: 'XAF',
      langue: 'FR',
      statut: CooperativeStatut.active,
    );

    final created = await _coopService.create(
      cooperative: cooperative,
      userId: userId,
    );

    final coopId = created.id;

    // 2. Paramètres financiers
    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'finance',
      key: 'commission_rate',
      value: 0.05,
      valueType: SettingValueType.double,
      userId: userId,
    );

    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'finance',
      key: 'taux_reserve',
      value: 0.10,
      valueType: SettingValueType.double,
      userId: userId,
    );

    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'finance',
      key: 'taux_frais_gestion',
      value: 0.05,
      valueType: SettingValueType.double,
      userId: userId,
    );

    // 3. Paramètres de vente
    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'vente',
      key: 'validation_double',
      value: true,
      valueType: SettingValueType.bool,
      userId: userId,
    );

    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'vente',
      key: 'seuil_validation_double',
      value: 100000,
      valueType: SettingValueType.double,
      userId: userId,
    );

    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'vente',
      key: 'variation_autorisee',
      value: 10.0,
      valueType: SettingValueType.double,
      userId: userId,
    );

    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'vente',
      key: 'taux_tva',
      value: 0.0,
      valueType: SettingValueType.double,
      userId: userId,
    );

    // 4. Paramètres de stock
    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'stock',
      key: 'seuil_alerte',
      value: 100,
      valueType: SettingValueType.double,
      userId: userId,
    );

    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'stock',
      key: 'unite_mesure_defaut',
      value: 'kg',
      valueType: SettingValueType.string,
      userId: userId,
    );

    // 5. Paramètres de campagne
    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'campagne',
      key: 'periode_days',
      value: 365,
      valueType: SettingValueType.int,
      userId: userId,
    );

    // 6. Paramètres de sécurité
    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'securite',
      key: 'journal_audit',
      value: true,
      valueType: SettingValueType.bool,
      userId: userId,
    );

    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'securite',
      key: 'sauvegarde_auto',
      value: true,
      valueType: SettingValueType.bool,
      userId: userId,
    );

    await _settingsService.saveSetting(
      cooperativeId: coopId,
      category: 'securite',
      key: 'frequence_sauvegarde',
      value: 'quotidienne',
      valueType: SettingValueType.string,
      userId: userId,
    );

    // 7. Paramètres du capital social
    await _capitalRepo.save(CapitalSettingsModel(
      cooperativeId: coopId,
      valeurPart: 10000,
      partsMin: 1,
      partsMax: 100,
      liberationObligatoire: false,
    ));

    // 8. Paramètres comptables
    await _accountingRepo.save(AccountingSettingsModel(
      cooperativeId: coopId,
      exerciceActif: DateTime.now().year,
      planComptable: 'SYSCOHADA',
      tauxReserve: 0.10,
      tauxFraisGestion: 0.05,
      compteCaisse: '571',
      compteBanque: '512',
    ));

    // 9. Paramètres de documents
    await _docRepo.save(DocumentSettingsModel(
      cooperativeId: coopId,
      typeDocument: DocumentType.facture,
      prefix: 'FAC',
      formatNumero: '{PREFIX}-{YEAR}-{NUM}',
      piedPage: 'Mentions légales conformes à la réglementation en vigueur.',
      signatureAuto: false,
    ));

    await _docRepo.save(DocumentSettingsModel(
      cooperativeId: coopId,
      typeDocument: DocumentType.recu,
      prefix: 'REC',
      formatNumero: '{PREFIX}-{YEAR}-{NUM}',
      signatureAuto: false,
    ));

    await _docRepo.save(DocumentSettingsModel(
      cooperativeId: coopId,
      typeDocument: DocumentType.vente,
      prefix: 'VNT',
      formatNumero: '{PREFIX}-{YEAR}-{NUM}',
      signatureAuto: false,
    ));

    return coopId;
  }

  /// Créer des paramètres globaux (non liés à une coopérative)
  Future<void> seedGlobalSettings({required int userId}) async {
    // Paramètres système globaux
    await _settingsService.saveSetting(
      cooperativeId: null,
      category: 'system',
      key: 'app_version',
      value: '2.0.0',
      valueType: SettingValueType.string,
      editable: false,
      userId: userId,
    );

    await _settingsService.saveSetting(
      cooperativeId: null,
      category: 'system',
      key: 'maintenance_mode',
      value: false,
      valueType: SettingValueType.bool,
      userId: userId,
    );

    await _settingsService.saveSetting(
      cooperativeId: null,
      category: 'system',
      key: 'max_file_size',
      value: 10485760, // 10 MB
      valueType: SettingValueType.int,
      userId: userId,
    );
  }
}

