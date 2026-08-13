class Session {
  final String sessionId;
  final String? specialty;
  final String? createdAt;
  final String? currentStage;
  final String? patientName;
  final String? chiefComplaint;
  final SessionSummary summary;
  final Diagnosis? diagnosis;
  final dynamic prescription; // shape not yet specified by API, kept raw

  Session({
    required this.sessionId,
    this.specialty,
    this.createdAt,
    this.currentStage,
    this.patientName,
    this.chiefComplaint,
    required this.summary,
    this.diagnosis,
    this.prescription,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionId: (json['session_id'] ?? '').toString(),
      specialty: json['specialty'],
      createdAt: json['created_at'],
      currentStage: json['current_stage'],
      patientName: json['patient_name'],
      chiefComplaint: json['chief_complaint'],
      summary: SessionSummary.fromJson(json['summary']),
      diagnosis: json['diagnosis'] != null
          ? Diagnosis.fromJson(json['diagnosis'] as Map<String, dynamic>)
          : null,
      prescription: json['prescription'],
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'specialty': specialty,
    'created_at': createdAt,
    'current_stage': currentStage,
    'patient_name': patientName,
    'chief_complaint': chiefComplaint,
    'summary': summary.toJson(),
    'diagnosis': diagnosis?.toJson(),
    'prescription': prescription,
  };

  @override
  String toString() =>
      'Session(sessionId: $sessionId, specialty: $specialty, currentStage: $currentStage, chiefComplaint: $chiefComplaint)';
}


class Diagnosis {
  final List<DifferentialDiagnosis> differentialDiagnoses;
  final List<String> urgentConcerns;
  final List<String> suggestedWorkup;
  final String? physicianNote;

  Diagnosis({
    required this.differentialDiagnoses,
    required this.urgentConcerns,
    required this.suggestedWorkup,
    this.physicianNote,
  });

  factory Diagnosis.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return Diagnosis(
      differentialDiagnoses: (json['differential_diagnoses'] as List<dynamic>? ?? [])
          .map((e) => DifferentialDiagnosis.fromJson(e as Map<String, dynamic>))
          .toList(),
      urgentConcerns: (json['urgent_concerns'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      suggestedWorkup: (json['suggested_workup'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      physicianNote: json['physician_note'],
    );
  }

  Map<String, dynamic> toJson() => {
    'differential_diagnoses': differentialDiagnoses.map((e) => e.toJson()).toList(),
    'urgent_concerns': urgentConcerns,
    'suggested_workup': suggestedWorkup,
    'physician_note': physicianNote,
  };
}


class DifferentialDiagnosis {
  final String condition;
  final String? likelihood;
  final String? reasoning;
  final String? icdCode;

  DifferentialDiagnosis({
    required this.condition,
    this.likelihood,
    this.reasoning,
    this.icdCode,
  });

  factory DifferentialDiagnosis.fromJson(Map<String, dynamic> json) {
    return DifferentialDiagnosis(
      condition: json['condition'] ?? '',
      likelihood: json['likelihood'],
      reasoning: json['reasoning'],
      icdCode: json['icd_code'],
    );
  }

  Map<String, dynamic> toJson() => {
    'condition': condition,
    'likelihood': likelihood,
    'reasoning': reasoning,
    'icd_code': icdCode,
  };

  @override
  String toString() =>
      'DifferentialDiagnosis(condition: $condition, likelihood: $likelihood, icdCode: $icdCode)';
}


class SessionSummary {
  final Subjective subjective;
  final Objective objective;
  final String? assessment;
  final String? plan;

  SessionSummary({
    required this.subjective,
    required this.objective,
    this.assessment,
    this.plan,
  });

  factory SessionSummary.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return SessionSummary(
      subjective: Subjective.fromJson(json['subjective']),
      objective: Objective.fromJson(json['objective']),
      assessment: json['assessment']?.toString(),
      plan: json['plan']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'subjective': subjective.toJson(),
    'objective': objective.toJson(),
    'assessment': assessment,
    'plan': plan,
  };
}


class Objective {
  final String? vitalSigns;
  final String? physicalExamination;

  Objective({this.vitalSigns, this.physicalExamination});

  factory Objective.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return Objective(
      vitalSigns: json['vital_signs'],
      physicalExamination: json['physical_examination'],
    );
  }

  Map<String, dynamic> toJson() => {
    'vital_signs': vitalSigns,
    'physical_examination': physicalExamination,
  };
}


class Subjective {
  final String? chiefComplaint;
  final String? historyOfPresentingIllness;
  final String? pastMedicalHistory;
  final String? surgicalHistory;
  final String? medications;
  final String? allergies;
  final String? familyHistory;
  final String? socialHistory;
  final String? reviewOfSystems;

  Subjective({
    this.chiefComplaint,
    this.historyOfPresentingIllness,
    this.pastMedicalHistory,
    this.surgicalHistory,
    this.medications,
    this.allergies,
    this.familyHistory,
    this.socialHistory,
    this.reviewOfSystems,
  });

  factory Subjective.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return Subjective(
      chiefComplaint: json['chief_complaint'],
      historyOfPresentingIllness: json['history_of_presenting_illness'],
      pastMedicalHistory: json['past_medical_history'],
      surgicalHistory: json['surgical_history'],
      medications: json['medications'],
      allergies: json['allergies'],
      familyHistory: json['family_history'],
      socialHistory: json['social_history'],
      reviewOfSystems: json['review_of_systems'],
    );
  }

  Map<String, dynamic> toJson() => {
    'chief_complaint': chiefComplaint,
    'history_of_presenting_illness': historyOfPresentingIllness,
    'past_medical_history': pastMedicalHistory,
    'surgical_history': surgicalHistory,
    'medications': medications,
    'allergies': allergies,
    'family_history': familyHistory,
    'social_history': socialHistory,
    'review_of_systems': reviewOfSystems,
  };
}
