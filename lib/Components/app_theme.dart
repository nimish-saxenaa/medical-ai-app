import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brand,
      secondary: AppColors.brand,
      surface: AppColors.surface,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: AppColors.background,

    textTheme: TextTheme(
      // Large Page Heading
      displayLarge: GoogleFonts.notoSerifJp(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      ),
      displayMedium: GoogleFonts.notoSerifJp(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      displaySmall: GoogleFonts.notoSerifJp(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.5,
      ),

      // Screen Heading
      headlineLarge: GoogleFonts.notoSerifJp(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.notoSerifJp(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textDisabled,
        height: 1.3,
      ),

      // Section Heading
      headlineMedium: GoogleFonts.notoSerifJp(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      ),

      // Card/Dialog Title
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      ),

      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      ),

      // Primary Body Text
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.5,

      ),

      // Secondary Body Text
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textDisabled,
        height: 1.5,
      ),

      // Small Caption
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textDisabled,
        height: 1.45,
      ),

      // Buttons
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.surface,
        letterSpacing: 0.2,
      ),

      // Chips / Tags
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.brand,
        letterSpacing: 0.2,
      ),

      // Tiny Labels
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textDisabled,
        letterSpacing: 0.3,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.surface,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        overlayColor: AppColors.surface.withAlpha(200),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brand,
        side: const BorderSide(color: AppColors.brand),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      hintStyle: TextStyle(color: AppColors.textDisabled),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.brand, width: 2),
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.brand,
      foregroundColor: AppColors.surface,
    ),

    dividerColor: AppColors.divider,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppDarkColors.brand,
      primary: AppDarkColors.brand,
      secondary: AppDarkColors.brand,
      surface: AppDarkColors.surface,
      brightness: Brightness.dark,
      onPrimary: AppDarkColors.textPrimary
    ),

    scaffoldBackgroundColor: AppDarkColors.background,

    textTheme: TextTheme(
      // Large Page Heading
      displayLarge: GoogleFonts.notoSerifJp(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppDarkColors.textPrimary,
        height: 1.25,
      ),
      displayMedium: GoogleFonts.notoSerifJp(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppDarkColors.textPrimary,
        height: 1.5,
      ),
      displaySmall: GoogleFonts.notoSerifJp(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppDarkColors.textPrimary,
        height: 1.5,
      ),

      // Screen Heading
      headlineLarge: GoogleFonts.notoSerifJp(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppDarkColors.textPrimary,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.notoSerifJp(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppDarkColors.textDisabled,
        height: 1.3,
      ),

      // Section Heading
      headlineMedium: GoogleFonts.notoSerifJp(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppDarkColors.textPrimary,
        height: 1.35,
      ),

      // Card/Dialog Title
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppDarkColors.textPrimary,
        height: 1.4,
      ),

      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppDarkColors.textPrimary,
        height: 1.4,
      ),

      // Primary Body Text
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppDarkColors.textPrimary,
        height: 1.5,
      ),

      // Secondary Body Text
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppDarkColors.textDisabled,
        height: 1.5,
      ),

      // Small Caption
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppDarkColors.textDisabled,
        height: 1.45,
      ),

      // Buttons
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppDarkColors.textPrimary,
        letterSpacing: 0.2,
      ),

      // Chips / Tags
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppDarkColors.brand,
        letterSpacing: 0.2,
      ),

      // Tiny Labels
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppDarkColors.textDisabled,
        letterSpacing: 0.3,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppDarkColors.background,
      foregroundColor: AppDarkColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppDarkColors.brand,
        foregroundColor: AppDarkColors.textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        overlayColor: AppDarkColors.textPrimary.withAlpha(200),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppDarkColors.brand,
        side: const BorderSide(color: AppDarkColors.brand),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppDarkColors.outlineVariant,
      hintStyle: TextStyle(color: AppDarkColors.textDisabled),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppDarkColors.brand, width: 2),
      ),
    ),

    cardTheme: CardThemeData(
      color: AppDarkColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppDarkColors.brand,
      foregroundColor: AppDarkColors.textPrimary,
    ),

    dividerColor: AppDarkColors.divider,
  );
}
