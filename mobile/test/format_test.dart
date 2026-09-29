import 'package:baba_yelp/models/models.dart';
import 'package:baba_yelp/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats distances at the precision the server sorts by', () {
    expect(formatDistance(null), '');
    expect(formatDistance(0.0), '< 0.1 mi');
    expect(formatDistance(0.2), '0.2 mi');
    expect(formatDistance(12.0), '12.0 mi');
  });

  test('formats ratings, radii and counts', () {
    expect(formatRating(null), '–');
    expect(formatRating(4.0), '4.0');
    expect(formatRating(4.75), anyOf('4.8', '4.7'));
    expect(formatRadius(10), '10 mi');
    expect(formatRadius(2.5), '2.5 mi');
    expect(pluralize(1, 'review'), '1 review');
    expect(pluralize(3, 'dish', 'dishes'), '3 dishes');
  });

  test('titles a dish search', () {
    const padThai = Dish(id: 1, name: 'Pad Thai');
    const tomYum = Dish(id: 2, name: 'Tom Yum Soup');
    const curry = Dish(id: 3, name: 'Green Curry');
    expect(dishesTitle([padThai]), 'Pad Thai');
    expect(dishesTitle([padThai, tomYum]), 'Pad Thai + Tom Yum Soup');
    expect(dishesTitle([padThai, tomYum, curry]), 'Pad Thai + 2 more');
  });

  test('describes how long ago something happened', () {
    final now = DateTime(2026, 9, 28, 12);
    expect(timeAgo(now.subtract(const Duration(hours: 3)), now: now), 'today');
    expect(timeAgo(now.subtract(const Duration(days: 1, hours: 2)), now: now), 'yesterday');
    expect(timeAgo(now.subtract(const Duration(days: 4)), now: now), '4 days ago');
    expect(timeAgo(now.subtract(const Duration(days: 15)), now: now), '2 weeks ago');
    expect(timeAgo(now.subtract(const Duration(days: 65)), now: now), '2 months ago');
    expect(timeAgo(now.subtract(const Duration(days: 400)), now: now), '1 year ago');
  });
}
