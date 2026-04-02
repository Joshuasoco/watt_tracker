import 'package:flutter_test/flutter_test.dart';
import 'package:watt_tracker/data/models/power_estimate.dart';
import 'package:watt_tracker/data/models/system_spec_model.dart';
import 'package:watt_tracker/data/models/usage_profile.dart';
import 'package:watt_tracker/data/services/power_estimation_service.dart';

void main() {
  group('PowerEstimationService', () {
    const service = PowerEstimationService();

    final spec = SystemSpecModel.defaults().copyWith(
      cpuName: 'AMD Ryzen 7 7800X3D',
      cpuTdpWatts: 120,
      gpuType: 'dedicated',
      gpuName: 'NVIDIA GeForce RTX 4070',
      gpuWatts: 200,
      ramGb: 32,
      ramSticks: 2,
      storageCount: 2,
      storageType: 'SSD',
      storageWattsEach: 3,
      fanCount: 4,
      fansWattsEach: 2,
      hasRgb: true,
      rgbWatts: 10,
      motherboardWatts: 55,
      motherboard: 'B650E',
      chassisType: 'desktop',
    );

    test('uses usage profiles to change estimated draw', () {
      final officeEstimate = service.estimate(
        spec: spec,
        ratePerKwh: 12.5,
        dailyHours: 8,
        usageProfile: UsageProfile.idleOffice,
      );
      final gamingEstimate = service.estimate(
        spec: spec,
        ratePerKwh: 12.5,
        dailyHours: 8,
        usageProfile: UsageProfile.gaming,
      );
      final renderEstimate = service.estimate(
        spec: spec,
        ratePerKwh: 12.5,
        dailyHours: 8,
        usageProfile: UsageProfile.renderAi,
      );

      expect(
        officeEstimate.estimatedWatts,
        lessThan(gamingEstimate.estimatedWatts),
      );
      expect(
        gamingEstimate.estimatedWatts,
        lessThan(renderEstimate.estimatedWatts),
      );
      expect(
        gamingEstimate.costPerMonth,
        greaterThan(officeEstimate.costPerMonth),
      );
    });

    test('returns high confidence when key hardware is known', () {
      final estimate = service.estimate(
        spec: spec,
        ratePerKwh: 13.47,
        dailyHours: 6,
        usageProfile: UsageProfile.balanced,
      );

      expect(estimate.confidence, EstimateConfidence.high);
      expect(estimate.confidenceReasons, hasLength(1));
      expect(estimate.confidenceReasons.first, contains('confirmed'));
    });

    test('returns lower confidence when profile uses fallback labels', () {
      final estimate = service.estimate(
        spec: SystemSpecModel.defaults(),
        ratePerKwh: 12,
        dailyHours: 8,
        usageProfile: UsageProfile.balanced,
      );

      expect(
        estimate.confidence,
        anyOf(EstimateConfidence.medium, EstimateConfidence.low),
      );
      expect(estimate.confidenceReasons, isNotEmpty);
    });

    test('applies manual calibration as a correction factor', () {
      final uncalibrated = service.estimate(
        spec: spec,
        ratePerKwh: 12,
        dailyHours: 8,
        usageProfile: UsageProfile.balanced,
      );
      final calibrated = service.estimate(
        spec: spec,
        ratePerKwh: 12,
        dailyHours: 8,
        usageProfile: UsageProfile.balanced,
        manualCalibrationWatts: 180,
      );

      expect(calibrated.isCalibrated, isTrue);
      expect(calibrated.manualCalibrationWatts, 180);
      expect(
        calibrated.calibrationFactor,
        closeTo(180 / uncalibrated.estimatedWatts, 0.0001),
      );
      expect(
        calibrated.uncalibratedWatts,
        closeTo(uncalibrated.estimatedWatts, 0.0001),
      );
      expect(calibrated.estimatedWatts, closeTo(180, 0.0001));
      expect(calibrated.formula, contains('calibration'));
    });
  });
}
