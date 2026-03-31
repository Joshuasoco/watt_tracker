import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A7E8C)),
      scaffoldBackgroundColor: const Color(0xFFF5F7F8),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0A7E8C),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
