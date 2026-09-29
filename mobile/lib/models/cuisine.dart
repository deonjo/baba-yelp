class Cuisine {
  const Cuisine({
    required this.id,
    required this.name,
    this.emoji,
    this.dishesCount = 0,
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) => Cuisine(
        id: json['id'] as int,
        name: json['name'] as String,
        emoji: json['emoji'] as String?,
        dishesCount: json['dishes_count'] as int? ?? 0,
      );

  final int id;
  final String name;
  final String? emoji;
  final int dishesCount;

  String get label => emoji == null || emoji!.isEmpty ? name : '$emoji $name';

  @override
  bool operator ==(Object other) => other is Cuisine && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
