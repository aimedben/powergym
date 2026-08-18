import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
// POWERGYM SPORT DESIGN SYSTEM
// Modern sporty theme: condensed bold typography, electric accents,
// gradient buttons with glow, dark cinematic backgrounds.
// ═══════════════════════════════════════════════════════════════════

class SportColors {
  // Dark palette
  static const Color bgDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF121826);
  static const Color cardDark = Color(0xFF1A2132);

  // Light palette
  static const Color bgLight = Color(0xFFF6F8FC);
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Colors.white;

  // Brand accents
  static const Color primary = Color(0xFF2563EB); // Electric blue
  static const Color primaryBright = Color(0xFF3B82F6);
  static const Color cyan = Color(0xFF06B6D4); // Electric cyan
  static const Color lime = Color(0xFF84CC16); // Energy lime
  static const Color green = Color(0xFF10B981); // Success
  static const Color amber = Color(0xFFF59E0B); // Warning
  static const Color red = Color(0xFFEF4444); // Danger
  static const Color violet = Color(0xFF8B5CF6); // Accent
  static const Color pink = Color(0xFFEC4899); // Female accent
  static const Color orange = Color(0xFFF97316); // CTA energy

  // Text colors
  static const Color textDark = Colors.white;
  static const Color textDarkMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFF0F172A);
  static const Color textLightMuted = Color(0xFF64748B);
}

/// Sporty condensed font families (Android system fonts, no download needed)
class SportFonts {
  static const String condensed = 'sans-serif-condensed';
  static const String black = 'sans-serif-black';
  static const String medium = 'sans-serif-medium';
}

/// Gradient for primary sport buttons
const LinearGradient sportPrimaryGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
);

/// Gradient for danger/energy actions
const LinearGradient sportDangerGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFFEF4444), Color(0xFFF97316)],
);

/// Gradient for success actions
const LinearGradient sportSuccessGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF10B981), Color(0xFF84CC16)],
);

/// Build the full sport TextTheme for a given brightness
TextTheme sportTextTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final Color title = isDark ? SportColors.textDark : SportColors.textLight;
  final Color body = isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF334155);
  final Color muted = isDark ? SportColors.textDarkMuted : SportColors.textLightMuted;

  return TextTheme(
    // Display / Hero
    displayLarge: TextStyle(
      fontFamily: SportFonts.black,
      fontSize: 40,
      fontWeight: FontWeight.w900,
      color: title,
      letterSpacing: -1.5,
      height: 1.05,
    ),
    displayMedium: TextStyle(
      fontFamily: SportFonts.black,
      fontSize: 32,
      fontWeight: FontWeight.w900,
      color: title,
      letterSpacing: -1,
      height: 1.1,
    ),
    displaySmall: TextStyle(
      fontFamily: SportFonts.black,
      fontSize: 26,
      fontWeight: FontWeight.w900,
      color: title,
      letterSpacing: -0.5,
      height: 1.15,
    ),
    // Headlines
    headlineLarge: TextStyle(
      fontFamily: SportFonts.black,
      fontSize: 26,
      fontWeight: FontWeight.w900,
      color: title,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontFamily: SportFonts.condensed,
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: title,
      letterSpacing: -0.3,
    ),
    headlineSmall: TextStyle(
      fontFamily: SportFonts.condensed,
      fontSize: 19,
      fontWeight: FontWeight.w800,
      color: title,
      letterSpacing: -0.2,
    ),
    // Titles
    titleLarge: TextStyle(
      fontFamily: SportFonts.condensed,
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: title,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      fontFamily: SportFonts.condensed,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: title,
    ),
    titleSmall: TextStyle(
      fontFamily: SportFonts.medium,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: title,
    ),
    // Body
    bodyLarge: TextStyle(fontSize: 16, color: body, height: 1.4),
    bodyMedium: TextStyle(fontSize: 14, color: body, height: 1.4),
    bodySmall: TextStyle(fontSize: 12, color: muted, height: 1.35),
    // Labels
    labelLarge: const TextStyle(
      fontFamily: SportFonts.condensed,
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    ),
    labelMedium: const TextStyle(
      fontFamily: SportFonts.medium,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    ),
    labelSmall: const TextStyle(
      fontFamily: SportFonts.medium,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    ),
  );
}
