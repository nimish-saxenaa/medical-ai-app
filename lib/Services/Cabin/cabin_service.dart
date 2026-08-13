import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Models/cabin_models.dart';
import '../Authentication/access_token.dart';
import '../Authentication/auth_service.dart';
import '../Authentication/navigation_service.dart'; // Assuming logout() is here as in patient_service.dart

String baseUrl = "https://med-history-agent.decrackle.io";

Future<CabinSession> createCabinSession({
  required String specialty,
  String? patientId,
  required String patientName,
  bool consent = true,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/cabin/");

  Future<http.Response> sendRequest(String token) {
    return http.post(
      url,
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

  return CabinSession.fromJson(jsonDecode(response.body));
}

Future<CabinSessionList> listCabinSessions({
  String? patientId,
  int? limit,
}) async {
  Map<String, String> queryParams = {};
  if (patientId != null) queryParams['patient_id'] = patientId;
  if (limit != null) queryParams['limit'] = limit.toString();

  Uri url = Uri.parse("$baseUrl/api/v1/cabin/").replace(queryParameters: queryParams);

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

  return CabinSessionList.fromJson(jsonDecode(response.body));
}

Future<CabinSession> getCabinSession(String sessionId) async {
  Uri url = Uri.parse("$baseUrl/api/v1/cabin/$sessionId");

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

  return CabinSession.fromJson(jsonDecode(response.body));
}

Future<CabinRecord> getCabinRecord(String sessionId) async {
  Uri url = Uri.parse("$baseUrl/api/v1/cabin/$sessionId/record");

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

  return CabinRecord.fromJson(jsonDecode(response.body));
}

Future<void> overrideCabinField({
  required String sessionId,
  required String field,
  required dynamic value,
  required String reason,
}) async {
  Uri url = Uri.parse("$baseUrl/api/v1/cabin/$sessionId/override");

  Future<http.Response> sendRequest(String token) {
    return http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "field": field,
        "value": value,
        "reason": reason,
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

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception("Failed to override field: ${response.body}");
  }
}

Future<void> deleteCabinSession(String sessionId) async {
  Uri url = Uri.parse("$baseUrl/api/v1/cabin/$sessionId");

  Future<http.Response> sendRequest(String token) {
    return http.delete(url, headers: {"Authorization": "Bearer $token"});
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

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception("Failed to delete session: ${response.body}");
  }
}
