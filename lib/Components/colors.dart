import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const brand = Color(0xFF33049F);
  static const brandVariant = Color(0xFF28037D);
  static const brandHighlight = Color(0xFFF0EAFF);
  static const brandMuted = Color(0xFFEDE9FE);
  
  // Base Colors
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF111827);
  static const textDisabled = Color(0xFF9CA3AF);
  static const textSecondary = Color(0xFF6B7280);
  static const background = Color(0xFFF9FAFB);
  static const transparent = Colors.transparent;
  
  // Patient Gender Specific
  static const genderMale = Color(0xFF2563eb);
  static const genderMaleContainer = Color(0xFFeff6ff);
  static const genderFemale = Color(0xFFdb2777);
  static const genderFemaleContainer = Color(0xFFfdf2f8);
  static const genderOther = Color(0xFF9333ea);
  static const genderOtherContainer = Color(0xFFfaf5ff);
  
  // Status & Analysis
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  
  // Analysis Pipeline & Steps
  static const stepSuccessBg = Color(0xFFECFDF5);
  static const stepSuccessBorder = Color(0xFFA7F3D0);
  static const stepSuccessText = Color(0xFF047857);
  
  // Red Flags / Urgent Concerns
  static const errorContainer = Color(0xFFFEF2F2);
  static const redFlagBorder = Color(0xFFFEE2E2);
  static const onErrorContainer = Color(0xFFB91C1C);
  
  // Warnings / Cautionary
  static const warningContainer = Color(0xFFFFFBEB);
  static const warningBorder = Color(0xFFFDE68A);
  static const onWarningContainer = Color(0xFFB45309);
  
  // Clinical Roles (Bubbles)
  static const bubblePatient = Color(0xFFE6FFFA);
  static const bubblePatientText = Color(0xFF319795);
  static const bubbleAttendee = Color(0xFFF7FAFC);
  static const bubbleAttendeeText = Color(0xFF4A5568);
  
  // UI Infrastructure
  static const outlineVariant = Color(0xFFE5E7EB);
  static const outline = Color(0xFFD1D5DB);
  static const divider = Color(0xFFF3F4F6);
  static const inverseSurface = Color(0xFF1F2937);

  // Animation & Visual Effects
  static const vizAccent1 = Color(0xFF4F46E5);
  static const vizAccent2 = Color(0xFF7C3AED);
  static const vizAccent3 = Color(0xFF06B6D4);

  // Feedback & Semantic Variants
  static const successContainer = Color(0xFFF0FDF4);
  static const successBorder = Color(0xFFDCFCE7);
  static const onSuccessContainer = Color(0xFF15803D);
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
  static const statusDiagnosed = Color(0xFF7c3aed);
  static const statusDiagnosedContainer = Color(0xFFf5f3ff);
  static const statusInProgress = Color(0xFFb45309);
  static const statusInProgressContainer = Color(0xFFfffbeb);
  static const statusFinalized = Color(0xFF047857);
  static const statusFinalizedContainer = Color(0xFFecfdf5);
  static const statusPrescribed = Color(0xFF0d9488);
  static const statusPrescribedContainer = Color(0xFFf0fdfa);
}

class AppDarkColors {
  // Brand Colors (unchanged, as requested)
  static const brand = AppColors.brand;
  static const brandDark = AppColors.brandVariant;
  static const brandContainer = Color(0xFF241B47);   // Tinted dark surface for brand accents
  static const brandMuted = Color(0xFF2E2456);

  // Structural Colors
  static const surface = Color(0xFF1A1730);          // Card/surface — warm dark slate, not flat black
  static const textPrimary = Color(0xFFEDEBF7);          // Primary text — soft off-white, faint purple tint
  static const textDisabled = Color(0xFF9691AD);           // Secondary text/icons
  static const textSecondary = Color(0xFFC7C3DA);        // Emphasized secondary text
  static const background = Color(0xFF12101F);       // Scaffold background — deep indigo-charcoal
  static const transparent = Colors.transparent;

