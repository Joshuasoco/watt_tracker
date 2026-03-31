import 'package:flutter_test/flutter_test.dart';
import 'package:watt_tracker/data/models/component_model.dart';
import 'package:watt_tracker/data/models/device_model.dart';
import 'package:watt_tracker/features/calculator/cubit/cost_calculator_cubit.dart';
import 'package:watt_tracker/features/calculator/cubit/cost_calculator_state.dart';

void main() {
  group('CostCalculatorCubit', () {
    test('calculates total cost using balanced load formula', () {
      final cubit = CostCalculatorCubit();

      cubit.setDevice(
        const DeviceModel(
          id: 'd1',
          type: DeviceType.desktop,
          label: 'Desktop',
          wattage: 200,
        ),
      );
      cubit.configureComponentWattage([
        const ComponentModel(
          id: 'gpu',
          type: ComponentType.gpu,
          label: 'GPU',
          wattage: 150,
        ),
        const ComponentModel(
          id: 'storage',
          type: ComponentType.storage,
          label: 'Storage',
          wattage: 8,
        ),
        const ComponentModel(
          id: 'fan',
          type: ComponentType.fans,
          label: 'Fans',
          wattage: 3,
        ),
        const ComponentModel(
          id: 'ram',
          type: ComponentType.ram,
          label: 'RAM',
          wattage: 10,
        ),
        const ComponentModel(
          id: 'rgb',
          type: ComponentType.rgb,
          label: 'RGB',
          wattage: 5,
        ),
      ]);
      cubit.setStorageDriveCount(2);
      cubit.setFanCount(3);
      cubit.setRatePerKwh(12.5);
      cubit.setHours(4);
      cubit.setLoadProfile(PerformanceLoadProfile.balanced);

      final expectedWatts = 200 + 150 + (8 * 2) + (3 * 3) + 10 + 5;
      final expectedCost = (expectedWatts * 70 / 1000) * 12.5 * 4;

      expect(cubit.state.totalWatts, closeTo(expectedWatts.toDouble(), 0.0001));
      expect(cubit.state.totalCost, closeTo(expectedCost, 0.0001));
    });

    test('applies eco, balanced and high multipliers', () {
      final cubit = CostCalculatorCubit();

      cubit.setDevice(
        const DeviceModel(
          id: 'd2',
          type: DeviceType.laptop,
          label: 'Laptop',
          wattage: 100,
        ),
      );
      cubit.setRatePerKwh(10);
      cubit.setHours(2);

      cubit.setLoadProfile(PerformanceLoadProfile.eco);
      final ecoCost = cubit.state.totalCost;

      cubit.setLoadProfile(PerformanceLoadProfile.balanced);
      final balancedCost = cubit.state.totalCost;

      cubit.setLoadProfile(PerformanceLoadProfile.high);
      final highCost = cubit.state.totalCost;

      expect(ecoCost, closeTo((100 * 40 / 1000) * 10 * 2, 0.0001));
      expect(balancedCost, closeTo((100 * 70 / 1000) * 10 * 2, 0.0001));
      expect(highCost, closeTo((100 * 100 / 1000) * 10 * 2, 0.0001));
    });

    test('handles GPU toggle on and off', () {
      final cubit = CostCalculatorCubit();

      cubit.setDevice(
        const DeviceModel(
          id: 'd3',
          type: DeviceType.pc,
          label: 'PC',
          wattage: 120,
        ),
      );
      cubit.configureComponentWattage([
        const ComponentModel(
          id: 'gpu',
          type: ComponentType.gpu,
          label: 'GPU',
          wattage: 200,
        ),
      ]);

      expect(cubit.state.totalWatts, 320);

      cubit.toggleGpu(false);
      expect(cubit.state.totalWatts, 120);

      cubit.toggleGpu(true);
      expect(cubit.state.totalWatts, 320);
    });

    test('handles per-drive and per-fan wattage counts', () {
      final cubit = CostCalculatorCubit();

      cubit.configureComponentWattage([
        const ComponentModel(
          id: 'storage',
          type: ComponentType.storage,
          label: 'Storage',
          wattage: 6,
        ),
        const ComponentModel(
          id: 'fan',
          type: ComponentType.fans,
          label: 'Fan',
          wattage: 4,
        ),
      ]);

      cubit.setStorageDriveCount(3);
      cubit.setFanCount(5);

      expect(cubit.state.totalWatts, 38);
    });

    test('clamps negative inputs to zero', () {
      final cubit = CostCalculatorCubit();

      cubit.setRatePerKwh(-1);
      cubit.setHours(-5);
      cubit.setStorageDriveCount(-2);
      cubit.setFanCount(-9);

      expect(cubit.state.ratePerKwh, 0);
      expect(cubit.state.hours, 0);
      expect(cubit.state.storageDriveCount, 0);
      expect(cubit.state.fanCount, 0);
      expect(cubit.state.totalCost, 0);
    });
  });
}
