import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Models/consultation_location_model.dart';

/// Captures and persists the location a consultation was recorded at.
///
/// Storage is local-only (SharedPreferences, keyed by session id) because the
/// consultation API has no location field. Every method here fails soft: a
/// denied permission, disabled GPS or a geocoder timeout returns null rather
/// than throwing, so a consultation is never blocked by location capture.
class ConsultationLocationService {
  static const String _keyPrefix = 'consultation_location_';

  /// Resolves the device's current city/state/country.
  ///
  /// Returns null if location services are off, permission is denied, or the
  /// lookup fails — callers should treat that as "no location recorded".
  static Future<ConsultationLocation?> captureCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Reverse geocoding needs network; keep the coordinates either way so the
      // record still has something if only the name lookup fails.
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          return ConsultationLocation(
            city: _firstNonEmpty([
              place.locality,
              place.subAdministrativeArea,
              place.subLocality,
            ]),
            state: _firstNonEmpty([place.administrativeArea]),
            country: _firstNonEmpty([place.country]),
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      } catch (_) {
        // Geocoding can fail silently; fall back to coordinates
      }

      return ConsultationLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return null;
    }
  }

  /// Captures the current location and stores it against [sessionId].
  static Future<void> captureAndSaveForSession(String sessionId) async {
    final location = await captureCurrentLocation();
    if (location == null || location.isEmpty) return;
    await saveForSession(sessionId, location);
  }

  static Future<void> saveForSession(
    String sessionId,
    ConsultationLocation location,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_keyPrefix$sessionId',
        jsonEncode(location.toJson()),
      );
    } catch (_) {
      // Ignored: non-critical preference save failure
    }
  }

  /// Returns the stored location for [sessionId], or null if none was recorded.
  static Future<ConsultationLocation?> getForSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$sessionId');
      if (raw == null) return null;
      final location = ConsultationLocation.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return location.isEmpty ? null : location;
    } catch (e) {
      return null;
    }
  }

  /// Bulk lookup for a history list — returns only the sessions that have one.
  static Future<Map<String, ConsultationLocation>> getForSessions(
    List<String> sessionIds,
  ) async {
    final result = <String, ConsultationLocation>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final sessionId in sessionIds) {
        final raw = prefs.getString('$_keyPrefix$sessionId');
        if (raw == null) continue;
        final location = ConsultationLocation.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (!location.isEmpty) result[sessionId] = location;
      }
    } catch (_) {
      // Ignored: lookup error falls back to partial results
    }
    return result;
  }

  /// Drops the stored location when its consultation is deleted.
  static Future<void> removeForSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$sessionId');
    } catch (_) {
      // Ignored: deletion error
    }
  }

  static String? _firstNonEmpty(List<String?> candidates) {
    for (final value in candidates) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
