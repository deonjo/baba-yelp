import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// An error returned by the API (or a network failure, when [statusCode] is null).
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;

  /// Validation errors keyed by field name, e.g. {"email": ["has already been taken"]}.
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetworkError => statusCode == null;

  /// The first validation error for [field], capitalized for display.
  String? fieldError(String field) {
    final messages = fieldErrors[field];
    if (messages == null || messages.isEmpty) return null;
    final message = messages.first;
    return message[0].toUpperCase() + message.substring(1);
  }

  @override
  String toString() => message;
}

/// Thrown when adding a restaurant that is already listed nearby.
class DuplicateRestaurantException extends ApiException {
  DuplicateRestaurantException(super.message, this.existing)
      : super(statusCode: 409);

  final Restaurant existing;
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );

  final String token;
  final User user;
}

class NewRestaurant {
  const NewRestaurant({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    this.zipCode,
    this.phone,
    this.location,
  });

  final String name;
  final String address;
  final String city;
  final String state;
  final String? zipCode;
  final String? phone;

  /// Where the restaurant is. When null the server geocodes the address.
  final GeoPoint? location;

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'phone': phone,
        if (location != null) ...{
          'latitude': location!.latitude,
          'longitude': location!.longitude,
        },
      };
}

/// Client for the Baba Yelp Rails API (`/api/v1`).
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  })  : baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  /// Bearer token sent with every request once signed in.
  String? token;

  /// Called when an authenticated request is rejected (e.g. the token was revoked).
  void Function()? onUnauthorized;

  // Accounts

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async =>
      AuthResult.fromJson(await _send('POST', '/users', body: {
        'user': {'name': name, 'email': email, 'password': password},
      }));

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async =>
      AuthResult.fromJson(await _send('POST', '/session',
          body: {'email': email, 'password': password}));

  Future<void> signOut() => _send('DELETE', '/session');

  Future<User> me() async =>
      User.fromJson((await _send('GET', '/me'))['user'] as Map<String, dynamic>);

  Future<void> deleteAccount(String password) =>
      _send('DELETE', '/me', body: {'password': password});

  Future<Paged<Review>> myReviews({
    int page = 1,
    int perPage = 20,
    int? restaurantId,
  }) async =>
      Paged.fromJson(
        await _send('GET', '/me/reviews', query: {
          'page': '$page',
          'per_page': '$perPage',
          if (restaurantId != null) 'restaurant_id': '$restaurantId',
        }),
        'reviews',
        Review.fromJson,
      );

  // Dishes

  Future<List<Cuisine>> cuisines() async =>
      ((await _send('GET', '/cuisines'))['cuisines'] as List<dynamic>)
          .map((json) => Cuisine.fromJson(json as Map<String, dynamic>))
          .toList();

  Future<Paged<Dish>> dishes({
    String? query,
    int? cuisineId,
    int page = 1,
    int perPage = 50,
  }) async =>
      Paged.fromJson(
        await _send('GET', '/dishes', query: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (cuisineId != null) 'cuisine_id': '$cuisineId',
          'page': '$page',
          'per_page': '$perPage',
        }),
        'dishes',
        Dish.fromJson,
      );

  Future<Dish> createDish({
    required String name,
    required int cuisineId,
    String? aliases,
    String? description,
  }) async =>
      Dish.fromJson((await _send('POST', '/dishes', body: {
        'dish': {
          'name': name,
          'cuisine_id': cuisineId,
          'aliases': aliases,
          'description': description,
        },
      }))['dish'] as Map<String, dynamic>);

  // Restaurants

  Future<Paged<Restaurant>> searchRestaurants(
    RestaurantSearchQuery query, {
    int page = 1,
    int perPage = 20,
  }) async =>
      Paged.fromJson(
        await _send('GET', '/restaurants', query: {
          ...query.toQueryParameters(),
          'page': '$page',
          'per_page': '$perPage',
        }),
        'restaurants',
        Restaurant.fromJson,
      );

  Future<Restaurant> restaurant(int id, {GeoPoint? from}) async =>
      Restaurant.fromJson((await _send('GET', '/restaurants/$id', query: {
        if (from != null) ...{
          'lat': '${from.latitude}',
          'lng': '${from.longitude}',
        },
      }))['restaurant'] as Map<String, dynamic>);

  /// Throws [DuplicateRestaurantException] if it is already listed nearby.
  Future<Restaurant> createRestaurant(NewRestaurant restaurant) async =>
      Restaurant.fromJson((await _send('POST', '/restaurants',
              body: {'restaurant': restaurant.toJson()}))['restaurant']
          as Map<String, dynamic>);

  Future<RestaurantDish> restaurantDish(int id) async =>
      RestaurantDish.fromJson((await _send('GET', '/restaurant_dishes/$id'))[
          'restaurant_dish'] as Map<String, dynamic>);

  // Reviews

  Future<Paged<Review>> reviews(int restaurantDishId, {int page = 1}) async =>
      Paged.fromJson(
        await _send('GET', '/restaurant_dishes/$restaurantDishId/reviews',
            query: {'page': '$page'}),
        'reviews',
        Review.fromJson,
      );

  /// Posts (or replaces) your reviews of dishes eaten at a restaurant. Dishes
  /// the restaurant isn't known to serve yet are added to its menu.
  Future<List<Review>> submitReviews(
    int restaurantId,
    List<ReviewInput> reviews,
  ) async =>
      ((await _send('POST', '/restaurants/$restaurantId/reviews', body: {
        'reviews': reviews.map((r) => r.toJson()).toList(),
      }))['reviews'] as List<dynamic>)
          .map((json) => Review.fromJson(json as Map<String, dynamic>))
          .toList();

  Future<void> deleteReview(int id) => _send('DELETE', '/reviews/$id');

  // Places

  Future<List<Place>> geocode(String query) async =>
      ((await _send('GET', '/geocode', query: {'q': query}))['results']
              as List<dynamic>)
          .map((json) => Place.fromJson(json as Map<String, dynamic>))
          .toList();

  Future<Place?> reverseGeocode(GeoPoint point) async {
    try {
      final json = await _send('GET', '/geocode/reverse', query: {
        'lat': '${point.latitude}',
        'lng': '${point.longitude}',
      });
      return Place.fromJson(json['result'] as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  // Plumbing

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1$path')
        .replace(queryParameters: query == null || query.isEmpty ? null : query);
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final sentToken = token != null;

    final http.Response response;
    try {
      response = await _http
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Please try again.');
    } on http.ClientException {
      throw ApiException(
          "Can't reach Baba Yelp right now. Check your connection and try again.");
    }

    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    if (response.statusCode == 401 && sentToken) onUnauthorized?.call();
    throw _error(response.statusCode, decoded);
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  ApiException _error(int statusCode, dynamic body) {
    final json = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    var message = json['error'] as String? ?? _defaultMessage(statusCode);
    final fieldErrors = <String, List<String>>{};
    final errors = json['errors'];
    if (errors is Map<String, dynamic>) {
      errors.forEach((field, messages) {
        if (messages is List) fieldErrors[field] = messages.map((m) => '$m').toList();
      });
    } else if (errors is List) {
      // Per-dish errors from posting several reviews at once.
      final details = errors.whereType<Map<String, dynamic>>().map((e) {
        final label = e['dish_name'] ?? 'Dish ${e['dish_id']}';
        return '$label: ${(e['errors'] as List<dynamic>? ?? const []).join(', ')}';
      });
      if (details.isNotEmpty) message = '$message\n${details.join('\n')}';
    }
    final restaurant = json['restaurant'];
    if (statusCode == 409 && restaurant is Map<String, dynamic>) {
      return DuplicateRestaurantException(message, Restaurant.fromJson(restaurant));
    }
    return ApiException(message, statusCode: statusCode, fieldErrors: fieldErrors);
  }

  static String _defaultMessage(int statusCode) => switch (statusCode) {
        401 => 'Please sign in to continue.',
        403 => "You're not allowed to do that.",
        404 => "We couldn't find that.",
        >= 500 => 'Something went wrong on our end. Please try again.',
        _ => 'Something went wrong (error $statusCode).',
      };
}
