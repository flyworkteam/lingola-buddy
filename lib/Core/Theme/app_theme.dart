import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingola_buddy/Core/Config/app_config.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final baseScheme = ColorScheme.fromSeed(seedColor: const Color(AppConfig.seedColorArgb));

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xffF2F5FC),
      colorScheme: baseScheme,
      textTheme: GoogleFonts.manropeTextTheme(GoogleFonts.nunitoSansTextTheme()),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xffF2F5FC),
        foregroundColor: baseScheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
