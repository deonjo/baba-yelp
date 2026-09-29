import 'dish.dart';
import 'place.dart';

enum SortMode {
  /// Closest first; restaurants that are equally far away (to 0.1 mi) are
  /// ordered by rating.
  distance,

  /// Best rated first; equal ratings (to 0.1 stars) go to the closer one.
  rating,
}

enum MatchMode {
  /// Only restaurants serving every selected dish.
  all,

  /// Restaurants serving at least one selected dish.
  any,
}

/// Parameters for GET /api/v1/restaurants.
class RestaurantSearchQuery {
  const RestaurantSearchQuery({
    this.text,
    this.dishes = const [],
    this.location,
    this.radiusMiles = 10,
    this.sort = SortMode.distance,
    this.match = MatchMode.all,
    this.minRating,
  });

  final String? text;
  final List<Dish> dishes;
  final SearchLocation? location;
  final double radiusMiles;
  final SortMode sort;
  final MatchMode match;
  final double? minRating;

  RestaurantSearchQuery copyWith({
    double? radiusMiles,
    SortMode? sort,
    MatchMode? match,
  }) =>
      RestaurantSearchQuery(
        text: text,
        dishes: dishes,
        location: location,
        radiusMiles: radiusMiles ?? this.radiusMiles,
        sort: sort ?? this.sort,
        match: match ?? this.match,
        minRating: minRating,
      );

  RestaurantSearchQuery withMinRating(double? value) => RestaurantSearchQuery(
        text: text,
        dishes: dishes,
        location: location,
        radiusMiles: radiusMiles,
        sort: sort,
        match: match,
        minRating: value,
      );

  Map<String, String> toQueryParameters() => {
        if (text != null && text!.trim().isNotEmpty) 'q': text!.trim(),
        if (dishes.isNotEmpty) 'dish_ids': dishes.map((d) => d.id).join(','),
        if (location != null) ...{
          'lat': location!.latitude.toString(),
          'lng': location!.longitude.toString(),
          'radius': radiusMiles.toString(),
        },
        'sort': sort.name,
        'match': match.name,
        if (minRating != null) 'min_rating': minRating.toString(),
      };
}
