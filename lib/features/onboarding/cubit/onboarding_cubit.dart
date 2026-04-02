import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/system_spec_model.dart';
import '../../../data/models/usage_profile.dart';
import '../../../data/repositories/wattwise_prefs_repository.dart';
import '../../../data/services/system_scan_service.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required WattwisePrefsRepository prefsRepository,
    SystemScanService? scanService,
  }) : _prefsRepository = prefsRepository,
       _scanService = scanService ?? SystemScanService(),
       super(OnboardingState.initial());

  final WattwisePrefsRepository _prefsRepository;
  final SystemScanService _scanService;

  void nextStep() {
    if (state.currentStep >= 6) return;
    emit(state.copyWith(currentStep: state.currentStep + 1));
  }

  void previousStep() {
    if (state.currentStep <= 0) return;
    emit(state.copyWith(currentStep: state.currentStep - 1));
  }

  Future<void> startScan() async {
    if (state.isScanning) return;

    final defaults = SystemSpecModel.defaults();
    emit(
      state.copyWith(
        scannedSpecs: defaults,
        isScanning: true,
        clearScanError: true,
        cpuScanned: false,
        gpuScanned: false,
        ramScanned: false,
        storageScanned: false,
        motherboardScanned: false,
      ),
    );
    try {
      final specs = await _scanService.scanSystem(
        onProgress: (progress) {
          if (isClosed) return;
          emit(
            state.copyWith(
              scannedSpecs: progress.specs,
              cpuScanned: progress.cpuScanned,
              gpuScanned: progress.gpuScanned,
              ramScanned: progress.ramScanned,
              storageScanned: progress.storageScanned,
              motherboardScanned: progress.motherboardScanned,
            ),
          );
        },
      );
      emit(
        state.copyWith(
          scannedSpecs: specs,
          confirmedSpecs: specs,
          isScanning: false,
          clearScanError: true,
          cpuScanned: true,
          gpuScanned: true,
          ramScanned: true,
          storageScanned: true,
          motherboardScanned: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isScanning: false,
          scanError: 'Unable to scan your system. Please try again.',
        ),
      );
    }
  }

  void confirmSpecs(SystemSpecModel specs) {
    emit(state.copyWith(confirmedSpecs: specs));
  }

  void setRate(double rate, String symbol) {
    final normalizedRate = rate <= 0 ? 0.01 : rate;
    final normalizedSymbol = symbol.trim().isEmpty ? '\u20B1' : symbol.trim();
    emit(
      state.copyWith(
        electricityRate: normalizedRate,
        currencySymbol: normalizedSymbol,
      ),
    );
  }

  void setHours(double hours) {
    final normalized = hours.clamp(1.0, 24.0).toDouble();
    emit(state.copyWith(dailyHours: normalized));
  }

  void setUsageProfile(UsageProfile usageProfile) {
    emit(state.copyWith(usageProfile: usageProfile));
  }

  void setTermsAccepted(bool accepted) {
    emit(state.copyWith(termsAccepted: accepted));
  }

  Future<void> completeOnboarding() async {
    await _prefsRepository.saveOnboardingData(
      specs: state.confirmedSpecs,
      electricityRate: state.electricityRate,
      currencySymbol: state.currencySymbol,
      dailyHours: state.dailyHours,
      usageProfile: state.usageProfile,
    );
  }
}
