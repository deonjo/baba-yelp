// End-to-end walkthrough of both use cases against a running, freshly seeded
// Rails API. Run from mobile/ with the server up (see README):
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/use_cases_test.dart \
//     --dart-define=API_BASE_URL=http://localhost:3000 -d <simulator>
//
// Screenshots land in build/screenshots/. It posts real reviews as
// demo@example.com and may add a restaurant, so reseed afterwards.
import 'package:baba_yelp/app.dart';
import 'package:baba_yelp/screens/discover_screen.dart';
import 'package:baba_yelp/screens/restaurant_screen.dart';
import 'package:baba_yelp/screens/review/rate_dishes_screen.dart';
import 'package:baba_yelp/screens/review/write_review_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

late IntegrationTestWidgetsFlutterBinding binding;

/// pumpAndSettle that gives up after a few seconds instead of failing, because
/// spinners (e.g. while the location is looked up) never settle.
Future<void> settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
        const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
  } on FlutterError {
    // Still animating; carry on.
  }
}

Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 30)}) =>
    waitUntil(tester, () => finder.evaluate().isNotEmpty, '$finder', timeout: timeout);

Future<void> waitUntil(WidgetTester tester, bool Function() condition, String description,
    {Duration timeout = const Duration(seconds: 30)}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) {
      await settle(tester);
      return;
    }
  }
  throw TestFailure('Timed out waiting for $description');
}

Future<void> screenshot(WidgetTester tester, String name) async {
  await settle(tester);
  await binding.takeScreenshot(name);
}

/// Taps a text field before typing: after the app unfocuses a field, typing
/// into it again only reaches the app once it has been refocused.
Future<void> typeInto(WidgetTester tester, Finder field, String text) async {
  await tester.tap(field);
  await settle(tester);
  await tester.enterText(field, text);
}

Future<void> pickDish(WidgetTester tester, Finder screen, String query, String name) async {
  await typeInto(tester, find.descendant(of: screen, matching: find.byKey(const Key('dish-search'))), query);
  final result = find.descendant(of: screen, matching: find.widgetWithText(ListTile, name));
  await waitFor(tester, result);
  await tester.tap(result.first);
  await settle(tester);
}

double top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text).first).dy;

