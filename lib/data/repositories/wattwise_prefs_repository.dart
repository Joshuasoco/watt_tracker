import 'package:hive_flutter/hive_flutter.dart';

import '../local/hive_boxes.dart';
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
  static const String sessionMilestoneHoursKey = 'session_milestone_hours';

  static const List<String> onboardingKeys = <String>[
    onboardingCompleteKey,
    cpuNameKey,
    gpuTypeKey,
    gpuNameKey,
    ramGbKey,
    ramSticksKey,
    storageCountKey,
    storageTypeKey,
    fanCountKey,
    hasRgbKey,
    motherboardKey,
    chassisTypeKey,
    electricityRateKey,
    currencySymbolKey,
    dailyHoursKey,
    usageProfileKey,
    sessionMilestoneHoursKey,
  ];

  final Box<dynamic> _prefsBox;

  bool get onboardingComplete =>
      (_prefsBox.get(onboardingCompleteKey, defaultValue: false) as bool?) ??
      false;

  String get currencySymbol {
    final raw = (_prefsBox.get(currencySymbolKey) as String?)?.trim();
    return raw == null || raw.isEmpty ? '\u20B1' : raw;
  }

  double get electricityRate {
    final raw = _prefsBox.get(electricityRateKey, defaultValue: 12.0);
    if (raw is num) {
      return raw <= 0 ? 12.0 : raw.toDouble();
    }
    return 12.0;
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

  double get sessionMilestoneHours {
    final raw = _prefsBox.get(sessionMilestoneHoursKey, defaultValue: 2.0);
    if (raw is num) {
      return raw.toDouble().clamp(0.0, 999.0);
    }
    return 2.0;
  }

  SystemSpecModel get systemSpec {
    final defaults = SystemSpecModel.defaults();

    return defaults.copyWith(
      cpuName: (_prefsBox.get(cpuNameKey) as String?) ?? defaults.cpuName,
      gpuType: (_prefsBox.get(gpuTypeKey) as String?) ?? defaults.gpuType,
      gpuName: (_prefsBox.get(gpuNameKey) as String?) ?? defaults.gpuName,
      ramGb: (_prefsBox.get(ramGbKey) as int?) ?? defaults.ramGb,
      ramSticks: (_prefsBox.get(ramSticksKey) as int?) ?? defaults.ramSticks,
      storageCount:
          (_prefsBox.get(storageCountKey) as int?) ?? defaults.storageCount,
      storageType:
          (_prefsBox.get(storageTypeKey) as String?) ?? defaults.storageType,
      fanCount: (_prefsBox.get(fanCountKey) as int?) ?? defaults.fanCount,
      hasRgb: (_prefsBox.get(hasRgbKey) as bool?) ?? defaults.hasRgb,
      motherboard:
          (_prefsBox.get(motherboardKey) as String?) ?? defaults.motherboard,
      chassisType:
          (_prefsBox.get(chassisTypeKey) as String?) ?? defaults.chassisType,
    );
  }

  Future<void> saveOnboardingData({
    required SystemSpecModel specs,
    required double electricityRate,
    required String currencySymbol,
    required double dailyHours,
    required UsageProfile usageProfile,
  }) async {
    await _prefsBox.putAll({
      onboardingCompleteKey: true,
      ...specs.toPrefsMap(),
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

  Future<void> resetOnboarding() async {
    await _prefsBox.deleteAll(onboardingKeys);
  }

  String _normalizeSymbol(String symbol) {
    final trimmed = symbol.trim();
    return trimmed.isEmpty ? '\u20B1' : trimmed;
  }
}
