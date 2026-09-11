import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Models/complete_analysis_model.dart';
import 'package:clinical_ai_app/Screens/PatientData/home_screen.dart';
import 'package:flutter/material.dart';
import '../../Custom Widgets/Consultation/custom_diagnosis_widgets.dart';
import '../../Custom Widgets/Consultation/custom_prescription_widgets.dart';
import '../../Custom Widgets/custom_button.dart';
import '../../Custom Widgets/Consultation/custom_clinical_note_widgets.dart';
import '../../Models/consultation_models.dart';
import '../../Services/Consultation/consultation_functions.dart';
import '../../Components/colors.dart';

enum ResultTab { clinicalNote, diagnosis, treatmentPlan }

class FinalScreen extends StatefulWidget {
  const FinalScreen({
    super.key,
    required this.token,
    required this.sessionId,
    required this.response,
  });
  static const routeName = "/final";
  final String token;
  final String sessionId;
  final CompleteResponse response;

  @override
  State<FinalScreen> createState() => _FinalScreenState();
}

class _FinalScreenState extends State<FinalScreen> {
  late TextEditingController prescriptionController;
  bool isGenerating = false;
  Prescription? prescription;

  @override
  void initState() {
    super.initState();
    prescriptionController = TextEditingController();
    if (widget.response.diagnosis.differentialDiagnoses.isNotEmpty) {
      prescriptionController.text =
          widget.response.diagnosis.differentialDiagnoses.first.condition;
    }
  }

  @override
  void dispose() {
    prescriptionController.dispose();
    super.dispose();
  }

  Widget _buildContent() {
    switch (selectedTab) {
      case ResultTab.clinicalNote:
        return ClinicalNotePage(data: widget.response.note.toJson());

      case ResultTab.diagnosis:
        return DiagnosisPage(diagnosis: widget.response.diagnosis);

      case ResultTab.treatmentPlan:
        return PrescriptionPage(
          isLoading: isGenerating,
          prescription: prescription,
          controller: prescriptionController,
          onChanged: (_) => setState(() {}),
          onGenerate: () async {
            setState(() {
              isGenerating = true;
            });

            try {
              final response = await prescribe(
                token: widget.token,
                sessionId: widget.sessionId,
                confirmedDiagnosis: prescriptionController.text,
              );

              setState(() {
                prescription = response;
                isGenerating = false;
              });
            } catch (e) {
              setState(() {
                isGenerating = false;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to generate prescription: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
        );
    }
  }

  ResultTab selectedTab = ResultTab.clinicalNote;
  Future<void> finalize(BuildContext context) async {
    await finalizeConsultation(
      token: widget.token,
      sessionId: widget.sessionId,
    );
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      HomeScreen.routeName,
      (route) => false,
    );
  }

  bool clinicSelected = true;
  bool diagnosisSelected = false;
  bool prescriptionSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Image.asset("assets/kuvaka_logo.png"),
        ),
        title: Text(
          "Consultation Completed",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppLayout.screenPadding,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppLayout.space16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppLayout.radius16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: AppLayout.space48,
                        height: AppLayout.space48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onPrimary.withAlpha(40),
                          borderRadius: BorderRadius.circular(AppLayout.radius12),
                        ),
                        child: Icon(
                          Icons.monitor_heart_outlined,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: AppLayout.iconLarge,
                        ),
                      ),

                      const SizedBox(height: AppLayout.space12),

                      Text(
                        "Clinical Results Ready",
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppLayout.space4),

                      Text(
                        "Review and share with the treating physician.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary.withAlpha(180),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppLayout.space16),
                Container(
                  padding: const EdgeInsets.all(AppLayout.space4 + 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppLayout.radius16),
                    color: Theme.of(context).dividerColor,
                  ),

                  child: Row(
                    children: [
                      Expanded(
                        child: PageButton(
                          text: 'Clinical Note',
                          selected: clinicSelected,
                          onTap: () {
                            setState(() {
                              clinicSelected = true;
                              diagnosisSelected = false;
                              prescriptionSelected = false;

                              selectedTab = ResultTab.clinicalNote;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppLayout.space4),
                      Expanded(
                        child: PageButton(
                          text: 'Diagnosis',
                          selected: diagnosisSelected,
                          onTap: () {
                            setState(() {
                              clinicSelected = false;
                              diagnosisSelected = true;
                              prescriptionSelected = false;
                              selectedTab = ResultTab.diagnosis;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppLayout.space4),
                      Expanded(
                        child: PageButton(
                          text: 'Prescription',
                          selected: prescriptionSelected,
                          onTap: () {
                            setState(() {
                              clinicSelected = false;
                              diagnosisSelected = false;
                              prescriptionSelected = true;
                              selectedTab = ResultTab.treatmentPlan;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppLayout.space16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppLayout.radius16),
                      boxShadow: Theme.of(context).brightness == Brightness.light ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ] : null,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppLayout.space16),
                      child: _buildContent(),
                    ),
                  ),
                ),
                const SizedBox(height: AppLayout.space16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: "Save\nConsultation",
                        onTap: () async {
                          await finalize(context);
                        },
                      ),
                    ),
                    const SizedBox(width: AppLayout.space16),
                    Expanded(
                      child: CustomButton(
                        text: "New\nConsultation",
                        onTap: () async {
                          await finalize(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PageButton extends StatelessWidget {
  const PageButton({
    super.key,
    required this.text,
    this.selected = false,
    required this.onTap,
  });
  final String text;
  final bool selected;
  final void Function() onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.surface : theme.dividerColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        splashColor: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.surface : theme.dividerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: selected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
