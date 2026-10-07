import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized design system for Wayv.
///
/// Uses Google Fonts "Montserrat" for a modern, premium feel.
/// Brand palette: Gold (#E2B05D) primary + Navy (#033189) secondary.
class AppTheme {
  AppTheme._(); // prevent instantiation

  // ──────────────────────────── Brand colours ────────────────────────────

  static const Color _gold = Color(0xFFE2B05D);        // primary
  static const Color _navy = Color(0xFF033189);         // secondary
  static const Color _goldLight = Color(0xFFF0CC85);    // lighter gold
  static const Color _navyLight = Color(0xFF1A4CAD);    // lighter navy
  static const Color _surfaceDark = Color(0xFF0E0E12);
  static const Color _cardDark = Color(0xFF1A1A24);
  static const Color _surfaceLight = Color(0xFFF8F7F4);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _error = Color(0xFFD94040);
  static const Color _success = Color(0xFF2EAF6A);

  // ──────────────────────────── Typography ────────────────────────────

  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.montserratTextTheme(base);
  }

  // ──────────────────────────── Light Theme ────────────────────────────

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _surfaceLight,
    textTheme: _buildTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: _surfaceLight,
      foregroundColor: _navy,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: _navy,
      ),
    ),
    cardTheme: CardThemeData(
      color: _cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2F0EC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _gold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.w500,
        color: const Color(0xFF555555),
      ),
      hintStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.w400,
        color: const Color(0xFF999999),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _gold,
        foregroundColor: _navy,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        textStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _navy,
        side: const BorderSide(color: _gold, width: 1.5),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _gold,
      foregroundColor: _navy,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _gold.withValues(alpha: 0.10),
      labelStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _navy,
      contentTextStyle: GoogleFonts.montserrat(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
    colorScheme: ColorScheme.light(
      primary: _gold,
      onPrimary: _navy,
      secondary: _navy,
      onSecondary: Colors.white,
      tertiary: _success,
      surface: _surfaceLight,
      error: _error,
    ),
  );

  // ──────────────────────────── Dark Theme ────────────────────────────

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _surfaceDark,
    textTheme: _buildTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: _surfaceDark,
      foregroundColor: _goldLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: _goldLight,
      ),
    ),
    cardTheme: CardThemeData(
      color: _cardDark,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF222230),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _gold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.w500,
        color: const Color(0xFF999999),
      ),
      hintStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.w400,
        color: const Color(0xFF666666),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _gold,
        foregroundColor: _navy,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        textStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _goldLight,
        side: const BorderSide(color: _gold, width: 1.5),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _gold,
      foregroundColor: _navy,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _gold.withValues(alpha: 0.12),
      labelStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _navyLight,
      contentTextStyle: GoogleFonts.montserrat(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
    colorScheme: ColorScheme.dark(
      primary: _gold,
      onPrimary: _navy,
      secondary: _navy,
      onSecondary: _goldLight,
      tertiary: _success,
      surface: _surfaceDark,
      error: _error,
    ),
  );
}
