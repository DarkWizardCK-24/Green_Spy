import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryGreen = Color(0xFF00FF88);
  static const Color secondaryGreen = Color(0xFF00CC6F);
  static const Color accentGreen = Color(0xFF00FF9D);

  // Background Colors
  static const Color darkBackground = Color(0xFF0A0E27);
  static const Color cardBackground = Color(0xFF151B3D);
  static const Color inputBackground = Color(0xFF1A2147);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8D4);
  static const Color textMuted = Color(0xFF6B7280);

  // Accent Colors
  static const Color errorRed = Color(0xFFFF4757);
  static const Color warningYellow = Color(0xFFFFA502);
  static const Color infoBlue = Color(0xFF3742FA);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, secondaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [cardBackground, inputBackground],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow
  static BoxShadow get glowShadow => BoxShadow(
    color: primaryGreen.withOpacity(0.3),
    blurRadius: 20,
    spreadRadius: 2,
  );

  static BoxShadow get cardShadow => BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 15,
    offset: const Offset(0, 5),
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryGreen,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryGreen,
        secondary: AppColors.secondaryGreen,
        surface: AppColors.cardBackground,
        error: AppColors.errorRed,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
