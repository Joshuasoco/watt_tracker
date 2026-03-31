import 'package:flutter/material.dart';

class SettingsState {
  const SettingsState({
    this.currencyCode = 'PHP',
    this.themeMode = ThemeMode.light,
    this.defaultRatePerKwh = 12,
  });

  final String currencyCode;
  final ThemeMode themeMode;
  final double defaultRatePerKwh;

  SettingsState copyWith({
    String? currencyCode,
    ThemeMode? themeMode,
    double? defaultRatePerKwh,
  }) {
    return SettingsState(
      currencyCode: currencyCode ?? this.currencyCode,
      themeMode: themeMode ?? this.themeMode,
      defaultRatePerKwh: defaultRatePerKwh ?? this.defaultRatePerKwh,
    );
  }
}
