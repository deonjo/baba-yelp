import 'cuisine.dart';
import 'dish.dart';
import 'restaurant.dart';
import 'review.dart';

/// A dish as served by one restaurant ("Pad Thai at Thai Orchid Kitchen").
/// This is what customers rate.
class RestaurantDish {
  const RestaurantDish({
    required this.id,
    required this.restaurantId,
    required this.dishId,
    required this.name,
    this.cuisine,
    this.averageRating,
    this.reviewsCount = 0,
    this.restaurant,
    this.ratingDistribution = const {},
    this.myReview,
  });

  factory RestaurantDish.fromJson(Map<String, dynamic> json) {
    final distribution = json['rating_distribution'] as Map<String, dynamic>?;
    return RestaurantDish(
      id: json['id'] as int,
      restaurantId: json['restaurant_id'] as int,
      dishId: json['dish_id'] as int,
      name: json['name'] as String,
      cuisine: json['cuisine'] == null
          ? null
          : Cuisine.fromJson(json['cuisine'] as Map<String, dynamic>),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewsCount: json['reviews_count'] as int? ?? 0,
      restaurant: json['restaurant'] == null
          ? null
          : Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>),
      ratingDistribution: {
        for (final entry in (distribution ?? const {}).entries)
          int.parse(entry.key): entry.value as int,
      },
      myReview: json['my_review'] == null
          ? null
          : Review.fromJson(json['my_review'] as Map<String, dynamic>),
    );
  }

  final int id;
  final int restaurantId;
  final int dishId;
  final String name;
  final Cuisine? cuisine;
  final double? averageRating;
  final int reviewsCount;
  final Restaurant? restaurant;

  /// Number of reviews per star rating (5 → count, …, 1 → count).
  final Map<int, int> ratingDistribution;

  /// The signed-in user's review of this dish, if any.
  final Review? myReview;

  Dish toDish() => Dish(id: dishId, name: name, cuisine: cuisine);
}
