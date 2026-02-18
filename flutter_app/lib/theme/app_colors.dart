import 'package:flutter/material.dart';

/// Color palette for Minber app - MUST match HTML prototype
class AppColors {
  AppColors._();

  // Gold colors
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFE8C97A);
  static const Color goldDark = Color(0xFF8B6914);

  // Emerald colors
  static const Color emerald = Color(0xFF1B5E3B);
  static const Color emeraldMid = Color(0xFF2D7A52);
  static const Color emeraldLight = Color(0xFF3FA069);

  // Cream colors
  static const Color cream = Color(0xFFF5EFE0);
  static const Color creamDark = Color(0xFFE8DFC8);

  // Dark colors
  static const Color dark = Color(0xFF0D1F14);
  static const Color darkMid = Color(0xFF142B1C);

  // Text colors
  static const Color textLight = Color(0xFFF0E8D5);
  static const Color textMuted = Color(0xFFA8C0A8);

  // Gradient colors
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
    colors: [emerald, darkMid, dark],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldLight, gold],
  );

  static const LinearGradient featuredCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emeraldMid, darkMid],
  );
}
