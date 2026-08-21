import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.primary,
      surface: AppColors.white,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: AppColors.greyLight,

    textTheme: TextTheme(
      // Large Page Heading
      displayLarge: GoogleFonts.notoSerifJp(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
        height: 1.25,
      ),
      displayMedium: GoogleFonts.notoSerifJp(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
        height: 1.5,
      ),
      displaySmall: GoogleFonts.notoSerifJp(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
        height: 1.5,
      ),

      // Screen Heading
      headlineLarge: GoogleFonts.notoSerifJp(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.notoSerifJp(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.grey,
        height: 1.3,
      ),

      // Section Heading
      headlineMedium: GoogleFonts.notoSerifJp(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
        height: 1.35,
      ),

      // Card/Dialog Title
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
        height: 1.4,
      ),

      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
        height: 1.4,
      ),

      // Primary Body Text
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.black,
        height: 1.5,

      ),

      // Secondary Body Text
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.grey,
        height: 1.5,
      ),

      // Small Caption
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.grey,
        height: 1.45,
      ),

      // Buttons
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
        letterSpacing: 0.2,
      ),

      // Chips / Tags
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0.2,
      ),

      // Tiny Labels
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.grey,
        letterSpacing: 0.3,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      elevation: 0,
      centerTitle: false,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        overlayColor: AppColors.white.withAlpha(200),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.greyLight,
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
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
    ),

    dividerColor: AppColors.dividerLight,
  );
}
