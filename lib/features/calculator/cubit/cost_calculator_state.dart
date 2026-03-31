enum PerformanceLoadProfile { eco, balanced, high }

extension PerformanceLoadProfileX on PerformanceLoadProfile {
  double get multiplierPercent {
    switch (this) {
      case PerformanceLoadProfile.eco:
        return 40;
      case PerformanceLoadProfile.balanced:
        return 70;
      case PerformanceLoadProfile.high:
        return 100;
    }
  }
}

class CostCalculatorState {
  const CostCalculatorState({
    this.deviceWattage = 0,
    this.gpuWattage = 0,
    this.isGpuEnabled = true,
    this.storageWattagePerDrive = 0,
    this.storageDriveCount = 1,
    this.fanWattagePerFan = 0,
    this.fanCount = 0,
    this.ramWattage = 0,
    this.rgbWattage = 0,
    this.isRgbEnabled = true,
    this.ratePerKwh = 0,
    this.hours = 0,
    this.loadProfile = PerformanceLoadProfile.balanced,
  });

  final double deviceWattage;
  final double gpuWattage;
  final bool isGpuEnabled;
  final double storageWattagePerDrive;
  final int storageDriveCount;
  final double fanWattagePerFan;
  final int fanCount;
  final double ramWattage;
  final double rgbWattage;
  final bool isRgbEnabled;
  final double ratePerKwh;
  final double hours;
  final PerformanceLoadProfile loadProfile;

  double get totalWatts {
    final gpu = isGpuEnabled ? gpuWattage : 0;
    final storage = storageWattagePerDrive * storageDriveCount;
    final fans = fanWattagePerFan * fanCount;
    final rgb = isRgbEnabled ? rgbWattage : 0;
    return deviceWattage + gpu + storage + fans + ramWattage + rgb;
  }

  double get totalCost {
    return (totalWatts * loadProfile.multiplierPercent / 1000) *
        ratePerKwh *
        hours;
  }

  CostCalculatorState copyWith({
    double? deviceWattage,
    double? gpuWattage,
    bool? isGpuEnabled,
    double? storageWattagePerDrive,
    int? storageDriveCount,
    double? fanWattagePerFan,
    int? fanCount,
    double? ramWattage,
    double? rgbWattage,
    bool? isRgbEnabled,
    double? ratePerKwh,
    double? hours,
    PerformanceLoadProfile? loadProfile,
  }) {
    return CostCalculatorState(
      deviceWattage: deviceWattage ?? this.deviceWattage,
      gpuWattage: gpuWattage ?? this.gpuWattage,
      isGpuEnabled: isGpuEnabled ?? this.isGpuEnabled,
      storageWattagePerDrive:
          storageWattagePerDrive ?? this.storageWattagePerDrive,
      storageDriveCount: storageDriveCount ?? this.storageDriveCount,
      fanWattagePerFan: fanWattagePerFan ?? this.fanWattagePerFan,
      fanCount: fanCount ?? this.fanCount,
      ramWattage: ramWattage ?? this.ramWattage,
      rgbWattage: rgbWattage ?? this.rgbWattage,
      isRgbEnabled: isRgbEnabled ?? this.isRgbEnabled,
      ratePerKwh: ratePerKwh ?? this.ratePerKwh,
      hours: hours ?? this.hours,
      loadProfile: loadProfile ?? this.loadProfile,
    );
  }
}
