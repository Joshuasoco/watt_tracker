import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_notifier/local_notifier.dart';

import '../../../data/models/power_estimate.dart';
import '../../../data/models/system_spec_model.dart';
import '../../../data/models/usage_profile.dart';
import '../../../data/repositories/wattage_preset_repository.dart';
import '../../../data/repositories/wattwise_prefs_repository.dart';
import '../../../data/services/cpu_load_poller_service.dart';
import '../../../data/services/power_estimation_service.dart';
import '../../../data/services/tray_service.dart';
import 'live_timer_state.dart';

class LiveTimerCubit extends Cubit<LiveTimerState> {
  LiveTimerCubit({
    required WattwisePrefsRepository prefsRepository,
    WattagePresetRepository? presetRepository,
    PowerEstimationService? estimationService,
    CpuLoadPollerService? cpuLoadPollerService,
  }) : _prefsRepository = prefsRepository,
       _presetRepository = presetRepository ?? WattagePresetRepository(),
       _estimationService = estimationService ?? const PowerEstimationService(),
       _cpuLoadPollerService = cpuLoadPollerService ?? CpuLoadPollerService(),
       super(LiveTimerState.initial()) {
    _initializeFromPrefs();
  }

  final WattwisePrefsRepository _prefsRepository;
  final WattagePresetRepository _presetRepository;
  final PowerEstimationService _estimationService;
  final CpuLoadPollerService _cpuLoadPollerService;
  StreamSubscription<int>? _tickerSub;
  StreamSubscription<CpuLoadPollResult>? _cpuLoadSub;
  PowerEstimate? _modelEstimate;
  double sessionMilestoneHours = 2.0;
  bool _milestoneNotified = false;

  String get formattedCost => _formattedCost();

  void _initializeFromPrefs() {
    final savedSpec = _prefsRepository.systemSpec;
    final rate = _prefsRepository.electricityRate;
    final dailyHours = _prefsRepository.dailyHours;
    final currencySymbol = _prefsRepository.currencySymbol;
    final usageProfile = _prefsRepository.usageProfile;
    final manualCalibrationWatts = _prefsRepository.manualCalibrationWatts;
    sessionMilestoneHours = _prefsRepository.sessionMilestoneHours;

    final spec = _resolveSpec(savedSpec);
    final estimate = _buildEstimate(
      spec: spec,
      rate: rate,
      dailyHours: dailyHours,
      usageProfile: usageProfile,
      manualCalibrationWatts: manualCalibrationWatts,
    );
    _modelEstimate = estimate;

    emit(
      state.copyWith(
        spec: spec,
        estimate: estimate,
        usageProfile: usageProfile,
        currencySymbol: currencySymbol,
        ratePerKwh: rate,
        dailyHours: dailyHours,
        costPerSecond: estimate.costPerSecond,
      ),
    );
  }

  void reloadPreferences() {
    final savedSpec = _prefsRepository.systemSpec;
    final rate = _prefsRepository.electricityRate;
    final dailyHours = _prefsRepository.dailyHours;
    final currencySymbol = _prefsRepository.currencySymbol;
    final usageProfile = _prefsRepository.usageProfile;
    final manualCalibrationWatts = _prefsRepository.manualCalibrationWatts;

    sessionMilestoneHours = _prefsRepository.sessionMilestoneHours;

    final spec = _resolveSpec(savedSpec);
    final estimate = _buildEstimate(
      spec: spec,
      rate: rate,
      dailyHours: dailyHours,
      usageProfile: usageProfile,
      manualCalibrationWatts: manualCalibrationWatts,
    );
    _modelEstimate = estimate;

    emit(
      state.copyWith(
        spec: spec,
        estimate: estimate,
        usageProfile: usageProfile,
        currencySymbol: currencySymbol,
        ratePerKwh: rate,
        dailyHours: dailyHours,
        costPerSecond: estimate.costPerSecond,
        isLiveLoadActive: false,
        liveCpuLoadPercent: null,
      ),
    );

    if (state.isRunning) {
      _startCpuLoadPolling();
    }

    unawaited(TrayService().updateTooltip(_formattedCost()));
  }

