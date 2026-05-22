import 'dart:async';
import 'dart:io';

class CpuLoadSample {
  const CpuLoadSample({
    required this.loadPercent,
    required this.idleWatts,
    required this.peakWatts,
    required this.cpuWatts,
  });

  final double loadPercent;
  final double idleWatts;
  final double peakWatts;
  final double cpuWatts;
}

class CpuLoadPollResult {
  const CpuLoadPollResult._({required this.isSuccess, this.sample, this.error});

  factory CpuLoadPollResult.success(CpuLoadSample sample) {
    return CpuLoadPollResult._(isSuccess: true, sample: sample);
  }

  factory CpuLoadPollResult.failure(String error) {
    return CpuLoadPollResult._(isSuccess: false, error: error);
  }

  final bool isSuccess;
  final CpuLoadSample? sample;
  final String? error;
}

typedef CpuLoadReader = Future<double?> Function();

class CpuLoadPollerService {
  CpuLoadPollerService({
    this.interval = const Duration(seconds: 2),
    this.commandTimeout = const Duration(seconds: 4),
    CpuLoadReader? loadReader,
  }) : _loadReader = loadReader;

  final Duration interval;
  final Duration commandTimeout;
  final CpuLoadReader? _loadReader;
  final StreamController<CpuLoadPollResult> _controller =
      StreamController<CpuLoadPollResult>.broadcast();

  Timer? _timer;
  bool _isPolling = false;
  bool _pollInFlight = false;
  int _generation = 0;
  double _peakWatts = 0;
  String _chassisType = 'desktop';

  Stream<CpuLoadPollResult> get stream => _controller.stream;

  void start({required double peakWatts, required String chassisType}) {
    stop();
    _peakWatts = peakWatts;
    _chassisType = chassisType;
    _isPolling = true;
    final generation = ++_generation;

    if (!Platform.isWindows && _loadReader == null) {
      scheduleMicrotask(() {
        if (_isPolling && generation == _generation) {
          _controller.add(
            CpuLoadPollResult.failure(
              'CPU load polling is only available on Windows.',
            ),
          );
          stop();
        }
      });
      return;
    }

    unawaited(_pollOnce(generation));
    _timer = Timer.periodic(interval, (_) {
      unawaited(_pollOnce(generation));
    });
  }

  void stop() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _isPolling = false;
    _pollInFlight = false;
  }

  Future<void> dispose() async {
    stop();
    await _controller.close();
  }

  Future<void> _pollOnce(int generation) async {
    if (!_isPolling || _pollInFlight || generation != _generation) {
      return;
    }

    _pollInFlight = true;
    try {
      final loadPercent = await (_loadReader ?? _readWindowsCpuLoad)();
      if (!_isPolling || generation != _generation) {
        return;
      }

      if (loadPercent == null || loadPercent.isNaN || loadPercent.isInfinite) {
        _controller.add(
          CpuLoadPollResult.failure('Win32_Processor.LoadPercentage failed.'),
        );
        stop();
        return;
      }

      final clampedLoad = _clampDouble(loadPercent, 0, 100);
      final idleWatts = idleWattsFor(
        tdpWatts: _peakWatts,
        chassisType: _chassisType,
      );
      final cpuWatts = estimateWatts(
        idleWatts: idleWatts,
        peakWatts: _peakWatts,
        cpuLoadPercent: clampedLoad,
      );

      _controller.add(
        CpuLoadPollResult.success(
          CpuLoadSample(
            loadPercent: clampedLoad,
            idleWatts: idleWatts,
            peakWatts: _peakWatts,
            cpuWatts: cpuWatts,
          ),
        ),
      );
    } catch (error) {
      if (_isPolling && generation == _generation) {
        _controller.add(CpuLoadPollResult.failure(error.toString()));
        stop();
      }
    } finally {
      if (generation == _generation) {
        _pollInFlight = false;
      }
    }
  }

  Future<double?> _readWindowsCpuLoad() async {
    const script = r'''
$loads = Get-CimInstance -ClassName Win32_Processor |
  Select-Object -ExpandProperty LoadPercentage
if ($null -eq $loads) { exit 2 }
[math]::Round(($loads | Measure-Object -Average).Average, 2)
''';

    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      script,
    ]).timeout(commandTimeout);

    if (result.exitCode != 0) {
      return null;
    }

    return double.tryParse(result.stdout.toString().trim());
  }

  static double idleWattsFor({
    required double tdpWatts,
    required String chassisType,
  }) {
    final idleFraction = chassisType.trim().toLowerCase() == 'laptop'
        ? 0.10
        : 0.15;
    return tdpWatts * idleFraction;
  }

  static double estimateWatts({
    required double idleWatts,
    required double peakWatts,
    required double cpuLoadPercent,
  }) {
    final loadFraction = _clampDouble(cpuLoadPercent, 0, 100) / 100;
    return idleWatts + (peakWatts - idleWatts) * loadFraction;
  }

  static double _clampDouble(double value, double min, double max) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}
