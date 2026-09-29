import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../widgets/review_tile.dart';
import '../widgets/star_rating.dart';
import '../widgets/states.dart';
import 'auth/sign_in_screen.dart';
import 'restaurant_screen.dart';
import 'review/rate_dishes_screen.dart';

/// One dish at one restaurant: its rating breakdown and reviews.
class RestaurantDishScreen extends StatefulWidget {
  const RestaurantDishScreen({super.key, required this.restaurantDishId});

  final int restaurantDishId;

  @override
  State<RestaurantDishScreen> createState() => _RestaurantDishScreenState();
}

class _RestaurantDishScreenState extends State<RestaurantDishScreen> {
  RestaurantDish? _dish;
  String? _error;
  final _reviews = <Review>[];
  int _page = 0;
  bool _hasMore = false;
  bool _loadingReviews = false;

  ApiClient get _api => context.read<ApiClient>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([
        _api.restaurantDish(widget.restaurantDishId),
        _api.reviews(widget.restaurantDishId),
      ]);
      final reviews = results[1] as Paged<Review>;
      if (!mounted) return;
      setState(() {
        _dish = results[0] as RestaurantDish;
        _reviews
          ..clear()
          ..addAll(reviews.items);
        _page = reviews.page;
        _hasMore = reviews.hasMore;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _loadMoreReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final reviews = await _api.reviews(widget.restaurantDishId, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _reviews.addAll(reviews.items);
        _page = reviews.page;
        _hasMore = reviews.hasMore;
      });
    } on ApiException catch (error) {
      if (mounted) showMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _review(RestaurantDish dish) async {
    if (!await ensureSignedIn(context, reason: 'Sign in to review ${dish.name}.') || !mounted) return;
    final posted = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => RateDishesScreen(
        restaurantId: dish.restaurantId,
        restaurantName: dish.restaurant?.name ?? 'this restaurant',
        dishes: [dish.toDish()],
      ),
    ));
    if (posted == true && mounted) {
      showMessage(context, 'Thanks! Your review is posted.');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dish = _dish;
    return Scaffold(
      appBar: AppBar(title: Text(dish?.name ?? 'Dish')),
      body: dish == null
          ? (_error == null ? const LoadingView() : ErrorView(message: _error!, onRetry: _load))
          : RefreshIndicator(onRefresh: _load, child: _buildBody(context, dish)),
    );
  }

  Widget _buildBody(BuildContext context, RestaurantDish dish) {
    final theme = Theme.of(context);
    final restaurant = dish.restaurant;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dish.name, style: theme.textTheme.headlineSmall),
              if (restaurant != null)
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RestaurantScreen(restaurantId: restaurant.id, preview: restaurant),
                  )),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'at ${restaurant.name} · ${restaurant.city}',
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Column(
                    children: [
                      Text(
                        formatRating(dish.averageRating),
                        style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      StarRating(rating: dish.averageRating, size: 18),
                      const SizedBox(height: 4),
                      Text(pluralize(dish.reviewsCount, 'review'), style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: RatingDistribution(distribution: dish.ratingDistribution)),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('write-review'),
                onPressed: () => _review(dish),
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(dish.myReview == null ? 'Write a review' : 'Edit your review'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text('Reviews', style: theme.textTheme.titleMedium),
        ),
        if (_reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No reviews yet. Tried it? Be the first to review it!'),
          ),
        for (final review in _reviews) ReviewTile(review: review),
        if (_hasMore)
          Center(
            child: _loadingReviews
                ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
                : TextButton(onPressed: _loadMoreReviews, child: const Text('Show more reviews')),
          ),
      ],
    );
  }
}
