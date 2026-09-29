import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../screens/add_dish_screen.dart';
import '../utils/format.dart';
import 'states.dart';

/// Search the dish catalog or browse it by cuisine, and pick one or more dishes.
class DishPicker extends StatefulWidget {
  const DishPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.maxDishes = 10,
    this.allowCreate = true,
  });

  final List<Dish> selected;
  final ValueChanged<List<Dish>> onChanged;
  final int maxDishes;

  /// Offer to add a dish that isn't in the catalog yet.
  final bool allowCreate;

  @override
  State<DishPicker> createState() => _DishPickerState();
}

class _DishPickerState extends State<DishPicker> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  int _searchGeneration = 0;
  String _query = '';
  bool _searching = false;
  List<Dish> _results = const [];
  String? _searchError;

  List<Cuisine>? _cuisines;
  String? _cuisinesError;
  Cuisine? _cuisine;
  final Map<int, List<Dish>> _dishesByCuisine = {};
  bool _loadingCuisine = false;

  ApiClient get _api => context.read<ApiClient>();

  @override
  void initState() {
    super.initState();
    _loadCuisines();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCuisines() async {
    setState(() => _cuisinesError = null);
    try {
      final cuisines = await _api.cuisines();
      if (mounted) setState(() => _cuisines = cuisines);
    } on ApiException catch (error) {
      if (mounted) setState(() => _cuisinesError = error.message);
    }
  }

  Future<void> _selectCuisine(Cuisine cuisine) async {
    if (_cuisine == cuisine) {
      setState(() => _cuisine = null);
      return;
    }
    setState(() => _cuisine = cuisine);
    if (_dishesByCuisine.containsKey(cuisine.id)) return;
    setState(() => _loadingCuisine = true);
    try {
      final page = await _api.dishes(cuisineId: cuisine.id, perPage: 100);
      _dishesByCuisine[cuisine.id] = page.items;
    } on ApiException catch (error) {
      if (mounted) showMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _loadingCuisine = false);
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    setState(() {
      _query = query;
      _searchError = null;
      if (query.isEmpty) _results = const [];
    });
    if (query.isNotEmpty) {
      _debounce = Timer(const Duration(milliseconds: 250), () => _search(query));
    }
  }

  Future<void> _search(String query) async {
    final generation = ++_searchGeneration;
    setState(() => _searching = true);
    try {
      final page = await _api.dishes(query: query, perPage: 8);
      if (!mounted || generation != _searchGeneration) return;
      setState(() => _results = page.items);
    } on ApiException catch (error) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() => _searchError = error.message);
    } finally {
      if (mounted && generation == _searchGeneration) setState(() => _searching = false);
    }
  }

  void _toggle(Dish dish) {
    final selected = [...widget.selected];
    if (selected.contains(dish)) {
      selected.remove(dish);
    } else if (selected.length >= widget.maxDishes) {
      showMessage(context, 'You can pick up to ${widget.maxDishes} dishes.');
      return;
    } else {
      selected.add(dish);
    }
    widget.onChanged(selected);
  }

  void _pickFromSearch(Dish dish) {
    if (!widget.selected.contains(dish)) _toggle(dish);
    _searchController.clear();
    _onQueryChanged('');
    FocusScope.of(context).unfocus();
  }

  Future<void> _addNewDish() async {
    final dish = await Navigator.of(context).push<Dish>(
      MaterialPageRoute(builder: (_) => AddDishScreen(initialName: _query)),
    );
    if (dish != null && mounted) _pickFromSearch(dish);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('dish-search'),
          controller: _searchController,
          onChanged: _onQueryChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search dishes, e.g. Pad Thai',
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _onQueryChanged('');
                    },
                  ),
          ),
        ),
        if (widget.selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final dish in widget.selected)
                  InputChip(
                    key: ValueKey('selected-dish-${dish.id}'),
                    label: Text(dish.name),
                    selected: true,
                    showCheckmark: false,
                    onDeleted: () => _toggle(dish),
                    deleteButtonTooltipMessage: 'Remove ${dish.name}',
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (_query.isNotEmpty) _buildSearchResults(context) else _buildBrowse(context),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_searching) const LinearProgressIndicator(),
        if (_searchError != null)
          ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(_searchError!),
            trailing: TextButton(onPressed: () => _search(_query), child: const Text('Retry')),
          ),
        for (final dish in _results)
          ListTile(
            key: ValueKey('dish-result-${dish.id}'),
            title: Text(dish.name),
            subtitle: Text([
              if (dish.cuisine != null) dish.cuisine!.label,
              'served at ${pluralize(dish.restaurantsCount, 'place')}',
            ].join(' · ')),
            trailing: Icon(
              widget.selected.contains(dish) ? Icons.check_circle : Icons.add_circle_outline,
              color: theme.colorScheme.primary,
            ),
            onTap: () => _pickFromSearch(dish),
          ),
        if (!_searching && _searchError == null && _results.isEmpty)
          ListTile(
            leading: const Icon(Icons.search_off),
            title: Text('No dishes match “$_query”'),
          ),
        if (widget.allowCreate && !_searching)
          ListTile(
            key: const Key('add-new-dish'),
            leading: const Icon(Icons.add),
            title: Text('Add “$_query” as a new dish'),
            onTap: _addNewDish,
          ),
      ],
    );
  }

  Widget _buildBrowse(BuildContext context) {
    final theme = Theme.of(context);
    if (_cuisinesError != null) {
      return ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(_cuisinesError!),
        trailing: TextButton(onPressed: _loadCuisines, child: const Text('Retry')),
      );
    }
    final cuisines = _cuisines;
    if (cuisines == null) return const LinearProgressIndicator();
    final dishes = _cuisine == null ? null : _dishesByCuisine[_cuisine!.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Or browse by cuisine', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cuisines.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cuisine = cuisines[index];
              return ChoiceChip(
                key: ValueKey('cuisine-${cuisine.id}'),
                label: Text(cuisine.label),
                selected: cuisine == _cuisine,
                onSelected: (_) => _selectCuisine(cuisine),
              );
            },
          ),
        ),
        if (_cuisine != null) ...[
          const SizedBox(height: 12),
          if (_loadingCuisine && dishes == null)
            const LinearProgressIndicator()
          else if (dishes != null)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final dish in dishes)
                  FilterChip(
                    key: ValueKey('cuisine-dish-${dish.id}'),
                    label: Text(dish.name),
                    selected: widget.selected.contains(dish),
                    onSelected: (_) => _toggle(dish),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}
