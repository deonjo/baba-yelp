import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../services/location_service.dart';

/// The location searches are made from: the device's position or a place the
/// user picked (e.g. "Fremont, CA").
class LocationState extends ChangeNotifier {
  LocationState({required this.locationService, required this.api});

  final LocationService locationService;
  final ApiClient api;

  SearchLocation? _location;
  bool _locating = false;
  LocationException? _error;

  /// Bumped whenever the location changes, so a slow GPS fix can't overwrite
  /// a place the user picked in the meantime.
  int _request = 0;

  SearchLocation? get location => _location;
  bool get locating => _locating;
  LocationException? get error => _error;

  Future<void> useCurrentLocation() async {
    final request = ++_request;
    _locating = true;
    _error = null;
    notifyListeners();
    try {
      final point = await locationService.currentPosition();
      if (request != _request) return;
      final current = SearchLocation(
        label: 'Current location',
        latitude: point.latitude,
        longitude: point.longitude,
        isCurrent: true,
      );
      _location = current;
      _locating = false;
      notifyListeners();
      _describe(current);
    } on LocationException catch (error) {
      if (request != _request) return;
      _error = error;
      _locating = false;
      notifyListeners();
    }
  }

  void usePlace(Place place) {
    _request++;
    _locating = false;
    _location = SearchLocation(
      label: place.label,
      latitude: place.latitude,
      longitude: place.longitude,
    );
    _error = null;
    notifyListeners();
  }

  /// Adds the city name to "Current location" once we know it.
  Future<void> _describe(SearchLocation current) async {
    try {
      final place = await api.reverseGeocode(current.point);
      final area = [place?.city, place?.state].whereType<String>().join(', ');
      if (area.isEmpty || !identical(_location, current)) return;
      _location = SearchLocation(
        label: 'Current location · $area',
        latitude: current.latitude,
        longitude: current.longitude,
        isCurrent: true,
      );
      notifyListeners();
    } on ApiException {
      // The plain label is fine.
    }
  }
}
