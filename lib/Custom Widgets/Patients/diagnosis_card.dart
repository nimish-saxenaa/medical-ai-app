import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_file/open_file.dart';

import '../../Components/colors.dart';
import '../../Models/consultation_location_model.dart';
import '../../Models/patient_response_history_model.dart';
import '../../Models/session_model.dart';
import '../../Services/Authentication/access_token.dart';
import '../../Services/Consultation/consultation_functions.dart';
import '../../Services/Location/location_service.dart';
import '../../Services/PDF/pdf_generator.dart';
import '../../Services/PatientData/patient_service.dart';
import '../custom_confirmation_alert.dart';

/// ---------- Data models ----------

class DiagnosisItem {
  final String severity; // High / Moderate / Low
  final String name;
  final String code;

  const DiagnosisItem({
    required this.severity,
    required this.name,
    required this.code,
  });
}

class SoapField {
  final String label;
  final String? value; // null / empty => "Not recorded"

  const SoapField({required this.label, this.value});
}

/// ---------- Main expandable card ----------

class DiagnosisCard extends StatefulWidget {
  final String title;
  final String status;
  final DateTime date;
  final String description;

  final List<String> redFlags;
  final List<DiagnosisItem> diagnoses;
  final String workup;

  final List<SoapField> subjective;
  final List<SoapField> objective;
  final bool show;
  final PatientHistoryResponse patientHistory;
  final int index;


  /// Where the consultation was recorded. Null for consultations captured
  /// before location tracking existed — the row is hidden in that case.
  final String? location;

  const DiagnosisCard({
    super.key,
    required this.title,
    required this.status,
    required this.date,
    required this.description,
    this.location,
    required this.redFlags,
    required this.diagnoses,
    required this.workup,
    required this.subjective,
    required this.objective,
    required this.show, required this.patientHistory, required this.index,
  });

  @override
  State<DiagnosisCard> createState() => _DiagnosisCardState();
}

