import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/energy_audit_repository.dart';
import '../../../data/repositories/wattwise_prefs_repository.dart';
import '../../../data/services/energy_audit_service.dart';
import '../../../data/services/windows_activity_sampler.dart';
import '../models/energy_audit_result.dart';
import 'energy_audit_state.dart';

class EnergyAuditCubit extends Cubit<EnergyAuditState> {
  EnergyAuditCubit({
    required EnergyAuditRepository auditRepository,
    required WattwisePrefsRepository prefsRepository,
    EnergyAuditService? auditService,
    WindowsActivitySampler? activitySampler,
  }) : _auditRepository = auditRepository,
       _prefsRepository = prefsRepository,
       _auditService = auditService ?? EnergyAuditService(),
       _activitySampler = activitySampler ?? const WindowsActivitySampler(),
       super(const EnergyAuditState());

  final EnergyAuditRepository _auditRepository;
  final WattwisePrefsRepository _prefsRepository;
  final EnergyAuditService _auditService;
  final WindowsActivitySampler _activitySampler;

  void loadLatest() {
    final latest = _auditRepository.getLatestResult();
    final history = _auditRepository.getHistory();
    emit(
      state.copyWith(
        status: EnergyAuditStatus.success,
        latestResult: latest,
        history: history,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> runAudit() async {
    emit(
      state.copyWith(
        status: EnergyAuditStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      final activitySample = await _activitySampler.sample();

      final result = _auditService.runAudit(
        spec: _prefsRepository.systemSpec,
        ratePerKwh: _prefsRepository.electricityRate,
        currencySymbol: _prefsRepository.currencySymbol,
        dailyHours: _prefsRepository.dailyHours,
        overrides: _auditRepository.getUserOverrides(),
        peripherals: _auditRepository.getPeripherals(),
        activitySample: activitySample,
      );

      await _auditRepository.saveAuditResult(result);
      _emitLoadedState(result);
    } catch (_) {
      emit(
        state.copyWith(
          status: EnergyAuditStatus.failure,
          errorMessage: 'Failed to run energy audit. Please try again.',
        ),
      );
    }
  }

  Future<void> dismissTip(String tipId) async {
    await _auditRepository.dismissTip(tipId);
    _emitLoadedState(_auditRepository.getLatestResult());
  }

  Future<void> snoozeTip(String tipId, {int? days}) async {
    final snoozeDays =
        days ?? _auditRepository.getAuditSettings().defaultSnoozeDays;
    final until = DateTime.now().toUtc().add(Duration(days: snoozeDays));
    await _auditRepository.snoozeTip(tipId, until);
    _emitLoadedState(_auditRepository.getLatestResult());
  }

  void _emitLoadedState(EnergyAuditResult? latest) {
    emit(
      state.copyWith(
        status: EnergyAuditStatus.success,
        latestResult: latest,
        history: _auditRepository.getHistory(),
        clearErrorMessage: true,
      ),
    );
  }
}
