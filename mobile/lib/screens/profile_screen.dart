import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/auth_state.dart';
import '../widgets/review_tile.dart';
import '../widgets/states.dart';
import 'auth/sign_in_screen.dart';
import 'auth/sign_up_screen.dart';
import 'restaurant_dish_screen.dart';
import 'review/rate_dishes_screen.dart';

enum _ProfileAction { signOut, deleteAccount }

enum _ReviewAction { edit, delete }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _loadedForUserId;
  final _reviews = <Review>[];
  int _page = 0;
  bool _hasMore = false;
  bool _loading = false;
  String? _error;

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<ApiClient>().myReviews(page: more ? _page + 1 : 1);
      if (!mounted) return;
      setState(() {
        if (!more) _reviews.clear();
        _reviews.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_load(), context.read<AuthState>().refresh()]);
  }

  Future<void> _edit(Review review) async {
    final posted = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => RateDishesScreen(
        restaurantId: review.restaurantId!,
        restaurantName: review.restaurantName!,
        dishes: [Dish(id: review.dishId!, name: review.dishName!)],
      ),
    ));
    if (posted == true && mounted) {
      showMessage(context, 'Review updated.');
      _load();
    }
  }

  Future<void> _delete(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this review?'),
        content: Text('Your review of ${review.dishName} at ${review.restaurantName} will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ApiClient>().deleteReview(review.id);
      if (!mounted) return;
      showMessage(context, 'Review deleted.');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showMessage(context, error.message);
    }
  }

  Future<void> _deleteAccount() async {
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This permanently deletes your account and all of your reviews.'),
            const SizedBox(height: 16),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm with your password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    final entered = password.text;
    password.dispose();
    if (confirmed != true || !mounted) return;
    try {
      await context.read<AuthState>().deleteAccount(entered);
      if (mounted) showMessage(context, 'Your account has been deleted.');
    } on ApiException catch (error) {
      if (mounted) showMessage(context, error.message);
    }
  }

  void _onAction(_ProfileAction action) {
    switch (action) {
      case _ProfileAction.signOut:
        context.read<AuthState>().signOut();
      case _ProfileAction.deleteAccount:
        _deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;

    if (user?.id != _loadedForUserId) {
      _loadedForUserId = user?.id;
      _reviews.clear();
      if (user != null) WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (user != null)
            PopupMenuButton<_ProfileAction>(
              onSelected: _onAction,
              itemBuilder: (_) => const [
                PopupMenuItem(value: _ProfileAction.signOut, child: Text('Sign out')),
                PopupMenuItem(value: _ProfileAction.deleteAccount, child: Text('Delete account')),
              ],
            ),
        ],
      ),
      body: auth.restoring
          ? const LoadingView()
          : user == null
              ? _buildSignedOut(context)
              : RefreshIndicator(onRefresh: _refresh, child: _buildSignedIn(context, user)),
    );
  }

  Widget _buildSignedOut(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const MessageView(
          icon: Icons.person_outline,
          title: 'Your reviews live here',
          message: 'Sign in to rate dishes, remember what you loved and help others eat well.',
        ),
        FilledButton(onPressed: () => ensureSignedIn(context), child: const Text('Sign in')),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpScreen())),
          child: const Text('Create an account'),
        ),
      ],
    );
  }

  Widget _buildSignedIn(BuildContext context, User user) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(user.initials, style: theme.textTheme.titleLarge),
          ),
          title: Text(user.name, style: theme.textTheme.titleLarge),
          subtitle: Text(user.email ?? ''),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('My reviews (${user.reviewsCount ?? _reviews.length})', style: theme.textTheme.titleMedium),
        ),
        if (_reviews.isEmpty && _loading) const LoadingView(),
        if (_reviews.isEmpty && !_loading && _error != null) ErrorView(message: _error!, onRetry: _load),
        if (_reviews.isEmpty && !_loading && _error == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('You haven’t reviewed anything yet. Use the Review tab to rate a dish you’ve eaten.'),
          ),
        for (final review in _reviews)
          ReviewTile(
            key: ValueKey('my-review-${review.id}'),
            review: review,
            title: '${review.dishName} · ${review.restaurantName}',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RestaurantDishScreen(restaurantDishId: review.restaurantDishId),
            )),
            trailing: PopupMenuButton<_ReviewAction>(
              tooltip: 'Review options',
              onSelected: (action) => action == _ReviewAction.edit ? _edit(review) : _delete(review),
              itemBuilder: (_) => const [
                PopupMenuItem(value: _ReviewAction.edit, child: Text('Edit')),
                PopupMenuItem(value: _ReviewAction.delete, child: Text('Delete')),
              ],
            ),
          ),
        if (_hasMore)
          Center(
            child: _loading
                ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
                : TextButton(onPressed: () => _load(more: true), child: const Text('Show more')),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
