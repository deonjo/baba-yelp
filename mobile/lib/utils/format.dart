import '../models/models.dart';

/// "0.8 mi". The server already rounds to 0.1 mi (the precision it sorts by).
String formatDistance(double? miles) {
  if (miles == null) return '';
  if (miles < 0.1) return '< 0.1 mi';
  return '${miles.toStringAsFixed(1)} mi';
}

/// "4.5", or "–" when there are no ratings yet.
String formatRating(double? rating) =>
    rating == null ? '–' : rating.toStringAsFixed(1);

String formatRadius(double miles) =>
    '${miles == miles.roundToDouble() ? miles.toInt() : miles} mi';

String pluralize(int count, String singular, [String? plural]) =>
    '$count ${count == 1 ? singular : plural ?? '${singular}s'}';

/// "Pad Thai + Tom Yum Soup", or "Pad Thai + 2 more" for longer lists.
String dishesTitle(List<Dish> dishes) {
  if (dishes.isEmpty) return 'Restaurants';
  if (dishes.length <= 2) return dishes.map((d) => d.name).join(' + ');
  return '${dishes.first.name} + ${dishes.length - 1} more';
}

String timeAgo(DateTime time, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(time);
  if (elapsed.inDays < 1) return 'today';
  if (elapsed.inDays < 2) return 'yesterday';
  if (elapsed.inDays < 7) return '${elapsed.inDays} days ago';
  if (elapsed.inDays < 30) return '${pluralize(elapsed.inDays ~/ 7, 'week')} ago';
  if (elapsed.inDays < 365) return '${pluralize(elapsed.inDays ~/ 30, 'month')} ago';
  return '${pluralize(elapsed.inDays ~/ 365, 'year')} ago';
}

const ratingLabels = ['Tap a star to rate', 'Not good', 'Could be better', 'OK', 'Good', 'Great!'];
