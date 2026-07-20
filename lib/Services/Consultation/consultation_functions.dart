import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../Models/consultation_models.dart';
import 'dart:typed_data';

/// POST /api/v1/consultation/start
/// specialty must be one of: general_medicine | psychotherapy | gynecology
/// patient_id optional — if provided, overrides name/age/gender from the patient record.
///
String baseUrl = "https://med-history-agent.decrackle.io";
Future<StartConsultationResponse> startConsultation({
  required String token,
  required String specialty,
  String? patientLanguage,
  String? patientName,
  int? patientAge,
  String? patientGender,
  String? chiefComplaint,
  required String patientId,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/consultation/start");
  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "specialty": specialty,
      "patient_language": ?patientLanguage,
      "patient_name": ?patientName,
      "patient_age": ?patientAge,
      "patient_gender": ?patientGender,
      "chief_complaint": ?chiefComplaint,
      "patient_id": patientId,
    }),
  );
  return StartConsultationResponse.fromJson(jsonDecode(response.body));
}

/// GET /api/v1/consultation/{session_id}
Future<SessionStateResponse> getSessionState({
  required String baseUrl,
  required String token,
  required String sessionId,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/consultation/$sessionId");
  final response = await http.get(
    url,
    headers: {"Authorization": "Bearer $token"},
  );
  return SessionStateResponse.fromJson(jsonDecode(response.body));
}

/// POST /api/v1/consultation/{session_id}/answer
/// 400 if session not in questionnaire stage / no active question.
Future<SubmitAnswerResponse> submitAnswer({
  required String token,
  required String sessionId,
  required String answer,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/consultation/$sessionId/answer");
  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({"answer": answer}),
  );
  return SubmitAnswerResponse.fromJson(jsonDecode(response.body));
}

/// POST /api/v1/consultation/{session_id}/answer-audio
/// multipart/form-data upload of an audio file.
/// Uploads audio to R2, transcribes via Deepgram, optionally translates,
/// then processes like /answer. 400 if wrong stage / no active question.
Future<SubmitAnswerResponse> submitAnswerAudio({
  required String token,
  required String sessionId,
  required File audioFile,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/consultation/$sessionId/answer-audio");
  final request = http.MultipartRequest("POST", url)
    ..headers["Authorization"] = "Bearer $token"
    ..files.add(await http.MultipartFile.fromPath("audio_file", audioFile.path));

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  return SubmitAnswerResponse.fromJson(jsonDecode(response.body));
}

/// GET /api/v1/consultation/{session_id}/qa-log
Future<QaLogResponse> getQaLog({
  required String token,
  required String sessionId,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/consultation/$sessionId/qa-log");
  final response = await http.get(
    url,
    headers: {"Authorization": "Bearer $token"},
  );

  return QaLogResponse.fromJson(jsonDecode(response.body));
}

/// PATCH /api/v1/consultation/{session_id}/answer/{question_id}
/// 404 if question_id not found in qa_log.
Future<EditAnswerResponse> editAnswer({
  required String token,
  required String sessionId,
  required String questionId,
  required String answer,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/consultation/$sessionId/answer/$questionId");
  final response = await http.patch(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({"answer": answer}),
  );
  return EditAnswerResponse.fromJson(jsonDecode(response.body));
}

/// POST /api/v1/consultation/{session_id}/prescribe
Future<Prescription> prescribe({
  required String token,
  required String sessionId,
  required String confirmedDiagnosis,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/consultation/$sessionId/prescribe");
  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({"confirmed_diagnosis": confirmedDiagnosis}),
  );
  print(response.body);
  return Prescription.fromJson(jsonDecode(response.body)['prescription']);
}

/// POST /api/v1/consultation/{session_id}/finalize
/// No body. Returns the full ConsultationContext object.
Future<void> finalizeConsultation({
  required String token,
  required String sessionId,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/consultation/$sessionId/finalize");
  final response = await http.post(
    url,
    headers: {"Authorization": "Bearer $token"},
  );
}

/// POST /api/v1/consultation/{session_id}/override
/// field: name of a ConsultationContext attribute. value: any type. reason: optional.
Future<OverrideFieldResponse> overrideField({
  required String token,
  required String sessionId,
  required String field,
  required dynamic value,
  String? reason,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/consultation/$sessionId/override");
  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "field": field,
      "value": value,
      "reason": ?reason,
    }),
  );
  return OverrideFieldResponse.fromJson(jsonDecode(response.body));
}

/// DELETE /api/v1/consultation/{session_id}
/// Note: per API docs, this handler may currently raise a 500/TypeError
/// server-side due to a missing internal argument — test directly.
Future<DeleteConsultationResponse> deleteConsultation({
  required String token,
  required String sessionId,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/consultation/$sessionId");
  final response = await http.delete(
    url,
    headers: {"Authorization": "Bearer $token"},
  );
  return DeleteConsultationResponse.fromJson(jsonDecode(response.body));
}

class SpeechAudio {
  final Uint8List bytes;

  /// Required by AVFoundation on iOS/macOS, which cannot sniff the container
  /// from the byte stream the way ExoPlayer does on Android.
  final String mimeType;

  SpeechAudio({required this.bytes, required this.mimeType});

  /// Container extension for the temp file we hand to the player. AVFoundation
  /// on iOS picks its decoder from the file extension, so this has to match the
  /// actual container rather than defaulting to something convenient.
  String get fileExtension {
    switch (mimeType) {
      case "audio/wav":
      case "audio/x-wav":
        return "wav";
      case "audio/ogg":
        return "ogg";
      case "audio/mp4":
      case "audio/aac":
        return "m4a";
      default:
        return "mp3";
    }
  }
}

/// Falls back to inspecting the container's magic bytes when the server does
/// not send a usable `Content-Type`.
///
/// Returns null when the payload is not recognisable audio. It deliberately
/// does NOT guess a default: labelling arbitrary bytes as mp3 makes the player
/// swallow the failure and produce silence with no error, which is far harder
/// to diagnose than an explicit throw.
String? _sniffAudioMimeType(Uint8List bytes) {
  if (bytes.length >= 3 &&
      ((bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) || // "ID3"
          (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0))) {
    return "audio/mpeg";
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 && bytes[1] == 0x49 && // "RIFF"
      bytes[8] == 0x57 && bytes[9] == 0x41) { // "WAVE"
    return "audio/wav";
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0x4F && bytes[1] == 0x67 && bytes[2] == 0x67) { // "OggS"
    return "audio/ogg";
  }
  if (bytes.length >= 8 &&
      bytes[4] == 0x66 && bytes[5] == 0x74 &&
      bytes[6] == 0x79 && bytes[7] == 0x70) { // "ftyp"
    return "audio/mp4";
  }
  return null;
}

/// Pulls audio out of a JSON envelope, whatever the server chose to call the
/// field. Returns null if this isn't a recognisable JSON-wrapped clip.
Uint8List? _decodeJsonWrappedAudio(Uint8List bodyBytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bodyBytes));
    if (decoded is! Map<String, dynamic>) return null;

    final encoded = decoded["audio"] ??
        decoded["audio_base64"] ??
        decoded["audio_content"] ??
        decoded["data"];
    if (encoded is! String || encoded.isEmpty) return null;

    // Tolerate a data: URI prefix as well as a bare base64 payload.
    final payload = encoded.contains(",")
        ? encoded.substring(encoded.indexOf(",") + 1)
        : encoded;
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}

/// Short readable preview of a non-audio body, for error messages.
String _bodyPreview(Uint8List bytes) {
  try {
    final text = utf8.decode(bytes);
    return text.length > 200 ? '${text.substring(0, 200)}…' : text;
  } catch (_) {
    return '<${bytes.length} bytes of binary, first: '
        '${bytes.take(8).map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}>';
  }
}

Future<SpeechAudio> textToSpeech({
  required String token,
  required String text,
}) async {
  final uri = Uri.parse("$baseUrl/api/v1/note/speak");

  final response = await http.post(
    uri,
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
    body: jsonEncode({"text": text}),
  );

  if (response.statusCode != 200) {
    throw Exception(
      "TTS failed (${response.statusCode}): ${response.body}",
    );
  }

  final contentType = response.headers["content-type"]?.split(";").first.trim();
  print(
    "🔊 [DEBUG] TTS response: ${response.statusCode}, "
    "content-type: $contentType, ${response.bodyBytes.length} bytes",
  );

  // Raw audio body — the common case.
  final directMime = _sniffAudioMimeType(response.bodyBytes);
  if (directMime != null) {
    return SpeechAudio(
      bytes: response.bodyBytes,
      mimeType: contentType != null && contentType.startsWith("audio/")
          ? contentType
          : directMime,
    );
  }

  // Not audio. The endpoint declares `application/json`, so the clip may be
  // base64 inside an envelope. Try that regardless of the declared
  // content-type, since the header has already proven unreliable.
  final unwrapped = _decodeJsonWrappedAudio(response.bodyBytes);
  if (unwrapped != null) {
    final unwrappedMime = _sniffAudioMimeType(unwrapped);
    print(
      "🔊 [DEBUG] Decoded ${unwrapped.length} bytes of base64 TTS audio "
      "(container: ${unwrappedMime ?? 'unrecognised'})",
    );
    if (unwrappedMime != null) {
      return SpeechAudio(bytes: unwrapped, mimeType: unwrappedMime);
    }
  }

  // Give up loudly rather than handing unplayable bytes to the player, which
  // would just produce silence with no error at all.
  throw Exception(
    "TTS response is not playable audio (content-type: $contentType, "
    "${response.bodyBytes.length} bytes): ${_bodyPreview(response.bodyBytes)}",
  );
}


