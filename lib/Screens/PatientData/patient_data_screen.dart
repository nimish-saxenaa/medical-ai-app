import 'dart:convert';

import 'package:clinical_ai_app/Custom%20Widgets/custom_button.dart';
import 'package:clinical_ai_app/Custom%20Widgets/custom_confirmation_alert.dart';
import 'package:clinical_ai_app/Custom%20Widgets/Patients/diagnosis_card.dart';
import 'package:clinical_ai_app/Services/Authentication/access_token.dart';
import 'package:clinical_ai_app/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_file/open_file.dart';

import '../../Custom Widgets/Patients/custom_name_initial.dart';
import '../../Models/patient_response_history_model.dart';
import '../../Models/session_model.dart';
import '../../Models/consultation_location_model.dart';
import '../../Services/Location/location_service.dart';
import '../../Services/Consultation/consultation_functions.dart';
import '../../Services/PatientData/patient_service.dart';
import '../../Services/PDF/pdf_generator.dart';
import '../../Components/colors.dart';
import '../Consultation/new_consultation_screen.dart';

class PatientDataScreen extends StatefulWidget {
  const PatientDataScreen({super.key, required this.patientHistory});
  static const routeName = "/patient-data";
  final PatientHistoryResponse patientHistory;

  @override
  State<PatientDataScreen> createState() => _PatientDataScreenState();
}

class _PatientDataScreenState extends State<PatientDataScreen> {
  late var history = widget.patientHistory;
  bool isDownloading = false;
  String? downloadingSessionId; // Track which consultation is being downloaded

  /// Recorded consultation locations, keyed by session id. Sessions captured
  /// before location tracking (or on another device) are simply absent.
  Map<String, ConsultationLocation> sessionLocations = {};

  @override
  void initState() {
    super.initState();
    _loadSessionLocations();
  }

  Future<void> _loadSessionLocations() async {
    final locations = await ConsultationLocationService.getForSessions(
      history.sessions.map((s) => s.sessionId).toList(),
    );
    if (!mounted) return;
    setState(() {
      sessionLocations = locations;
    });
  }

