import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme() {
  const background = Color(0xFFF2F4F7);
  const surface = Color(0xFFFFFFFF);
  const primary = Color(0xFF121316);
  const accent = Color(0xFFDDF0A7);
  const textPrimary = Color(0xFF121316);
  const textSecondary = Color(0xFF6F7480);
  const divider = Color(0xFFE8EBF1);
  const border = Color(0xFFE3E6EC);

  final colorScheme = const ColorScheme.light(
    primary: primary,
    onPrimary: Colors.white,
    secondary: textSecondary,
    onSecondary: Colors.white,
    surface: surface,
    onSurface: textPrimary,
    error: primary,
    onError: Colors.white,
  ).copyWith(
    outline: border,
    outlineVariant: divider,
    onSurfaceVariant: textSecondary,
    surfaceContainerHighest: surface,
    secondaryContainer: accent,
  );

  final base = GoogleFonts.montserratTextTheme();

  final textTheme = base.copyWith(
    displayLarge: GoogleFonts.montserrat(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      height: 1.02,
      letterSpacing: -0.8,
    ),
    displayMedium: GoogleFonts.montserrat(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      height: 1.04,
      letterSpacing: -0.5,
    ),
    headlineLarge: GoogleFonts.montserrat(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      height: 1.14,
      letterSpacing: -0.2,
    ),
    headlineSmall: GoogleFonts.montserrat(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.18,
      letterSpacing: -0.2,
    ),
    titleLarge: GoogleFonts.montserrat(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.3,
    ),
    titleMedium: GoogleFonts.montserrat(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      height: 1.2,
      letterSpacing: 1.8,
    ),
    bodyLarge: GoogleFonts.montserrat(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.montserrat(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: textSecondary,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.montserrat(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: textSecondary,
      height: 1.45,
    ),
    labelLarge: GoogleFonts.montserrat(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      height: 1.2,
      letterSpacing: 1.6,
    ),
  );

  return ThemeData.light(useMaterial3: false).copyWith(
    scaffoldBackgroundColor: background,
    colorScheme: colorScheme,
    textTheme: textTheme,
    dividerColor: divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: border),
        borderRadius: BorderRadius.circular(28),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textPrimary,
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium,
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(color: primary),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(color: primary),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(color: primary),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primary,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(
      color: divider,
      thickness: 1,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: background,
      headerForegroundColor: Colors.white,
      headerBackgroundColor: primary,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return Colors.transparent;
      }),
    ),
  );
}
