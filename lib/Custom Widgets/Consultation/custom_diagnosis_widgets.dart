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
            color: AppColors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 12),

        Column(
          children: diagnoses
              .map(
                (diagnosis) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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

  Color get _backgroundColor =>
      _isHigh ? AppColors.redFlagBg : AppColors.successContainer;

  Color get _chipBackground =>
      _isHigh ? AppColors.redFlagBorder : AppColors.successBorder;

  Color get _chipForeground =>
      _isHigh ? AppColors.redFlagText : AppColors.successText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _borderColor, width: 4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _chipBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  diagnosis.likelihood ?? "",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _chipForeground,
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
                        color: AppColors.black,
                      ),
                    ),
                    TextSpan(
                      text: diagnosis.icdCode ?? "",
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            diagnosis.reasoning ?? "",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.greyDark,
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
            const SizedBox(width: 8),
            Text(
              "URGENT CONCERNS",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Column(
          children: concerns
              .map(
                (concern) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      concern,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(
                        color: AppColors.redFlagText,
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
    if (workup.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.science_outlined, size: 18, color: AppColors.grey),
            const SizedBox(width: 8),
            Text(
              "SUGGESTED WORKUP",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Column(
          children: workup
              .map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "•",
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(
                        color: AppColors.grey,
                        fontSize: 18,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(
                        color: AppColors.greyDark,
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
    if (physicianNote == null || physicianNote!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.assignment_outlined,
              size: 18,
              color: AppColors.grey,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              physicianNote!.replaceFirst(RegExp(r'^">'), ''),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.greyDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}