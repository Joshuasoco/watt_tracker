import 'package:equatable/equatable.dart';

import '../../../data/models/power_estimate.dart';
import '../../../data/models/system_spec_model.dart';
import '../../../data/models/usage_profile.dart';

class LiveTimerState extends Equatable {
  const LiveTimerState({
    required this.spec,
    required this.estimate,
    this.usageProfile = UsageProfile.balanced,
    this.currencySymbol = '\u20B1',
    this.ratePerKwh = 12,
    this.dailyHours = 8,
    this.elapsedSeconds = 0,
    this.totalCostAccumulated = 0,
    this.costPerSecond = 0,
    this.isRunning = false,
  });

  factory LiveTimerState.initial() {
    return LiveTimerState(
      spec: SystemSpecModel.defaults(),
      estimate: PowerEstimate(
        usageProfile: UsageProfile.balanced,
        peakWatts: SystemSpecModel.defaults().totalWatts.toDouble(),
        estimatedWatts: SystemSpecModel.defaults().totalWatts.toDouble(),
        costPerSecond: 0,
        costPerHour: 0,
        costPerDay: 0,
        costPerMonth: 0,
        confidence: EstimateConfidence.low,
        confidenceReasons: const ['Estimate not calculated yet.'],
        formula: '',
        generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        components: const [],
      ),
    );
  }

  final SystemSpecModel spec;
  final PowerEstimate estimate;
  final UsageProfile usageProfile;
  final String currencySymbol;
  final double ratePerKwh;
  final double dailyHours;
  final int elapsedSeconds;
  final double totalCostAccumulated;
  final double costPerSecond;
  final bool isRunning;

  double get perHour => estimate.costPerHour;
  double get perDay => estimate.costPerDay;
  double get perMonth => estimate.costPerMonth;

  LiveTimerState copyWith({
    SystemSpecModel? spec,
    PowerEstimate? estimate,
    UsageProfile? usageProfile,
    String? currencySymbol,
    double? ratePerKwh,
    double? dailyHours,
    int? elapsedSeconds,
    double? totalCostAccumulated,
    double? costPerSecond,
    bool? isRunning,
  }) {
    return LiveTimerState(
      spec: spec ?? this.spec,
      estimate: estimate ?? this.estimate,
      usageProfile: usageProfile ?? this.usageProfile,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      ratePerKwh: ratePerKwh ?? this.ratePerKwh,
      dailyHours: dailyHours ?? this.dailyHours,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalCostAccumulated: totalCostAccumulated ?? this.totalCostAccumulated,
      costPerSecond: costPerSecond ?? this.costPerSecond,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  @override
  List<Object?> get props => [
    spec,
    estimate,
    usageProfile,
    currencySymbol,
    ratePerKwh,
    dailyHours,
    elapsedSeconds,
    totalCostAccumulated,
    costPerSecond,
    isRunning,
  ];
}
