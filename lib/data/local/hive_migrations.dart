import 'package:hive_flutter/hive_flutter.dart';

import '../../features/audit/models/audit_settings.dart';
import '../models/field_metadata.dart';
import '../models/system_spec_model.dart';
import '../repositories/wattwise_prefs_repository.dart';

class HiveMigrations {
  const HiveMigrations._();

  static Future<void> run({
    required Box<dynamic> wattwisePrefsBox,
    required Box<dynamic> energyAuditBox,
    required Box<dynamic> appPreferencesBox,
  }) async {
    await Future.wait([
      _migrateWattwisePrefs(wattwisePrefsBox),
      _migrateEnergyAudit(energyAuditBox),
      _migrateAppPreferences(appPreferencesBox),
    ]);
  }

  static Future<void> _migrateWattwisePrefs(Box<dynamic> box) async {
    final version =
        (box.get(WattwisePrefsRepository.schemaVersionKey) as int?) ?? 1;
    if (version >= WattwisePrefsRepository.currentSchemaVersion) {
      return;
    }

    final savedAt = DateTime.now().toUtc();
    final metadata = <String, FieldMetadata>{};
    for (final field in SystemSpecModel.metadataFields) {
      final legacyKey = _legacyPrefsKeyForField(field);
      metadata[field] = box.containsKey(legacyKey)
          ? FieldMetadata.user(lastUpdated: savedAt)
          : FieldMetadata.unknown();
    }

    await box.putAll({
      WattwisePrefsRepository.schemaVersionKey:
          WattwisePrefsRepository.currentSchemaVersion,
      WattwisePrefsRepository.specMetadataKey: SystemSpecModel.metadataToPrefs(
        metadata,
      ),
    });
  }

  static Future<void> _migrateEnergyAudit(Box<dynamic> box) async {
    final rawSettings = box.get(EnergyAuditRepositoryKeys.settingsKey);
    final settings = rawSettings is Map
        ? AuditSettings.fromMap(Map<String, dynamic>.from(rawSettings))
        : const AuditSettings();

    await box.put(EnergyAuditRepositoryKeys.settingsKey, settings.toMap());
  }

  static Future<void> _migrateAppPreferences(Box<dynamic> box) async {
    await box.put('schema_version', 2);
  }

  static String _legacyPrefsKeyForField(String field) {
    switch (field) {
      case SystemSpecModel.cpuNameField:
        return WattwisePrefsRepository.cpuNameKey;
      case SystemSpecModel.gpuTypeField:
        return WattwisePrefsRepository.gpuTypeKey;
      case SystemSpecModel.gpuNameField:
        return WattwisePrefsRepository.gpuNameKey;
      case SystemSpecModel.ramGbField:
        return WattwisePrefsRepository.ramGbKey;
      case SystemSpecModel.ramSticksField:
        return WattwisePrefsRepository.ramSticksKey;
      case SystemSpecModel.storageCountField:
        return WattwisePrefsRepository.storageCountKey;
      case SystemSpecModel.storageTypeField:
        return WattwisePrefsRepository.storageTypeKey;
      case SystemSpecModel.fanCountField:
        return WattwisePrefsRepository.fanCountKey;
      case SystemSpecModel.hasRgbField:
        return WattwisePrefsRepository.hasRgbKey;
      case SystemSpecModel.motherboardField:
        return WattwisePrefsRepository.motherboardKey;
      case SystemSpecModel.chassisTypeField:
        return WattwisePrefsRepository.chassisTypeKey;
      default:
        return field;
    }
  }
}

class EnergyAuditRepositoryKeys {
  const EnergyAuditRepositoryKeys._();

  static const String settingsKey = 'settings';
}
