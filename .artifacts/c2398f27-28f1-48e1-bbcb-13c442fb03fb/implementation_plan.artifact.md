# Implementation Plan - Refactor Hard-Coded Colors to AppColors

This plan outlines the systematic replacement of hard-coded colors (hex literals and Flutter built-in constants) with semantic constants in the `AppColors` class.

## User Review Required

> [!IMPORTANT]
> This refactor involves changes to over 600 locations. While the primary goal is technical consolidation, it's a significant sweep of the codebase.

> [!NOTE]
> I will be adding several new semantic color constants to `AppColors` to accommodate colors that were previously only available as literals.

## Proposed Changes

### [Component] UI Foundation

#### [MODIFY] [colors.dart](file:///E:/Code/medical-ai-app/lib/Components/colors.dart)
Add missing color constants identified during the scan. This includes:
- Semantic status colors (Success/Error variants).
- specific UI component colors (Waveform, Avatars).
- Standard grey/slate shades used for borders and dividers.

### [Component] Custom Widgets & Screens

#### [MODIFY] Multiple Files
I will iterate through all identified files and replace color literals with their corresponding `AppColors` constant.
Key files include:
- `lib/Custom Widgets/Consultation/custom_diagnosis_widgets.dart`
- `lib/Custom Widgets/Patients/diagnosis_card.dart`
- `lib/Screens/Consultation/history_taking_screen.dart`
- `lib/Screens/Consultation/cabin_consultation_screen.dart`

**Mapping Strategy:**
- `Color(0xFFFEF2F2)` -> `AppColors.redFlagBg`
- `Color(0xFFE5E7EB)` -> `AppColors.borderLight`
- `Colors.white` -> `AppColors.white` (or `Theme.of(context).colorScheme.surface` where appropriate)
- `Colors.red` -> `AppColors.error`

---

## Verification Plan

### Automated Tests
- I will perform a project build to ensure no syntax errors were introduced during the massive search-and-replace operation.
- I will run another `grep` scan after the changes to verify that the number of hard-coded literals has been significantly reduced (approaching zero).

### Manual Verification
- I recommend the user spot-check key screens (Home, Consultation, Diagnosis Card) to ensure visual consistency was maintained.
