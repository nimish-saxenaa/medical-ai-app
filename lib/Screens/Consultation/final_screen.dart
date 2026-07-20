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
  TextEditingController prescriptionController = TextEditingController();
  bool isGenerating = false;
  Prescription? prescription;
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
          onGenerate: () async {
            setState(() {
              isGenerating = true;
            });

            final response = await prescribe(
              token: widget.token,
              sessionId: widget.sessionId,
              confirmedDiagnosis: prescriptionController.text,
            );

            setState(() {
              prescription = response;
              isGenerating = false;
            });
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
          ).textTheme.bodyLarge?.copyWith(color: AppColors.grey),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.monitor_heart_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Clinical Results Ready",
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Review and share with the treating physician.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withAlpha(180),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Color(0xfff3f4f6),
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
                      const SizedBox(width: 4),
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
                      const SizedBox(width: 4),
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
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildContent(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomButton(
                        onPressed: () {
                          finalize(context);
                        },
                        child: Text(
                          "Save\nConsultation",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        onPressed: () {
                          finalize(context);
                        },
                        child: Text(
                          "New\nConsultation",
                          textAlign: TextAlign.center,
                        ),
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
    return Material(
      color: selected ? AppColors.white : Color(0xfff3f4f6),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        splashColor: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Color(0xfff3f4f6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: selected ? AppColors.primary : AppColors.greyDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
