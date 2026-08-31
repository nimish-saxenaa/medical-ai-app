import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'access_token.dart';

String baseUrl = "https://med-history-agent.decrackle.io";

Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  Uri url = Uri.parse(
    "$baseUrl/api/v1/auth/login",
  );
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email, "password": password}),
  );
  return jsonDecode(response.body);
}

Future<Map<String, dynamic>> createAccount({
  required String name,
  required String email,
  required String password,
}) async {
  Uri url = Uri.parse(
    "$baseUrl/api/v1/auth/register",
  );
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"name": name, "email": email, "password": password}),
  );
  return jsonDecode(response.body);
}

Future<Map<String, dynamic>> refreshTokens() async {
  Uri url = Uri.parse(
    "$baseUrl/api/v1/auth/refresh",
  );
  final refreshToken = await AccessTokenService.getRequestToken();
  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Cookie": "refresh_token=$refreshToken",
    },
  );
  return jsonDecode(response.body);
}

/// Ensures we have a valid access token. 
/// If the current one is likely expired (or on demand), it attempts a refresh.
Future<String?> getValidAccessToken() async {
  String? token = await AccessTokenService.getToken();
  if (token == null) return null;

  // We do a "pre-emptive" refresh by checking if the token works 
  // or simply attempting a refresh if we're unsure.
  // For raw WebSocket connections, it's safer to refresh right before connecting
  // if we haven't refreshed in a while.
  
  // However, since we don't have expiration tracking yet, 
  // the most robust way is to just call refreshTokens() and update storage.
  try {
    final result = await refreshTokens();
    final newAccessToken = result['access_token'] ?? result['accessToken'];
    final newRefreshToken = result['refresh_token'] ?? result['refreshToken'];

    if (newAccessToken != null && newRefreshToken != null) {
      await AccessTokenService.saveAccessToken(newAccessToken.toString());
      await AccessTokenService.saveRefreshToken(newRefreshToken.toString());

      if (result['user'] != null) {
        await AccessTokenService.saveUserData(result['user']);
      }
      return newAccessToken.toString();
    }
  } catch (e) {
  }
  
  return token; // Fallback to current token if refresh fails
}



