import 'dart:convert';

import 'package:baba_yelp/app.dart';
import 'package:baba_yelp/screens/discover_screen.dart';
import 'package:baba_yelp/screens/restaurant_screen.dart';
import 'package:baba_yelp/screens/review/rate_dishes_screen.dart';
import 'package:baba_yelp/screens/review/write_review_tab.dart';
import 'package:baba_yelp/services/token_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_backend.dart';

final orchid = restaurantJson(1, 'Thai Orchid Kitchen', distance: 0.2, rating: 4.5, reviews: 14, dishes: [
  menuItemJson(10, 1, padThai, rating: 4.6, reviews: 5),
  menuItemJson(11, 1, tomYum, rating: 4.4, reviews: 9),
]);
final basil = restaurantJson(2, 'Thai Basil Express', distance: 0.2, rating: 3.8, reviews: 8, dishes: [
  menuItemJson(20, 2, padThai, rating: 4.0, reviews: 4),
  menuItemJson(21, 2, tomYum, rating: 3.5, reviews: 4),
]);
final bangkok = restaurantJson(3, 'Bangkok Street Eats', distance: 0.9, rating: 4.8, reviews: 16, dishes: [
  menuItemJson(30, 3, padThai, rating: 4.8, reviews: 9),
  menuItemJson(31, 3, tomYum, rating: 4.7, reviews: 7),
]);

FakeBackend backendWithCatalog({bool signedIn = false}) {
  final backend = FakeBackend()..stubBasics(signedIn: signedIn);
  backend.onRequest('GET', '/dishes', (request) async {
    final query = (request.url.queryParameters['q'] ?? '').toLowerCase();
    final matches = [padThai, tomYum].where((d) => (d['name'] as String).toLowerCase().contains(query)).toList();
    return FakeBackend.json(paged('dishes', matches));
  });
  return backend;
}

Future<void> startApp(WidgetTester tester, FakeBackend backend, {String? token}) async {
  tester.view.physicalSize = const Size(1290, 2796);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BabaYelpApp.create(
    api: backend.api(),
    tokenStore: MemoryTokenStore(token),
    locationService: FakeLocationService(),
  ));
  await tester.pumpAndSettle();
}

/// Types into a DishPicker search box and taps the matching result.
Future<void> pickDish(WidgetTester tester, Finder scope, String query, int dishId) async {
  await tester.enterText(find.descendant(of: scope, matching: find.byKey(const Key('dish-search'))), query);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: scope, matching: find.byKey(ValueKey('dish-result-$dishId'))));
  await tester.pumpAndSettle();
}

double top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text)).dy;

