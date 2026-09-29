class User {
  const User({
    required this.id,
    required this.name,
    this.email,
    this.reviewsCount,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String?,
        reviewsCount: json['reviews_count'] as int?,
      );

  final int id;
  final String name;
  final String? email;
  final int? reviewsCount;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => String.fromCharCode(part.runes.first).toUpperCase())
      .join();
}
