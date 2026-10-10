import 'package:flutter/material.dart';

class AppTheme {
  // Paleta Institucional FluvMed
  static const Color primaryTeal = Color(0xFF007A78);
  static const Color darkSlate = Color(0xFF0F1E2A);
  static const Color amberWarning = Color(0xFFD97706);
  static const Color backgroundLight = Color(0xFFF4F7F9);
  static const Color surfaceWhite = Colors.white;

  // Paleta de Alto Contraste (e-MAG / WCAG AAA)
  static const Color highContrastYellow = Color(0xFFFFD600);
  static const Color highContrastBlack = Colors.black;
  static const Color highContrastCard = Color(0xFF1E1E1E);

  static ThemeData buildTheme({required bool altoContraste, required double escalaFonte}) {
    if (altoContraste) {
      return ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: highContrastBlack,
        colorScheme: const ColorScheme.dark(
          primary: highContrastYellow,
          surface: highContrastCard,
          onPrimary: Colors.black,
          onSurface: Colors.white,
        ),
        textTheme: _buildScaledTextTheme(Colors.white, escalaFonte),
      );
    }

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkSlate,
      primaryColor: primaryTeal,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: amberWarning,
        surface: backgroundLight,
      ),
      textTheme: _buildScaledTextTheme(const Color(0xFF1E293B), escalaFonte),
    );
  }

  static TextTheme _buildScaledTextTheme(Color baseColor, double factor) {
    return TextTheme(
      titleLarge: TextStyle(
        fontSize: 20 * factor,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16 * factor,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16 * factor,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * factor,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12 * factor,
        color: baseColor.withOpacity(0.8),
      ),
    );
  }
}