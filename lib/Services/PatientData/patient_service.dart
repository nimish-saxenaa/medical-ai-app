import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Models/patient_list_model.dart';
import '../../Models/patient_model.dart';
import '../../Models/patient_response_history_model.dart';
import '../Authentication/auth_service.dart';

String baseUrl = "https://med-history-agent.decrackle.io";

Future<Patient> createPatient({
  required String name,
  required int age,
  String? gender,
  String? phone,
}) async {
  final response = await TokenManager.handle401((token) => http.post(
    Uri.parse("$baseUrl/api/v1/patients"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "name": name,
      "age": age,
      "gender": gender,
      "phone": phone,
    }),
  ));

  return Patient.fromJson(jsonDecode(response.body));
}

Future<PatientListProvider> listPatients() async {
  final response = await TokenManager.handle401((token) => http.get(
    Uri.parse("$baseUrl/api/v1/patients"),
    headers: {"Authorization": "Bearer $token"},
  ));

  return PatientListProvider.fromJson(jsonDecode(response.body));
}

Future<Patient> getPatient({required String patientId}) async {
  final response = await TokenManager.handle401((token) => http.get(
    Uri.parse("$baseUrl/api/v1/patients/$patientId"),
    headers: {"Authorization": "Bearer $token"},
  ));

  return Patient.fromJson(jsonDecode(response.body));
}

Future<PatientHistoryResponse> getPatientHistory({
  required String patientId,
}) async {
  final response = await TokenManager.handle401((token) => http.get(
    Uri.parse("$baseUrl/api/v1/patients/$patientId/history"),
    headers: {"Authorization": "Bearer $token"},
  ));

  return PatientHistoryResponse.fromJson(jsonDecode(response.body));
}

Future<Patient> updatePatient({
  required String patientId,
  String? name,
  int? age,
  String? gender,
  String? phone,
}) async {
  final response = await TokenManager.handle401((token) => http.patch(
    Uri.parse("$baseUrl/api/v1/patients/$patientId"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "name": name,
      "age": age,
      "gender": gender,
      "phone": phone,
    }),
  ));

  return Patient.fromJson(jsonDecode(response.body));
}
