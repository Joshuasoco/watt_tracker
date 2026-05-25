import 'package:hive_flutter/hive_flutter.dart';

import '../local/hive_boxes.dart';
import '../models/billing_defaults.dart';
import '../models/system_spec_model.dart';
import '../models/usage_profile.dart';

class WattwisePrefsRepository {
  WattwisePrefsRepository({Box<dynamic>? prefsBox})
    : _prefsBox = prefsBox ?? Hive.box<dynamic>(HiveBoxes.wattwisePrefs);

  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String cpuNameKey = 'cpu_name';
  static const String gpuTypeKey = 'gpu_type';
  static const String gpuNameKey = 'gpu_name';
  static const String ramGbKey = 'ram_gb';
  static const String ramSticksKey = 'ram_sticks';
  static const String storageCountKey = 'storage_count';
  static const String storageTypeKey = 'storage_type';
  static const String fanCountKey = 'fan_count';
  static const String hasRgbKey = 'has_rgb';
  static const String motherboardKey = 'motherboard';
  static const String chassisTypeKey = 'chassis_type';
  static const String electricityRateKey = 'electricity_rate';
  static const String currencySymbolKey = 'currency_symbol';
  static const String dailyHoursKey = 'daily_hours';
  static const String usageProfileKey = 'usage_profile';
  static const String manualCalibrationWattsKey = 'manual_calibration_watts';
  static const String calibrationUpdatedAtKey = 'calibration_updated_at';
  static const String sessionMilestoneHoursKey = 'session_milestone_hours';
  static const String trackingActivatedOnceKey = 'tracking_activated_once';
  static const String schemaVersionKey = 'schema_version';
  static const String specMetadataKey = 'spec_metadata';
  static const int currentSchemaVersion = 2;

  static const List<String> onboardingKeys = <String>[
    onboardingCompleteKey,
    cpuNameKey,
    SystemSpecModel.cpuTdpWattsField,
    gpuTypeKey,
    gpuNameKey,
    SystemSpecModel.gpuWattsField,
    ramGbKey,
    ramSticksKey,
    storageCountKey,
    storageTypeKey,
    SystemSpecModel.storageWattsEachField,
    fanCountKey,
    hasRgbKey,
    SystemSpecModel.rgbWattsField,
    motherboardKey,
    chassisTypeKey,
    electricityRateKey,
    currencySymbolKey,
    dailyHoursKey,
    usageProfileKey,
    manualCalibrationWattsKey,
    calibrationUpdatedAtKey,
    sessionMilestoneHoursKey,
    trackingActivatedOnceKey,
    schemaVersionKey,
    specMetadataKey,
  ];

  final Box<dynamic> _prefsBox;

  bool get onboardingComplete =>
      (_prefsBox.get(onboardingCompleteKey, defaultValue: false) as bool?) ??
      false;

  String get currencySymbol {
    final raw = (_prefsBox.get(currencySymbolKey) as String?)?.trim();
    return raw == null || raw.isEmpty
        ? BillingDefaults.forCurrentLocale().currencySymbol
        : raw;
  }

  double get electricityRate {
    final suggestion = BillingDefaults.forCurrentLocale().ratePerKwh;
    final raw = _prefsBox.get(electricityRateKey);
    if (raw is num) {
      return raw <= 0 ? suggestion : raw.toDouble();
    }
    return suggestion;
  }

  double get dailyHours {
    final raw = _prefsBox.get(dailyHoursKey, defaultValue: 8.0);
    if (raw is num) {
      return raw.toDouble().clamp(1.0, 24.0);
    }
    return 8.0;
  }

  UsageProfile get usageProfile {
    final raw = _prefsBox.get(usageProfileKey) as String?;
    return usageProfileFromStorage(raw);
  }

  double? get manualCalibrationWatts {
    final raw = _prefsBox.get(manualCalibrationWattsKey);
    if (raw is num && raw > 0) {
      return raw.toDouble();
    }
    return null;
  }

