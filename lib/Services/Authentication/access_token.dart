import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccessTokenService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveAccessToken(String accessToken, [int? expiresInSeconds]) async {
    await _storage.write(
      key: "access_token",
      value: accessToken,
    );
    // Requirements Part 1: Default to 900 seconds (15 mins) if expires_in is missing
    final effectiveExpiresIn = expiresInSeconds ?? 900;
    final expiry = DateTime.now().add(Duration(seconds: effectiveExpiresIn));
    await _storage.write(
      key: "access_token_expiry",
      value: expiry.toIso8601String(),
    );
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(
      key: "refresh_token",
      value: refreshToken,
    );
  }

  static Future<DateTime?> getAccessTokenExpiry() async {
    final expiryStr = await _storage.read(key: "access_token_expiry");
    if (expiryStr == null) return null;
    return DateTime.tryParse(expiryStr);
  }

  static Future<bool> isTokenNearExpiry() async {
    final expiry = await getAccessTokenExpiry();
    if (expiry == null) return true;
    // 1 minute safety margin
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 1)));
  }

  static Future<void> saveUserName(String name) async {
    await _storage.write(
      key: "user_name",
      value: name,
    );
  }

  static Future<void> saveUserEmail(String email) async {
    await _storage.write(
      key: "user_email",
      value: email,
    );
  }

  static Future<void> saveUserId(String id) async {
    await _storage.write(
      key: "user_id",
      value: id,
    );
  }

  static Future<void> saveUserData(Map<String, dynamic> user) async {
    if (user['name'] != null) {
      await saveUserName(user['name'].toString());
    }
    if (user['email'] != null) {
      await saveUserEmail(user['email'].toString());
    }
    if (user['id'] != null) {
      await saveUserId(user['id'].toString());
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(
      key: "access_token",
    );
  }

  static Future<String?> getRequestToken() async {
    return await _storage.read(
      key: "refresh_token",
    );
  }

  static Future<String?> getUserName() async {
    return await _storage.read(
      key: "user_name",
    );
  }

  static Future<String?> getUserEmail() async {
    return await _storage.read(
      key: "user_email",
    );
  }

  static Future<String?> getUserId() async {
    return await _storage.read(
      key: "user_id",
    );
  }

  static Future<void> deleteToken() async {
    await _storage.delete(
      key: "access_token",
    );
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }

}