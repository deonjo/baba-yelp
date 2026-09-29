import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import 'auth/sign_in_screen.dart';

/// Adds a dish that isn't in the catalog yet. Pops with the new dish.
class AddDishScreen extends StatefulWidget {
  const AddDishScreen({super.key, this.initialName = ''});

  final String initialName;

  @override
  State<AddDishScreen> createState() => _AddDishScreenState();
}

class _AddDishScreenState extends State<AddDishScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  final _aliases = TextEditingController();
  final _description = TextEditingController();
  List<Cuisine>? _cuisines;
  Cuisine? _cuisine;
  bool _saving = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _loadCuisines();
  }

  @override
  void dispose() {
    _name.dispose();
    _aliases.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadCuisines() async {
    try {
      final cuisines = await context.read<ApiClient>().cuisines();
      if (mounted) setState(() => _cuisines = cuisines);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await ensureSignedIn(context, reason: 'Sign in to add dishes.') || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final dish = await context.read<ApiClient>().createDish(
            name: _name.text.trim(),
            cuisineId: _cuisine!.id,
            aliases: _aliases.text.trim().isEmpty ? null : _aliases.text.trim(),
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(dish);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: const Text('Add a dish')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Can’t find a dish? Add it so everyone can rate it.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Dish name', errorText: error?.fieldError('name')),
              validator: (value) => (value ?? '').trim().isEmpty ? 'Enter the dish name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Cuisine>(
              initialValue: _cuisine,
              items: [
                for (final cuisine in _cuisines ?? const <Cuisine>[])
                  DropdownMenuItem(value: cuisine, child: Text(cuisine.label)),
              ],
              onChanged: (cuisine) => setState(() => _cuisine = cuisine),
              decoration: InputDecoration(
                labelText: 'Cuisine',
                errorText: error?.fieldError('cuisine'),
                helperText: _cuisines == null ? 'Loading cuisines…' : null,
              ),
              validator: (value) => value == null ? 'Pick a cuisine' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aliases,
              decoration: const InputDecoration(
                labelText: 'Other names (optional)',
                helperText: 'Comma-separated, e.g. Phat Thai, Pad Thai Noodles',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            if (error != null && error.fieldErrors.isEmpty)
              Text(error.message, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Add dish'),
          ),
        ),
      ),
    );
  }
}
