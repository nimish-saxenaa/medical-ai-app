import 'dart:convert';
import 'dart:developer' as dev;
import 'package:clinical_ai_app/Services/Authentication/navigation_service.dart';
import 'package:http/http.dart' as http;
import '../../Models/patient_list_model.dart';
import '../../Models/patient_model.dart';
import '../../Models/patient_response_history_model.dart';
import '../Authentication/access_token.dart';
import '../Authentication/auth_service.dart';

String baseUrl = "https://med-history-agent.decrackle.io";

Future<Patient> createPatient({
  required String name,
  required int age,
  String? gender,
  String? phone,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/patients");

  Future<http.Response> sendRequest(String token) {
    return http.post(
      url,
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
    );
  }

  String token = await AccessTokenService.getToken() ?? "";
  var response = await sendRequest(token);

  if (response.statusCode == 401) {
    final result = await refreshTokens();

    final newAccessToken = result['access_token'] ?? result['accessToken'];
    final newRefreshToken = result['refresh_token'] ?? result['refreshToken'];

    if (newAccessToken != null && newRefreshToken != null) {
      await AccessTokenService.saveAccessToken(newAccessToken.toString());
      await AccessTokenService.saveRefreshToken(newRefreshToken.toString());

      response = await sendRequest(newAccessToken.toString());
    }

    if (response.statusCode == 401) {
      logout();
      throw Exception("Unauthorized");
    }
  }

  return Patient.fromJson(jsonDecode(response.body));
}

Future<PatientListProvider> listPatients() async {
  Uri url = Uri.parse("$baseUrl/api/v1/patients");

  Future<http.Response> sendRequest(String token) {
    return http.get(url, headers: {"Authorization": "Bearer $token"});
  }

  String token = await AccessTokenService.getToken() ?? "";
  var response = await sendRequest(token);

  if (response.statusCode == 401) {
    final result = await refreshTokens();

    final newAccessToken = result['access_token'] ?? result['accessToken'];
    final newRefreshToken = result['refresh_token'] ?? result['refreshToken'];

    if (newAccessToken != null && newRefreshToken != null) {
      await AccessTokenService.saveAccessToken(newAccessToken.toString());
      await AccessTokenService.saveRefreshToken(newRefreshToken.toString());

      response = await sendRequest(newAccessToken.toString());
    }

    if (response.statusCode == 401) {
      logout();
      throw Exception("Unauthorized");
    }
  }

  return PatientListProvider.fromJson(jsonDecode(response.body));
}

Future<Patient> getPatient({required String patientId}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/patients/$patientId");

  Future<http.Response> sendRequest(String token) {
    return http.get(url, headers: {"Authorization": "Bearer $token"});
  }

  String token = await AccessTokenService.getToken() ?? "";
  var response = await sendRequest(token);

  if (response.statusCode == 401) {
    final result = await refreshTokens();

    final newAccessToken = result['access_token'] ?? result['accessToken'];
    final newRefreshToken = result['refresh_token'] ?? result['refreshToken'];

    if (newAccessToken != null && newRefreshToken != null) {
      await AccessTokenService.saveAccessToken(newAccessToken.toString());
      await AccessTokenService.saveRefreshToken(newRefreshToken.toString());

      response = await sendRequest(newAccessToken.toString());
    }

    if (response.statusCode == 401) {
      logout();
      throw Exception("Unauthorized");
    }
  }

  return Patient.fromJson(jsonDecode(response.body));
}

Future<PatientHistoryResponse> getPatientHistory({
  required String patientId,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/patients/$patientId/history");

  Future<http.Response> sendRequest(String token) {
    return http.get(url, headers: {"Authorization": "Bearer $token"});
  }

  String token = await AccessTokenService.getToken() ?? "";
  var response = await sendRequest(token);

  if (response.statusCode == 401) {
    final result = await refreshTokens();

    final newAccessToken = result['access_token'] ?? result['accessToken'];
    final newRefreshToken = result['refresh_token'] ?? result['refreshToken'];

    if (newAccessToken != null && newRefreshToken != null) {
      await AccessTokenService.saveAccessToken(newAccessToken.toString());
      await AccessTokenService.saveRefreshToken(newRefreshToken.toString());

      response = await sendRequest(newAccessToken.toString());
    }

    if (response.statusCode == 401) {
      logout();
      throw Exception("Unauthorized");
    }
  }

  return PatientHistoryResponse.fromJson(jsonDecode(response.body));
}

Future<Patient> updatePatient({
  required String patientId,
  String? name,
  int? age,
  String? gender,
  String? phone,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/patients/$patientId");

  Future<http.Response> sendRequest(String token) {
    return http.patch(
      url,
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
    );
  }

  String token = await AccessTokenService.getToken() ?? "";
  var response = await sendRequest(token);

  if (response.statusCode == 401) {
    final result = await refreshTokens();

    final newAccessToken = result['access_token'] ?? result['accessToken'];
    final newRefreshToken = result['refresh_token'] ?? result['refreshToken'];

    if (newAccessToken != null && newRefreshToken != null) {
      await AccessTokenService.saveAccessToken(newAccessToken.toString());
      await AccessTokenService.saveRefreshToken(newRefreshToken.toString());

      response = await sendRequest(newAccessToken.toString());
    }

    if (response.statusCode == 401) {
      logout();
      throw Exception("Unauthorized");
    }
  }

  return Patient.fromJson(jsonDecode(response.body));
}