Future<void> backToHome(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).popUntil((route) => route.isFirst);
  await settle(tester);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pad Thai + Tom Yum Soup near Fremont: find, then review', (tester) async {
    await tester.pumpWidget(BabaYelpApp.create());
    await waitFor(tester, find.text('What are you craving?'));

    // Use case 1: search near Fremont, CA.
    await tester.tap(find.byKey(const Key('location-bar')));
    await waitFor(tester, find.byKey(const Key('place-search')));
    await tester.enterText(find.byKey(const Key('place-search')), 'Fremont, CA');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await waitFor(tester, find.widgetWithText(ListTile, 'Fremont, CA'));
    await tester.tap(find.widgetWithText(ListTile, 'Fremont, CA').first);
    await settle(tester);

    final discover = find.byType(DiscoverScreen);
    await pickDish(tester, discover, 'Pad Thai', 'Pad Thai');
    await pickDish(tester, discover, 'Tom Yum', 'Tom Yum Soup');
    await screenshot(tester, '01-discover');

    await tester.tap(find.byKey(const Key('find-restaurants')));
    await waitFor(tester, find.text('Thai Orchid Kitchen'));
    expect(top(tester, 'Thai Orchid Kitchen'), lessThan(top(tester, 'Thai Basil Express')),
        reason: 'both are 0.2 mi away, so the better-rated one comes first');
    expect(top(tester, 'Thai Basil Express'), lessThan(top(tester, 'Bangkok Street Eats')));
    await screenshot(tester, '02-results-by-distance');

    await tester.tap(find.text('Top rated'));
    await waitUntil(
      tester,
      () => find.text('Bangkok Street Eats').evaluate().isNotEmpty &&
          find.text('Thai Orchid Kitchen').evaluate().isNotEmpty &&
          top(tester, 'Bangkok Street Eats') < top(tester, 'Thai Orchid Kitchen'),
      'rating order',
    );
    await screenshot(tester, '03-results-by-rating');

    await tester.tap(find.text('Thai Orchid Kitchen'));
    await waitFor(tester, find.textContaining('On the menu ('));
    await screenshot(tester, '04-restaurant');

    await tester.tap(find.descendant(of: find.byType(ListTile), matching: find.text('Pad Thai')).first);
    await waitFor(tester, find.text('Reviews'));
    await screenshot(tester, '05-dish-at-restaurant');
    await backToHome(tester);

    // Use case 2: sign in, pick the dishes, find the restaurant, rate them.
    await tester.tap(find.text('Profile'));
    await settle(tester);
    if (find.text('Demo Diner').evaluate().isEmpty) {
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await waitFor(tester, find.byKey(const Key('sign-in-email')));
      await tester.enterText(find.byKey(const Key('sign-in-email')), 'demo@example.com');
      await tester.enterText(find.byKey(const Key('sign-in-password')), 'password123');
      await tester.tap(find.byKey(const Key('sign-in-submit')));
      await waitFor(tester, find.text('Demo Diner'));
    }

    await tester.tap(find.text('Review'));
    await settle(tester);
    final reviewTab = find.byType(WriteReviewTab);
    await pickDish(tester, reviewTab, 'Pad Thai', 'Pad Thai');
    await pickDish(tester, reviewTab, 'Tom Yum', 'Tom Yum Soup');
    await screenshot(tester, '06-review-what');

    await tester.tap(find.byKey(const Key('choose-restaurant')));
    await waitFor(tester, find.text('Nearby places that serve them'));
    await screenshot(tester, '07-review-where');

    await tester.enterText(find.byKey(const Key('restaurant-search')), 'Thai Orchid');
    await waitFor(tester, find.widgetWithText(ListTile, 'Thai Orchid Kitchen'));
    await tester.tap(find.widgetWithText(ListTile, 'Thai Orchid Kitchen'));
    await waitFor(tester, find.byType(RateDishesScreen));
    await waitFor(tester, find.byKey(const Key('post-reviews')));

    final padThai = find.ancestor(of: find.text('Pad Thai'), matching: find.byType(Card));
    final tomYum = find.ancestor(of: find.text('Tom Yum Soup'), matching: find.byType(Card));
    await tester.tap(find.descendant(of: padThai, matching: find.byKey(const ValueKey('star-5'))));
    await tester.enterText(find.descendant(of: padThai, matching: find.byType(TextField)),
        'Perfect balance of tamarind and lime, and the noodles had real wok hei.');
    await tester.ensureVisible(tomYum);
    await tester.tap(find.descendant(of: tomYum, matching: find.byKey(const ValueKey('star-4'))));
    await tester.enterText(find.descendant(of: tomYum, matching: find.byType(TextField)),
        'Bright, sour and properly spicy. A little heavy on the lemongrass.');
    FocusManager.instance.primaryFocus?.unfocus();
    await screenshot(tester, '08-review-rate');

    await tester.tap(find.byKey(const Key('post-reviews')));
    await waitFor(tester, find.text('Thanks! Your 2 reviews are posted.'));
    await waitFor(tester, find.byType(RestaurantScreen));
    await waitFor(tester, find.textContaining('On the menu ('));
    await screenshot(tester, '09-review-posted');
    await backToHome(tester);

    // Use case 2, new restaurant: add it by address, then review.
    await pickDish(tester, reviewTab, 'Pad Thai', 'Pad Thai');
    await tester.tap(find.byKey(const Key('choose-restaurant')));
    await waitFor(tester, find.byKey(const Key('add-restaurant')));
    await tester.tap(find.byKey(const Key('add-restaurant')));
    await waitFor(tester, find.byKey(const Key('restaurant-name')));
    await tester.enterText(find.byKey(const Key('restaurant-name')), 'Baba Thai Test Kitchen');
    await tester.enterText(find.byKey(const Key('restaurant-address')), '39100 Argonaut Way');
    await tester.enterText(find.byKey(const Key('restaurant-city')), 'Fremont');
    await tester.enterText(find.byKey(const Key('restaurant-state')), 'CA');
    FocusManager.instance.primaryFocus?.unfocus();
    await screenshot(tester, '10-add-restaurant');
    await tester.tap(find.byKey(const Key('save-restaurant')));
    await waitUntil(
      tester,
      () => find.byType(RateDishesScreen).evaluate().isNotEmpty || find.text('Already listed').evaluate().isNotEmpty,
      'restaurant saved',
    );
    if (find.text('Already listed').evaluate().isNotEmpty) {
      await tester.tap(find.text('Use it'));
    }
    await waitFor(tester, find.byKey(const Key('post-reviews')));
    expect(find.text('At Baba Thai Test Kitchen'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('star-4')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('post-reviews')));
    await waitFor(tester, find.text('Thanks! Your review is posted.'));
    await waitFor(tester, find.textContaining('On the menu ('));
    await screenshot(tester, '11-new-restaurant-reviewed');
  });
}
