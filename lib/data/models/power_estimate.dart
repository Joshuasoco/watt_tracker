import 'package:equatable/equatable.dart';

import 'usage_profile.dart';

enum EstimateConfidence { high, medium, low }

extension EstimateConfidenceX on EstimateConfidence {
  String get label {
    switch (this) {
      case EstimateConfidence.high:
        return 'High';
      case EstimateConfidence.medium:
        return 'Medium';
      case EstimateConfidence.low:
        return 'Low';
    }
  }
}

class PowerEstimateComponent extends Equatable {
  const PowerEstimateComponent({
    required this.key,
    required this.label,
    required this.peakWatts,
    required this.estimatedWatts,
  });

  final String key;
  final String label;
  final double peakWatts;
  final double estimatedWatts;

  double estimatedCostPerHour(double ratePerKwh) {
    return (estimatedWatts / 1000) * ratePerKwh;
  }

  @override
  List<Object?> get props => [key, label, peakWatts, estimatedWatts];
}

class PowerEstimate extends Equatable {
  const PowerEstimate({
    required this.usageProfile,
    required this.peakWatts,
    required this.estimatedWatts,
    required this.costPerSecond,
    required this.costPerHour,
    required this.costPerDay,
    required this.costPerMonth,
    required this.confidence,
    required this.confidenceReasons,
    required this.formula,
    required this.generatedAt,
    required this.components,
  });

  final UsageProfile usageProfile;
  final double peakWatts;
  final double estimatedWatts;
  final double costPerSecond;
  final double costPerHour;
  final double costPerDay;
  final double costPerMonth;
  final EstimateConfidence confidence;
  final List<String> confidenceReasons;
  final String formula;
  final DateTime generatedAt;
  final List<PowerEstimateComponent> components;

  @override
  List<Object?> get props => [
    usageProfile,
    peakWatts,
    estimatedWatts,
    costPerSecond,
    costPerHour,
    costPerDay,
    costPerMonth,
    confidence,
    confidenceReasons,
    formula,
    generatedAt,
    components,
  ];
}