  /// Show PDF saved notification
  void _showPdfSavedNotification(String filePath) {
    if (!mounted) return;

    final fileName = filePath.split('/').last;
    final savedIn = filePath.contains('/storage/emulated/0/Download')
        ? 'Downloads folder'
        : 'App storage';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PDF saved',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(fileName, style: TextStyle(fontSize: 12)),
            SizedBox(height: 2),
            Text(
              'Saved to: $savedIn',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 6),
        action: SnackBarAction(
          label: 'OPEN',
          textColor: Colors.white,
          onPressed: () => OpenFile.open(filePath),
        ),
      ),
    );
  }

  /// Show a simple status message
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Download SINGLE consultation report as PDF
  Future<void> downloadConsultationReport(Session consultation) async {
    setState(() {
      isDownloading = true;
      downloadingSessionId = consultation.sessionId;
    });

    try {
      // Diagnostic: shows exactly what the history API returned for this
      // session, so empty PDF sections can be traced to missing API data.
      print('📄 Session payload for PDF: ${jsonEncode(consultation.toJson())}');

      // Generate PDF for single consultation
      final pdfFile = await PatientPdfGenerator.generateConsultationReport(
        consultation: consultation,
        patient: history.patient,
        location: sessionLocations[consultation.sessionId],
      );

      setState(() {
        isDownloading = false;
        downloadingSessionId = null;
      });

      print('✅ Consultation PDF saved: ${pdfFile.path}');
      _showPdfSavedNotification(pdfFile.path);
    } catch (e) {
      setState(() {
        isDownloading = false;
        downloadingSessionId = null;
      });

      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );

      print('❌ Error generating consultation PDF: $e');
    }
  }

  /// Download patient report as PDF (ALL consultations)
  Future<void> downloadPatientReport() async {
    setState(() {
      isDownloading = true;
    });

    try {
      // Generate PDF
      final pdfFile = await PatientPdfGenerator.generatePatientReport(
        patientHistory: history,
        locations: sessionLocations,
      );

      setState(() {
        isDownloading = false;
      });

      print('✅ Full patient report saved: ${pdfFile.path}');
      _showPdfSavedNotification(pdfFile.path);
    } catch (e) {
      setState(() {
        isDownloading = false;
      });

      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Error generating PDF: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );

      print('❌ Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  Icon(Icons.arrow_back),
                  Text(
                    "Patients  /  ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              history.patient.name,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        actions: [
          // Download PDF Button
          // IconButton(
          //   onPressed: isDownloading ? null : downloadPatientReport,
          //   icon: isDownloading
          //       ? SizedBox(
          //           width: 20,
          //           height: 20,
          //           child: CircularProgressIndicator(strokeWidth: 2),
          //         )
          //       : Icon(LucideIcons.download),
          //   tooltip: 'Download Patient Report',
          // ),
          SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Image.asset("assets/kuvaka_logo.png"),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomNameInitial(name: history.patient.name, size: 60),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: history.patient.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                  children: [
                                    TextSpan(
                                      text:
                                          "\n${history.patient.age} Yrs · ${history.patient.gender ?? ""}",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  IconText(
                                    icon: LucideIcons.calendar,
                                    text: DateFormat('d MMM yy').format(
                                      parseServerDate(
                                        history.patient.createdAt,
                                      ),
                                    ),
                                  ),
                                  IconText(
                                    icon: LucideIcons.stethoscope,
                                    text:
                                        '${history.sessions.length} Consultations',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewConsultationScreen(
                        patientName: history.patient.name,
                        patientAge: history.patient.age,
                        patientGender: history.patient.gender ?? "",
                        patientId: history.patient.patientId,
                      ),
                    ),
                  );
                },
                child: Text("+ New Consultation"),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  text: "Consultation History  ",
                  style: Theme.of(context).textTheme.displaySmall,
                  children: [
                    TextSpan(
                      text: "${history.sessions.length}",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              history.sessions.isNotEmpty
                  ? Column(
                      children: List.generate(
                        history.sessions.length,
                        (index) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Action icons - Download & Delete
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Download icon
                                  IconButton(
                                    onPressed:
                                        downloadingSessionId ==
                                            history.sessions[index].sessionId
                                        ? null
                                        : () => downloadConsultationReport(
                                            history.sessions[index],
                                          ),
                                    icon:
                                        downloadingSessionId ==
                                            history.sessions[index].sessionId
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(LucideIcons.download, size: 20),
                                    tooltip: 'Download PDF',
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.primary
                                          .withOpacity(0.1),
                                      foregroundColor: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  // Delete icon
                                  IconButton(
                                    onPressed: () {
                                      showCustomConfirmationAlert(
                                        "Do you want to delete this consultation?",
                                        context,
                                        () async {
                                          // Close the confirmation dialog first
                                          Navigator.pop(context);

                                          try {
                                            String? token =
                                                await AccessTokenService.getToken();
                                            final deletedSessionId = history
                                                .sessions[index]
                                                .sessionId;
                                            await deleteConsultation(
                                              token: token!,
                                              sessionId: deletedSessionId,
                                            );
                                            // Don't leave the location behind
                                            // for a consultation that's gone.
                                            await ConsultationLocationService.removeForSession(
                                              deletedSessionId,
                                            );

                                            var newHistory =
                                                await getPatientHistory(
                                                  patientId:
                                                      history.patient.patientId,
                                                );
                                            if (!mounted) return;
                                            setState(() {
                                              history = newHistory;
                                              sessionLocations.remove(
                                                deletedSessionId,
                                              );
                                            });

                                            _showMessage(
                                              'Consultation deleted successfully',
                                            );
                                          } catch (e) {
                                            print(
                                              '❌ Error deleting consultation: $e',
                                            );
                                            _showMessage(
                                              'Failed to delete consultation',
                                              isError: true,
                                            );
                                          }
                                        },
                                      );
                                    },
                                    icon: Icon(LucideIcons.trash2, size: 20),
                                    tooltip: 'Delete',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red.withOpacity(
                                        0.1,
                                      ),
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Diagnosis Card
                            DiagnosisCard(
                              title: getSpecialtyName(
                                history.sessions[index].specialty ?? "",
                              ),
                              status: getDiagnosisStatus(
                                history.sessions[index].currentStage ?? "",
                              ),
                              date: parseServerDate(
                                history.sessions[index].createdAt,
                              ),

                              description:
                                  history.sessions[index].chiefComplaint ?? "",
                              location:
                                  sessionLocations[history
                                          .sessions[index]
                                          .sessionId]
                                      ?.fullLocation,
                              redFlags:
                                  history
                                      .sessions[index]
                                      .diagnosis
                                      ?.urgentConcerns ??
                                  [],
                              diagnoses: List.generate(
                                (history
                                                .sessions[index]
                                                .diagnosis
                                                ?.differentialDiagnoses
                                                .length ??
                                            0) >
                                        3
                                    ? 3
                                    : history
                                              .sessions[index]
                                              .diagnosis
                                              ?.differentialDiagnoses
                                              .length ??
                                          0,
                                (diffDia) => DiagnosisItem(
                                  severity:
                                      history
                                          .sessions[index]
                                          .diagnosis
                                          ?.differentialDiagnoses[diffDia]
                                          .likelihood ??
                                      "",
                                  name:
                                      history
                                          .sessions[index]
                                          .diagnosis
                                          ?.differentialDiagnoses[diffDia]
                                          .condition ??
                                      "",
                                  code:
                                      history
                                          .sessions[index]
                                          .diagnosis
                                          ?.differentialDiagnoses[diffDia]
                                          .icdCode ??
                                      "",
                                ),
                              ),
                              workup:
                                  "Workup: ${history.sessions[index].diagnosis?.suggestedWorkup.take(2).join("\n") ?? ""} + ${history.sessions[index].diagnosis?.suggestedWorkup.length ?? 2 - 2} more",

                              subjective: [
                                SoapField(
                                  label: 'Chief complaint',
                                  value:
                                      history.sessions[index].chiefComplaint ??
                                      history
                                          .sessions[index]
                                          .summary
                                          .subjective
                                          .chiefComplaint,
                                ),
                                SoapField(
                                  label: 'HPI',
                                  value: history
                                      .sessions[index]
                                      .summary
                                      .subjective
                                      .historyOfPresentingIllness,
                                ),
                                SoapField(
                                  label: 'Past medical history',
                                  value: history
                                      .sessions[index]
                                      .summary
                                      .subjective
                                      .pastMedicalHistory,
                                ),
                                SoapField(
                                  label: 'Surgical history',
                                  value: history
                                      .sessions[index]
                                      .summary
                                      .subjective
                                      .surgicalHistory,
                                ),
                                SoapField(
                                  label: 'Medications',
                                  value: history
                                      .sessions[index]
                                      .summary
                                      .subjective
                                      .medications,
                                ),
                                SoapField(
                                  label: 'Allergies',
                                  value: history
                                      .sessions[index]
                                      .summary
                                      .subjective
                                      .allergies,
                                ),
                                SoapField(
                                  label: 'Family history',
                                  value: history
                                      .sessions[index]
                                      .summary
                                      .subjective
                                      .familyHistory,
                                ),
                                SoapField(
                                  label: 'Social history',
                                  value: history
                                      .sessions[index]
                                      .summary
                                      .subjective
                                      .socialHistory,
                                ),
                                SoapField(
                                  label: 'Review of systems',
                                  value: history
                                      .sessions[index]
                                      .summary
                                      .subjective
                                      .reviewOfSystems,
                                ),
                              ],
                              objective: [
                                SoapField(
                                  label: 'Vital signs',
                                  value: history
                                      .sessions[index]
                                      .summary
                                      .objective
                                      .vitalSigns,
                                ),
                                SoapField(
                                  label: 'Physical exam',
                                  value: history
                                      .sessions[index]
                                      .summary
                                      .objective
                                      .physicalExamination,
                                ),
                              ],
                              show: history.sessions[index].diagnosis != null
                                  ? true
                                  : false,
                            ),
                            SizedBox(height: 16), // Space between consultations
                          ],
                        ),
                      ),
                    )
                  : const NoConsultationsEmptyState(),
            ],
          ),
        ),
      ),
    );
  }
}

class IconText extends StatelessWidget {
  const IconText({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.grey, size: 14),
        SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

class NoConsultationsEmptyState extends StatelessWidget {
  const NoConsultationsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grey.withAlpha(50), // gray-200
          width: 2,
          style: BorderStyle.solid, // see note below for true "dashed"
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight, // brand-light
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.stethoscope, // stethoscope stand-in
              size: 20,
              color: AppColors.primary, // brand
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No consultations yet',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Start the first one using the button above.',
            style: Theme.of(context).textTheme.bodyMedium, // gray-400
          ),
        ],
      ),
    );
  }
}
