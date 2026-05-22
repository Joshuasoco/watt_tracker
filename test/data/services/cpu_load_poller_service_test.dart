import 'package:flutter_test/flutter_test.dart';
import 'package:watt_tracker/data/services/cpu_load_poller_service.dart';

void main() {
  group('CpuLoadPollerService', () {
    test('scales desktop CPU watts from idle floor to TDP ceiling', () {
      final idleWatts = CpuLoadPollerService.idleWattsFor(
        tdpWatts: 100,
        chassisType: 'desktop',
      );
      final estimatedWatts = CpuLoadPollerService.estimateWatts(
        idleWatts: idleWatts,
        peakWatts: 100,
        cpuLoadPercent: 50,
      );

      expect(idleWatts, 15);
      expect(estimatedWatts, 57.5);
    });

    test('uses a lower laptop idle floor', () {
      final idleWatts = CpuLoadPollerService.idleWattsFor(
        tdpWatts: 100,
        chassisType: 'laptop',
      );

      expect(idleWatts, 10);
    });

    test('emits a scaled sample from an injected load reader', () async {
      final service = CpuLoadPollerService(
        interval: const Duration(minutes: 5),
        loadReader: () async => 25,
      );
      addTearDown(service.dispose);

      final eventFuture = service.stream.first;
      service.start(peakWatts: 80, chassisType: 'desktop');
      final event = await eventFuture.timeout(const Duration(seconds: 1));

      expect(event.isSuccess, isTrue);
      expect(event.sample?.loadPercent, 25);
      expect(event.sample?.idleWatts, 12);
      expect(event.sample?.cpuWatts, 29);
    });
  });
}