  DateTime? get calibrationUpdatedAt {
    final raw = _prefsBox.get(calibrationUpdatedAtKey);
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  double get sessionMilestoneHours {
    final raw = _prefsBox.get(sessionMilestoneHoursKey, defaultValue: 2.0);
    if (raw is num) {
      return raw.toDouble().clamp(0.0, 999.0);
    }
    return 2.0;
  }

  bool get trackingActivatedOnce =>
      (_prefsBox.get(trackingActivatedOnceKey, defaultValue: false) as bool?) ??
      false;

  SystemSpecModel get systemSpec {
    return SystemSpecModel.fromPrefsMap({
      SystemSpecModel.cpuNameField: _prefsBox.get(cpuNameKey),
      SystemSpecModel.cpuTdpWattsField: _prefsBox.get(
        SystemSpecModel.cpuTdpWattsField,
      ),
      SystemSpecModel.gpuTypeField: _prefsBox.get(gpuTypeKey),
      SystemSpecModel.gpuNameField: _prefsBox.get(gpuNameKey),
      SystemSpecModel.gpuWattsField: _prefsBox.get(
        SystemSpecModel.gpuWattsField,
      ),
      SystemSpecModel.ramGbField: _prefsBox.get(ramGbKey),
      SystemSpecModel.ramSticksField: _prefsBox.get(ramSticksKey),
      SystemSpecModel.storageCountField: _prefsBox.get(storageCountKey),
      SystemSpecModel.storageTypeField: _prefsBox.get(storageTypeKey),
      SystemSpecModel.storageWattsEachField: _prefsBox.get(
        SystemSpecModel.storageWattsEachField,
      ),
      SystemSpecModel.fanCountField: _prefsBox.get(fanCountKey),
      SystemSpecModel.hasRgbField: _prefsBox.get(hasRgbKey),
      SystemSpecModel.rgbWattsField: _prefsBox.get(
        SystemSpecModel.rgbWattsField,
      ),
      SystemSpecModel.motherboardField: _prefsBox.get(motherboardKey),
      SystemSpecModel.chassisTypeField: _prefsBox.get(chassisTypeKey),
      specMetadataKey: _prefsBox.get(specMetadataKey),
    });
  }

  Future<void> saveOnboardingData({
    required SystemSpecModel specs,
    required double electricityRate,
    required String currencySymbol,
    required double dailyHours,
    required UsageProfile usageProfile,
  }) async {
    await _prefsBox.putAll({
      schemaVersionKey: currentSchemaVersion,
      onboardingCompleteKey: true,
      ...specs
          .copyWith(
            fieldMetadata: SystemSpecModel.userConfirmedMetadata(
              lastUpdated: DateTime.now().toUtc(),
            ),
          )
          .toPrefsMap(),
      electricityRateKey: electricityRate <= 0 ? 0.01 : electricityRate,
      currencySymbolKey: _normalizeSymbol(currencySymbol),
      dailyHoursKey: dailyHours.clamp(1.0, 24.0),
      usageProfileKey: usageProfile.storageKey,
    });
  }

  Future<void> saveUsagePreferences({
    required double electricityRate,
    required String currencySymbol,
    required double dailyHours,
    required UsageProfile usageProfile,
  }) async {
    await _prefsBox.putAll({
      schemaVersionKey: currentSchemaVersion,
      electricityRateKey: electricityRate <= 0 ? 0.01 : electricityRate,
      currencySymbolKey: _normalizeSymbol(currencySymbol),
      dailyHoursKey: dailyHours.clamp(1.0, 24.0),
      usageProfileKey: usageProfile.storageKey,
    });
  }

  Future<void> saveSessionMilestoneHours(double hours) async {
    await _prefsBox.put(
      sessionMilestoneHoursKey,
      hours.isNegative ? 0.0 : hours.clamp(0.0, 999.0),
    );
  }

  Future<void> markTrackingActivated() async {
    await _prefsBox.put(trackingActivatedOnceKey, true);
  }

  Future<void> saveManualCalibration(double? watts) async {
    if (watts == null || watts <= 0) {
      await _prefsBox.delete(manualCalibrationWattsKey);
      await _prefsBox.delete(calibrationUpdatedAtKey);
      return;
    }

    await _prefsBox.putAll({
      manualCalibrationWattsKey: watts,
      calibrationUpdatedAtKey: DateTime.now().toIso8601String(),
    });
  }

  Future<void> resetOnboarding() async {
    await _prefsBox.deleteAll(onboardingKeys);
  }

  String _normalizeSymbol(String symbol) {
    final trimmed = symbol.trim();
    return trimmed.isEmpty
        ? BillingDefaults.forCurrentLocale().currencySymbol
        : trimmed;
  }
}
