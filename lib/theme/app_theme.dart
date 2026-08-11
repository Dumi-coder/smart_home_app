import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for the Smart Home app.
///
/// Design language: "Skyline" — a cool powder-blue base, deep navy ink,
/// and a single vivid azure accent that stands in for "live / on /
/// active" everywhere in the app (toggles, nav bar, glowing badges).
/// Every other accent is a muted, desaturated companion so azure always
/// reads as the signal color.
///
/// Note: some field names (brass/pine) are retained from an earlier
/// warm palette iteration for compatibility with the rest of the
/// codebase — the values below are the current blue theme.
class AppColors {
  AppColors._();

  // ── Core palette ──
  static const Color background = Color(0xFFEAF1F8); // Powder blue-white
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceSunk = Color(0xFFDCE7F1); // Recessed / track bg

  static const Color ink = Color(0xFF14202E); // Deep navy-black
  static const Color pine = Color(0xFF2C5C8A); // Brand steel blue
  static const Color pineDeep = Color(0xFF132436); // Nav / dark surfaces

  // ── Signal accent (the one "alive" color in the app) ──
  static const Color brass = Color(0xFF2E90E0); // Vivid azure
  static const Color brassDeep = Color(0xFF1D6FB8);
  static const Color brassPale = Color(0xFFD3E8FB);

  // Back-compat aliases used across widgets/screens.
  static const Color primaryActive = brass;
  static const Color primaryActiveDark = brassDeep;

  // ── Status colors ──
  static const Color statusOn = brass;
  static const Color statusOff = Color(0xFFB7C2CC);
  static const Color statusError = Color(0xFFB0462F);
  static const Color statusDisconnected = Color(0xFF8B96A3);

  // ── Accent per device type (muted, desaturated companions to azure) ──
  static const Color accentBulb = brass; // lighting shares the signal color
  static const Color accentIron = Color(0xFFB0462F); // warm clay red (alerts)
  static const Color accentCamera = Color(0xFF1E8F8F); // teal
  static const Color accentOutlet = Color(0xFF7FA88F); // sage neutral
  static const Color accentMultiswitch = Color(0xFF6E5A8C); // muted plum

  // ── Navigation bar ──
  static const Color navBarBackground = pineDeep;
  static const Color navBarActiveIcon = brass;
  static const Color navBarInactiveIcon = Color(0xFF7C8FA3);

  // ── Quick action card backgrounds ──
  static const Color quickActionLights = Color(0xFFD3E8FB); // pale azure
  static const Color quickActionTurnOff = Color(0xFFF0D9D2); // pale clay
  static const Color quickActionLock = Color(0xFFD7E3EA); // pale slate

  // ── Text ──
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF5B6B7C);
  static const Color textOnDark = Color(0xFFEAF2FA);

  // ── Misc ──
  static const Color chipSelected = ink;
  static const Color chipUnselected = surface;
  static const Color cardShadow = Color(0x1A0F1C2A);
  static const Color divider = Color(0xFFD7E2EC);

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

  static const double card = 20.0;
  static const double chip = 26.0;
  static const double button = 14.0;
  static const double bottomSheet = 26.0;
  static const double navBar = 28.0;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

/// Font roles:
///  - Display (Space Grotesk): greetings, big kWh/temperature numbers,
///    section headlines — carries the app's personality.
///  - Body (Manrope): everything else people read — titles, labels, copy.
///  - Mono (IBM Plex Mono): small data readouts, timestamps, units — used
///    sparingly for a "meter readout" feel.
class AppFonts {
  AppFonts._();

  static TextStyle display({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double? height,
  }) =>
      GoogleFonts.manrope(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );

  static TextStyle mono({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.textSecondary,
    double? letterSpacing = 0.2,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pine,
        primary: AppColors.pine,
        secondary: AppColors.brass,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      splashFactory: NoSplash.splashFactory,
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        headlineLarge: AppFonts.display(fontSize: 30, fontWeight: FontWeight.w700),
        headlineMedium: AppFonts.display(fontSize: 22, fontWeight: FontWeight.w600),
        titleLarge: AppFonts.body(fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: AppFonts.body(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: AppFonts.body(fontSize: 15, fontWeight: FontWeight.w500),
        bodyMedium: AppFonts.body(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        labelLarge: AppFonts.body(fontSize: 14, fontWeight: FontWeight.w700),
        labelSmall: AppFonts.mono(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.divider, width: 1),
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
        labelStyle: AppFonts.body(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppFonts.display(fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? AppColors.brass : AppColors.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
              ? AppColors.brass.withValues(alpha: 0.35)
              : AppColors.surfaceSunk,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}