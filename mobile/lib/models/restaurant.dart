import 'restaurant_dish.dart';

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.zipCode,
    this.phone,
    this.dishesCount = 0,
    this.distanceMiles,
    this.rating,
    this.reviewsCount = 0,
    this.dishes = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        zipCode: json['zip_code'] as String?,
        phone: json['phone'] as String?,
        fullAddress: json['full_address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        dishesCount: json['dishes_count'] as int? ?? 0,
        distanceMiles: (json['distance_miles'] as num?)?.toDouble(),
        rating: (json['rating'] as num?)?.toDouble(),
        reviewsCount: json['reviews_count'] as int? ?? 0,
        dishes: (json['dishes'] as List<dynamic>? ?? const [])
            .map((d) => RestaurantDish.fromJson(d as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String? zipCode;
  final String? phone;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final int dishesCount;

  /// Distance from the search location, rounded to 0.1 mi by the server.
  final double? distanceMiles;

  /// Combined rating of the searched dishes (or of all dishes on the
  /// restaurant page); null when nothing has been reviewed yet.
  final double? rating;
  final int reviewsCount;

  /// The searched dishes (search results) or the whole menu (detail).
  final List<RestaurantDish> dishes;
}