class _DiagnosisCardState extends State<DiagnosisCard> {
  bool _expanded = false;

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour >= 12 ? 'pm' : 'am';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, '
        '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }
 late Color primaryColor;
  late Color lightColor;
  late var history = widget.patientHistory;
  Map<String, ConsultationLocation> sessionLocations = {};
  bool isDownloading = false;
  String? downloadingSessionId; // Track which consultation is being downloaded

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
    switch (widget.status) {
      case "Diagnosed":
        primaryColor = AppColors.diagnosedPrimary;
        lightColor = AppColors.diagnosedLight;
        break;

      case "In Progress":
        primaryColor = AppColors.progressPrimary;
        lightColor = AppColors.progressLight;
        break;
    case "Finalized":
      primaryColor = AppColors.finalizedPrimary;
      lightColor = AppColors.finalizedLight;
      case "Prescribed":
        primaryColor = AppColors.prescribedPrimary;
        lightColor = AppColors.prescribedLight;
      default:
        primaryColor = AppColors.grey;
        lightColor = AppColors.greyLight;
    }
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)), // gray-100
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              /*onLongPress: () async {
                String? token = await AccessTokenService.getToken();
                getQaLog( token: token!, sessionId: history.sessions[widget.index].sessionId);
                },*/
              onTap: () => setState(() => _expanded = !_expanded),
              hoverColor: Colors.green,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.title,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: lightColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: primaryColor,
                                    width: 0.75,
                                  ),
                                ),
                                child: Text(
                                  widget.status,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          splashRadius: 10,
                          child: downloadingSessionId ==
                              history.sessions[widget.index].sessionId
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(
                            LucideIcons.moreVertical,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          tooltip: 'Options',
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (value) {
                            if (value == 'download') {
                              downloadConsultationReport(history.sessions[widget.index]);
                            } else if (value == 'delete') {
                              showCustomConfirmationAlert(
                                "Do you want to delete this consultation?",
                                context,
                                    () async {
                                  // Close the confirmation dialog first
                                  Navigator.pop(context);

                                  try {
                                    String? token = await AccessTokenService.getToken();
                                    final deletedSessionId = history.sessions[widget.index].sessionId;
                                    await deleteConsultation(
                                      token: token!,
                                      sessionId: deletedSessionId,
                                    );
                                    // Don't leave the location behind
                                    // for a consultation that's gone.
                                    await ConsultationLocationService.removeForSession(
                                      deletedSessionId,
                                    );

                                    var newHistory = await getPatientHistory(
                                      patientId: history.patient.patientId,
                                    );
                                    if (!mounted) return;
                                    setState(() {
                                      history = newHistory;
                                      sessionLocations.remove(deletedSessionId);
                                    });

                                    _showMessage('Consultation deleted successfully');
                                  } catch (e) {
                                    print('❌ Error deleting consultation: $e');
                                    _showMessage('Failed to delete consultation', isError: true);
                                  }
                                },
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'download',
                              enabled: downloadingSessionId != history.sessions[widget.index].sessionId,
                              child: Row(
                                children: const [
                                  Icon(LucideIcons.download, size: 18),
                                  SizedBox(width: 10),
                                  Text('Download PDF'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.calendar,
                          size: 12,
                          color: Color(0xFFD1D5DB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(widget.date),
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '· ${widget.description}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.location != null &&
                        widget.location!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 12,
                            color: Color(0xFFD1D5DB),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.location!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_expanded && widget.show)
            _ExpandedBody(
              redFlags: widget.redFlags,
              diagnoses: widget.diagnoses,
              workup: widget.workup,
              subjective: widget.subjective,
              objective: widget.objective,
              show: widget.show,
            ),
          if (_expanded && !widget.show)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB), // gray-50/60 approximation
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "No diagnosis recorded yet.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

/*

 */
/// ---------- Expanded body ----------

class _ExpandedBody extends StatelessWidget {
  final List<String> redFlags;
  final List<DiagnosisItem> diagnoses;
  final String workup;
  final List<SoapField> subjective;
  final List<SoapField> objective;
  final bool show;
  const _ExpandedBody({
    required this.redFlags,
    required this.diagnoses,
    required this.workup,
    required this.subjective,
    required this.objective,
    required this.show,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB), // gray-50/60 approximation
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Diagnosis'),
          const SizedBox(height: 12),
          // Red flag alerts
          Column(
            children: redFlags
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RedFlagAlert(text: f),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          // Diagnosis rows
          ...diagnoses.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DiagnosisRow(item: d),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            workup,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Clinical Summary'),
          const SizedBox(height: 20),
          _SoapSection(letter: 'S', title: 'Subjective', fields: subjective),
          const SizedBox(height: 20),
          _SoapSection(letter: 'O', title: 'Objective', fields: objective),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _RedFlagAlert extends StatelessWidget {
  final String text;
  const _RedFlagAlert({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // red-50
        border: Border.all(color: const Color(0xFFFEE2E2)), // red-100
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_rounded,
              size: 14,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFB91C1C), // red-700
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosisRow extends StatelessWidget {
  final DiagnosisItem item;
  const _DiagnosisRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isHigh = item.severity.toLowerCase() == 'high';
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isHigh ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.severity,
            style: TextStyle(
              color: isHigh ? const Color(0xFFB91C1C) : const Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          item.name,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '(${item.code})',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
        ),
      ],
    );
  }
}

class _SoapSection extends StatelessWidget {
  final String letter;
  final String title;
  final List<SoapField> fields;

  const _SoapSection({
    required this.letter,
    required this.title,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE), // brand-light approx
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  color: Color(0xFF7C3AED), // brand approx
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: fields
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            f.label,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (f.value == null) ? 'Not recorded' : f.value!,
                            style: TextStyle(
                              color: (f.value == null)
                                  ? const Color(0xFFD1D5DB)
                                  : const Color(0xFF374151),
                              fontSize: 12,
                              height: 1.5,
                              fontStyle: (f.value == null)
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
