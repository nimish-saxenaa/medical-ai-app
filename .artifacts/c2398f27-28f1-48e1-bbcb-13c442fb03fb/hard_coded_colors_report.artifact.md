# Hard-Coded Colors Report

This document identifies all occurrences of hard-coded colors in the project, categorized by their type and impact on theme maintenance.

## Summary

The project contains **670+** instances of colors that are not derived from the application theme via `Theme.of(context)`.

### Key Findings
- **High Risk**: Direct Hex literals like `Color(0xFF...)` are scattered throughout the UI components.
- **Medium Risk**: Extensive use of `Colors.white`, `Colors.black`, and `Colors.red` instead of using the `AppColors` palette or theme-derived colors.
- **Architecture**: `AppColors` is used directly in many widgets, which prevents easy implementation of Dark Mode or alternative themes.

---

## 1. Direct Hex Literals (`Color(0x...)`)
These are the most rigid form of hard-coding and should ideally be moved to `AppColors` or replaced with theme-based colors.

| File | Line | Code Snippet |
| :--- | :--- | :--- |
| `lib/Custom Widgets/Consultation/custom_diagnosis_widgets.dart` | 77 | `_isHigh ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4)` |
| `lib/Custom Widgets/Consultation/custom_diagnosis_widgets.dart` | 80 | `_isHigh ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7)` |
| `lib/Custom Widgets/Consultation/custom_diagnosis_widgets.dart` | 83 | `_isHigh ? const Color(0xFFB91C1C) : const Color(0xFF15803D)` |
| `lib/Custom Widgets/Consultation/custom_diagnosis_widgets.dart` | 211 | `color: const Color(0xFFB91C1C)` |
| `lib/Custom Widgets/Consultation/custom_diagnosis_widgets.dart` | 317 | `border: Border.all(color: const Color(0xFFE5E7EB))` |
| `lib/Custom Widgets/Consultation/custom_prescription_widgets.dart` | 407 | `color: const Color(0xFF991B1B)` |
| `lib/Custom Widgets/Consultation/siri_waveform.dart` | 110 | `color: const Color(0xff4F46E5)` |
| `lib/Custom Widgets/Consultation/siri_waveform.dart` | 116 | `color: const Color(0xff7C3AED)` |
| `lib/Custom Widgets/Consultation/siri_waveform.dart` | 122 | `color: const Color(0xff06B6D4)` |
| `lib/Custom Widgets/Patients/cabin_diagnosis_card.dart` | 139 | `color: Color(0xFF9CA3AF)` |
| `lib/Custom Widgets/Patients/cabin_diagnosis_card.dart` | 179 | `color: Color(0xFFD1D5DB)` |
| `lib/Custom Widgets/Patients/diagnosis_card.dart` | 209 | `color: Color(0xFF9CA3AF)` |
| `lib/Custom Widgets/Patients/diagnosis_card.dart` | 341 | `color: Color(0xFFF9FAFB)` |
| `lib/Screens/Consultation/analysis_screen.dart` | 171 | `color: Color(0xFF111827)` |
| `lib/Screens/Consultation/history_taking_screen.dart` | 649 | `color: Color(0xfff0eaff)` |
| `lib/Screens/Consultation/history_taking_screen.dart` | 1108 | `color: const Color(0xffE2E8F0)` |
| `lib/Screens/Consultation/history_taking_screen.dart` | 1136 | `color: Color(0xffEF4444)` |

---

## 2. Flutter Palette (`Colors.[name]`)
Usage of built-in Flutter constants. While better than literals, they still ignore the app's custom palette and theme.

| File | Line | Usage |
| :--- | :--- | :--- |
| `lib/Components/app_theme.dart` | 13 | `surface: Colors.white` |
| `lib/Components/app_theme.dart` | 128 | `backgroundColor: Colors.white` |
| `lib/Custom Widgets/Consultation/ai_speaking_orb.dart` | 86 | `Colors.greenAccent` |
| `lib/Custom Widgets/Consultation/ai_speaking_orb.dart` | 166 | `Colors.white` |
| `lib/Custom Widgets/CustomAlertDialog.dart` | 7 | `Colors.black.withAlpha(100)` |
| `lib/Screens/Authentication/login_screen.dart` | 44 | `backgroundColor: Colors.white` |
| `lib/Screens/Consultation/analysis_screen.dart` | 126 | `backgroundColor: Colors.white` |
| `lib/Screens/Consultation/cabin_consultation_screen.dart` | 255 | `backgroundColor: Colors.red` |
| `lib/Screens/Consultation/cabin_consultation_screen.dart` | 436 | `Colors.white` |
| `lib/Screens/PatientData/home_screen.dart` | 109 | `backgroundColor: Colors.white` |
| `lib/Screens/PatientData/patient_history_view.dart` | 163 | `backgroundColor: isError ? Colors.red : Colors.green` |

---

## 3. Direct Palette Usage (`AppColors.[name]`)
These files use the `AppColors` palette directly. While consistent with the brand, they bypass `Theme.of(context)`, making them "hard-coded" relative to the theme system.

| File | Line | Usage |
| :--- | :--- | :--- |
| `lib/Custom Widgets/Consultation/ai_speaking_orb.dart` | 154 | `AppColors.primary` |
| `lib/Custom Widgets/Consultation/custom_clinical_note_widgets.dart` | 46 | `AppColors.greyDark` |
| `lib/Custom Widgets/Consultation/custom_diagnosis_widgets.dart` | 74 | `AppColors.error` / `AppColors.success` |
| `lib/Screens/Consultation/analysis_screen.dart` | 60 | `AppColors.primary` |
| `lib/Screens/Consultation/cabin_consultation_screen.dart` | 445 | `AppColors.primary` |
| `lib/Screens/PatientData/home_screen.dart` | 378 | `AppColors.primary` |

---

## Recommendations

1.  **Centralize Status Colors**: Colors like `FEF2F2` (red background) and `F0FDF4` (green background) should be added to `AppColors` as `errorContainer` and `successContainer`.
2.  **Use Theme Extension**: For non-standard colors (like male/female patient colors), consider using a `ThemeExtension` so they can be accessed via `Theme.of(context).extension<MyColors>()!`.
3.  **Refactor UI Screens**: Replace `Colors.white` and `Colors.black` with `Theme.of(context).colorScheme.surface` and `Theme.of(context).colorScheme.onSurface`.
4.  **Semantic Naming**: Ensure all colors in `AppColors` have semantic names (e.g., `backgroundSubtle`, `borderWeak`) rather than just `greyLight`.
