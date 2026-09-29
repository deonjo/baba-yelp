import 'package:baba_yelp/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_backend.dart';

void main() {
  test('parses a search result with per-dish ratings', () {
    final restaurant = Restaurant.fromJson(restaurantJson(
      1,
      'Thai Orchid Kitchen',
      distance: 0.2,
      rating: 4.5,
      reviews: 14,
      dishes: [menuItemJson(10, 1, padThai, rating: 4.6, reviews: 5), menuItemJson(11, 1, tomYum)],
    ));

    expect(restaurant.name, 'Thai Orchid Kitchen');
    expect(restaurant.distanceMiles, 0.2);
    expect(restaurant.rating, 4.5);
    expect(restaurant.reviewsCount, 14);
    expect(restaurant.dishes.map((d) => d.name), ['Pad Thai', 'Tom Yum Soup']);
    expect(restaurant.dishes.first.averageRating, 4.6);
    expect(restaurant.dishes.last.averageRating, isNull);
    expect(restaurant.dishes.first.toDish(), const Dish(id: 11, name: 'Pad Thai'));
  });

  test('parses a restaurant dish with its rating breakdown and my review', () {
    final dish = RestaurantDish.fromJson({
      ...menuItemJson(10, 1, padThai, rating: 4.0, reviews: 2),
      'restaurant': restaurantJson(1, 'Thai Orchid Kitchen'),
      'rating_distribution': {'5': 1, '4': 0, '3': 1, '2': 0, '1': 0},
      'my_review': {
        'id': 7,
        'restaurant_dish_id': 10,
        'rating': 5,
        'body': 'Great',
        'user': {'id': 1, 'name': 'Demo Diner'},
        'created_at': '2026-09-01T12:00:00Z',
        'updated_at': '2026-09-01T12:00:00Z',
      },
    });

    expect(dish.restaurant!.name, 'Thai Orchid Kitchen');
    expect(dish.ratingDistribution, {5: 1, 4: 0, 3: 1, 2: 0, 1: 0});
    expect(dish.myReview!.rating, 5);
    expect(dish.myReview!.createdAt, DateTime.utc(2026, 9, 1, 12));
  });

  test('parses my reviews with their dish and restaurant', () {
    final page = Paged.fromJson(
      paged('reviews', [
        {
          'id': 7,
          'restaurant_dish_id': 10,
          'rating': 4,
          'body': null,
          'user': {'id': 1, 'name': 'Demo Diner'},
          'created_at': '2026-09-01T12:00:00Z',
          'updated_at': '2026-09-02T12:00:00Z',
          'dish': {'id': 11, 'name': 'Pad Thai'},
          'restaurant': {'id': 1, 'name': 'Thai Orchid Kitchen', 'city': 'Fremont'},
        },
      ], totalPages: 3),
      'reviews',
      Review.fromJson,
    );

    final review = page.items.single;
    expect([review.dishId, review.dishName, review.restaurantName], [11, 'Pad Thai', 'Thai Orchid Kitchen']);
    expect(review.body, isNull);
    expect(page.hasMore, isTrue);
  });

  test('builds search query parameters', () {
    const query = RestaurantSearchQuery(
      dishes: [Dish(id: 11, name: 'Pad Thai'), Dish(id: 12, name: 'Tom Yum Soup')],
      location: SearchLocation(label: 'Fremont, CA', latitude: 37.5, longitude: -121.9),
      radiusMiles: 5,
      sort: SortMode.rating,
    );

    expect(query.toQueryParameters(), {
      'dish_ids': '11,12',
      'lat': '37.5',
      'lng': '-121.9',
      'radius': '5.0',
      'sort': 'rating',
      'match': 'all',
    });
    expect(query.withMinRating(4).toQueryParameters()['min_rating'], '4.0');
    expect(query.copyWith(match: MatchMode.any).toQueryParameters()['match'], 'any');
  });

  test('omits blank review text', () {
    expect(const ReviewInput(dishId: 1, rating: 5, body: '  ').toJson(), {'dish_id': 1, 'rating': 5, 'body': null});
    expect(const ReviewInput(dishId: 1, rating: 4, body: ' Yum ').toJson()['body'], 'Yum');
  });

  test('user initials', () {
    expect(const User(id: 1, name: 'Demo Diner').initials, 'DD');
    expect(const User(id: 1, name: 'cher').initials, 'C');
  });
}
