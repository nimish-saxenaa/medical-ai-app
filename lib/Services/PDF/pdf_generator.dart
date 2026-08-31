import 'dart:io';
import 'package:clinical_ai_app/functions.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../Models/patient_response_history_model.dart';
import '../../Models/patient_model.dart';
import '../../Models/session_model.dart';
import '../../Models/consultation_location_model.dart';

class PatientPdfGenerator {
  /// Generate PDF for a SINGLE consultation
  static Future<File> generateConsultationReport({
    required Session consultation,
    required Patient patient,
    ConsultationLocation? location,
  }) async {
    final pdf = pw.Document();

    // MultiPage so long consultations flow onto extra pages instead of being
    // silently clipped at the bottom of a single fixed page.
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildConsultationHeader(patient, consultation, location),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Consultation Details
          ..._buildSingleConsultationDetails(consultation),
        ],
      ),
    );

    // Save PDF to device
    final output = await _getSingleConsultationFile(
      patient.name,
      consultation.specialty ?? 'Consultation',
      consultation.createdAt ?? DateTime.now().toString(),
    );
    final file = File(output.path);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Generate PDF for patient with all consultation history
  static Future<File> generatePatientReport({
    required PatientHistoryResponse patientHistory,
    Map<String, ConsultationLocation> locations = const {},
  }) async {
    final pdf = pw.Document();

    // Split consultations into pages (max 2 per page to avoid TooManyPagesException)
    final consultationsPerPage = 2;
    final totalPages = (patientHistory.sessions.length / consultationsPerPage)
        .ceil();

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIndex = pageIndex * consultationsPerPage;
      final endIndex = (startIndex + consultationsPerPage).clamp(
        0,
        patientHistory.sessions.length,
      );
      final sessionsInPage = patientHistory.sessions.sublist(
        startIndex,
        endIndex,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header (only on first page)
              if (pageIndex == 0) ...[
                _buildHeader(patientHistory.patient),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
              ],

              // Page title
              pw.Text(
                pageIndex == 0
                    ? 'Consultation History (${patientHistory.sessions.length} total)'
                    : 'Consultation History (continued)',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),

              // Consultations for this page
              ...sessionsInPage.map(
                (session) => pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 16),
                  child: _buildCompactConsultationCard(
                    session,
                    locations[session.sessionId],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Save PDF to device
    final output = await _getOutputFile(patientHistory.patient.name);
    final file = File(output.path);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Build consultation header for single consultation PDF
  static pw.Widget _buildConsultationHeader(
    Patient patient,
    Session consultation,
    ConsultationLocation? location,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Consultation Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Patient: ${patient.name}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Age: ${patient.age} years  |  Gender: ${patient.gender ?? "N/A"}',
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Specialty: ${consultation.specialty ?? "General"}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Consultation Date:',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  DateFormat('d MMM yyyy').format(
                    parseServerDate(consultation.createdAt),
                  ),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Full width so a long "City, State, Country" never squeezes the
        // date column. Omitted entirely when no location was recorded.
        if (location != null && !location.isEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Location: ${location.fullLocation}',
            style: pw.TextStyle(fontSize: 11),
          ),
        ],
      ],
    );
  }

  /// Build detailed single consultation content
  static List<pw.Widget> _buildSingleConsultationDetails(Session session) {
    final subjective = session.summary.subjective;
    final objective = session.summary.objective;

    // Collect the fields that actually carry content so we can tell the
    // difference between "section is empty" and "section was dropped".
    final subjectiveFields = <pw.Widget>[
      _buildSoapField('Chief Complaint', subjective.chiefComplaint),
      _buildSoapField(
        'History of Presenting Illness',
        subjective.historyOfPresentingIllness,
      ),
      _buildSoapField('Past Medical History', subjective.pastMedicalHistory),
      _buildSoapField('Surgical History', subjective.surgicalHistory),
      _buildSoapField('Medications', subjective.medications),
      _buildSoapField('Allergies', subjective.allergies),
      _buildSoapField('Family History', subjective.familyHistory),
      _buildSoapField('Social History', subjective.socialHistory),
      _buildSoapField('Review of Systems', subjective.reviewOfSystems),
    ].where((w) => w is! pw.SizedBox).toList();

    final objectiveFields = <pw.Widget>[
      _buildSoapField('Vital Signs', objective.vitalSigns),
      _buildSoapField('Physical Examination', objective.physicalExamination),
    ].where((w) => w is! pw.SizedBox).toList();

    return [
      // Chief Complaint
      if (session.chiefComplaint != null && session.chiefComplaint!.isNotEmpty)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Chief Complaint',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(session.chiefComplaint!, style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 12),
          ],
        ),

      // Subjective
      pw.Text(
        'SUBJECTIVE',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
      ),
      pw.SizedBox(height: 8),
      if (subjectiveFields.isEmpty)
        _buildEmptyNote('No subjective findings recorded for this consultation.')
      else
        ...subjectiveFields,
      pw.SizedBox(height: 12),

      // Objective
      pw.Text(
        'OBJECTIVE',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
      ),
      pw.SizedBox(height: 8),
      if (objectiveFields.isEmpty)
        _buildEmptyNote('No objective findings recorded for this consultation.')
      else
        ...objectiveFields,
      pw.SizedBox(height: 12),

      // Narrative assessment / plan from the summary (previously never shown)
      if (session.summary.assessment != null &&
          session.summary.assessment!.isNotEmpty) ...[
        pw.Text(
          'ASSESSMENT',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.Text(session.summary.assessment!, style: pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 12),
      ],
      if (session.summary.plan != null && session.summary.plan!.isNotEmpty) ...[
        pw.Text(
          'PLAN',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.Text(session.summary.plan!, style: pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 12),
      ],

      // Assessment & Plan
      if (session.diagnosis == null)
        _buildEmptyNote('No diagnosis recorded for this consultation.'),
      if (session.diagnosis != null) ...[
          pw.Text(
            'ASSESSMENT & PLAN',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),

          // Red Flags (if any)
          if (session.diagnosis!.urgentConcerns.isNotEmpty) ...[
            pw.Container(
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.red300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '⚠️ RED FLAGS / URGENT CONCERNS',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      color: PdfColors.red700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  ...session.diagnosis!.urgentConcerns.map(
                    (concern) => pw.Padding(
                      padding: pw.EdgeInsets.only(left: 8, top: 2),
                      child: pw.Text(
                        '• $concern',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.red700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // Differential Diagnoses
          if (session.diagnosis!.differentialDiagnoses.isNotEmpty) ...[
            pw.Text(
              'Differential Diagnoses:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            ...session.diagnosis!.differentialDiagnoses.map(
              (dx) => pw.Padding(
                padding: pw.EdgeInsets.only(left: 8, top: 4),
                child: pw.Text(
                  '- ${dx.condition} (${dx.likelihood})\n  ICD Code: ${dx.icdCode}',
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // Suggested Workup
          if (session.diagnosis!.suggestedWorkup.isNotEmpty) ...[
            pw.Text(
              'Suggested Workup:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            ...session.diagnosis!.suggestedWorkup.map(
              (workup) => pw.Padding(
                padding: pw.EdgeInsets.only(left: 8, top: 2),
                child: pw.Text('- $workup', style: pw.TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ],
    ];
  }

  /// Placeholder shown when a section has no data, so the reader can tell the
  /// section was genuinely empty rather than lost during generation.
  static pw.Widget _buildEmptyNote(String message) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        message,
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  /// Build compact consultation card for full patient report
  static pw.Widget _buildCompactConsultationCard(
    Session session,
    ConsultationLocation? location,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                session.specialty ?? 'General',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                DateFormat('d MMM yyyy').format(
                  parseServerDate(session.createdAt),
                ),
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          if (session.chiefComplaint != null &&
              session.chiefComplaint!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'CC: ${session.chiefComplaint}',
              style: pw.TextStyle(fontSize: 10),
              maxLines: 2,
            ),
          ],
          if (session.diagnosis != null &&
              session.diagnosis!.differentialDiagnoses.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Dx: ${session.diagnosis!.differentialDiagnoses.first.condition}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
          if (location != null && !location.isEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Location: ${location.fullLocation}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  /// Build patient header section
  static pw.Widget _buildHeader(Patient patient) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Patient Medical Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Patient Name: ${patient.name}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Age: ${patient.age} years'),
                pw.SizedBox(height: 4),
                pw.Text('Gender: ${patient.gender ?? "Not specified"}'),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Report Generated:', style: pw.TextStyle(fontSize: 10)),
                pw.Text(
                  DateFormat('d MMM yyyy, HH:mm').format(DateTime.now()),
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Patient Since:', style: pw.TextStyle(fontSize: 10)),
                pw.Text(
                  DateFormat('d MMM yyyy').format(
                    parseServerDate(patient.createdAt),
                  ),
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Build SOAP field
  static pw.Widget _buildSoapField(String label, String? value) {
    if (value == null ||
        value.isEmpty ||
        value.toLowerCase() == 'none' ||
        value.toLowerCase() == 'not available') {
      return pw.SizedBox.shrink();
    }

    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// Resolve the directory PDFs are written to.
  ///
  /// On Android we aim for the public Downloads folder so the file shows up in
  /// the Files / Downloads app. If that isn't writable (scoped storage without
  /// permission) we fall back to the app-specific external directory.
  static Future<Directory> _resolveOutputDirectory() async {
    if (Platform.isAndroid) {
      if (await _ensureStoragePermission()) {
        final downloads = Directory('/storage/emulated/0/Download');
        try {
          if (!await downloads.exists()) {
            await downloads.create(recursive: true);
          }
          // Verify we can actually write there before committing to it.
          final probe = File(
            '${downloads.path}/.write_probe_${DateTime.now().millisecondsSinceEpoch}',
          );
          await probe.writeAsString('');
          await probe.delete();
          return downloads;
        } catch (e) {
        }
      }
      final external = await getExternalStorageDirectory();
      if (external != null) return external;
    }
    return getApplicationDocumentsDirectory();
  }

  /// Request the storage permission Android needs to write to Downloads.
  static Future<bool> _ensureStoragePermission() async {
    // Android 13+ no longer grants/needs WRITE_EXTERNAL_STORAGE; the write is
    // attempted directly and falls back if it fails.
    if (await Permission.storage.isGranted) return true;
    final status = await Permission.storage.request();
    if (status.isGranted) return true;

    if (await Permission.manageExternalStorage.isGranted) return true;
    // Not requesting MANAGE_EXTERNAL_STORAGE interactively: still try the write.
    return true;
  }

  /// Get output file path for full patient report
  static Future<File> _getOutputFile(String patientName) async {
    final directory = await _resolveOutputDirectory();

    final fileName =
        'Patient_${patientName.replaceAll(' ', '_')}_Full_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

    return File('${directory.path}/$fileName');
  }

  /// Get output file path for single consultation
  static Future<File> _getSingleConsultationFile(
    String patientName,
    String specialty,
    String consultationDate,
  ) async {
    final directory = await _resolveOutputDirectory();

    final dateStr = DateFormat(
      'yyyyMMdd',
    ).format(parseServerDate(consultationDate));
    final fileName =
        '${patientName.replaceAll(' ', '_')}_${specialty.replaceAll(' ', '_')}_$dateStr.pdf';

    return File('${directory.path}/$fileName');
  }
}
