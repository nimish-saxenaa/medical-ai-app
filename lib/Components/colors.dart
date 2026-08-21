import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const primary = Color(0xFF33049F);
  static const primaryDark = Color(0xFF28037D);
  static const primaryLight = Color(0xFFF0EAFF);
  static const primaryMuted = Color(0xFFEDE9FE);
  
  // Base Colors
  static const white = Colors.white;
  static const black = Color(0xFF111827);
  static const grey = Color(0xFF9CA3AF);
  static const greyDark = Color(0xFF6B7280);
  static const greyLight = Color(0xFFF9FAFB);
  static const transparent = Colors.transparent;
  
  // Patient Gender Specific
  static const primaryMale = Color(0xFF2563eb);
  static const secondaryMale = Color(0xFFeff6ff);
  static const primaryFemale = Color(0xFFdb2777);
  static const secondaryFemale = Color(0xFFfdf2f8);
  static const primaryOther = Color(0xFF9333ea);
  static const secondaryOther = Color(0xFFfaf5ff);
  
  // Status & Analysis
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  
  // Analysis Pipeline & Steps
  static const stepSuccessBg = Color(0xFFECFDF5);
  static const stepSuccessBorder = Color(0xFFA7F3D0);
  static const stepSuccessText = Color(0xFF047857);
  
  // Red Flags / Urgent Concerns
  static const redFlagBg = Color(0xFFFEF2F2);
  static const redFlagBorder = Color(0xFFFEE2E2);
  static const redFlagText = Color(0xFFB91C1C);
  
  // Warnings / Cautionary
  static const warningBg = Color(0xFFFFFBEB);
  static const warningBorder = Color(0xFFFDE68A);
  static const warningText = Color(0xFFB45309);
  
  // Clinical Roles (Bubbles)
  static const patientBg = Color(0xFFE6FFFA);
  static const patientAccent = Color(0xFF319795);
  static const attendeeBg = Color(0xFFF7FAFC);
  static const attendeeAccent = Color(0xFF4A5568);
  
  // UI Infrastructure
  static const borderLight = Color(0xFFE5E7EB);
  static const borderMedium = Color(0xFFD1D5DB);
  static const dividerLight = Color(0xFFF3F4F6);
  static const surfaceDark = Color(0xFF1F2937);

  // Animation & Visual Effects
  static const waveformIndigo = Color(0xFF4F46E5);
  static const waveformPurple = Color(0xFF7C3AED);
  static const waveformCyan = Color(0xFF06B6D4);

  // Feedback & Semantic Variants
  static const successContainer = Color(0xFFF0FDF4);
  static const successBorder = Color(0xFFDCFCE7);
  static const successText = Color(0xFF15803D);
  static const successIcon = Color(0xFF34D399);

  // Additional Slate/Grey shades
  static const slate200 = Color(0xFFE2E8F0);
  static const slate500 = Color(0xFF64748B);
  static const slate700 = Color(0xFF374151);

  // Extra Brand colors
  static const blue600 = Color(0xFF2563EB);
  static const purple600 = Color(0xFF7C3AED);
  static const rose600 = Color(0xFFE11D48);
  static const amber800 = Color(0xFF92400E);

  // Avatar Palettes
  static const avatarBlueBg = Color(0xFFDBEAFE);
  static const avatarBlueText = Color(0xFF1D4ED8);
  static const avatarGreenBg = Color(0xFFD1FAE5);
  static const avatarGreenText = Color(0xFF047857);
  static const avatarAmberBg = Color(0xFFFEF3C7);
  static const avatarAmberText = Color(0xFF92400E);
  static const avatarPinkBg = Color(0xFFFFE4E6);
  static const avatarPinkText = Color(0xFFBE123C);

  // Legacy Status Colors (Synced)
  static const diagnosedPrimary = Color(0xFF7c3aed);
  static const diagnosedLight = Color(0xFFf5f3ff);
  static const progressPrimary = Color(0xFFb45309);
  static const progressLight = Color(0xFFfffbeb);
  static const finalizedPrimary = Color(0xFF047857);
  static const finalizedLight = Color(0xFFecfdf5);
  static const prescribedPrimary = Color(0xFF0d9488);
  static const prescribedLight = Color(0xFFf0fdfa);
}

class AppDarkColors {
  // Brand Colors (Identical to Light Theme)
  static const primary = AppColors.primary;
  static const primaryDark = AppColors.primaryDark;
  static const primaryLight = Color(0xFF1F1A3D); // Deeper variant for backgrounds
  static const primaryMuted = Color(0xFF2D264D);

  // Structural Colors (Inverted/Darkened)
  static const white = Color(0xFF111827);     // Becomes dark surface
  static const black = Colors.white;          // Becomes light text
  static const grey = Color(0xFF9CA3AF);
  static const greyDark = Color(0xFFD1D5DB);  // Lighter grey for dark mode readability
  static const greyLight = Color(0xFF000000); // Scaffold background
  static const transparent = Colors.transparent;

  // Status & Analysis (Keep the same vibrant icons/borders)
  static const success = AppColors.success;
  static const error = AppColors.error;
  static const warning = AppColors.warning;

  // Analysis Pipeline & Steps (Dark variants)
  static const stepSuccessBg = Color(0xFF064E3B);
  static const stepSuccessBorder = Color(0xFF065F46);
  static const stepSuccessText = Color(0xFFD1FAE5);

  // Red Flags / Urgent Concerns (Dark variants)
  static const redFlagBg = Color(0xFF450A0A);
  static const redFlagBorder = Color(0xFF7F1D1D);
  static const redFlagText = Color(0xFFFECACA);

  // Warnings / Cautionary (Dark variants)
  static const warningBg = Color(0xFF451A03);
  static const warningBorder = Color(0xFF78350F);
  static const warningText = Color(0xFFFDE68A);

  // Clinical Roles (Bubbles - adjusted for dark mode)
  static const patientBg = Color(0xFF0D2E2E);
  static const patientAccent = Color(0xFF4FD1C5);
  static const attendeeBg = Color(0xFF1A202C);
  static const attendeeAccent = Color(0xFFA0AEC0);

  // UI Infrastructure
  static const borderLight = Color(0xFF1F2937);
  static const borderMedium = Color(0xFF374151);
  static const dividerLight = Color(0xFF1F2937);
  static const surfaceDark = Color(0xFF0F172A);

  // Legacy Status Colors (Synced)
  static const diagnosedPrimary = AppColors.diagnosedPrimary;
  static const diagnosedLight = Color(0xFF2D264D);
  static const progressPrimary = AppColors.progressPrimary;
  static const progressLight = Color(0xFF451A03);
  static const finalizedPrimary = AppColors.finalizedPrimary;
  static const finalizedLight = Color(0xFF064E3B);
  static const prescribedPrimary = AppColors.prescribedPrimary;
  static const prescribedLight = Color(0xFF0D2E2E);
}
