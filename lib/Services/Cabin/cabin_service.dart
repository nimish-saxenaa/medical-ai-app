import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Models/cabin_models.dart';
import '../Authentication/auth_service.dart';

String baseUrl = "https://med-history-agent.decrackle.io";

Future<CabinSession> createCabinSession({
  required String specialty,
  String? patientId,
  required String patientName,
  bool consent = true,
}) async {
  final response = await TokenManager.handle401((token) => http.post(
    Uri.parse("$baseUrl/api/v1/cabin/"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "specialty": specialty,
      "patient_id": patientId,
      "patient_name": patientName,
      "consent": consent,
    }),
  ));

  return CabinSession.fromJson(jsonDecode(response.body));
}

Future<CabinSessionList> listCabinSessions({
  String? patientId,
  int? limit,
}) async {
  Map<String, String> queryParams = {};
  if (patientId != null) queryParams['patient_id'] = patientId;
  if (limit != null) queryParams['limit'] = limit.toString();

  final url = Uri.parse("$baseUrl/api/v1/cabin/").replace(queryParameters: queryParams);

  final response = await TokenManager.handle401((token) => http.get(
    url,
    headers: {"Authorization": "Bearer $token"},
  ));

  return CabinSessionList.fromJson(jsonDecode(response.body));
}

Future<CabinSession> getCabinSession(String sessionId) async {
  final response = await TokenManager.handle401((token) => http.get(
    Uri.parse("$baseUrl/api/v1/cabin/$sessionId"),
    headers: {"Authorization": "Bearer $token"},
  ));

  return CabinSession.fromJson(jsonDecode(response.body));
}

Future<CabinRecord> getCabinRecord(String sessionId) async {
  final response = await TokenManager.handle401((token) => http.get(
    Uri.parse("$baseUrl/api/v1/cabin/$sessionId/record"),
    headers: {"Authorization": "Bearer $token"},
  ));

  return CabinRecord.fromJson(jsonDecode(response.body));
}

Future<void> overrideCabinField({
  required String sessionId,
  required String field,
  required dynamic value,
  required String reason,
}) async {
  final response = await TokenManager.handle401((token) => http.post(
    Uri.parse("$baseUrl/api/v1/cabin/$sessionId/override"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "field": field,
      "value": value,
      "reason": reason,
    }),
  ));

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception("Failed to override field: ${response.body}");
  }
}

Future<void> deleteCabinSession(String sessionId) async {
  final response = await TokenManager.handle401((token) => http.delete(
    Uri.parse("$baseUrl/api/v1/cabin/$sessionId"),
    headers: {"Authorization": "Bearer $token"},
  ));

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception("Failed to delete session: ${response.body}");
  }
}
