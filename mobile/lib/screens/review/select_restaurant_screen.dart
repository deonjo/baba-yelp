import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../state/location_state.dart';
import '../../utils/format.dart';
import '../../widgets/states.dart';
import 'add_restaurant_screen.dart';
import 'rate_dishes_screen.dart';

/// Use case 2, step 2: find the restaurant where you ate (or add it).
/// Pops with the restaurant once the reviews are posted.
class SelectRestaurantScreen extends StatefulWidget {
  const SelectRestaurantScreen({super.key, required this.dishes});

  final List<Dish> dishes;

  @override
  State<SelectRestaurantScreen> createState() => _SelectRestaurantScreenState();
}

class _SelectRestaurantScreenState extends State<SelectRestaurantScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  int _generation = 0;
  final _restaurants = <Restaurant>[];
  int _page = 0;
  bool _hasMore = false;
  bool _loading = false;
  String? _error;

  String get _text => _searchController.text.trim();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Without a name, list nearby places already known to serve these dishes;
  /// with a name, search every restaurant by name (nearest first).
  RestaurantSearchQuery get _query => RestaurantSearchQuery(
        text: _text,
        dishes: _text.isEmpty ? widget.dishes : const [],
        match: MatchMode.any,
        location: context.read<LocationState>().location,
        radiusMiles: _text.isEmpty ? 25 : 100,
        sort: SortMode.distance,
      );

  Future<void> _load({bool more = false}) async {
    final generation = more ? _generation : ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _restaurants.clear();
        _page = 0;
      }
    });
    try {
      final page = await context.read<ApiClient>().searchRestaurants(_query, page: _page + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _restaurants.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
      });
    } on ApiException catch (error) {
      if (mounted && generation == _generation) setState(() => _error = error.message);
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _choose(Restaurant restaurant) async {
    final posted = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => RateDishesScreen(
        restaurantId: restaurant.id,
        restaurantName: restaurant.name,
        dishes: widget.dishes,
      ),
    ));
    if (posted == true && mounted) Navigator.of(context).pop(restaurant);
  }

  Future<void> _addRestaurant() async {
    final restaurant = await Navigator.of(context).push<Restaurant>(
      MaterialPageRoute(builder: (_) => AddRestaurantScreen(initialName: _text)),
    );
    if (restaurant != null && mounted) _choose(restaurant);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Where did you eat?')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              key: const Key('restaurant-search'),
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search restaurants by name',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Reviewing: ${widget.dishes.map((d) => d.name).join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ListTile(
            key: const Key('add-restaurant'),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.add_business_outlined, color: theme.colorScheme.onPrimaryContainer),
            ),
            title: const Text('Add a new restaurant'),
            subtitle: const Text('Not listed yet? It only takes a few seconds.'),
            onTap: _addRestaurant,
          ),
          const Divider(height: 1),
          Expanded(child: _buildResults(context)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final theme = Theme.of(context);
    if (_restaurants.isEmpty) {
      if (_loading) return const LoadingView();
      if (_error != null) return ErrorView(message: _error!, onRetry: _load);
      return MessageView(
        icon: Icons.storefront_outlined,
        title: _text.isEmpty
            ? 'No places nearby are known to serve ${widget.dishes.length == 1 ? 'this dish' : 'these dishes'} yet'
            : 'No restaurants match “$_text”',
        message: 'Search by name, or add the restaurant.',
      );
    }
    return ListView.builder(
      itemCount: _restaurants.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              _text.isEmpty ? 'Nearby places that serve ${widget.dishes.length == 1 ? 'it' : 'them'}' : 'Matching restaurants',
              style: theme.textTheme.labelLarge,
            ),
          );
        }
        if (index == _restaurants.length + 1) {
          if (!_hasMore) return const SizedBox(height: 24);
          return Center(
            child: _loading
                ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
                : TextButton(onPressed: () => _load(more: true), child: const Text('Show more')),
          );
        }
        final restaurant = _restaurants[index - 1];
        return ListTile(
          key: ValueKey('pick-restaurant-${restaurant.id}'),
          title: Text(restaurant.name),
          subtitle: Text(restaurant.fullAddress),
          trailing: Text(formatDistance(restaurant.distanceMiles), style: theme.textTheme.labelLarge),
          onTap: () => _choose(restaurant),
        );
      },
    );
  }
}
