import 'package:flutter/material.dart';

import '../../../data/models/billing_defaults.dart';

class SettingsState {
  SettingsState({
    String? currencyCode,
    this.themeMode = ThemeMode.light,
    double? defaultRatePerKwh,
    this.onboardingCompleted = false,
  }) : currencyCode =
           currencyCode ?? BillingDefaults.forCurrentLocale().currencyCode,
       defaultRatePerKwh =
           defaultRatePerKwh ?? BillingDefaults.forCurrentLocale().ratePerKwh;

  final String currencyCode;
  final ThemeMode themeMode;
  final double defaultRatePerKwh;
  final bool onboardingCompleted;

  SettingsState copyWith({
    String? currencyCode,
    ThemeMode? themeMode,
    double? defaultRatePerKwh,
    bool? onboardingCompleted,
  }) {
    return SettingsState(
      currencyCode: currencyCode ?? this.currencyCode,
      themeMode: themeMode ?? this.themeMode,
      defaultRatePerKwh: defaultRatePerKwh ?? this.defaultRatePerKwh,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
