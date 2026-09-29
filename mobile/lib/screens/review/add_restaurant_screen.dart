import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../models/models.dart';
import '../../services/location_service.dart';
import '../../state/location_state.dart';
import '../../widgets/states.dart';

/// Adds a restaurant: by address (geocoded by the server) or pinned to where
/// you are right now.
class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key, this.initialName = ''});

  final String initialName;

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _phone = TextEditingController();
  GeoPoint? _pinned;
  bool _locating = false;
  bool _saving = false;
  ApiException? _error;

  @override
  void dispose() {
    for (final controller in [_name, _address, _city, _state, _zip, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final point = await context.read<LocationState>().locationService.currentPosition();
      if (!mounted) return;
      Place? place;
      try {
        place = await context.read<ApiClient>().reverseGeocode(point);
      } on ApiException {
        place = null;
      }
      if (!mounted) return;
      setState(() {
        _pinned = point;
        if (place != null) {
          _address.text = place.street ?? _address.text;
          _city.text = place.city ?? _city.text;
          _state.text = place.state ?? _state.text;
          _zip.text = place.zipCode ?? _zip.text;
        }
      });
      showMessage(
        context,
        place == null
            ? 'Pinned to your location. Please fill in the address.'
            : 'Address filled in from your location. Please double-check it.',
      );
    } on LocationException catch (error) {
      if (mounted) showMessage(context, error.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    Restaurant? existing;
    ApiException? failure;
    try {
      final restaurant = await context.read<ApiClient>().createRestaurant(NewRestaurant(
        name: _name.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        zipCode: _zip.text.trim().isEmpty ? null : _zip.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        location: _pinned,
      ));
      if (mounted) Navigator.of(context).pop(restaurant);
      return;
    } on DuplicateRestaurantException catch (error) {
      existing = error.existing;
    } on ApiException catch (error) {
      failure = error;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = failure;
    });
    if (existing != null) _offerExisting(existing);
  }

  Future<void> _offerExisting(Restaurant existing) async {
    final useExisting = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Already listed'),
        content: Text('${existing.name} is already on Baba Yelp at ${existing.fullAddress}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Use it')),
        ],
      ),
    );
    if (useExisting == true && mounted) Navigator.of(context).pop(existing);
  }

  String? _required(String? value, String message) => (value ?? '').trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: const Text('Add a restaurant')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Add the place where you ate. We’ll put it on the map so others can find it.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('restaurant-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Restaurant name', errorText: error?.fieldError('name')),
              validator: (value) => _required(value, 'Enter the restaurant’s name'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_pinned == null ? Icons.my_location : Icons.check_circle_outline),
              label: Text(_pinned == null ? 'I’m here now: use my location' : 'Pinned to your location'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('restaurant-address'),
              controller: _address,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Street address', errorText: error?.fieldError('address')),
              validator: (value) => _required(value, 'Enter the street address'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    key: const Key('restaurant-city'),
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: 'City', errorText: error?.fieldError('city')),
                    validator: (value) => _required(value, 'Enter the city'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: const Key('restaurant-state'),
                    controller: _state,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(labelText: 'State', errorText: error?.fieldError('state')),
                    validator: (value) => _required(value, 'Required'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _zip,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'ZIP (optional)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone (optional)'),
                  ),
                ),
              ],
            ),
            if (error != null && error.fieldErrors.isEmpty) ...[
              const SizedBox(height: 16),
              Text(error.message, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton(
            key: const Key('save-restaurant'),
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Add restaurant'),
          ),
        ),
      ),
    );
  }
}