void main() {
  testWidgets('use case 1: finds nearby restaurants making both dishes, by distance or by rating', (tester) async {
    final backend = backendWithCatalog();
    backend.onRequest('GET', '/restaurants', (request) async {
      final byRating = request.url.queryParameters['sort'] == 'rating';
      return FakeBackend.json(paged('restaurants', byRating ? [bangkok, orchid, basil] : [orchid, basil, bangkok]));
    });

    await startApp(tester, backend);
    expect(find.text('Current location · Fremont, CA'), findsOneWidget);

    final discover = find.byType(DiscoverScreen);
    await pickDish(tester, discover, 'pad', 11);
    await pickDish(tester, discover, 'tom', 12);
    expect(find.byKey(const ValueKey('selected-dish-11')), findsOneWidget);
    expect(find.byKey(const ValueKey('selected-dish-12')), findsOneWidget);

    await tester.tap(find.byKey(const Key('find-restaurants')));
    await tester.pumpAndSettle();

    final search = backend.requestsTo('GET', '/restaurants').last.url.queryParameters;
    expect(search, containsPair('dish_ids', '11,12'));
    expect(search, containsPair('lat', '37.5483'));
    expect(search, containsPair('lng', '-121.9886'));
    expect(search, containsPair('radius', '10.0'));
    expect(search, containsPair('sort', 'distance'));
    expect(search, containsPair('match', 'all'));

    expect(find.text('Pad Thai + Tom Yum Soup'), findsOneWidget);
    expect(find.text('Sorted by distance, then rating.'), findsOneWidget);
    expect(find.text('Serves both'), findsOneWidget);
    expect(top(tester, 'Thai Orchid Kitchen'), lessThan(top(tester, 'Thai Basil Express')));
    expect(top(tester, 'Thai Basil Express'), lessThan(top(tester, 'Bangkok Street Eats')));
    expect(find.text('0.2 mi'), findsNWidgets(2));
    expect(find.text('4.6 (5)'), findsOneWidget);

    await tester.tap(find.text('Top rated'));
    await tester.pumpAndSettle();

    expect(backend.requestsTo('GET', '/restaurants').last.url.queryParameters['sort'], 'rating');
    expect(find.text('Sorted by rating, then distance.'), findsOneWidget);
    expect(top(tester, 'Bangkok Street Eats'), lessThan(top(tester, 'Thai Orchid Kitchen')));
  });

  testWidgets('use case 1: filters to well-rated places and widens the search', (tester) async {
    final backend = backendWithCatalog();
    backend.onRequest('GET', '/restaurants', (request) async {
      final params = request.url.queryParameters;
      if (params['radius'] == '50.0') return FakeBackend.json(paged('restaurants', [bangkok]));
      return FakeBackend.json(paged('restaurants', []));
    });

    await startApp(tester, backend);
    await pickDish(tester, find.byType(DiscoverScreen), 'pad', 11);
    await tester.tap(find.byKey(const Key('find-restaurants')));
    await tester.pumpAndSettle();

    expect(find.text('No restaurants found'), findsOneWidget);
    await tester.tap(find.byKey(const Key('min-rating')));
    await tester.pumpAndSettle();
    expect(backend.requestsTo('GET', '/restaurants').last.url.queryParameters['min_rating'], '4.0');

    await tester.tap(find.text('Search within 50 mi'));
    await tester.pumpAndSettle();
    expect(find.text('Bangkok Street Eats'), findsOneWidget);
  });

  testWidgets('use case 2: reviews two dishes at a restaurant found by name', (tester) async {
    final backend = backendWithCatalog(signedIn: true);
    backend.onRequest('GET', '/restaurants', (request) async {
      final params = request.url.queryParameters;
      // Without a name: nearby places known to serve the dishes. With one: name search.
      final results = params['q'] == null ? [bangkok] : [if ('thai orchid kitchen'.contains(params['q']!.toLowerCase())) orchid];
      return FakeBackend.json(paged('restaurants', results));
    });
    backend.on('POST', '/restaurants/1/reviews', {'reviews': []}, status: 201);
    backend.on('GET', '/restaurants/1', {'restaurant': orchid});

    await startApp(tester, backend, token: 'demo-token');
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    final reviewTab = find.byType(WriteReviewTab);
    expect(find.text('What did you eat?'), findsOneWidget);
    await pickDish(tester, reviewTab, 'pad', 11);
    await pickDish(tester, reviewTab, 'tom', 12);
    await tester.tap(find.byKey(const Key('choose-restaurant')));
    await tester.pumpAndSettle();

    expect(find.text('Where did you eat?'), findsOneWidget);
    expect(find.text('Bangkok Street Eats'), findsOneWidget);
    expect(backend.requestsTo('GET', '/restaurants').last.url.queryParameters['match'], 'any');

    await tester.enterText(find.byKey(const Key('restaurant-search')), 'orchid');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(backend.requestsTo('GET', '/restaurants').last.url.queryParameters['q'], 'orchid');
    await tester.tap(find.byKey(const ValueKey('pick-restaurant-1')));
    await tester.pumpAndSettle();

    expect(find.byType(RateDishesScreen), findsOneWidget);
    final post = find.byKey(const Key('post-reviews'));
    expect(tester.widget<FilledButton>(post).onPressed, isNull, reason: 'every dish needs a rating');

    await tester.tap(find.descendant(of: find.byKey(const ValueKey('rate-dish-11')), matching: find.byKey(const ValueKey('star-5'))));
    await tester.enterText(find.byKey(const ValueKey('review-body-11')), 'Perfectly balanced, not too sweet.');
    await tester.ensureVisible(find.byKey(const ValueKey('rate-dish-12')));
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('rate-dish-12')), matching: find.byKey(const ValueKey('star-4'))));
    await tester.pumpAndSettle();
    expect(find.text('Great!'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);

    await tester.tap(post);
    await tester.pumpAndSettle();

    final posted = backend.requestsTo('POST', '/restaurants/1/reviews').single;
    expect(posted.headers['Authorization'], 'Bearer demo-token');
    expect(jsonDecode(posted.body), {
      'reviews': [
        {'dish_id': 11, 'rating': 5, 'body': 'Perfectly balanced, not too sweet.'},
        {'dish_id': 12, 'rating': 4, 'body': null},
      ],
    });
    expect(find.byType(RestaurantScreen), findsOneWidget);
    expect(find.text('Thanks! Your 2 reviews are posted.'), findsOneWidget);
  });

  testWidgets('use case 2: adds a restaurant that is not listed yet', (tester) async {
    final backend = backendWithCatalog(signedIn: true);
    backend.on('GET', '/restaurants', paged('restaurants', []));
    final created = restaurantJson(9, 'Siam Smile');
    backend.onRequest('POST', '/restaurants', (request) async {
      final restaurant = (jsonDecode(request.body) as Map<String, dynamic>)['restaurant'] as Map<String, dynamic>;
      if (restaurant['name'] == 'Thai Orchid Kitchen') {
        return FakeBackend.json({'error': 'Thai Orchid Kitchen is already listed.', 'restaurant': orchid}, status: 409);
      }
      return FakeBackend.json({'restaurant': created}, status: 201);
    });
    backend.on('POST', '/restaurants/9/reviews', {'reviews': []}, status: 201);
    backend.on('GET', '/restaurants/9', {'restaurant': created});

    await startApp(tester, backend, token: 'demo-token');
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await pickDish(tester, find.byType(WriteReviewTab), 'pad', 11);
    await tester.tap(find.byKey(const Key('choose-restaurant')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-restaurant')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('restaurant-name')), 'Thai Orchid Kitchen');
    await tester.enterText(find.byKey(const Key('restaurant-address')), '39170 State St');
    await tester.enterText(find.byKey(const Key('restaurant-city')), 'Fremont');
    await tester.enterText(find.byKey(const Key('restaurant-state')), 'CA');
    await tester.tap(find.byKey(const Key('save-restaurant')));
    await tester.pumpAndSettle();

    // Already listed: offer the existing one, but let's add a different place instead.
    expect(find.text('Already listed'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('restaurant-name')), 'Siam Smile');
    await tester.tap(find.byKey(const Key('save-restaurant')));
    await tester.pumpAndSettle();

    final body = jsonDecode(backend.requestsTo('POST', '/restaurants').last.body) as Map<String, dynamic>;
    expect(body['restaurant'], containsPair('address', '39170 State St'));
    expect(body['restaurant'], isNot(contains('latitude')), reason: 'the server geocodes the address');

    expect(find.byType(RateDishesScreen), findsOneWidget);
    expect(find.text('At Siam Smile'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('star-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('post-reviews')));
    await tester.pumpAndSettle();

    expect(backend.requestsTo('POST', '/restaurants/9/reviews'), hasLength(1));
    expect(find.text('Thanks! Your review is posted.'), findsOneWidget);
  });

  testWidgets('asks you to sign in before reviewing', (tester) async {
    final backend = backendWithCatalog();
    backend.on('POST', '/session', {'token': 'new-token', 'user': demoUser}, status: 201);
    backend.on('GET', '/me/reviews', paged('reviews', []));

    await startApp(tester, backend);
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Share what you ate'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sign-in-email')), 'demo@example.com');
    await tester.enterText(find.byKey(const Key('sign-in-password')), 'password123');
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(jsonDecode(backend.requestsTo('POST', '/session').single.body), {'email': 'demo@example.com', 'password': 'password123'});
    expect(find.text('What did you eat?'), findsOneWidget);
  });
}
