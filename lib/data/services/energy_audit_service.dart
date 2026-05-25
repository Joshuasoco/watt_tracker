import '../../features/audit/models/audit_finding.dart';
import '../../features/audit/models/audit_activity_sample.dart';
import '../../features/audit/models/audit_tip.dart';
import '../../features/audit/models/audit_user_overrides.dart';
import '../../features/audit/models/component_cost_breakdown.dart';
import '../../features/audit/models/energy_audit_result.dart';
import '../../features/audit/models/peripheral_profile.dart';
import '../models/system_spec_model.dart';
import '../repositories/wattage_preset_repository.dart';

class EnergyAuditService {
  EnergyAuditService({WattagePresetRepository? presetRepository})
    : _presetRepository = presetRepository ?? WattagePresetRepository();

  static const double _minimumMeaningfulTipPct = 0.01;
  static const double _impactThresholdRateMultiplier = 0.5;

  final WattagePresetRepository _presetRepository;

  EnergyAuditResult runAudit({
    required SystemSpecModel spec,
    required double ratePerKwh,
    required String currencySymbol,
    required double dailyHours,
    required AuditUserOverrides overrides,
    required List<PeripheralProfile> peripherals,
    AuditActivitySample? activitySample,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now().toUtc();
    final resolvedSpec = _resolveSpec(spec, overrides);
    final componentWatts = _componentWattsMap(resolvedSpec, peripherals);
    final totalWatts = componentWatts.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    final hourlyCost = (totalWatts / 1000) * ratePerKwh;
    final monthlyCost = hourlyCost * dailyHours * 30;
    final breakdowns =
        componentWatts.entries
            .map(
              (entry) => ComponentCostBreakdown(
                key: entry.key,
                label: _labelForKey(entry.key),
                watts: entry.value,
                monthlyCost: monthlyCost == 0
                    ? 0
                    : monthlyCost * (entry.value / totalWatts),
                billShare: monthlyCost == 0 ? 0 : entry.value / totalWatts,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));

    final findings = _buildFindings(
      resolvedSpec: resolvedSpec,
      breakdowns: breakdowns,
      monthlyCost: monthlyCost,
      dailyHours: dailyHours,
      ratePerKwh: ratePerKwh,
      now: timestamp,
      peripherals: peripherals,
      overrides: overrides,
      activitySample: activitySample,
    );

    final tips = _buildTips(
      resolvedSpec: resolvedSpec,
      findings: findings,
      monthlyCost: monthlyCost,
      dailyHours: dailyHours,
      ratePerKwh: ratePerKwh,
      now: timestamp,
    );

    final confidence = _overallConfidence(
      hasOverrides: overrides.hasOverrides,
      hasPeripherals: peripherals.isNotEmpty,
      hasActivitySample: activitySample != null,
    );

    final dataCompleteness = _dataCompleteness(
      resolvedSpec: resolvedSpec,
      hasOverrides: overrides.hasOverrides,
      hasActivitySample: activitySample != null,
    );

    return EnergyAuditResult(
      id: 'audit_${timestamp.microsecondsSinceEpoch}',
      createdAt: timestamp,
      specSnapshot: _specSnapshot(resolvedSpec),
      ratePerKwh: ratePerKwh,
      currencySymbol: currencySymbol,
      dailyHours: dailyHours,
      totalWatts: totalWatts,
      totalMonthlyCost: monthlyCost,
      confidence: confidence,
      breakdowns: breakdowns,
      findings: findings,
      tips: tips,
      dataCompleteness: dataCompleteness,
    );
  }

  SystemSpecModel _resolveSpec(
    SystemSpecModel spec,
    AuditUserOverrides overrides,
  ) {
    final cpuWatts =
        overrides.cpuWattsOverride?.round() ??
        _presetRepository.resolveCpuTdp(spec.cpuName);
    final gpuWatts =
        overrides.gpuWattsOverride?.round() ??
        _presetRepository.resolveGpuWatts(spec.gpuName, spec.gpuType);
    final motherboardWatts =
        overrides.motherboardWattsOverride?.round() ?? spec.motherboardWatts;
    final rgbWatts = overrides.rgbWattsOverride?.round() ?? spec.rgbWatts;
    final fanWattsEach =
        overrides.fanWattsEachOverride?.round() ?? spec.fansWattsEach;

    return spec.copyWith(
      cpuTdpWatts: cpuWatts,
      gpuWatts: gpuWatts,
      motherboardWatts: motherboardWatts,
      rgbWatts: spec.hasRgb ? rgbWatts : 0,
      fansWattsEach: fanWattsEach,
      storageWattsEach: spec.storageType == 'HDD' ? 7 : 3,
    );
  }

  Map<String, double> _componentWattsMap(
    SystemSpecModel spec,
    List<PeripheralProfile> peripherals,
  ) {
    final peripheralWatts = peripherals.fold<double>(
      0,
      (sum, item) => sum + item.watts,
    );

    return <String, double>{
      'cpu': spec.cpuTdpWatts.toDouble(),
      'gpu': spec.gpuWatts.toDouble(),
      'ram': (spec.ramSticks * spec.ramWattsPerStick).toDouble(),
      'storage': (spec.storageCount * spec.storageWattsEach).toDouble(),
      'cooling': (spec.fanCount * spec.fansWattsEach).toDouble(),
      'rgb': spec.hasRgb ? spec.rgbWatts.toDouble() : 0,
      'motherboard': spec.motherboardWatts.toDouble(),
      'peripherals': peripheralWatts,
    };
  }

  List<AuditFinding> _buildFindings({
    required SystemSpecModel resolvedSpec,
    required List<ComponentCostBreakdown> breakdowns,
    required double monthlyCost,
    required double dailyHours,
    required double ratePerKwh,
    required DateTime now,
    required List<PeripheralProfile> peripherals,
    required AuditUserOverrides overrides,
    required AuditActivitySample? activitySample,
  }) {
    final findings = <AuditFinding>[];
    final gpuBreakdown = breakdowns.firstWhere(
      (item) => item.key == 'gpu',
      orElse: () => const ComponentCostBreakdown(
        key: 'gpu',
        label: 'GPU',
        watts: 0,
        monthlyCost: 0,
        billShare: 0,
      ),
    );
    final cpuBreakdown = breakdowns.firstWhere(
      (item) => item.key == 'cpu',
      orElse: () => const ComponentCostBreakdown(
        key: 'cpu',
        label: 'CPU',
        watts: 0,
        monthlyCost: 0,
        billShare: 0,
      ),
    );
    final coolingBreakdown = breakdowns.firstWhere(
      (item) => item.key == 'cooling',
      orElse: () => const ComponentCostBreakdown(
        key: 'cooling',
        label: 'Cooling',
        watts: 0,
        monthlyCost: 0,
        billShare: 0,
      ),
    );
    final rgbBreakdown = breakdowns.firstWhere(
      (item) => item.key == 'rgb',
      orElse: () => const ComponentCostBreakdown(
        key: 'rgb',
        label: 'RGB / Lighting',
        watts: 0,
        monthlyCost: 0,
        billShare: 0,
      ),
    );
    final peripheralsBreakdown = breakdowns.firstWhere(
      (item) => item.key == 'peripherals',
      orElse: () => const ComponentCostBreakdown(
        key: 'peripherals',
        label: 'Peripherals',
        watts: 0,
        monthlyCost: 0,
        billShare: 0,
      ),
    );

    final impactThreshold = ratePerKwh * _impactThresholdRateMultiplier;

    if (resolvedSpec.gpuType == 'dedicated' && dailyHours >= 6) {
      final estimatedIdleWatts = _maxDouble(18, resolvedSpec.gpuWatts * 0.18);
      final estimatedImpact =
          ((estimatedIdleWatts / 1000) * dailyHours * 30) * ratePerKwh;
      if (estimatedImpact >= impactThreshold) {
        final hasTelemetryLowGpu =
            activitySample != null && activitySample.gpuUsageAvg < 5;
        findings.add(
          AuditFinding(
            id: 'finding_gpu_idle_${now.microsecondsSinceEpoch}',
            type: 'idle_waste',
            severity: gpuBreakdown.billShare >= 0.2 ? 'high' : 'medium',
            confidence: hasTelemetryLowGpu ? 'high' : 'medium',
            title: 'Dedicated GPU appears costly during light workloads',
            description: hasTelemetryLowGpu
                ? 'Recent activity sampling shows low GPU utilization, but baseline dedicated GPU draw is still likely contributing to cost.'
                : 'Your hardware profile suggests a dedicated GPU may be drawing meaningful idle power outside heavy sessions.',
            estimatedMonthlyImpact: estimatedImpact,
            componentKeys: const <String>['gpu'],
            createdAt: now,
          ),
        );
      }
    }

    if (activitySample != null && activitySample.indicatesIdleWaste) {
      final idleWatts = _maxDouble(10, resolvedSpec.totalWatts * 0.12);
      final idleImpact =
          ((idleWatts / 1000) * _minDouble(2, dailyHours) * 30) * ratePerKwh;
      if (idleImpact >= impactThreshold) {
        findings.add(
          AuditFinding(
            id: 'finding_idle_session_${now.microsecondsSinceEpoch}',
            type: 'idle_waste',
            severity: 'medium',
            confidence: 'high',
            title: 'Low-activity session time may be wasting energy',
            description:
                'A short activity sample showed low CPU/GPU usage while active, suggesting avoidable idle power draw.',
            estimatedMonthlyImpact: idleImpact,
            componentKeys: const <String>['cpu', 'gpu', 'motherboard'],
            createdAt: now,
          ),
        );
      }
    }

    if (resolvedSpec.fanCount >= 5 || resolvedSpec.hasRgb) {
      final extrasImpact =
          coolingBreakdown.monthlyCost + rgbBreakdown.monthlyCost;
      if (monthlyCost > 0 && extrasImpact / monthlyCost >= 0.03) {
        findings.add(
          AuditFinding(
            id: 'finding_extras_${now.microsecondsSinceEpoch}',
            type: 'always_on_extras',
            severity: extrasImpact / monthlyCost >= 0.1 ? 'high' : 'medium',
            confidence: 'medium',
            title: 'Always-on extras are adding recurring cost',
            description:
                'Cooling and lighting currently account for ${(extrasImpact / monthlyCost * 100).toStringAsFixed(0)}% of your estimated monthly electricity cost.',
            estimatedMonthlyImpact: extrasImpact,
            componentKeys: const <String>['cooling', 'rgb'],
            createdAt: now,
          ),
        );
      }
    }

    if (peripheralsBreakdown.monthlyCost > 0 &&
        monthlyCost > 0 &&
        peripheralsBreakdown.monthlyCost / monthlyCost >= 0.03) {
      findings.add(
        AuditFinding(
          id: 'finding_peripherals_${now.microsecondsSinceEpoch}',
          type: 'always_on_extras',
          severity: peripheralsBreakdown.billShare >= 0.2 ? 'high' : 'medium',
          confidence: peripherals.isEmpty ? 'low' : 'medium',
          title: 'Peripheral draw looks significant',
          description:
              'Connected accessories are estimated at ${peripheralsBreakdown.watts.toStringAsFixed(0)} W, which may be avoidable during inactive periods.',
          estimatedMonthlyImpact: peripheralsBreakdown.monthlyCost,
          componentKeys: const <String>['peripherals'],
          createdAt: now,
        ),
      );
    }

    if (cpuBreakdown.billShare >= 0.35 &&
        dailyHours >= 8 &&
        (resolvedSpec.chassisType == 'desktop' ||
            resolvedSpec.chassisType == 'workstation')) {
      findings.add(
        AuditFinding(
          id: 'finding_cpu_core_${now.microsecondsSinceEpoch}',
          type: 'high_draw_core',
          severity: 'high',
          confidence: 'medium',
          title: 'CPU/platform draw is a major share',
          description:
              'CPU-related draw is currently ${(cpuBreakdown.billShare * 100).toStringAsFixed(0)}% of your bill estimate. Power-plan tuning may reduce this baseline.',
          estimatedMonthlyImpact: cpuBreakdown.monthlyCost,
          componentKeys: const <String>['cpu', 'motherboard'],
          createdAt: now,
        ),
      );
    }

    final looksMismatched =
        (resolvedSpec.chassisType == 'laptop' &&
            (resolvedSpec.fanCount >= 4 || resolvedSpec.hasRgb)) ||
        (resolvedSpec.gpuType == 'integrated' && resolvedSpec.gpuWatts > 80);

    if (looksMismatched) {
      findings.add(
        AuditFinding(
          id: 'finding_profile_mismatch_${now.microsecondsSinceEpoch}',
          type: 'profile_mismatch',
          severity: 'medium',
          confidence: overrides.hasOverrides ? 'medium' : 'low',
          title: 'Profile data may not match current hardware behavior',
          description:
              'Some saved assumptions look inconsistent with your current profile. Review hardware details to improve audit confidence.',
          estimatedMonthlyImpact: 0,
          componentKeys: const <String>['gpu', 'cooling', 'rgb'],
          createdAt: now,
        ),
      );
    }

    return findings;
  }

  List<AuditTip> _buildTips({
    required SystemSpecModel resolvedSpec,
    required List<AuditFinding> findings,
    required double monthlyCost,
    required double dailyHours,
    required double ratePerKwh,
    required DateTime now,
  }) {
    final tips = <AuditTip>[];

    final gpuFinding = findings
        .where((f) => f.componentKeys.contains('gpu'))
        .firstOrNull;
    if (resolvedSpec.gpuType == 'dedicated' && gpuFinding != null) {
      final wattsSaved = _minDouble(40, resolvedSpec.gpuWatts * 0.15);
      final monthlySavings = _monthlySavings(
        wattsSaved,
        dailyHours,
        ratePerKwh,
      );
      if (_shouldShowTip(monthlySavings, monthlyCost)) {
        tips.add(
          AuditTip(
            id: 'tip_gpu_limit_${now.microsecondsSinceEpoch}',
            findingId: gpuFinding.id,
            actionType: 'gpu_power_limit',
            title: 'Limit GPU power during light workloads',
            body:
                'Using a lower GPU power target for non-gaming activity could save around ${monthlySavings.toStringAsFixed(2)} per month.',
            estimatedWattsSaved: wattsSaved,
            estimatedMonthlySavings: monthlySavings,
            confidence: 'medium',
          ),
        );
      }
    }

    if (resolvedSpec.hasRgb) {
      final wattsSaved = resolvedSpec.rgbWatts.toDouble();
      final monthlySavings = _monthlySavings(
        wattsSaved,
        dailyHours,
        ratePerKwh,
      );
      final findingId = _findingIdForType(findings, 'always_on_extras');
      if (_shouldShowTip(monthlySavings, monthlyCost) && findingId != null) {
        tips.add(
          AuditTip(
            id: 'tip_rgb_${now.microsecondsSinceEpoch}',
            findingId: findingId,
            actionType: 'rgb_reduction',
            title: 'Reduce RGB usage outside active sessions',
            body:
                'Disabling lighting when you do not need it can reduce baseline draw and trim recurring cost.',
            estimatedWattsSaved: wattsSaved,
            estimatedMonthlySavings: monthlySavings,
            confidence: 'medium',
          ),
        );
      }
    }

    if (resolvedSpec.fanCount >= 4) {
      final fanWatts = (resolvedSpec.fanCount * resolvedSpec.fansWattsEach)
          .toDouble();
      final wattsSaved = fanWatts * 0.3;
      final monthlySavings = _monthlySavings(
        wattsSaved,
        dailyHours,
        ratePerKwh,
      );
      final findingId = _findingIdForType(findings, 'always_on_extras');
      if (_shouldShowTip(monthlySavings, monthlyCost) && findingId != null) {
        tips.add(
          AuditTip(
            id: 'tip_fan_curve_${now.microsecondsSinceEpoch}',
            findingId: findingId,
            actionType: 'fan_curve',
            title: 'Tune fan curve for low-load periods',
            body:
                'A gentler fan curve can lower cooling overhead during idle and light usage windows.',
            estimatedWattsSaved: wattsSaved,
            estimatedMonthlySavings: monthlySavings,
            confidence: 'low',
          ),
        );
      }
    }

    final idleFinding = findings
        .where((f) => f.type == 'idle_waste')
        .firstOrNull;
    if (idleFinding != null) {
      final wattsSaved = _maxDouble(12, resolvedSpec.totalWatts * 0.1);
      final monthlySavings = _monthlySavings(
        wattsSaved,
        _minDouble(2, dailyHours),
        ratePerKwh,
      );
      if (_shouldShowTip(monthlySavings, monthlyCost)) {
        tips.add(
          AuditTip(
            id: 'tip_sleep_${now.microsecondsSinceEpoch}',
            findingId: idleFinding.id,
            actionType: 'sleep_auto_lock',
            title: 'Enable sleep after 15 minutes',
            body:
                'Sleep timers reduce avoidable idle energy use and can cut waste from unattended sessions.',
            estimatedWattsSaved: wattsSaved,
            estimatedMonthlySavings: monthlySavings,
            confidence: 'medium',
          ),
        );
      }
    }

    tips.sort(
      (a, b) => b.estimatedMonthlySavings.compareTo(a.estimatedMonthlySavings),
    );
    return tips.take(3).toList(growable: false);
  }

  Map<String, dynamic> _specSnapshot(SystemSpecModel spec) {
    return <String, dynamic>{
      'cpu_name': spec.cpuName,
      'gpu_name': spec.gpuName,
      'gpu_type': spec.gpuType,
      'ram_gb': spec.ramGb,
      'ram_sticks': spec.ramSticks,
      'storage_count': spec.storageCount,
      'storage_type': spec.storageType,
      'fan_count': spec.fanCount,
      'has_rgb': spec.hasRgb,
      'motherboard': spec.motherboard,
      'chassis_type': spec.chassisType,
    };
  }

  String _overallConfidence({
    required bool hasOverrides,
    required bool hasPeripherals,
    required bool hasActivitySample,
  }) {
    if (hasActivitySample) {
      return 'high';
    }
    if (hasOverrides && !hasPeripherals) {
      return 'medium';
    }
    return hasPeripherals ? 'high' : 'medium';
  }

  double _dataCompleteness({
    required SystemSpecModel resolvedSpec,
    required bool hasOverrides,
    required bool hasActivitySample,
  }) {
    var score = 0.75;
    if (resolvedSpec.cpuName.toLowerCase() != 'unknown cpu') {
      score += 0.05;
    }
    if (resolvedSpec.gpuName.toLowerCase() != 'integrated graphics') {
      score += 0.05;
    }
    if (hasOverrides) {
      score += 0.05;
    }
    if (hasActivitySample) {
      score += 0.1;
    }
    return score.clamp(0, 1).toDouble();
  }

  String? _findingIdForType(List<AuditFinding> findings, String type) {
    return findings.where((item) => item.type == type).firstOrNull?.id;
  }

  bool _shouldShowTip(double monthlySavings, double monthlyCost) {
    if (monthlyCost <= 0) {
      return monthlySavings > 0;
    }
    return monthlySavings >= monthlyCost * _minimumMeaningfulTipPct;
  }

  double _monthlySavings(
    double wattsSaved,
    double hoursPerDay,
    double ratePerKwh,
  ) {
    return ((wattsSaved / 1000) * hoursPerDay * 30) * ratePerKwh;
  }

  String _labelForKey(String key) {
    switch (key) {
      case 'cpu':
        return 'CPU';
      case 'gpu':
        return 'GPU';
      case 'ram':
        return 'RAM';
      case 'storage':
        return 'Storage';
      case 'cooling':
        return 'Cooling';
      case 'rgb':
        return 'RGB / Lighting';
      case 'motherboard':
        return 'Motherboard / Platform';
      case 'peripherals':
        return 'Peripherals';
      default:
        return key;
    }
  }

  double _maxDouble(double a, double b) => a > b ? a : b;

  double _minDouble(double a, double b) => a < b ? a : b;
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}
