// lib/theme/app_theme.dart
// GoalKeeper design system — colors, fonts, component styles

import 'package:flutter/material.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────

class AppColors {
  // Backgrounds
  static const Color background     = Color(0xFF0D0D12);
  static const Color sidebarBg      = Color(0xFF111118);
  static const Color cardBg         = Color(0x0FFFFFFF);  // white 6%
  static const Color cardBgStrong   = Color(0x1AFFFFFF);  // white 10%
  static const Color divider        = Color(0x14FFFFFF);  // white 8%

  // Text
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFF8E8EA0);
  static const Color textTertiary   = Color(0xFF5A5A72);
  static const Color textDisabled   = Color(0xFF3A3A50);

  // Accent — teal (primary brand color)
  static const Color accent         = Color(0xFF4ECDC4);
  static const Color accentGreen    = Color(0xFF2ECC71);

  // Goal type colors
  static const Color assignment     = Color(0xFFFF6B6B);
  static const Color project        = Color(0xFF4ECDC4);
  static const Color personalGoal   = Color(0xFFFFE66D);
  static const Color habit          = Color(0xFFA8E6CF);
  static const Color examPrep       = Color(0xFFC3B1E1);
  static const Color creative       = Color(0xFFFFB347);

  // Schedule item colors
  static const Color homework       = Color(0xFF4ECDC4);
  static const Color test           = Color(0xFFFF6B6B);
  static const Color quiz           = Color(0xFFFFB347);
  static const Color reading        = Color(0xFFA8E6CF);

  // Status
  static const Color danger         = Color(0xFFFF453A);
  static const Color warning        = Color(0xFFFF9F0A);
  static const Color success        = Color(0xFF32D74B);

  // Calendar event colors
  static const Color eventBlue      = Color(0xFF4A90E2);
  static const Color eventRed       = Color(0xFFFF6B6B);
  static const Color eventGreen     = Color(0xFF4ECDC4);
  static const Color eventOrange    = Color(0xFFFFB347);
  static const Color eventPurple    = Color(0xFFC3B1E1);
  static const Color eventTeal      = Color(0xFFA8E6CF);
}

// ─── Typography ───────────────────────────────────────────────────────────────

class AppText {
  static const String displayFont = 'Geist';
  static const String bodyFont    = 'DMSans';

  // Display / headings — Geist
  static TextStyle display(double size, {FontWeight weight = FontWeight.w700, Color color = AppColors.textPrimary}) =>
      TextStyle(fontFamily: displayFont, fontSize: size, fontWeight: weight, color: color);

  // Body / labels — DM Sans
  static TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color color = AppColors.textPrimary}) =>
      TextStyle(fontFamily: bodyFont, fontSize: size, fontWeight: weight, color: color);

  // Monospaced numbers (countdown)
  static TextStyle mono(double size, {FontWeight weight = FontWeight.w700, Color color = AppColors.textPrimary}) =>
      TextStyle(fontFamily: displayFont, fontSize: size, fontWeight: weight, color: color,
                fontFeatures: [const FontFeature.tabularFigures()]);

  // Label caps
  static TextStyle label(double size, {Color color = AppColors.textTertiary}) =>
      TextStyle(fontFamily: bodyFont, fontSize: size, fontWeight: FontWeight.w600,
                color: color, letterSpacing: 0.8);
}

// ─── Spacing ──────────────────────────────────────────────────────────────────

class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 28;
}

// ─── Radius ───────────────────────────────────────────────────────────────────

class AppRadius {
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
}

// ─── ThemeData ────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppText.bodyFont,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.accent,
        secondary: AppColors.accentGreen,
        surface:   AppColors.sidebarBg,
        error:     AppColors.danger,
      ),
      dividerColor: AppColors.divider,
      textTheme: TextTheme(
        displayLarge:  AppText.display(32),
        displayMedium: AppText.display(24),
        displaySmall:  AppText.display(20),
        titleLarge:    AppText.display(18, weight: FontWeight.w700),
        titleMedium:   AppText.display(15, weight: FontWeight.w600),
        titleSmall:    AppText.display(13, weight: FontWeight.w600),
        bodyLarge:     AppText.body(14),
        bodyMedium:    AppText.body(13),
        bodySmall:     AppText.body(12),
        labelLarge:    AppText.body(12, weight: FontWeight.w600),
        labelMedium:   AppText.body(11, weight: FontWeight.w500),
        labelSmall:    AppText.label(10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        hintStyle: AppText.body(13, color: AppColors.textDisabled),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          textStyle: AppText.body(13, weight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppText.body(13),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.accent : AppColors.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.accent.withOpacity(0.4)
                : Colors.white.withOpacity(0.1)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.accent : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

// ─── Reusable card decoration ─────────────────────────────────────────────────

BoxDecoration cardDecoration({Color? borderColor, double opacity = 0.06}) => BoxDecoration(
  color: Colors.white.withOpacity(opacity),
  borderRadius: BorderRadius.circular(AppRadius.md),
  border: Border.all(
    color: borderColor ?? Colors.white.withOpacity(0.08),
    width: 1,
  ),
);
