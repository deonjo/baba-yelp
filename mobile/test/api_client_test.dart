import 'dart:convert';

import 'package:baba_yelp/api/api_client.dart';
import 'package:baba_yelp/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_backend.dart';

void main() {
  test('sends the bearer token and JSON body', () async {
    final backend = FakeBackend()
      ..on('POST', '/restaurants/1/reviews', {'reviews': []}, status: 201);
    final api = backend.api(token: 'secret');

    await api.submitReviews(1, const [ReviewInput(dishId: 11, rating: 5, body: 'Yum')]);

    final request = backend.requests.single;
    expect(request.url.toString(), 'http://api.test/api/v1/restaurants/1/reviews');
    expect(request.headers['Authorization'], 'Bearer secret');
    expect(jsonDecode(request.body), {
      'reviews': [
        {'dish_id': 11, 'rating': 5, 'body': 'Yum'},
      ],
    });
  });

  test('searches restaurants with the query parameters', () async {
    final backend = FakeBackend()
      ..on('GET', '/restaurants', paged('restaurants', [restaurantJson(1, 'Thai Orchid Kitchen', distance: 0.2)]));

    final page = await backend.api().searchRestaurants(
          const RestaurantSearchQuery(
            dishes: [Dish(id: 11, name: 'Pad Thai')],
            location: SearchLocation(label: 'Here', latitude: 37.5, longitude: -121.9),
          ),
          page: 2,
        );

    expect(page.items.single.name, 'Thai Orchid Kitchen');
    expect(backend.requests.single.url.queryParameters, {
      'dish_ids': '11',
      'lat': '37.5',
      'lng': '-121.9',
      'radius': '10.0',
      'sort': 'distance',
      'match': 'all',
      'page': '2',
      'per_page': '20',
    });
  });

  test('turns validation errors into field messages', () async {
    final backend = FakeBackend()
      ..on('POST', '/users', {
        'error': 'Email has already been taken',
        'errors': {
          'email': ['has already been taken'],
        },
      }, status: 422);

    final error = await backend.api().signUp(name: 'A', email: 'a@example.com', password: 'password123').then<ApiException?>(
          (_) => null,
          onError: (Object e) => e as ApiException,
        );

    expect(error!.statusCode, 422);
    expect(error.fieldError('email'), 'Has already been taken');
    expect(error.fieldError('name'), isNull);
  });

  test('reports a restaurant that already exists', () async {
    final backend = FakeBackend()
      ..on('POST', '/restaurants', {
        'error': 'Thai Orchid Kitchen is already listed at 1 State St.',
        'restaurant': restaurantJson(1, 'Thai Orchid Kitchen'),
      }, status: 409);

    expect(
      () => backend.api(token: 't').createRestaurant(const NewRestaurant(name: 'Thai Orchid Kitchen', address: '1 State St', city: 'Fremont', state: 'CA')),
      throwsA(isA<DuplicateRestaurantException>().having((e) => e.existing.name, 'existing', 'Thai Orchid Kitchen')),
    );
  });

  test('explains which reviews failed', () async {
    final backend = FakeBackend()
      ..on('POST', '/restaurants/1/reviews', {
        'error': 'Your reviews could not be saved.',
        'errors': [
          {
            'dish_id': 11,
            'dish_name': 'Pad Thai',
            'errors': ['Rating must be in 1..5'],
          },
        ],
      }, status: 422);

    expect(
      () => backend.api(token: 't').submitReviews(1, const [ReviewInput(dishId: 11, rating: 9)]),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Pad Thai: Rating must be in 1..5'))),
    );
  });

  test('tells the app when its token is rejected', () async {
    var rejected = 0;
    final backend = FakeBackend()..on('GET', '/me', {'error': 'Please sign in to continue.'}, status: 401);
    final api = backend.api(token: 'revoked')..onUnauthorized = () => rejected++;

    await expectLater(api.me(), throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'unauthorized', isTrue)));
    expect(rejected, 1);
  });

  test('maps network failures to a friendly message', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test/',
      httpClient: MockClient((_) async => throw http.ClientException('Connection refused')),
    );

    await expectLater(
      api.cuisines(),
      throwsA(isA<ApiException>().having((e) => e.isNetworkError, 'network', isTrue)),
    );
  });

  test('reverse geocoding returns null when nothing is found', () async {
    final backend = FakeBackend()..on('GET', '/geocode/reverse', {'error': 'Not found.'}, status: 404);
    expect(await backend.api().reverseGeocode(fremont), isNull);
  });
}
