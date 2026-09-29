import 'user.dart';

class Review {
  const Review({
    required this.id,
    required this.restaurantDishId,
    required this.rating,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
    this.body,
    this.dishId,
    this.dishName,
    this.restaurantId,
    this.restaurantName,
    this.restaurantCity,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final dish = json['dish'] as Map<String, dynamic>?;
    final restaurant = json['restaurant'] as Map<String, dynamic>?;
    return Review(
      id: json['id'] as int,
      restaurantDishId: json['restaurant_dish_id'] as int,
      rating: json['rating'] as int,
      body: json['body'] as String?,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      dishId: dish?['id'] as int?,
      dishName: dish?['name'] as String?,
      restaurantId: restaurant?['id'] as int?,
      restaurantName: restaurant?['name'] as String?,
      restaurantCity: restaurant?['city'] as String?,
    );
  }

  final int id;
  final int restaurantDishId;
  final int rating;
  final String? body;
  final User user;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Present when listing your own reviews.
  final int? dishId;
  final String? dishName;
  final int? restaurantId;
  final String? restaurantName;
  final String? restaurantCity;
}

/// One dish's rating and text when posting reviews.
class ReviewInput {
  const ReviewInput({required this.dishId, required this.rating, this.body});

  final int dishId;
  final int rating;
  final String? body;

  Map<String, dynamic> toJson() => {
        'dish_id': dishId,
        'rating': rating,
        'body': (body?.trim().isEmpty ?? true) ? null : body!.trim(),
      };
}
