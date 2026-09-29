import 'package:geolocator/geolocator.dart';

import '../models/place.dart';

class LocationException implements Exception {
  const LocationException(this.message, {this.canOpenSettings = false});

  final String message;
  final bool canOpenSettings;

  @override
  String toString() => message;
}

/// The device's position. Abstracted so tests can use a fixed location.
abstract class LocationService {
  /// Throws [LocationException] with a user-facing message on failure.
  Future<GeoPoint> currentPosition();

  Future<void> openSettings();
}

class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<GeoPoint> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
          'Location services are turned off. Turn them on or pick a place instead.',
          canOpenSettings: true);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
          'Location permission was denied. Pick a place to search near instead.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
          'Location access is off for Baba Yelp. Allow it in Settings or pick a place instead.',
          canOpenSettings: true);
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (_) {
      throw const LocationException(
          "Couldn't get your location. Try again or pick a place instead.");
    }
  }

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();
}
