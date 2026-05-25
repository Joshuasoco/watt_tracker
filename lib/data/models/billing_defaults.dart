import 'dart:ui';

class BillingDefaults {
  const BillingDefaults({
    required this.currencyCode,
    required this.currencySymbol,
    required this.ratePerKwh,
  });

  final String currencyCode;
  final String currencySymbol;
  final double ratePerKwh;

  factory BillingDefaults.forCurrentLocale() {
    final locale = PlatformDispatcher.instance.locale;
    return BillingDefaults.forCountryCode(locale.countryCode);
  }

  factory BillingDefaults.forCountryCode(String? countryCode) {
    switch ((countryCode ?? '').toUpperCase()) {
      case 'PH':
        return const BillingDefaults(
          currencyCode: 'PHP',
          currencySymbol: '\u20B1',
          ratePerKwh: 12,
        );
      case 'US':
        return const BillingDefaults(
          currencyCode: 'USD',
          currencySymbol: r'$',
          ratePerKwh: 0.17,
        );
      default:
        return const BillingDefaults(
          currencyCode: 'USD',
          currencySymbol: r'$',
          ratePerKwh: 0,
        );
    }
  }
}
