class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// A geocoding result, e.g. "Fremont, CA" or "39170 State St, Fremont, CA".
class Place {
  const Place({
    required this.label,
    required this.latitude,
    required this.longitude,
    this.address,
    this.street,
    this.city,
    this.state,
    this.zipCode,
  });

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        label: json['label'] as String,
        address: json['address'] as String?,
        street: json['street'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        zipCode: json['zip_code'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  final String label;
  final String? address;
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final double latitude;
  final double longitude;

  GeoPoint get point => GeoPoint(latitude, longitude);
}

/// Where the user wants to search from: their current position or a place
/// they picked.
class SearchLocation {
  const SearchLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
    this.isCurrent = false,
  });

  final String label;
  final double latitude;
  final double longitude;
  final bool isCurrent;

  GeoPoint get point => GeoPoint(latitude, longitude);
}
