import 'package:clinical_ai_app/Custom%20Widgets/Consultation/custom_clinical_note_widgets.dart';
import 'package:flutter/material.dart';
import 'package:clinical_ai_app/Models/consultation_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../Components/colors.dart';

class PrescriptionPage extends StatelessWidget {
  const PrescriptionPage({
    super.key,
    required this.controller,
    required this.onGenerate,
    this.onChanged,
    this.isLoading = false,
    this.prescription,
  });

  final TextEditingController controller;
  final VoidCallback onGenerate;
  final ValueChanged<String>? onChanged;
  final bool isLoading;
  final Prescription? prescription;

  @override
  Widget build(BuildContext context) {
    final canGenerate = controller.text.trim().isNotEmpty && !isLoading;
    return Column(
      children: [
        prescription == null ? Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 300),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dividerLight),
          ),
          child: PrescriptionField(controller: controller, onGenerate: onGenerate, onChanged: onChanged, isLoading: isLoading),
        ) : PrescriptionField(controller: controller, onGenerate: onGenerate, onChanged: onChanged, isLoading: isLoading),
        if (prescription != null) ...[
          TreatmentPlanWidget(prescription: prescription!),
        ],
      ],
    );
  }
}

class PrescriptionField extends StatelessWidget {
  const PrescriptionField({
    super.key,
    required this.controller,
    required this.onGenerate,
    this.onChanged,
    required this.isLoading,
  });

  final TextEditingController controller;
  final VoidCallback onGenerate;
  final ValueChanged<String>? onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final canGenerate = controller.text.trim().isNotEmpty && !isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter the confirmed diagnosis to generate a personalised treatment plan.",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.greyDark),
        ),

        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  hintText:
                      "e.g. Acute bronchitis, Major Depressive Episode…",
                ),
              ),
            ),

            const SizedBox(width: 12),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: canGenerate ? onGenerate : null,
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Generate"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class TreatmentPlanWidget extends StatelessWidget {
  const TreatmentPlanWidget({super.key, required this.prescription});

  final Prescription prescription;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prescription.pharmacological.isNotEmpty) ...[
            Text(
              "PHARMACOLOGICAL TREATMENT",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            ...prescription.pharmacological.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MedicationCard(medication: e),
              ),
            ),
          ],

          if (prescription.nonPharmacological.isNotEmpty) ...[


            const TitleText(title: "Non-Pharmacological Treatment"),

            const SizedBox(height: 16),

            ...prescription.nonPharmacological.map((e) => _BulletItem(text: e)),
          ],

          if (prescription.followUp != null &&
              prescription.followUp!.trim().isNotEmpty) ...[

            const TitleText(title: "Follow Up"),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(40)),
              ),
              child: Text(
                prescription.followUp!.replaceAll('"', ''),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.greyDark,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (prescription.referrals.isNotEmpty) ...[


            const TitleText(title: "Referrals"),

            const SizedBox(height: 16),

            ...prescription.referrals.map((e) => _BulletItem(text: e)),
          ],

          if (prescription.contraindicationWarnings.isNotEmpty) ...[


            const TitleText(title: "Contraindication Warnings"),

            const SizedBox(height: 16),

            ...prescription.contraindicationWarnings.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WarningCard(text: e),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
  });

  final Medication medication;

  Widget _row(
      BuildContext context,
      String title,
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    "💊",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  medication.drugName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// Information table
          _row(context, "Dose", medication.dose),
          _row(context, "Frequency", medication.frequency),
          _row(context, "Duration", medication.duration),
          _row(context, "Instructions", medication.instructions),

          /// Warning
          if (medication.warnings != null &&
              medication.warnings!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warningBorder,
                ),
              ),
              child: Text(
                "⚠️ ${medication.warnings!}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.warningText,
                  height: 1.4,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(LucideIcons.circleCheckBig, size: 16,color: AppColors.success,),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
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

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redFlagBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF991B1B),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
