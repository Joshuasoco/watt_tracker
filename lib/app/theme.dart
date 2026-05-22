import 'package:flutter/material.dart';

class AppTheme {
  static const Color _ink = Color(0xFF111111);
  static const Color _softInk = Color(0xFF2A2A2A);
  static const Color _paper = Color(0xFFF7F7F5);
  static const Color _mist = Color(0xFFE9E9E6);
  static const Color _line = Color(0xFFD8D8D4);

  static ThemeData get light {
    final scheme = const ColorScheme.light(
      primary: _ink,
      secondary: _softInk,
      tertiary: _softInk,
      surface: Colors.white,
      onSurface: _ink,
      onPrimary: Colors.white,
      outline: _line,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _paper,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _ink,
        height: 1.05,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _ink,
        height: 1.05,
      ),
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: _softInk,
        height: 1.45,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: _softInk.withValues(alpha: 0.88),
        height: 1.4,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        color: _ink,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: _line),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: _mist,
        selectedColor: _mist,
        side: const BorderSide(color: _line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: _ink,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          side: const BorderSide(color: _line),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _ink, width: 1.4),
        ),
        labelStyle: textTheme.bodyMedium,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _ink,
        linearTrackColor: _mist,
        circularTrackColor: _mist,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerColor: _line,
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      switchTheme: const SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(Colors.white),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Color(0xFFE6E6E6),
        tertiary: Color(0xFFE6E6E6),
      ),
    );
  }
}
