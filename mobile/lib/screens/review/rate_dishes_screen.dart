import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../state/auth_state.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/states.dart';

/// Use case 2, final step: rate each dish and say what you thought.
/// Pops with true once the reviews are posted.
class RateDishesScreen extends StatefulWidget {
  const RateDishesScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.dishes,
  });

  final int restaurantId;
  final String restaurantName;
  final List<Dish> dishes;

  @override
  State<RateDishesScreen> createState() => _RateDishesScreenState();
}

class _RateDishesScreenState extends State<RateDishesScreen> {
  final _ratings = <int, int>{};
  late final _bodies = {for (final dish in widget.dishes) dish.id: TextEditingController()};
  final _alreadyReviewed = <int>{};
  bool _loadingExisting = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExistingReviews();
  }

  @override
  void dispose() {
    for (final controller in _bodies.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Prefill dishes you've reviewed here before; posting again updates them.
  Future<void> _loadExistingReviews() async {
    try {
      final page = await context.read<ApiClient>().myReviews(restaurantId: widget.restaurantId, perPage: 50);
      if (!mounted) return;
      setState(() {
        for (final review in page.items) {
          final dishId = review.dishId;
          if (dishId == null || !_bodies.containsKey(dishId)) continue;
          _alreadyReviewed.add(dishId);
          _ratings[dishId] = review.rating;
          _bodies[dishId]!.text = review.body ?? '';
        }
      });
    } on ApiException {
      // Not fatal: the form just starts empty.
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  bool get _complete => widget.dishes.every((dish) => (_ratings[dish.id] ?? 0) > 0);

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<ApiClient>().submitReviews(widget.restaurantId, [
        for (final dish in widget.dishes)
          ReviewInput(dishId: dish.id, rating: _ratings[dish.id]!, body: _bodies[dish.id]!.text),
      ]);
      if (!mounted) return;
      context.read<AuthState>().refresh();
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.dishes.length;
    return Scaffold(
      appBar: AppBar(title: Text(count == 1 ? 'Rate your dish' : 'Rate your dishes')),
      body: _loadingExisting
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('At ${widget.restaurantName}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final dish in widget.dishes) ...[
                  Card(
                    key: ValueKey('rate-dish-${dish.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dish.name, style: theme.textTheme.titleLarge),
                          if (_alreadyReviewed.contains(dish.id))
                            Text(
                              'You reviewed this before. Posting will update your review.',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          const SizedBox(height: 8),
                          StarRatingInput(
                            value: _ratings[dish.id] ?? 0,
                            onChanged: (stars) => setState(() => _ratings[dish.id] = stars),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: ValueKey('review-body-${dish.id}'),
                            controller: _bodies[dish.id],
                            minLines: 3,
                            maxLines: 8,
                            maxLength: 2000,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'How did it taste? Flavor, portion, spice level…',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_error != null) Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton(
            key: const Key('post-reviews'),
            onPressed: _complete && !_submitting && !_loadingExisting ? _submit : null,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _submitting
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_complete
                    ? (count == 1 ? 'Post review' : 'Post $count reviews')
                    : 'Tap the stars to rate ${count == 1 ? 'it' : 'each dish'}'),
          ),
        ),
      ),
    );
  }
}
