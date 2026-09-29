import 'cuisine.dart';

/// A dish in the catalog, e.g. "Pad Thai" (Thai). Not tied to a restaurant.
class Dish {
  const Dish({
    required this.id,
    required this.name,
    this.cuisine,
    this.aliases = const [],
    this.description,
    this.restaurantsCount = 0,
  });

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
        id: json['id'] as int,
        name: json['name'] as String,
        cuisine: json['cuisine'] == null
            ? null
            : Cuisine.fromJson(json['cuisine'] as Map<String, dynamic>),
        aliases: (json['aliases'] as List<dynamic>? ?? const [])
            .cast<String>(),
        description: json['description'] as String?,
        restaurantsCount: json['restaurants_count'] as int? ?? 0,
      );

  final int id;
  final String name;
  final Cuisine? cuisine;
  final List<String> aliases;
  final String? description;
  final int restaurantsCount;

  @override
  bool operator ==(Object other) => other is Dish && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
