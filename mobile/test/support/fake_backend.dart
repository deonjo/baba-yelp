import 'dart:convert';

import 'package:baba_yelp/api/api_client.dart';
import 'package:baba_yelp/models/models.dart';
import 'package:baba_yelp/services/location_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const fremont = GeoPoint(37.5483, -121.9886);

class FakeLocationService implements LocationService {
  FakeLocationService([this.point = fremont]);

  GeoPoint point;

  @override
  Future<GeoPoint> currentPosition() async => point;

  @override
  Future<void> openSettings() async {}
}

Map<String, dynamic> cuisineJson(int id, String name, String emoji) =>
    {'id': id, 'name': name, 'emoji': emoji, 'dishes_count': 2};

final thai = cuisineJson(2, 'Thai', '🇹🇭');

Map<String, dynamic> dishJson(int id, String name, {int restaurants = 3}) => {
      'id': id,
      'name': name,
      'aliases': <String>[],
      'description': null,
      'cuisine': {'id': 2, 'name': 'Thai', 'emoji': '🇹🇭'},
      'restaurants_count': restaurants,
    };

final padThai = dishJson(11, 'Pad Thai');
final tomYum = dishJson(12, 'Tom Yum Soup');

Map<String, dynamic> restaurantJson(
  int id,
  String name, {
  double? distance,
  double? rating,
  int reviews = 0,
  List<Map<String, dynamic>> dishes = const [],
}) =>
    {
      'id': id,
      'name': name,
      'address': '$id State St',
      'city': 'Fremont',
      'state': 'CA',
      'zip_code': '94538',
      'phone': '(510) 555-01$id',
      'full_address': '$id State St, Fremont, CA 94538',
      'latitude': 37.55,
      'longitude': -121.98,
      'dishes_count': dishes.length,
      'distance_miles': distance,
      'rating': rating,
      'reviews_count': reviews,
      'dishes': dishes,
    };

Map<String, dynamic> menuItemJson(int id, int restaurantId, Map<String, dynamic> dish,
        {double? rating, int reviews = 0}) =>
    {
      'id': id,
      'restaurant_id': restaurantId,
      'dish_id': dish['id'],
      'name': dish['name'],
      'cuisine': {'id': 2, 'name': 'Thai', 'emoji': '🇹🇭'},
      'average_rating': rating,
      'reviews_count': reviews,
    };

Map<String, dynamic> paged(String key, List<dynamic> items, {int page = 1, int totalPages = 1}) => {
      key: items,
      'meta': {'page': page, 'per_page': 20, 'total_count': items.length, 'total_pages': totalPages},
    };

const demoUser = {'id': 1, 'name': 'Demo Diner', 'email': 'demo@example.com', 'reviews_count': 0};

/// A scripted Rails API: routes requests by method + path and records them.
class FakeBackend {
  FakeBackend() {
    client = MockClient(_handle);
  }

  late final MockClient client;
  final requests = <http.Request>[];
  final _routes = <String, Future<http.Response> Function(http.Request)>{};

  ApiClient api({String? token}) => ApiClient(baseUrl: 'http://api.test', httpClient: client)..token = token;

  void on(String method, String path, Object? body, {int status = 200}) =>
      _routes['$method $path'] = (_) async => json(body, status: status);

  void onRequest(String method, String path, Future<http.Response> Function(http.Request) handler) =>
      _routes['$method $path'] = handler;

  static http.Response json(Object? body, {int status = 200}) => http.Response.bytes(
        utf8.encode(body == null ? '' : jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Iterable<http.Request> requestsTo(String method, String path) =>
      requests.where((r) => r.method == method && r.url.path == '/api/v1$path');

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path.replaceFirst('/api/v1', '');
    final handler = _routes['${request.method} $path'];
    if (handler == null) return json({'error': 'No fake route for ${request.method} $path'}, status: 404);
    return handler(request);
  }

  /// Endpoints every screen touches at startup.
  void stubBasics({bool signedIn = false}) {
    on('GET', '/cuisines', {
      'cuisines': [cuisineJson(1, 'American', '🇺🇸'), thai],
    });
    on('GET', '/geocode/reverse', {
      'result': {
        'label': 'Fremont, CA',
        'address': 'Fremont, Alameda County, California, United States',
        'street': null,
        'city': 'Fremont',
        'state': 'CA',
        'zip_code': '94538',
        'latitude': fremont.latitude,
        'longitude': fremont.longitude,
      },
    });
    if (signedIn) {
      on('GET', '/me', {'user': demoUser});
      on('GET', '/me/reviews', paged('reviews', []));
    } else {
      on('GET', '/me', {'error': 'Please sign in to continue.'}, status: 401);
    }
  }
}
