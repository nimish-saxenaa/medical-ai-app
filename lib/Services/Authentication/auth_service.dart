import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'access_token.dart';
import 'navigation_service.dart';

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
  final data = jsonDecode(response.body);
  if (data['access_token'] != null) {
    await AccessTokenService.saveAccessToken(data['access_token'], data['expires_in']);
    await AccessTokenService.saveRefreshToken(data['refresh_token']);
    if (data['user'] != null) {
      await AccessTokenService.saveUserData(data['user']);
    }
  }
  return data;
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
  final data = jsonDecode(response.body);
  if (data['access_token'] != null) {
    await AccessTokenService.saveAccessToken(data['access_token'], data['expires_in']);
    await AccessTokenService.saveRefreshToken(data['refresh_token']);
    if (data['user'] != null) {
      await AccessTokenService.saveUserData(data['user']);
    }
  }
  return data;
}

Future<Map<String, dynamic>> refreshTokens() async {
  Uri url = Uri.parse(
    "$baseUrl/api/v1/auth/refresh",
  );
  final refreshToken = await AccessTokenService.getRequestToken();
  if (refreshToken == null) return {"detail": "No refresh token"};
  
  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Cookie": "refresh_token=$refreshToken",
    },
  );
  
  final data = jsonDecode(response.body);
  if (data['access_token'] != null) {
    await AccessTokenService.saveAccessToken(data['access_token'], data['expires_in']);
    // Refresh tokens often return a new refresh token too
    if (data['refresh_token'] != null) {
      await AccessTokenService.saveRefreshToken(data['refresh_token']);
    }
    if (data['user'] != null) {
      await AccessTokenService.saveUserData(data['user']);
    }
  }
  return data;
}

class TokenManager {
  static Future<String?>? _refreshFuture;

  /// Ensures we have a valid access token.
  /// If the token is near expiry, it refreshes it.
  /// Prevents multiple simultaneous refreshes.
  static Future<String?> getValidAccessToken() async {
    final token = await AccessTokenService.getToken();
    if (token == null) return null;

    if (await AccessTokenService.isTokenNearExpiry()) {
      return await refreshAndGetToken();
    }
    
    return token;
  }

  /// Force a refresh and return the new token.
  /// Handles simultaneous requests by returning the same future.
  static Future<String?> refreshAndGetToken() async {
    if (_refreshFuture != null) {
      return await _refreshFuture;
    }

    _refreshFuture = _performRefresh();
    try {
      final newToken = await _refreshFuture;
      return newToken;
    } finally {
      _refreshFuture = null;
    }
  }

  static Future<String?> _performRefresh() async {
    try {
      final result = await refreshTokens();
      final newAccessToken = result['access_token'] ?? result['accessToken'];
      if (newAccessToken != null) {
        return newAccessToken.toString();
      }
    } catch (e) {
      debugPrint("Token refresh failed: $e");
    }
    return null;
  }

  /// Handles 401 responses by refreshing once and retrying the request.
  /// If retry fails with 401, logs out the user.
  static Future<http.Response> handle401(
    Future<http.Response> Function(String token) requestAction,
  ) async {
    // 1. Initial attempt with current token logic
    String? token = await getValidAccessToken();
    if (token == null) {
      logout();
      throw Exception("Unauthorized: No token available");
    }

    var response = await requestAction(token);

    if (response.statusCode == 401) {
      // 2. Refresh specifically on 401
      token = await refreshAndGetToken();
      if (token == null) {
        logout();
        throw Exception("Unauthorized: Refresh failed");
      }

      // 3. Retry once
      response = await requestAction(token);

      if (response.statusCode == 401) {
        // 4. Still 401, logout
        logout();
        throw Exception("Unauthorized: Session invalid");
      }
    }

    return response;
  }
}

/// Legacy helper for getValidAccessToken (kept for compatibility)
Future<String?> getValidAccessToken() => TokenManager.getValidAccessToken();
