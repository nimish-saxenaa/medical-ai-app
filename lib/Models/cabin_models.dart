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
  final String? createdAt;
  final String? endedAt;
  final CabinPanel? panel;

  CabinSession({
    required this.sessionId,
    this.specialty,
    this.patientId,
    this.patientName,
    this.consent,
    this.consentCapturedAt,
    this.status,
    this.createdAt,
    this.endedAt,
    this.panel,
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
      createdAt: json['created_at'],
      endedAt: json['ended_at'],
      panel: json['panel'] != null ? CabinPanel.fromJson(json['panel'] as Map<String, dynamic>) : null,
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
    'created_at': createdAt,
    'ended_at': endedAt,
    'panel': panel?.toJson(),
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

class CabinUtterance {
  final String id;
  final int? seq;
  final String text;
  final String? role;
  final double? confidence;
  final String? language;
  final String? createdAt;
  final double? ts; // Server timestamp from message root

  CabinUtterance({
    required this.id,
    this.seq,
    required this.text,
    this.role,
    this.confidence,
    this.language,
    this.createdAt,
    this.ts,
  });

  factory CabinUtterance.fromJson(Map<String, dynamic> json) {
    // Handle the wrapper message structure: {"type": "utterance", "utterance": {...}, "ts": ...}
    final data = json['utterance'] ?? json;
    return CabinUtterance(
      id: (data['utterance_id'] ?? data['id'] ?? '').toString(),
      seq: data['seq'] as int?,
      text: (data['text'] ?? '').toString(),
      role: data['role']?.toString() ?? 'unknown',
      confidence: (data['role_confidence'] as num? ?? data['confidence'] as num?)?.toDouble(),
      language: data['language']?.toString(),
      createdAt: data['created_at']?.toString(),
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'utterance_id': id,
    'seq': seq,
    'text': text,
    'role': role,
    'role_confidence': confidence,
    'language': language,
    'created_at': createdAt,
    'ts': ts,
  };

  CabinUtterance copyWith({String? role, double? confidence}) {
    return CabinUtterance(
      id: id,
      seq: seq,
      text: text,
      role: role ?? this.role,
      confidence: confidence ?? this.confidence,
      language: language,
      createdAt: createdAt,
      ts: ts,
    );
  }
}

class CabinSuggestions {
  final List<CabinQuestion> questionsToAsk;
  final List<DifferentialDiagnosis> differentials;
  final List<String> testsToConsider;
  final List<String> redFlags;
  final int? seq;

  CabinSuggestions({
    required this.questionsToAsk,
    required this.differentials,
    required this.testsToConsider,
    required this.redFlags,
    this.seq,
  });

  factory CabinSuggestions.fromJson(Map<String, dynamic> json) {
    final data = json['suggestions'] ?? json;
    final rawQuestions = data['questions_to_ask'] as List<dynamic>? ?? [];
    
    return CabinSuggestions(
      questionsToAsk: rawQuestions.map((e) {
        if (e is String) {
          return CabinQuestion(question: e, reason: "");
        } else if (e is Map<String, dynamic>) {
          return CabinQuestion.fromJson(e);
        } else {
          return CabinQuestion(question: e.toString(), reason: "");
        }
      }).toList(),
      differentials: (data['differentials'] as List<dynamic>? ?? [])
          .map((e) => DifferentialDiagnosis.fromJson(e as Map<String, dynamic>))
          .toList(),
      testsToConsider: (data['tests_to_consider'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      redFlags: (data['red_flags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      seq: json['seq'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'questions_to_ask': questionsToAsk.map((e) => e.toJson()).toList(),
    'differentials': differentials.map((e) => e.toJson()).toList(),
    'tests_to_consider': testsToConsider,
    'red_flags': redFlags,
    'seq': seq,
  };
}

class CabinQuestion {
  final String question;
  final String reason;

  CabinQuestion({required this.question, required this.reason});

  factory CabinQuestion.fromJson(Map<String, dynamic> json) {
    return CabinQuestion(
      question: (json['question'] ?? json['text'] ?? '').toString(),
      reason: (json['rationale'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'reason': reason,
  };
}

class CabinPanel {
  final List<CabinSymptom> symptoms;
  final List<DifferentialDiagnosis> diagnoses;
  final List<String> tests;
  final List<Medication> medications;
  final List<String> questionsAsked;
  final String? updatedAt;
  final int? seq;

  CabinPanel({
    required this.symptoms,
    required this.diagnoses,
    required this.tests,
    required this.medications,
    required this.questionsAsked,
    this.updatedAt,
    this.seq,
  });

  factory CabinPanel.fromJson(Map<String, dynamic> json) {
    // Handle wrapper if present: {"type": "panel", "panel": {...}, "seq": ...}
    final data = json['panel'] ?? json;
    return CabinPanel(
      symptoms: (data['symptoms'] as List<dynamic>? ?? [])
          .map((e) => CabinSymptom.fromJson(e as Map<String, dynamic>))
          .toList(),
      diagnoses: (data['diagnoses'] as List<dynamic>? ?? [])
          .map((e) => DifferentialDiagnosis.fromJson(e as Map<String, dynamic>))
          .toList(),
      tests: (data['tests'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      medications: (data['medications'] as List<dynamic>? ?? [])
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionsAsked: (data['questions_asked'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      updatedAt: data['updated_at']?.toString(),
      seq: json['seq'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'symptoms': symptoms.map((e) => e.toJson()).toList(),
    'diagnoses': diagnoses.map((e) => e.toJson()).toList(),
    'tests': tests,
    'medications': medications.map((e) => e.toJson()).toList(),
    'questions_asked': questionsAsked,
    'updated_at': updatedAt,
    'seq': seq,
  };
}

class CabinSymptom {
  final String name;
  final String? description;
  final String? reportedBy;

  CabinSymptom({required this.name, this.description, this.reportedBy});

  factory CabinSymptom.fromJson(Map<String, dynamic> json) {
    return CabinSymptom(
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      reportedBy: json['reported_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'reported_by': reportedBy,
  };
}

class CabinSnapshot {
  final List<CabinUtterance> utterances;
  final CabinPanel panel;
  final CabinSuggestions suggestions;

  CabinSnapshot({
    required this.utterances,
    required this.panel,
    required this.suggestions,
  });

  factory CabinSnapshot.fromJson(Map<String, dynamic> json) {
    return CabinSnapshot(
      utterances: (json['utterances'] as List<dynamic>? ?? [])
          .map((e) => CabinUtterance.fromJson(e as Map<String, dynamic>))
          .toList(),
      panel: CabinPanel.fromJson(json['panel'] as Map<String, dynamic>? ?? {}),
      suggestions: CabinSuggestions.fromJson(json['suggestions'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class CabinRecord {
  final String sessionId;
  final List<CabinUtterance> utterances;
  final CabinPanel panel;
  final CabinSuggestions? suggestions;
  final List<dynamic> overrides;
  final List<dynamic> auditTrail;

  CabinRecord({
    required this.sessionId,
    required this.utterances,
    required this.panel,
    this.suggestions,
    required this.overrides,
    required this.auditTrail,
  });

  factory CabinRecord.fromJson(Map<String, dynamic> json) {
    return CabinRecord(
      sessionId: (json['session_id'] ?? '').toString(),
      utterances: (json['utterances'] as List<dynamic>? ?? [])
          .map((e) => CabinUtterance.fromJson(e as Map<String, dynamic>))
          .toList(),
      panel: CabinPanel.fromJson(json['panel'] as Map<String, dynamic>? ?? {}),
      suggestions: json['suggestions'] != null 
          ? CabinSuggestions.fromJson(json['suggestions'] as Map<String, dynamic>) 
          : null,
      overrides: json['overrides'] as List<dynamic>? ?? [],
      auditTrail: json['audit_trail'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'utterances': utterances.map((e) => e.toJson()).toList(),
    'panel': panel.toJson(),
    'suggestions': suggestions?.toJson(),
    'overrides': overrides,
    'audit_trail': auditTrail,
  };
}
