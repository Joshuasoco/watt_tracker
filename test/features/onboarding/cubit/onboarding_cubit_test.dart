import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:watt_tracker/data/models/system_spec_model.dart';
import 'package:watt_tracker/data/repositories/wattwise_prefs_repository.dart';
import 'package:watt_tracker/data/services/system_scan_service.dart';
import 'package:watt_tracker/features/onboarding/cubit/onboarding_cubit.dart';

class FakeProgressScanService extends SystemScanService {
  @override
  Future<SystemSpecModel> scanSystem({
    void Function(SystemScanProgress progress)? onProgress,
  }) async {
    final defaults = SystemSpecModel.defaults();

    onProgress?.call(
      SystemScanProgress(
        specs: defaults.copyWith(cpuName: 'AMD Ryzen 5 5600H'),
        cpuScanned: true,
        gpuScanned: false,
        ramScanned: false,
        storageScanned: false,
        motherboardScanned: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    onProgress?.call(
      SystemScanProgress(
        specs: defaults.copyWith(
          cpuName: 'AMD Ryzen 5 5600H',
          gpuName: 'NVIDIA GeForce RTX 3050',
          gpuType: 'dedicated',
          gpuWatts: 80,
        ),
        cpuScanned: true,
        gpuScanned: true,
        ramScanned: false,
        storageScanned: false,
        motherboardScanned: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    return defaults.copyWith(
      cpuName: 'AMD Ryzen 5 5600H',
      gpuName: 'NVIDIA GeForce RTX 3050',
      gpuType: 'dedicated',
      gpuWatts: 80,
      ramGb: 16,
      ramSticks: 2,
      storageCount: 1,
      storageType: 'SSD',
      motherboard: 'ROG STRIX B550-I',
      chassisType: 'desktop',
      fanCount: 3,
      hasRgb: true,
      rgbWatts: 10,
    );
  }
}

void main() {
  late Directory tempDir;
  late Box<dynamic> prefsBox;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('watt_tracker_onboarding_');
    Hive.init(tempDir.path);
    prefsBox = await Hive.openBox<dynamic>('test_wattwise_prefs');
  });

  tearDown(() async {
    await prefsBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('startScan reveals fields progressively before completion', () async {
    final cubit = OnboardingCubit(
      prefsRepository: WattwisePrefsRepository(prefsBox: prefsBox),
      scanService: FakeProgressScanService(),
    );
    final emittedStates = <dynamic>[];
    final subscription = cubit.stream.listen(emittedStates.add);

    await cubit.startScan();

    expect(emittedStates, isNotEmpty);
    expect(emittedStates.first.isScanning, isTrue);
    expect(emittedStates.first.cpuScanned, isFalse);
    expect(
      emittedStates.any(
        (state) => state.cpuScanned && !state.gpuScanned && state.isScanning,
      ),
      isTrue,
    );
    expect(
      emittedStates.any(
        (state) => state.gpuScanned && !state.ramScanned && state.isScanning,
      ),
      isTrue,
    );

    expect(cubit.state.isScanning, isFalse);
    expect(cubit.state.cpuScanned, isTrue);
    expect(cubit.state.gpuScanned, isTrue);
    expect(cubit.state.ramScanned, isTrue);
    expect(cubit.state.storageScanned, isTrue);
    expect(cubit.state.motherboardScanned, isTrue);
    expect(cubit.state.confirmedSpecs.cpuName, 'AMD Ryzen 5 5600H');
    expect(cubit.state.confirmedSpecs.ramGb, 16);
    expect(cubit.state.confirmedSpecs.motherboard, 'ROG STRIX B550-I');

    await subscription.cancel();
    await cubit.close();
  });
}