  // Patient Gender Specific
  static const genderMale = Color(0xFF5B9AF0);
  static const genderMaleContainer = Color(0xFF19233D);
  static const genderFemale = Color(0xFFEC6FA3);
  static const genderFemaleContainer = Color(0xFF321D2C);
  static const genderOther = Color(0xFFB07AF0);
  static const genderOtherContainer = Color(0xFF2B1F42);

  // Status & Analysis
  static const success = Color(0xFF3ED9A0);
  static const error = Color(0xFFF16565);
  static const warning = Color(0xFFF5B84E);

  // Analysis Pipeline & Steps
  static const stepSuccessBg = Color(0xFF12312A);
  static const stepSuccessBorder = Color(0xFF1F5E4C);
  static const stepSuccessText = Color(0xFF7DEBC0);

  // Red Flags / Urgent Concerns
  static const errorContainer = Color(0xFF321818);
  static const redFlagBorder = Color(0xFF632B2B);
  static const onErrorContainer = Color(0xFFF9A8A8);

  // Warnings / Cautionary
  static const warningContainer = Color(0xFF332508);
  static const warningBorder = Color(0xFF624A16);
  static const onWarningContainer = Color(0xFFF7D383);

  // Clinical Roles (Bubbles)
  static const bubblePatient = Color(0xFF122E2C);
  static const bubblePatientText = Color(0xFF5FE0CE);
  static const bubbleAttendee = Color(0xFF201D33);
  static const bubbleAttendeeText = Color(0xFFB4AECB);

  // UI Infrastructure
  static const outlineVariant = Color(0xFF2C2745);
  static const outline = Color(0xFF433C63);
  static const divider = Color(0xFF221E38);
  static const inverseSurface = Color(0xFF0E0C1A);     // Deepest elevation (sheets, modals)

  // Animation & Visual Effects
  static const vizAccent1 = Color(0xFF8B87F5);
  static const vizAccent2 = Color(0xFFB08CF7);
  static const vizAccent3 = Color(0xFF4FD8EA);

  // Feedback & Semantic Variants
  static const successContainer = Color(0xFF122C21);
  static const successBorder = Color(0xFF20503C);
  static const onSuccessContainer = Color(0xFF7DEBC0);
  static const successIcon = Color(0xFF4ADE9C);

  // Additional Slate/Grey shades
  static const slate200 = Color(0xFF322D4C);
  static const slate500 = Color(0xFFA29CBC);
  static const slate700 = Color(0xFFDCD9EA);

  // Extra Brand colors
  static const blue600 = Color(0xFF5B9AF0);
  static const purple600 = Color(0xFFB08CF7);
  static const rose600 = Color(0xFFF06B92);
  static const amber800 = Color(0xFFF5B84E);

  // Avatar Palettes
  static const avatarBlueBg = Color(0xFF1B2846);
  static const avatarBlueText = Color(0xFF8FB8F7);
  static const avatarGreenBg = Color(0xFF12312A);
  static const avatarGreenText = Color(0xFF7DEBC0);
  static const avatarAmberBg = Color(0xFF332508);
  static const avatarAmberText = Color(0xFFF7D383);
  static const avatarPinkBg = Color(0xFF361D2A);
  static const avatarPinkText = Color(0xFFF6A8C0);

  // Legacy Status Colors
  static const statusDiagnosed = Color(0xFFB08CF7);
  static const statusDiagnosedContainer = Color(0xFF2A2150);
  static const statusInProgress = Color(0xFFF5B84E);
  static const statusInProgressContainer = Color(0xFF332508);
  static const statusFinalized = Color(0xFF3ED9A0);
  static const statusFinalizedContainer = Color(0xFF12312A);
  static const statusPrescribed = Color(0xFF3FDBC6);
  static const statusPrescribedContainer = Color(0xFF122E2C);
}
