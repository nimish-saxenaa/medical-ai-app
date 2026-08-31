import 'package:flutter/material.dart';

class AppLayout {
  // --- Spacing (Padding/Margin) ---
  // Using an 8-point grid system for consistency
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;

  // Semantic Spacing
  static const double screenPaddingMobile = space16;
  static const double screenPaddingTablet = space24;
  static const double cardPadding = space16;
  static const double elementGap = space12;

  // --- Border Radii ---
  static const double radius8 = 8.0;
  static const double radius10 = 10.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radiusCircular = 100.0;

  // Semantic Radii
  static const double cardRadius = radius16;
  static const double inputRadius = radius16;
  static const double buttonRadius = radius12;
  static const double panelRadius = radius24;

  // --- Border Widths ---
  static const double borderThin = 0.5;
  static const double borderMedium = 1.0;
  static const double borderThick = 2.0;

  // --- Icon Sizes ---
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconExtraLarge = 32.0;

  // --- Common Insets ---
  static const EdgeInsets screenPadding = EdgeInsets.all(screenPaddingMobile);
  static const EdgeInsets screenPaddingTab = EdgeInsets.all(screenPaddingTablet);
}
