import '../models/power_estimate.dart';
import '../models/system_spec_model.dart';
import '../models/usage_profile.dart';

class PowerEstimationService {
  const PowerEstimationService();

  PowerEstimate estimate({
    required SystemSpecModel spec,
    required double ratePerKwh,
    required double dailyHours,
    required UsageProfile usageProfile,
  }) {
    final components = <PowerEstimateComponent>[
      PowerEstimateComponent(
        key: 'cpu',
        label: 'CPU',
        peakWatts: spec.cpuTdpWatts.toDouble(),
        estimatedWatts: _loadedCoreWatts(
          peakWatts: spec.cpuTdpWatts.toDouble(),
          idleWatts: _cpuIdleWatts(spec),
          loadFraction: _cpuLoadFraction(usageProfile),
        ),
      ),
      PowerEstimateComponent(
        key: 'gpu',
        label: 'GPU',
        peakWatts: spec.gpuWatts.toDouble(),
        estimatedWatts: _loadedCoreWatts(
          peakWatts: spec.gpuWatts.toDouble(),
          idleWatts: _gpuIdleWatts(spec),
          loadFraction: _gpuLoadFraction(spec, usageProfile),
        ),
      ),
      PowerEstimateComponent(
        key: 'ram',
        label: 'RAM',
        peakWatts: (spec.ramSticks * spec.ramWattsPerStick).toDouble(),
        estimatedWatts:
            (spec.ramSticks * spec.ramWattsPerStick) *
            _ramMultiplier(usageProfile),
      ),
      PowerEstimateComponent(
        key: 'storage',
        label: 'Storage',
        peakWatts: (spec.storageCount * spec.storageWattsEach).toDouble(),
        estimatedWatts:
            (spec.storageCount * spec.storageWattsEach) *
            _storageMultiplier(usageProfile),
      ),
      PowerEstimateComponent(
        key: 'fans',
        label: 'Cooling',
        peakWatts: (spec.fanCount * spec.fansWattsEach).toDouble(),
        estimatedWatts:
            (spec.fanCount * spec.fansWattsEach) *
            _coolingMultiplier(usageProfile),
      ),
      PowerEstimateComponent(
        key: 'rgb',
        label: 'RGB',
        peakWatts: spec.hasRgb ? spec.rgbWatts.toDouble() : 0,
        estimatedWatts: spec.hasRgb ? spec.rgbWatts.toDouble() : 0,
      ),
      PowerEstimateComponent(
        key: 'motherboard',
        label: 'Motherboard',
        peakWatts: spec.motherboardWatts.toDouble(),
        estimatedWatts:
            spec.motherboardWatts * _platformMultiplier(spec, usageProfile),
      ),
    ];

    final estimatedWatts = components.fold<double>(
      0,
      (sum, component) => sum + component.estimatedWatts,
    );
    final peakWatts = components.fold<double>(
      0,
      (sum, component) => sum + component.peakWatts,
    );
    final costPerHour = (estimatedWatts / 1000) * ratePerKwh;
    final confidenceReasons = _confidenceReasons(spec);
    final confidence = _estimateConfidence(confidenceReasons);
    final generatedAt = DateTime.now();

    return PowerEstimate(
      usageProfile: usageProfile,
      peakWatts: peakWatts,
      estimatedWatts: estimatedWatts,
      costPerSecond: costPerHour / 3600,
      costPerHour: costPerHour,
      costPerDay: costPerHour * dailyHours,
      costPerMonth: costPerHour * dailyHours * 30,
      confidence: confidence,
      confidenceReasons: confidenceReasons.isEmpty
          ? [
              'Core hardware looks confirmed, so this estimate is based on saved component models.',
            ]
          : confidenceReasons,
      formula:
          '${estimatedWatts.toStringAsFixed(0)} W x ${ratePerKwh.toStringAsFixed(2)} /kWh x ${dailyHours.toStringAsFixed(1)} hrs/day',
      generatedAt: generatedAt,
      components: components,
    );
  }

  double _cpuIdleWatts(SystemSpecModel spec) {
    final floor = spec.chassisType == 'laptop' ? 7.0 : 12.0;
    return _clampDouble(
      spec.cpuTdpWatts * 0.18,
      floor,
      spec.cpuTdpWatts * 0.55,
    );
  }

