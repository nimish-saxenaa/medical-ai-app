import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:flutter/material.dart';

import '../../Models/session_model.dart';
import '../../Components/colors.dart';

class DiagnosisPage extends StatelessWidget {
  const DiagnosisPage({super.key, required this.diagnosis});
  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DifferentialDiagnosesSection(
          diagnoses: diagnosis.differentialDiagnoses,
        ),
        UrgentConcernsSection(concerns: diagnosis.urgentConcerns),
        SuggestedWorkupSection(workup: diagnosis.suggestedWorkup),
        PhysicianNoteSection(physicianNote: diagnosis.physicianNote),
      ],
    );
  }
}

class DifferentialDiagnosesSection extends StatelessWidget {
  const DifferentialDiagnosesSection({super.key, required this.diagnoses});

  final List<DifferentialDiagnosis> diagnoses;

  @override
  Widget build(BuildContext context) {
    if (diagnoses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DIFFERENTIAL DIAGNOSES",
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: AppLayout.space12),

        Column(
          children: diagnoses
              .map(
                (diagnosis) => Padding(
              padding: const EdgeInsets.only(bottom: AppLayout.space12),
              child: _DiagnosisCard(diagnosis: diagnosis),
            ),
          )
              .toList(),
        ),
      ],
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  const _DiagnosisCard({required this.diagnosis});

  final DifferentialDiagnosis diagnosis;

  bool get _isHigh =>
      diagnosis.likelihood?.toLowerCase().contains("high") ?? false;

  Color get _borderColor => _isHigh ? AppColors.error : AppColors.success;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color backgroundColor = _isHigh 
        ? (isDark ? AppColors.error.withAlpha(40) : AppColors.errorContainer)
        : (isDark ? AppColors.success.withAlpha(40) : AppColors.statusFinalizedContainer);
    
    final Color chipBackground = _isHigh 
        ? (isDark ? AppColors.error.withAlpha(60) : AppColors.redFlagBorder)
        : (isDark ? AppColors.success.withAlpha(60) : AppColors.statusFinalizedContainer);
    
    final Color chipForeground = _isHigh 
        ? (isDark ? Colors.white : AppColors.onErrorContainer)
        : (isDark ? Colors.white : AppColors.stepSuccessText);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border(left: BorderSide(color: _borderColor, width: 4)),
      ),
      padding: const EdgeInsets.all(AppLayout.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: chipBackground,
                  borderRadius: BorderRadius.circular(AppLayout.radius16),
                ),
                child: Text(
                  diagnosis.likelihood ?? "",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: chipForeground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${diagnosis.condition}  ",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    TextSpan(
                      text: diagnosis.icdCode ?? "",
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppLayout.space8),

          Text(
            diagnosis.reasoning ?? "",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class UrgentConcernsSection extends StatelessWidget {
  const UrgentConcernsSection({super.key, required this.concerns});

  final List<String> concerns;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (concerns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: AppColors.error,
            ),
            const SizedBox(width: AppLayout.space8),
            Text(
              "URGENT CONCERNS",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppLayout.space12),

        Column(
          children: concerns
              .map(
                (concern) => Padding(
              padding: const EdgeInsets.only(bottom: AppLayout.space8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      "•",
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 18,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppLayout.space8),
                  Expanded(
                    child: Text(
                      concern,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(
                        color: isDark ? Colors.white : AppColors.onErrorContainer,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              .toList(),
        ),
      ],
    );
  }
}

class SuggestedWorkupSection extends StatelessWidget {
  const SuggestedWorkupSection({super.key, required this.workup});

  final List<String> workup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (workup.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.science_outlined, size: 18, color: theme.textTheme.bodyMedium?.color),
            const SizedBox(width: AppLayout.space8),
            Text(
              "SUGGESTED WORKUP",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppLayout.space12),

        Column(
          children: workup
              .map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppLayout.space8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "•",
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 18,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppLayout.space8),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              .toList(),
        ),
      ],
    );
  }
}

class PhysicianNoteSection extends StatelessWidget {
  const PhysicianNoteSection({super.key, required this.physicianNote});

  final String? physicianNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (physicianNote == null || physicianNote!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppLayout.space16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.assignment_outlined,
              size: 18,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),

          const SizedBox(width: AppLayout.space8),

          Expanded(
            child: Text(
              physicianNote!.replaceFirst(RegExp(r'^">'), ''),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
