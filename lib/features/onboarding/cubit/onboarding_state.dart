import 'package:equatable/equatable.dart';

import '../../../data/models/system_spec_model.dart';
import '../../../data/models/usage_profile.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.currentStep = 0,
    required this.scannedSpecs,
    required this.confirmedSpecs,
    this.electricityRate = 12.0,
    this.currencySymbol = '\u20B1',
    this.dailyHours = 8,
    this.usageProfile = UsageProfile.balanced,
    this.isScanning = false,
    this.scanError,
    this.termsAccepted = false,
    this.cpuScanned = false,
    this.gpuScanned = false,
    this.ramScanned = false,
    this.storageScanned = false,
    this.motherboardScanned = false,
  });

  factory OnboardingState.initial() {
    final defaults = SystemSpecModel.defaults();
    return OnboardingState(scannedSpecs: defaults, confirmedSpecs: defaults);
  }

  final int currentStep;
  final SystemSpecModel scannedSpecs;
  final SystemSpecModel confirmedSpecs;
  final double electricityRate;
  final String currencySymbol;
  final double dailyHours;
  final UsageProfile usageProfile;
  final bool isScanning;
  final String? scanError;
  final bool termsAccepted;
  final bool cpuScanned;
  final bool gpuScanned;
  final bool ramScanned;
  final bool storageScanned;
  final bool motherboardScanned;

  OnboardingState copyWith({
    int? currentStep,
    SystemSpecModel? scannedSpecs,
    SystemSpecModel? confirmedSpecs,
    double? electricityRate,
    String? currencySymbol,
    double? dailyHours,
    UsageProfile? usageProfile,
    bool? isScanning,
    String? scanError,
    bool clearScanError = false,
    bool? termsAccepted,
    bool? cpuScanned,
    bool? gpuScanned,
    bool? ramScanned,
    bool? storageScanned,
    bool? motherboardScanned,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      scannedSpecs: scannedSpecs ?? this.scannedSpecs,
      confirmedSpecs: confirmedSpecs ?? this.confirmedSpecs,
      electricityRate: electricityRate ?? this.electricityRate,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      dailyHours: dailyHours ?? this.dailyHours,
      usageProfile: usageProfile ?? this.usageProfile,
      isScanning: isScanning ?? this.isScanning,
      scanError: clearScanError ? null : (scanError ?? this.scanError),
      termsAccepted: termsAccepted ?? this.termsAccepted,
      cpuScanned: cpuScanned ?? this.cpuScanned,
      gpuScanned: gpuScanned ?? this.gpuScanned,
      ramScanned: ramScanned ?? this.ramScanned,
      storageScanned: storageScanned ?? this.storageScanned,
      motherboardScanned: motherboardScanned ?? this.motherboardScanned,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    scannedSpecs,
    confirmedSpecs,
    electricityRate,
    currencySymbol,
    dailyHours,
    usageProfile,
    isScanning,
    scanError,
    termsAccepted,
    cpuScanned,
    gpuScanned,
    ramScanned,
    storageScanned,
    motherboardScanned,
  ];
}