  double _gpuIdleWatts(SystemSpecModel spec) {
    if (spec.gpuType == 'dedicated') {
      return _clampDouble(spec.gpuWatts * 0.12, 18.0, spec.gpuWatts * 0.45);
    }
    return _clampDouble(spec.gpuWatts * 0.4, 4.0, spec.gpuWatts * 0.75);
  }

  double _loadedCoreWatts({
    required double peakWatts,
    required double idleWatts,
    required double loadFraction,
  }) {
    if (peakWatts <= 0) {
      return 0;
    }
    return idleWatts + (peakWatts - idleWatts) * loadFraction;
  }

  double _cpuLoadFraction(UsageProfile profile) {
    switch (profile) {
      case UsageProfile.idleOffice:
        return 0.2;
      case UsageProfile.balanced:
        return 0.42;
      case UsageProfile.gaming:
        return 0.55;
      case UsageProfile.renderAi:
        return 0.72;
    }
  }

  double _gpuLoadFraction(SystemSpecModel spec, UsageProfile profile) {
    switch (profile) {
      case UsageProfile.idleOffice:
        return spec.gpuType == 'dedicated' ? 0.08 : 0.14;
      case UsageProfile.balanced:
        return spec.gpuType == 'dedicated' ? 0.3 : 0.26;
      case UsageProfile.gaming:
        return spec.gpuType == 'dedicated' ? 0.72 : 0.48;
      case UsageProfile.renderAi:
        return spec.gpuType == 'dedicated' ? 0.86 : 0.52;
    }
  }

  double _ramMultiplier(UsageProfile profile) {
    switch (profile) {
      case UsageProfile.idleOffice:
        return 0.72;
      case UsageProfile.balanced:
        return 0.82;
      case UsageProfile.gaming:
        return 0.9;
      case UsageProfile.renderAi:
        return 0.96;
    }
  }

  double _storageMultiplier(UsageProfile profile) {
    switch (profile) {
      case UsageProfile.idleOffice:
        return 0.62;
      case UsageProfile.balanced:
        return 0.75;
      case UsageProfile.gaming:
        return 0.84;
      case UsageProfile.renderAi:
        return 0.9;
    }
  }

  double _coolingMultiplier(UsageProfile profile) {
    switch (profile) {
      case UsageProfile.idleOffice:
        return 0.58;
      case UsageProfile.balanced:
        return 0.72;
      case UsageProfile.gaming:
        return 0.9;
      case UsageProfile.renderAi:
        return 1;
    }
  }

  double _platformMultiplier(SystemSpecModel spec, UsageProfile profile) {
    final laptopAdjustment = spec.chassisType == 'laptop' ? -0.08 : 0.0;
    switch (profile) {
      case UsageProfile.idleOffice:
        return 0.68 + laptopAdjustment;
      case UsageProfile.balanced:
        return 0.8 + laptopAdjustment;
      case UsageProfile.gaming:
        return 0.9 + laptopAdjustment;
      case UsageProfile.renderAi:
        return 0.95 + laptopAdjustment;
    }
  }

  List<String> _confidenceReasons(SystemSpecModel spec) {
    final reasons = <String>[];

    if (_looksUnknown(spec.cpuName)) {
      reasons.add(
        'CPU model is generic, so WattWise is using a fallback CPU watt estimate.',
      );
    }
    if (_looksUnknown(spec.gpuName)) {
      reasons.add(
        'GPU model is incomplete, which lowers confidence in graphics power assumptions.',
      );
    }
    if (_looksUnknown(spec.motherboard)) {
      reasons.add(
        'Motherboard details are missing, so platform overhead uses a default baseline.',
      );
    }
    if (spec.gpuType == 'dedicated' && spec.gpuWatts <= 30) {
      reasons.add(
        'Dedicated GPU wattage looks unusually low, so real-world draw may differ.',
      );
    }

    return reasons;
  }

  EstimateConfidence _estimateConfidence(List<String> reasons) {
    if (reasons.length >= 3) {
      return EstimateConfidence.low;
    }
    if (reasons.isNotEmpty) {
      return EstimateConfidence.medium;
    }
    return EstimateConfidence.high;
  }

  bool _looksUnknown(String raw) {
    final normalized = raw.trim().toLowerCase();
    return normalized.isEmpty || normalized.contains('unknown');
  }

  double _clampDouble(double value, double min, double max) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}
