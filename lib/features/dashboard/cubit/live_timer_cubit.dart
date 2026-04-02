import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_notifier/local_notifier.dart';

import '../../../data/models/power_estimate.dart';
import '../../../data/models/system_spec_model.dart';
import '../../../data/models/usage_profile.dart';
import '../../../data/repositories/wattage_preset_repository.dart';
import '../../../data/repositories/wattwise_prefs_repository.dart';
import '../../../data/services/power_estimation_service.dart';
import '../../../data/services/tray_service.dart';
import 'live_timer_state.dart';

class LiveTimerCubit extends Cubit<LiveTimerState> {
  LiveTimerCubit({
    required WattwisePrefsRepository prefsRepository,
    WattagePresetRepository? presetRepository,
    PowerEstimationService? estimationService,
  }) : _prefsRepository = prefsRepository,
       _presetRepository = presetRepository ?? WattagePresetRepository(),
       _estimationService = estimationService ?? const PowerEstimationService(),
       super(LiveTimerState.initial()) {
    _initializeFromPrefs();
  }

  final WattwisePrefsRepository _prefsRepository;
  final WattagePresetRepository _presetRepository;
  final PowerEstimationService _estimationService;
  StreamSubscription<int>? _tickerSub;
  double sessionMilestoneHours = 2.0;
  bool _milestoneNotified = false;

  String get formattedCost => _formattedCost();

  void _initializeFromPrefs() {
    final savedSpec = _prefsRepository.systemSpec;
    final rate = _prefsRepository.electricityRate;
    final dailyHours = _prefsRepository.dailyHours;
    final currencySymbol = _prefsRepository.currencySymbol;
    final usageProfile = _prefsRepository.usageProfile;
    sessionMilestoneHours = _prefsRepository.sessionMilestoneHours;

    final spec = _resolveSpec(savedSpec);
    final estimate = _buildEstimate(
      spec: spec,
      rate: rate,
      dailyHours: dailyHours,
      usageProfile: usageProfile,
    );

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

    sessionMilestoneHours = _prefsRepository.sessionMilestoneHours;

    final spec = _resolveSpec(savedSpec);
    final estimate = _buildEstimate(
      spec: spec,
      rate: rate,
      dailyHours: dailyHours,
      usageProfile: usageProfile,
    );

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

    unawaited(TrayService().updateTooltip(_formattedCost()));
  }

  void startTimer() {
    if (state.isRunning) {
      return;
    }

    emit(state.copyWith(isRunning: true));
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
    emit(state.copyWith(isRunning: false));
    unawaited(TrayService().rebuildMenu(false));
    unawaited(TrayService().updateTooltip(_formattedCost()));
  }

  void resetTimer() {
    _tickerSub?.cancel();
    _tickerSub = null;
    _milestoneNotified = false;
    emit(
      state.copyWith(
        elapsedSeconds: 0,
        totalCostAccumulated: 0,
        isRunning: false,
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
  }) {
    return _estimationService.estimate(
      spec: spec,
      ratePerKwh: rate,
      dailyHours: dailyHours,
      usageProfile: usageProfile,
    );
  }

  @override
  Future<void> close() async {
    await _tickerSub?.cancel();
    await TrayService().dispose();
    return super.close();
  }
}
