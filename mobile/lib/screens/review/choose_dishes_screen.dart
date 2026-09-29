import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../widgets/dish_picker.dart';
import 'rate_dishes_screen.dart';

/// Pick which dishes you ate at a known restaurant, then rate them.
class ChooseDishesScreen extends StatefulWidget {
  const ChooseDishesScreen({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  State<ChooseDishesScreen> createState() => _ChooseDishesScreenState();
}

class _ChooseDishesScreenState extends State<ChooseDishesScreen> {
  List<Dish> _dishes = const [];

  void _toggle(Dish dish) => setState(() {
        _dishes = _dishes.contains(dish)
            ? _dishes.where((d) => d != dish).toList()
            : [..._dishes, dish];
      });

  Future<void> _next() async {
    final posted = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => RateDishesScreen(
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        dishes: _dishes,
      ),
    ));
    if (posted == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menu = widget.restaurant.dishes;
    return Scaffold(
      appBar: AppBar(title: const Text('What did you eat?')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('At ${widget.restaurant.name}', style: theme.textTheme.titleMedium),
          if (menu.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('On the menu here', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final item in menu)
                  FilterChip(
                    label: Text(item.name),
                    selected: _dishes.contains(item.toDish()),
                    onSelected: (_) => _toggle(item.toDish()),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text(menu.isEmpty ? 'Find the dishes you ate' : 'Something else?', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          DishPicker(selected: _dishes, onChanged: (dishes) => setState(() => _dishes = dishes)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton(
            onPressed: _dishes.isEmpty ? null : _next,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text(_dishes.isEmpty ? 'Pick what you ate' : 'Next: rate ${_dishes.length == 1 ? 'it' : 'them'}'),
          ),
        ),
      ),
    );
  }
}
