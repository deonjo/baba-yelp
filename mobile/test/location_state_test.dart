import 'dart:async';

import 'package:baba_yelp/models/models.dart';
import 'package:baba_yelp/services/location_service.dart';
import 'package:baba_yelp/state/location_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_backend.dart';

/// A location service whose answer arrives when the test says so.
class SlowLocationService implements LocationService {
  final pending = Completer<GeoPoint>();

  @override
  Future<GeoPoint> currentPosition() => pending.future;

  @override
  Future<void> openSettings() async {}
}

class DeniedLocationService implements LocationService {
  @override
  Future<GeoPoint> currentPosition() async => throw const LocationException('Location permission was denied.');

  @override
  Future<void> openSettings() async {}
}

const fremontPlace = Place(label: 'Fremont, CA', latitude: 37.5482697, longitude: -121.988571);

void main() {
  test('uses the current position and names the area', () async {
    final backend = FakeBackend()..stubBasics();
    final state = LocationState(locationService: FakeLocationService(), api: backend.api());

    await state.useCurrentLocation();
    expect(state.location!.isCurrent, isTrue);
    expect(state.location!.latitude, fremont.latitude);

    await pumpEventQueue();
    expect(state.location!.label, 'Current location · Fremont, CA');
  });

  test('a place picked while locating wins over the late GPS fix', () async {
    final backend = FakeBackend()..stubBasics();
    final gps = SlowLocationService();
    final state = LocationState(locationService: gps, api: backend.api());

    final locating = state.useCurrentLocation();
    expect(state.locating, isTrue);

    state.usePlace(fremontPlace);
    expect(state.locating, isFalse);

    gps.pending.complete(const GeoPoint(40.7128, -74.0060));
    await locating;
    expect(state.location!.label, 'Fremont, CA');
    expect(state.location!.isCurrent, isFalse);
  });

  test('reports why the location is unavailable', () async {
    final state = LocationState(locationService: DeniedLocationService(), api: FakeBackend().api());

    await state.useCurrentLocation();
    expect(state.location, isNull);
    expect(state.locating, isFalse);
    expect(state.error!.message, 'Location permission was denied.');

    state.usePlace(fremontPlace);
    expect(state.error, isNull);
  });
}
