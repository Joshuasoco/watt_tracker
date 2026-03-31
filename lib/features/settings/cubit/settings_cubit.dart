import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void setCurrencyCode(String currencyCode) {
    if (currencyCode.trim().isEmpty) return;
    emit(state.copyWith(currencyCode: currencyCode.trim().toUpperCase()));
  }

  void setThemeMode(ThemeMode themeMode) {
    emit(state.copyWith(themeMode: themeMode));
  }

  void setDefaultRatePerKwh(double rate) {
    emit(state.copyWith(defaultRatePerKwh: rate < 0 ? 0 : rate));
  }
}
