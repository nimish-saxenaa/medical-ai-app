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
  static const dividerLight = Color(0xFFF3F4F6);
  static const surfaceDark = Color(0xFF1F2937);

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