  void startTimer() {
    if (state.isRunning) {
      return;
    }

    emit(state.copyWith(isRunning: true));
    _startCpuLoadPolling();
    unawaited(TrayService().rebuildMenu(true));
    unawaited(TrayService().updateTooltip(_formattedCost()));

    _tickerSub?.cancel();
    _tickerSub = Stream.periodic(const Duration(seconds: 1), (tick) => tick)
        .listen((_) {
          final nextState = state.copyWith(
            elapsedSeconds: state.elapsedSeconds + 1,
            totalCostAccumulated:
                state.totalCostAccumulated + state.costPerSecond,
            isRunning: true,
          );

          emit(nextState);
          unawaited(TrayService().updateTooltip(_formattedCost()));
          _checkMilestone();
        });
  }

  void pauseTimer() {
    _tickerSub?.cancel();
    _tickerSub = null;
    _stopCpuLoadPolling(restoreModelEstimate: true);
    emit(state.copyWith(isRunning: false));
    unawaited(TrayService().rebuildMenu(false));
    unawaited(TrayService().updateTooltip(_formattedCost()));
  }

  void resetTimer() {
    _tickerSub?.cancel();
    _tickerSub = null;
    _stopCpuLoadPolling(restoreModelEstimate: true);
    _milestoneNotified = false;
    emit(
      state.copyWith(
        elapsedSeconds: 0,
        totalCostAccumulated: 0,
        isRunning: false,
        isLiveLoadActive: false,
        liveCpuLoadPercent: null,
      ),
    );
    unawaited(TrayService().updateTooltip(_formattedCost()));
    unawaited(TrayService().rebuildMenu(false));
  }

  void _checkMilestone() {
    final hoursElapsed = state.elapsedSeconds / 3600;
    if (sessionMilestoneHours > 0 &&
        hoursElapsed >= sessionMilestoneHours &&
        !_milestoneNotified) {
      _milestoneNotified = true;
      _sendMilestoneNotification(hoursElapsed);
    }
  }

  void _sendMilestoneNotification(double hours) {
    final notification = LocalNotification(
      title: 'WattWise - Session milestone reached',
      body:
          'You\'ve been tracking for ${hours.toStringAsFixed(1)} hours. Total cost: ${_formattedCost()}',
    );
    unawaited(notification.show());
  }

  String _formattedCost() {
    return '${state.currencySymbol}${state.totalCostAccumulated.toStringAsFixed(4)}';
  }

  SystemSpecModel _resolveSpec(SystemSpecModel savedSpec) {
    return savedSpec.copyWith(
      cpuTdpWatts: _presetRepository.resolveCpuTdp(savedSpec.cpuName),
      gpuWatts: _presetRepository.resolveGpuWatts(
        savedSpec.gpuName,
        savedSpec.gpuType,
      ),
      storageWattsEach: savedSpec.storageType == 'HDD' ? 7 : 3,
      rgbWatts: savedSpec.hasRgb ? 10 : 0,
    );
  }

  PowerEstimate _buildEstimate({
    required SystemSpecModel spec,
    required double rate,
    required double dailyHours,
    required UsageProfile usageProfile,
    required double? manualCalibrationWatts,
  }) {
    return _estimationService.estimate(
      spec: spec,
      ratePerKwh: rate,
      dailyHours: dailyHours,
      usageProfile: usageProfile,
      manualCalibrationWatts: manualCalibrationWatts,
    );
  }

  void _startCpuLoadPolling() {
    _cpuLoadSub?.cancel();
    _cpuLoadPollerService.stop();
    _cpuLoadSub = _cpuLoadPollerService.stream.listen(_handleCpuLoadPoll);
    _cpuLoadPollerService.start(
      peakWatts: state.spec.cpuTdpWatts.toDouble(),
      chassisType: state.spec.chassisType,
    );
  }

