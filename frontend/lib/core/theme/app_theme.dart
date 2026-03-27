import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme() {
  final baseBody = GoogleFonts.manropeTextTheme();

  return ThemeData.dark(useMaterial3: true).copyWith(
    scaffoldBackgroundColor: const Color(0xFF070707),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF5E39B),
      secondary: Color(0xFFE7E7E7),
      surface: Color(0xFF111111),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      error: Color(0xFFE8B4B4),
      onError: Colors.black,
    ),
    textTheme: baseBody.copyWith(
      displayLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 48,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
      displayMedium: GoogleFonts.dmSerifDisplay(
        fontSize: 36,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
      headlineLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 28,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.6,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1.0,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        color: Colors.white,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        color: Colors.white,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 12,
        color: Colors.white70,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: Colors.white,
      ),
    ),
    dividerColor: Colors.white12,
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.05),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(28),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      labelStyle: GoogleFonts.manrope(color: Colors.white70),
      hintStyle: GoogleFonts.manrope(color: Colors.white38),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF5E39B), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE8B4B4)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE8B4B4), width: 1.2),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF151515),
      contentTextStyle: GoogleFonts.manrope(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.white12,
      thickness: 1,
    ),
  );
}
