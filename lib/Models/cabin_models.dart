import 'package:clinical_ai_app/Models/session_model.dart';
import 'package:clinical_ai_app/Models/consultation_models.dart';

class CabinSession {
  final String sessionId;
  final String? specialty;
  final String? patientId;
  final String? patientName;
  final bool? consent;
  final String? consentCapturedAt;
  final String? status;

  CabinSession({
    required this.sessionId,
    this.specialty,
    this.patientId,
    this.patientName,
    this.consent,
    this.consentCapturedAt,
    this.status,
  });

  factory CabinSession.fromJson(Map<String, dynamic> json) {
    return CabinSession(
      sessionId: (json['session_id'] ?? '').toString(),
      specialty: json['specialty'],
      patientId: json['patient_id']?.toString(),
      patientName: json['patient_name'],
      consent: json['consent'] == true,
      consentCapturedAt: json['consent_captured_at'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'specialty': specialty,
    'patient_id': patientId,
    'patient_name': patientName,
    'consent': consent,
    'consent_captured_at': consentCapturedAt,
    'status': status,
  };
}

class CabinSessionList {
  final List<CabinSession> sessions;

  CabinSessionList({required this.sessions});

  factory CabinSessionList.fromJson(Map<String, dynamic> json) {
    return CabinSessionList(
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((e) => CabinSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'sessions': sessions.map((e) => e.toJson()).toList(),
  };
}

class CabinRecord {
  final String sessionId;
  final List<dynamic> utterances;
  final CabinPanel panel;
  final dynamic suggestions; // Re-use Prescription or keep dynamic if not fully specified
  final List<dynamic> overrides;
  final List<dynamic> auditTrail;

  CabinRecord({
    required this.sessionId,
    required this.utterances,
    required this.panel,
    required this.suggestions,
    required this.overrides,
    required this.auditTrail,
  });

  factory CabinRecord.fromJson(Map<String, dynamic> json) {
    return CabinRecord(
      sessionId: (json['session_id'] ?? '').toString(),
      utterances: json['utterances'] as List<dynamic>? ?? [],
      panel: CabinPanel.fromJson(json['panel'] as Map<String, dynamic>? ?? {}),
      suggestions: json['suggestions'],
      overrides: json['overrides'] as List<dynamic>? ?? [],
      auditTrail: json['audit_trail'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'utterances': utterances,
    'panel': panel.toJson(),
    'suggestions': suggestions,
    'overrides': overrides,
    'audit_trail': auditTrail,
  };
}

class CabinPanel {
  final SessionSummary? summary;
  final Diagnosis? diagnosis;

  CabinPanel({this.summary, this.diagnosis});

  factory CabinPanel.fromJson(Map<String, dynamic> json) {
    return CabinPanel(
      summary: json['summary'] != null ? SessionSummary.fromJson(json['summary']) : null,
      diagnosis: json['diagnosis'] != null ? Diagnosis.fromJson(json['diagnosis']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary?.toJson(),
    'diagnosis': diagnosis?.toJson(),
  };
}
