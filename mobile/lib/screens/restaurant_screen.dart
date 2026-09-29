import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/location_state.dart';
import '../utils/format.dart';
import '../widgets/star_rating.dart';
import '../widgets/states.dart';
import 'auth/sign_in_screen.dart';
import 'restaurant_dish_screen.dart';
import 'review/choose_dishes_screen.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key, required this.restaurantId, this.preview});

  final int restaurantId;

  /// Shown while the full details load (e.g. the search result that was tapped).
  final Restaurant? preview;

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  Restaurant? _restaurant;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final from = context.read<LocationState>().location?.point;
      final restaurant = await context.read<ApiClient>().restaurant(widget.restaurantId, from: from);
      if (mounted) setState(() => _restaurant = restaurant);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _openDirections(Restaurant restaurant) async {
    final destination = '${restaurant.latitude},${restaurant.longitude}';
    final uri = defaultTargetPlatform == TargetPlatform.iOS
        ? Uri.https('maps.apple.com', '/', {'daddr': destination, 'q': restaurant.name})
        : Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': destination});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      showMessage(context, "Couldn't open maps.");
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));
    if (!await launchUrl(uri) && mounted) showMessage(context, "Couldn't start a call.");
  }

  Future<void> _review(Restaurant restaurant) async {
    if (!await ensureSignedIn(context, reason: 'Sign in to review dishes.') || !mounted) return;
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ChooseDishesScreen(restaurant: restaurant)),
    );
    if (posted == true && mounted) {
      showMessage(context, 'Thanks! Your reviews are posted.');
      _load();
    }
  }

  Future<void> _openDish(RestaurantDish dish) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RestaurantDishScreen(restaurantDishId: dish.id),
    ));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = _restaurant ?? widget.preview;
    return Scaffold(
      appBar: AppBar(title: Text(restaurant?.name ?? 'Restaurant')),
      body: restaurant == null
          ? (_error == null ? const LoadingView() : ErrorView(message: _error!, onRetry: _load))
          : RefreshIndicator(onRefresh: _load, child: _buildDetails(context, restaurant)),
    );
  }

  Widget _buildDetails(BuildContext context, Restaurant restaurant) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final loaded = _restaurant;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(restaurant.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              if (loaded != null) RatingSummary(rating: loaded.rating, reviewsCount: loaded.reviewsCount),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place_outlined, size: 18, color: muted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(restaurant.fullAddress)),
                  if (restaurant.distanceMiles != null)
                    Text(formatDistance(restaurant.distanceMiles), style: theme.textTheme.labelLarge),
                ],
              ),
              if (restaurant.phone != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 18, color: muted),
                    const SizedBox(width: 6),
                    Text(restaurant.phone!),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openDirections(restaurant),
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Directions'),
                  ),
                  if (restaurant.phone != null)
                    OutlinedButton.icon(
                      onPressed: () => _call(restaurant.phone!),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Call'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('review-here'),
                onPressed: () => _review(loaded ?? restaurant),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Review dishes you ate here'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 24),
              Text(
                loaded == null ? 'On the menu' : 'On the menu (${loaded.dishes.length})',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (loaded == null)
          _error == null
              ? const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())
              : ErrorView(message: _error!, onRetry: _load)
        else if (loaded.dishes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No dishes rated here yet. Be the first to review one!'),
          )
        else
          for (final dish in loaded.dishes)
            ListTile(
              key: ValueKey('menu-dish-${dish.id}'),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Text(dish.cuisine?.emoji ?? '🍽️'),
              ),
              title: Text(dish.name),
              subtitle: Align(
                alignment: Alignment.centerLeft,
                child: RatingSummary(rating: dish.averageRating, reviewsCount: dish.reviewsCount, size: 14),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openDish(dish),
            ),
      ],
    );
  }
}
