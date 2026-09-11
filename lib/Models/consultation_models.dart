

import 'package:clinical_ai_app/Models/session_model.dart';

/// ---------------------------------------------------------------------
/// POST /api/v1/consultation/start
/// ---------------------------------------------------------------------
class StartConsultationResponse {
  final String sessionId;
  final String? specialty;
  final String? stage;
  final String? openingQuestion;

  StartConsultationResponse({
    required this.sessionId,
    this.specialty,
    this.stage,
    this.openingQuestion,
  });

  factory StartConsultationResponse.fromJson(Map<String, dynamic> json) {
    return StartConsultationResponse(
      sessionId: (json['session_id'] ?? '').toString(),
      specialty: json['specialty'],
      stage: json['stage'],
      openingQuestion: json['opening_question'],
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'specialty': specialty,
        'stage': stage,
        'opening_question': openingQuestion,
      };
}

/// ---------------------------------------------------------------------
/// GET /api/v1/consultation/{session_id}
/// ---------------------------------------------------------------------
class SessionStateResponse {
  final String sessionId;
  final String? specialty;
  final String? currentStage;
  final int qaCount;
  final List<String> flags;
  final bool historyComplete;
  final bool hasSummary;
  final bool hasDiagnosis;
  final bool hasPrescription;

  SessionStateResponse({
    required this.sessionId,
    this.specialty,
    this.currentStage,
    required this.qaCount,
    required this.flags,
    required this.historyComplete,
    required this.hasSummary,
    required this.hasDiagnosis,
    required this.hasPrescription,
  });

