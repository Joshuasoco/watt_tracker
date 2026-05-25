import 'package:hive_flutter/hive_flutter.dart';

import '../../features/audit/models/audit_tip.dart';
import '../../features/audit/models/audit_settings.dart';
import '../../features/audit/models/audit_user_overrides.dart';
import '../../features/audit/models/energy_audit_result.dart';
import '../../features/audit/models/peripheral_profile.dart';
import '../local/hive_boxes.dart';

class EnergyAuditRepository {
  EnergyAuditRepository({Box<dynamic>? auditBox})
    : _auditBox = auditBox ?? Hive.box<dynamic>(HiveBoxes.energyAudit);

  static const String latestResultKey = 'latest_result';
  static const String historyKey = 'history';
  static const String tipPreferencesKey = 'tip_preferences';
  static const String userOverridesKey = 'user_overrides';
  static const String peripheralsKey = 'peripherals';
  static const String settingsKey = 'settings';
  static const int maxHistoryItems = 20;

  final Box<dynamic> _auditBox;

  EnergyAuditResult? getLatestResult() {
    final raw = _auditBox.get(latestResultKey);
    if (raw is Map) {
      return EnergyAuditResult.fromMap(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  List<EnergyAuditResult> getHistory() {
    final raw = _auditBox.get(historyKey);
    if (raw is! List) {
      return const <EnergyAuditResult>[];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) => EnergyAuditResult.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<void> saveAuditResult(EnergyAuditResult result) async {
    final history = getHistory().toList(growable: true);
    history.removeWhere((item) => item.id == result.id);
    history.insert(0, result);

    if (history.length > maxHistoryItems) {
      history.removeRange(maxHistoryItems, history.length);
    }

    await _auditBox.put(latestResultKey, result.toMap());
    await _auditBox.put(
      historyKey,
      history.map((item) => item.toMap()).toList(growable: false),
    );
  }

  AuditUserOverrides getUserOverrides() {
    final raw = _auditBox.get(userOverridesKey);
    if (raw is Map) {
      return AuditUserOverrides.fromMap(Map<String, dynamic>.from(raw));
    }
    return const AuditUserOverrides();
  }

  Future<void> saveUserOverrides(AuditUserOverrides overrides) async {
    await _auditBox.put(userOverridesKey, overrides.toMap());
  }

  List<PeripheralProfile> getPeripherals() {
    final raw = _auditBox.get(peripheralsKey);
    if (raw is! List) {
      return const <PeripheralProfile>[];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) => PeripheralProfile.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<void> savePeripherals(List<PeripheralProfile> peripherals) async {
    await _auditBox.put(
      peripheralsKey,
      peripherals.map((item) => item.toMap()).toList(growable: false),
    );
  }

  AuditSettings getAuditSettings() {
    final raw = _auditBox.get(settingsKey);
    if (raw is Map) {
      return AuditSettings.fromMap(Map<String, dynamic>.from(raw));
    }

    return const AuditSettings();
  }

  Future<void> saveAuditSettings(AuditSettings settings) async {
    await _auditBox.put(settingsKey, settings.toMap());
  }

  Map<String, dynamic> getTipPreferences() {
    final raw = _auditBox.get(tipPreferencesKey);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return <String, dynamic>{
      'dismissed_tip_ids': <String>[],
      'snoozed_until': <String, String>{},
    };
  }

  Future<void> dismissTip(String tipId) async {
    final prefs = getTipPreferences();
    final dismissed =
        (prefs['dismissed_tip_ids'] as List?)?.whereType<String>().toSet() ??
        <String>{};
    dismissed.add(tipId);

    await _auditBox.put(tipPreferencesKey, {
      ...prefs,
      'dismissed_tip_ids': dismissed.toList(growable: false),
    });

    await _updateTipState(
      tipId: tipId,
      transform: (tip) => tip.copyWith(isDismissed: true),
    );
  }

  Future<void> snoozeTip(String tipId, DateTime until) async {
    final prefs = getTipPreferences();
    final snoozedUntil = _toStringMap(prefs['snoozed_until']);
    snoozedUntil[tipId] = until.toIso8601String();

    await _auditBox.put(tipPreferencesKey, {
      ...prefs,
      'snoozed_until': snoozedUntil,
    });

    await _updateTipState(
      tipId: tipId,
      transform: (tip) => tip.copyWith(dismissedUntil: until),
    );
  }

  Future<void> _updateTipState({
    required String tipId,
    required AuditTip Function(AuditTip tip) transform,
  }) async {
    final latest = getLatestResult();
    if (latest == null) {
      return;
    }

    final updatedTips = latest.tips
        .map((tip) => tip.id == tipId ? transform(tip) : tip)
        .toList(growable: false);

    final updatedResult = EnergyAuditResult(
      id: latest.id,
      createdAt: latest.createdAt,
      specSnapshot: latest.specSnapshot,
      ratePerKwh: latest.ratePerKwh,
      currencySymbol: latest.currencySymbol,
      dailyHours: latest.dailyHours,
      totalWatts: latest.totalWatts,
      totalMonthlyCost: latest.totalMonthlyCost,
      confidence: latest.confidence,
      breakdowns: latest.breakdowns,
      findings: latest.findings,
      tips: updatedTips,
      dataCompleteness: latest.dataCompleteness,
    );

    await saveAuditResult(updatedResult);
  }

  Map<String, String> _toStringMap(dynamic value) {
    if (value is Map) {
      final mapped = <String, String>{};
      value.forEach((key, item) {
        if (key is String && item is String) {
          mapped[key] = item;
        }
      });
      return mapped;
    }
    return <String, String>{};
  }
}
