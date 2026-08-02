import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for the Smart Home app.
/// Based on the Figma UI spec (Section 1 of implementation_requirements.txt).
class AppColors {
  AppColors._();

  // ── Core palette ──
  static const Color background = Color(0xFFF5F5F0); // Soft cream
  static const Color surface = Colors.white;
  static const Color primaryActive = Color(0xFFD4E157); // Lime green
  static const Color primaryActiveDark = Color(0xFFC0CA33);

  // ── Status colors ──
  static const Color statusOn = Color(0xFFD4E157);
  static const Color statusOff = Color(0xFFBDBDBD);
  static const Color statusError = Color(0xFFEF5350);
  static const Color statusDisconnected = Color(0xFF9E9E9E);

  // ── Accent per device type ──
  static const Color accentBulb = Color(0xFFFFF176); // Soft yellow
  static const Color accentIron = Color(0xFFEF9A9A); // Soft red
  static const Color accentCamera = Color(0xFF90CAF9); // Calm blue
  static const Color accentOutlet = Color(0xFFE0E0E0); // Neutral
  static const Color accentMultiswitch = Color(0xFFCE93D8); // Soft purple

  // ── Navigation bar ──
  static const Color navBarBackground = Color(0xFF1E1E1E);
  static const Color navBarActiveIcon = Color(0xFFD4E157);
  static const Color navBarInactiveIcon = Color(0xFF757575);

  // ── Quick action card backgrounds ──
  static const Color quickActionLights = Color(0xFFFFF9C4); // Pale yellow
  static const Color quickActionTurnOff = Color(0xFFFFCDD2); // Pale red
  static const Color quickActionLock = Color(0xFFBBDEFB); // Pale blue

  // ── Text ──
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnDark = Color(0xFFF5F5F5);

  // ── Misc ──
  static const Color chipSelected = Color(0xFF212121);
  static const Color chipUnselected = Color(0xFFF5F5F0);
  static const Color cardShadow = Color(0x14000000);
  static const Color divider = Color(0xFFE0E0E0);

  /// Returns the accent color for a given DeviceStatus string.
  static Color colorForStatus(String status) {
    switch (status) {
      case 'ON':
        return statusOn;
      case 'OFF':
        return statusOff;
      case 'ERROR':
        return statusError;
      case 'DISCONNECTED':
        return statusDisconnected;
      default:
        return statusOff;
    }
  }
}

class AppRadius {
  AppRadius._();

  static const double card = 24.0;
  static const double chip = 30.0;
  static const double button = 16.0;
  static const double bottomSheet = 28.0;
  static const double navBar = 30.0;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryActive,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipUnselected,
        selectedColor: AppColors.chipSelected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }
}