  factory SessionStateResponse.fromJson(Map<String, dynamic> json) {
    return SessionStateResponse(
      sessionId: (json['session_id'] ?? '').toString(),
      specialty: json['specialty'],
      currentStage: json['current_stage'],
      qaCount: json['qa_count'] is int
          ? json['qa_count']
          : int.tryParse(json['qa_count']?.toString() ?? '') ?? 0,
      flags: (json['flags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      historyComplete: json['history_complete'] == true,
      hasSummary: json['has_summary'] == true,
      hasDiagnosis: json['has_diagnosis'] == true,
      hasPrescription: json['has_prescription'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'specialty': specialty,
        'current_stage': currentStage,
        'qa_count': qaCount,
        'flags': flags,
        'history_complete': historyComplete,
        'has_summary': hasSummary,
        'has_diagnosis': hasDiagnosis,
        'has_prescription': hasPrescription,
      };
}

/// ---------------------------------------------------------------------
/// POST /api/v1/consultation/{session_id}/answer
/// (also used for /answer-audio, and the final "done" event of /answer-stream)
/// ---------------------------------------------------------------------
class SubmitAnswerResponse {
  final List<String> newFlags;
  final String? nextQuestion;
  final bool historyComplete;

  SubmitAnswerResponse({
    required this.newFlags,
    this.nextQuestion,
    required this.historyComplete,
  });

  factory SubmitAnswerResponse.fromJson(Map<String, dynamic> json) {
    return SubmitAnswerResponse(
      newFlags: (json['new_flags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      nextQuestion: json['next_question'],
      historyComplete: json['history_complete'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'new_flags': newFlags,
        'next_question': nextQuestion,
        'history_complete': historyComplete,
      };
}

/// ---------------------------------------------------------------------
/// GET /api/v1/consultation/{session_id}/qa-log
/// ---------------------------------------------------------------------


class QaLogResponse {
  final List<Map<String,dynamic>> qaLog;
  final List<Map<String,dynamic>> flags;
  final String? rawTranscript;
  final String? translatedTranscript;

  QaLogResponse({
    required this.qaLog,
    required this.flags,
    this.rawTranscript,
    this.translatedTranscript,
  });

  factory QaLogResponse.fromJson(Map<String, dynamic> json) {
    return QaLogResponse(
      qaLog: List<Map<String, dynamic>>.from(
        (json['qa_log'] as List).map(
              (e) => Map<String, dynamic>.from(e),
        ),
      ),
      flags: List<Map<String, dynamic>>.from(
        (json['flags'] as List).map(
              (e) => Map<String, dynamic>.from(e),
        ),
      ),
      rawTranscript: json['raw_transcript'] as String?,
      translatedTranscript: json['translated_transcript'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'qa_log': qaLog,
        'flags': flags,
        'raw_transcript': rawTranscript,
        'translated_transcript': translatedTranscript,
      };
}

/// ---------------------------------------------------------------------
/// PATCH /api/v1/consultation/{session_id}/answer/{question_id}
/// ---------------------------------------------------------------------
class EditAnswerResponse {
  final bool ok;

  EditAnswerResponse({required this.ok});

  factory EditAnswerResponse.fromJson(Map<String, dynamic> json) {
    return EditAnswerResponse(ok: json['ok'] == true);
  }

  Map<String, dynamic> toJson() => {'ok': ok};
}

/// ---------------------------------------------------------------------
/// POST /api/v1/consultation/{session_id}/prescribe
/// Shape of "prescription" is not yet specified by the API, kept raw.
/// ---------------------------------------------------------------------
class Prescription {
  final List<Medication> pharmacological;
  final List<String> nonPharmacological;
  final String? followUp;
  final List<String> referrals;
  final List<String> contraindicationWarnings;
  

  Prescription({
    required this.pharmacological,
    required this.nonPharmacological,
    this.followUp,
    required this.referrals,
    required this.contraindicationWarnings,
  });

  factory Prescription.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return Prescription(
      pharmacological: (json['pharmacological'] as List<dynamic>? ?? [])
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList(),

      nonPharmacological:
      (json['non_pharmacological'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),

      followUp: json['follow_up']?.toString(),

      referrals: (json['referrals'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),

      contraindicationWarnings:
      (json['contraindication_warnings'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'pharmacological':
    pharmacological.map((e) => e.toJson()).toList(),
    'non_pharmacological': nonPharmacological,
    'follow_up': followUp,
    'referrals': referrals,
    'contraindication_warnings': contraindicationWarnings,
  };

  @override
  String toString() =>
      'Prescription(medications: ${pharmacological.length}, referrals: ${referrals.length})';
}

class Medication {
  final String drugName;
  final String? dose;
  final String? frequency;
  final String? duration;
  final String? instructions;
  final String? warnings;
  final String? action;
  final String? note;

  Medication({
    required this.drugName,
    this.dose,
    this.frequency,
    this.duration,
    this.instructions,
    this.warnings,
    this.action,
    this.note,
  });

  factory Medication.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return Medication(
      drugName: json['drug_name']?.toString() ?? '',
      dose: json['dose']?.toString(),
      frequency: json['frequency']?.toString(),
      duration: json['duration']?.toString(),
      instructions: json['instructions']?.toString(),
      warnings: json['warnings']?.toString(),
      action: json['action']?.toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'drug_name': drugName,
    'dose': dose,
    'frequency': frequency,
    'duration': duration,
    'instructions': instructions,
    'warnings': warnings,
    'action': action,
    'note': note,
  };

  @override
  String toString() =>
      'Medication(drugName: $drugName, dose: $dose)';
}

/// ---------------------------------------------------------------------
/// POST /api/v1/consultation/{session_id}/finalize
/// Full ConsultationContext object.
/// ---------------------------------------------------------------------
class ConsultationContext {
  final String sessionId;
  final String? specialty;
  final String? stage;
  final List<Map<String, dynamic>> qaLog;
  final List<Map<String, dynamic>> flags;
  final SessionSummary? summary;
  final Diagnosis? diagnosis;
  final dynamic prescription; // raw, shape not yet specified
  final Map<String, dynamic>? overrides;
  final Map<String, dynamic> raw; // full raw payload for any extra fields

  ConsultationContext({
    required this.sessionId,
    this.specialty,
    this.stage,
    required this.qaLog,
    required this.flags,
    this.summary,
    this.diagnosis,
    this.prescription,
    this.overrides,
    required this.raw,
  });

  factory ConsultationContext.fromJson(Map<String, dynamic> json) {
    return ConsultationContext(
      sessionId: (json['session_id'] ?? '').toString(),
      specialty: json['specialty'],
      stage: json['stage'],
      qaLog: (json['qa_log'] as List<Map<String, dynamic>>? ?? []),
      flags: (json['flags'] as List<Map<String, dynamic>>? ?? []),
      summary: json['summary'] != null
          ? SessionSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
      diagnosis: json['diagnosis'] != null
          ? Diagnosis.fromJson(json['diagnosis'] as Map<String, dynamic>)
          : null,
      prescription: json['prescription'],
      overrides: json['overrides'] as Map<String, dynamic>?,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// ---------------------------------------------------------------------
/// POST /api/v1/consultation/{session_id}/override
/// ---------------------------------------------------------------------
class OverrideFieldResponse {
  final String overridden;
  final dynamic newValue;

  OverrideFieldResponse({required this.overridden, this.newValue});

  factory OverrideFieldResponse.fromJson(Map<String, dynamic> json) {
    return OverrideFieldResponse(
      overridden: (json['overridden'] ?? '').toString(),
      newValue: json['new_value'],
    );
  }

  Map<String, dynamic> toJson() => {
        'overridden': overridden,
        'new_value': newValue,
      };
}

/// ---------------------------------------------------------------------
/// DELETE /api/v1/consultation/{session_id}
/// ---------------------------------------------------------------------
class DeleteConsultationResponse {
  final String deleted;

  DeleteConsultationResponse({required this.deleted});

  factory DeleteConsultationResponse.fromJson(Map<String, dynamic> json) {
    return DeleteConsultationResponse(deleted: (json['deleted'] ?? '').toString());
  }

  Map<String, dynamic> toJson() => {'deleted': deleted};
}



