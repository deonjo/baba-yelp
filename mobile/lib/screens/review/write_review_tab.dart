import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/auth_state.dart';
import '../../utils/format.dart';
import '../../widgets/dish_picker.dart';
import '../../widgets/states.dart';
import '../auth/sign_in_screen.dart';
import '../restaurant_screen.dart';
import 'select_restaurant_screen.dart';

/// Use case 2, step 1: "What did you eat?" Then pick the restaurant and rate.
class WriteReviewTab extends StatefulWidget {
  const WriteReviewTab({super.key});

  @override
  State<WriteReviewTab> createState() => _WriteReviewTabState();
}

class _WriteReviewTabState extends State<WriteReviewTab> {
  List<Dish> _dishes = const [];

  Future<void> _next() async {
    final count = _dishes.length;
    final restaurant = await Navigator.of(context).push<Restaurant>(
      MaterialPageRoute(builder: (_) => SelectRestaurantScreen(dishes: _dishes)),
    );
    if (restaurant == null || !mounted) return;
    setState(() => _dishes = const []);
    showMessage(context, 'Thanks! Your ${count == 1 ? 'review is' : '$count reviews are'} posted.');
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RestaurantScreen(restaurantId: restaurant.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final theme = Theme.of(context);

    final Widget body;
    if (auth.restoring) {
      body = const LoadingView();
    } else if (!auth.isSignedIn) {
      body = MessageView(
        icon: Icons.rate_review_outlined,
        title: 'Share what you ate',
        message: 'Sign in to rate dishes and help others find great food.',
        actionLabel: 'Sign in',
        onAction: () => ensureSignedIn(context),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('What did you eat?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Pick the dishes you want to review. You can rate several at once.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          DishPicker(selected: _dishes, onChanged: (dishes) => setState(() => _dishes = dishes)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Write a review')),
      body: body,
      bottomNavigationBar: auth.isSignedIn
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.icon(
                  key: const Key('choose-restaurant'),
                  onPressed: _dishes.isEmpty ? null : _next,
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(_dishes.isEmpty
                      ? 'Pick what you ate'
                      : 'Next: where did you eat ${_dishes.length == 1 ? 'it' : pluralize(_dishes.length, 'dish', 'dishes')}?'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
            )
          : null,
    );
  }
}
