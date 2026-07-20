/// Location where a consultation took place.
///
/// Captured from the device GPS at consultation start and reverse-geocoded to
/// a city / state / country. Stored locally per session — the backend does not
/// carry this field yet, so consultations recorded before this feature (or on
/// another device) simply have no location.
class ConsultationLocation {
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;

  ConsultationLocation({
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
  });

  /// City, State, Country — skipping any part the geocoder could not resolve.
  String get fullLocation =>
      [city, state, country].where((e) => e != null && e.trim().isNotEmpty).join(', ');

  /// A location with nothing worth showing is treated as no location at all.
  bool get isEmpty => fullLocation.isEmpty;

  factory ConsultationLocation.fromJson(Map<String, dynamic> json) {
    return ConsultationLocation(
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'state': state,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  String toString() => 'ConsultationLocation($fullLocation)';
}
