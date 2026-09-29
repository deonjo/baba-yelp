import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/location_state.dart';
import '../utils/format.dart';
import '../widgets/dish_picker.dart';
import '../widgets/location_bar.dart';
import 'results_screen.dart';

const radiusChoices = <double>[2, 5, 10, 25, 50];

/// Use case 1: "I feel like Pad Thai and Tom Yum soup — who near me makes
/// them well?"
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<Dish> _dishes = const [];
  double _radius = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final location = context.read<LocationState>();
      if (location.location == null && !location.locating) location.useCurrentLocation();
    });
  }

  void _search() {
    final location = context.read<LocationState>().location;
    if (location == null) {
      showLocationPicker(context);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultsScreen(
        query: RestaurantSearchQuery(dishes: _dishes, location: location, radiusMiles: _radius),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation = context.select<LocationState, bool>((state) => state.location != null);

    return Scaffold(
      appBar: AppBar(title: const Text('Baba Yelp')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('What are you craving?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Pick one or more dishes and we’ll find nearby restaurants that make them well.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          DishPicker(selected: _dishes, onChanged: (dishes) => setState(() => _dishes = dishes)),
          const SizedBox(height: 24),
          Text('Near', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          const LocationBar(),
          const SizedBox(height: 16),
          Text('Within', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final radius in radiusChoices)
                ChoiceChip(
                  label: Text(formatRadius(radius)),
                  selected: radius == _radius,
                  onSelected: (_) => setState(() => _radius = radius),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton.icon(
            key: const Key('find-restaurants'),
            onPressed: _dishes.isEmpty ? null : _search,
            icon: const Icon(Icons.search),
            label: Text(
              _dishes.isEmpty
                  ? 'Pick a dish to start'
                  : hasLocation
                      ? 'Find restaurants'
                      : 'Choose a location to search',
            ),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ),
      ),
    );
  }
}
