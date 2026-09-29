/// One page of a paginated API list.
class Paged<T> {
  const Paged({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalCount,
  });

  factory Paged.fromJson(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    final items = (json[key] as List<dynamic>)
        .map((item) => parse(item as Map<String, dynamic>))
        .toList();
    return Paged(
      items: items,
      page: meta['page'] as int? ?? 1,
      totalPages: meta['total_pages'] as int? ?? 1,
      totalCount: meta['total_count'] as int? ?? items.length,
    );
  }

  final List<T> items;
  final int page;
  final int totalPages;
  final int totalCount;

  bool get hasMore => page < totalPages;
}