  void _stopCpuLoadPolling({required bool restoreModelEstimate}) {
    unawaited(_cpuLoadSub?.cancel());
    _cpuLoadSub = null;
    _cpuLoadPollerService.stop();

    if (!restoreModelEstimate) {
      return;
    }

    final fallbackEstimate = _modelEstimate ?? state.estimate;
    emit(
      state.copyWith(
        estimate: fallbackEstimate,
        costPerSecond: fallbackEstimate.costPerSecond,
        isLiveLoadActive: false,
        liveCpuLoadPercent: null,
      ),
    );
  }

  void _handleCpuLoadPoll(CpuLoadPollResult result) {
    if (!state.isRunning) {
      return;
    }

    if (!result.isSuccess || result.sample == null) {
      // Fallback behavior: if Windows load polling fails, stop the poller and
      // return the ticker to the saved model estimate with the "Model only"
      // badge. This avoids accumulating cost from a stale live-load sample.
      _stopCpuLoadPolling(restoreModelEstimate: true);
      return;
    }

    final sample = result.sample!;
    final liveEstimate = _estimateWithLiveCpuLoad(sample);
    emit(
      state.copyWith(
        estimate: liveEstimate,
        costPerSecond: liveEstimate.costPerSecond,
        isLiveLoadActive: true,
        liveCpuLoadPercent: sample.loadPercent,
      ),
    );
  }

  PowerEstimate _estimateWithLiveCpuLoad(CpuLoadSample sample) {
    final modelEstimate = _modelEstimate ?? state.estimate;
    final components = modelEstimate.components
        .map(
          (component) => component.key == 'cpu'
              ? PowerEstimateComponent(
                  key: component.key,
                  label: component.label,
                  peakWatts: component.peakWatts,
                  estimatedWatts: sample.cpuWatts,
                )
              : component,
        )
        .toList();
    final estimatedWatts = components.fold<double>(
      0,
      (sum, component) => sum + component.estimatedWatts,
    );
    final costPerHour = (estimatedWatts / 1000) * state.ratePerKwh;
    final formula =
        'CPU live load ${sample.loadPercent.toStringAsFixed(0)}%: '
        '${sample.idleWatts.toStringAsFixed(0)} W idle + '
        '(${sample.peakWatts.toStringAsFixed(0)} W peak - '
        '${sample.idleWatts.toStringAsFixed(0)} W idle) x '
        '${(sample.loadPercent / 100).toStringAsFixed(2)} = '
        '${sample.cpuWatts.toStringAsFixed(0)} W CPU; '
        'total ${estimatedWatts.toStringAsFixed(0)} W x '
        '${state.ratePerKwh.toStringAsFixed(2)} /kWh x '
        '${state.dailyHours.toStringAsFixed(1)} hrs/day';

    return PowerEstimate(
      usageProfile: modelEstimate.usageProfile,
      peakWatts: modelEstimate.peakWatts,
      uncalibratedWatts: modelEstimate.uncalibratedWatts,
      estimatedWatts: estimatedWatts,
      calibrationFactor: modelEstimate.calibrationFactor,
      manualCalibrationWatts: modelEstimate.manualCalibrationWatts,
      costPerSecond: costPerHour / 3600,
      costPerHour: costPerHour,
      costPerDay: costPerHour * state.dailyHours,
      costPerMonth: costPerHour * state.dailyHours * 30,
      confidence: modelEstimate.confidence,
      confidenceReasons: [
        'CPU load is sampled from Win32_Processor.LoadPercentage every 2 seconds.',
        ...modelEstimate.confidenceReasons,
      ],
      formula: formula,
      generatedAt: DateTime.now(),
      components: components,
    );
  }

  @override
  Future<void> close() async {
    await _tickerSub?.cancel();
    await _cpuLoadSub?.cancel();
    await _cpuLoadPollerService.dispose();
    await TrayService().dispose();
    return super.close();
  }
}
