import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/component_model.dart';
import '../../../../data/models/device_model.dart';
import 'cost_calculator_state.dart';

class CostCalculatorCubit extends Cubit<CostCalculatorState> {
  CostCalculatorCubit() : super(const CostCalculatorState());

  void setDevice(DeviceModel device) {
    emit(state.copyWith(deviceWattage: device.wattage));
  }

  void setRatePerKwh(double ratePerKwh) {
    emit(state.copyWith(ratePerKwh: ratePerKwh < 0 ? 0 : ratePerKwh));
  }

  void setHours(double hours) {
    emit(state.copyWith(hours: hours < 0 ? 0 : hours));
  }

  void setLoadProfile(PerformanceLoadProfile loadProfile) {
    emit(state.copyWith(loadProfile: loadProfile));
  }

  void toggleGpu(bool enabled) {
    emit(state.copyWith(isGpuEnabled: enabled));
  }

  void setStorageDriveCount(int count) {
    emit(state.copyWith(storageDriveCount: count < 0 ? 0 : count));
  }

  void setFanCount(int count) {
    emit(state.copyWith(fanCount: count < 0 ? 0 : count));
  }

  void toggleRgb(bool enabled) {
    emit(state.copyWith(isRgbEnabled: enabled));
  }

  void configureComponentWattage(List<ComponentModel> components) {
    double? gpuWattage;
    double? storageWattage;
    double? fanWattage;
    double? ramWattage;
    double? rgbWattage;

    for (final component in components) {
      switch (component.type) {
        case ComponentType.gpu:
          gpuWattage = component.wattage;
          break;
        case ComponentType.storage:
          storageWattage = component.wattage;
          break;
        case ComponentType.fans:
          fanWattage = component.wattage;
          break;
        case ComponentType.ram:
          ramWattage = component.wattage;
          break;
        case ComponentType.rgb:
          rgbWattage = component.wattage;
          break;
      }
    }

    emit(
      state.copyWith(
        gpuWattage: gpuWattage,
        storageWattagePerDrive: storageWattage,
        fanWattagePerFan: fanWattage,
        ramWattage: ramWattage,
        rgbWattage: rgbWattage,
      ),
    );
  }
}
