import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/states.dart';
import 'discover_screen.dart';
import 'restaurant_dish_screen.dart';
import 'restaurant_screen.dart';

/// Restaurants near the search location that serve the chosen dishes, sorted
/// by distance then rating, or by rating then distance.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.query});

  final RestaurantSearchQuery query;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late RestaurantSearchQuery _query = widget.query;
  final _scrollController = ScrollController();
  final _restaurants = <Restaurant>[];
  int _page = 0;
  int _totalCount = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 600) _loadMore();
    });
    _reload();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reload() {
    _generation++;
    setState(() {
      _restaurants.clear();
      _page = 0;
      _totalCount = 0;
      _hasMore = true;
      _loading = false;
      _error = null;
    });
    return _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<ApiClient>().searchRestaurants(_query, page: _page + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _restaurants.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
        _totalCount = page.totalCount;
      });
    } on ApiException catch (error) {
      if (mounted && generation == _generation) setState(() => _error = error.message);
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  String get _matchAllLabel => _query.dishes.length == 2 ? 'Serves both' : 'Serves all ${_query.dishes.length}';

  void _update(RestaurantSearchQuery query) {
    _query = query;
    _reload();
  }

  void _openRestaurant(Restaurant restaurant) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RestaurantScreen(restaurantId: restaurant.id, preview: restaurant),
      ));

  void _openDish(RestaurantDish dish) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RestaurantDishScreen(restaurantDishId: dish.id),
      ));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dishesTitle(_query.dishes), overflow: TextOverflow.ellipsis),
            Text(
              'near ${_query.location?.label ?? 'you'}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildControls(context)),
            ..._buildResults(context),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<SortMode>(
            key: const Key('sort-mode'),
            segments: const [
              ButtonSegment(value: SortMode.distance, icon: Icon(Icons.near_me_outlined), label: Text('Nearest')),
              ButtonSegment(value: SortMode.rating, icon: Icon(Icons.star_outline_rounded), label: Text('Top rated')),
            ],
            selected: {_query.sort},
            onSelectionChanged: (selection) => _update(_query.copyWith(sort: selection.first)),
          ),
          const SizedBox(height: 6),
          Text(
            _query.sort == SortMode.distance
                ? 'Sorted by distance, then rating.'
                : 'Sorted by rating, then distance.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              PopupMenuButton<double>(
                tooltip: 'Search radius',
                initialValue: _query.radiusMiles,
                onSelected: (radius) => _update(_query.copyWith(radiusMiles: radius)),
                itemBuilder: (_) => [
                  for (final radius in radiusChoices)
                    PopupMenuItem(value: radius, child: Text('Within ${formatRadius(radius)}')),
                ],
                child: Chip(
                  avatar: const Icon(Icons.radar, size: 18),
                  label: Text('Within ${formatRadius(_query.radiusMiles)}'),
                ),
              ),
              if (_query.dishes.length > 1)
                FilterChip(
                  key: const Key('match-all'),
                  label: Text(_matchAllLabel),
                  selected: _query.match == MatchMode.all,
                  onSelected: (all) => _update(_query.copyWith(match: all ? MatchMode.all : MatchMode.any)),
                ),
              FilterChip(
                key: const Key('min-rating'),
                label: const Text('4★ & up'),
                selected: _query.minRating != null,
                onSelected: (on) => _update(_query.withMinRating(on ? 4.0 : null)),
              ),
            ],
          ),
          if (_restaurants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(pluralize(_totalCount, 'restaurant'), style: theme.textTheme.labelLarge),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildResults(BuildContext context) {
    if (_restaurants.isEmpty) {
      final Widget child;
      if (_loading || (_error == null && _hasMore)) {
        child = const LoadingView();
      } else if (_error != null) {
        child = ErrorView(message: _error!, onRetry: _reload);
      } else {
        child = MessageView(
          icon: Icons.ramen_dining_outlined,
          title: 'No restaurants found',
          message: _query.match == MatchMode.all && _query.dishes.length > 1
              ? 'No place within ${formatRadius(_query.radiusMiles)} serves all of these dishes. '
                  'Turn off “$_matchAllLabel” or search farther away.'
              : 'Nothing within ${formatRadius(_query.radiusMiles)} yet. Try searching farther away.',
          actionLabel: _query.radiusMiles < radiusChoices.last ? 'Search within ${formatRadius(radiusChoices.last)}' : null,
          onAction: () => _update(_query.copyWith(radiusMiles: radiusChoices.last)),
        );
      }
      return [SliverFillRemaining(hasScrollBody: false, child: child)];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: _restaurants.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final restaurant = _restaurants[index];
            return RestaurantResultCard(
              key: ValueKey('restaurant-${restaurant.id}'),
              restaurant: restaurant,
              onTap: () => _openRestaurant(restaurant),
              onDishTap: _openDish,
            );
          },
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: _loading
                ? const CircularProgressIndicator()
                : _error != null
                    ? TextButton(onPressed: _loadMore, child: Text('$_error Tap to retry.'))
                    : _hasMore
                        ? const SizedBox.shrink()
                        : Text("That's everything nearby.", style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      ),
    ];
  }
}
