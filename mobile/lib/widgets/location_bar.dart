import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/location_state.dart';

/// Shows where searches are made from; tap to change it.
class LocationBar extends StatelessWidget {
  const LocationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LocationState>();
    final theme = Theme.of(context);
    final location = state.location;
    final error = state.error;

    return Card(
      child: ListTile(
        key: const Key('location-bar'),
        onTap: () => showLocationPicker(context),
        leading: Icon(
          location?.isCurrent ?? true ? Icons.my_location : Icons.place_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          state.locating
              ? 'Finding your location…'
              : location?.label ?? 'Choose where to search',
        ),
        subtitle: error != null && location == null
            ? Text(error.message, style: TextStyle(color: theme.colorScheme.error))
            : null,
        trailing: state.locating
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : TextButton(onPressed: () => showLocationPicker(context), child: const Text('Change')),
      ),
    );
  }
}

Future<void> showLocationPicker(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _LocationPickerSheet(),
    );

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _controller = TextEditingController();
  bool _searching = false;
  String? _error;
  List<Place>? _results;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.length < 2) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await context.read<ApiClient>().geocode(query);
      if (mounted) setState(() => _results = results);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _useCurrentLocation() {
    context.read<LocationState>().useCurrentLocation();
    Navigator.of(context).pop();
  }

  void _usePlace(Place place) {
    context.read<LocationState>().usePlace(place);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LocationState>();
    final theme = Theme.of(context);
    final results = _results;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Search near', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.my_location),
                title: const Text('Use my current location'),
                onTap: _useCurrentLocation,
              ),
              if (state.error?.canOpenSettings ?? false)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => state.locationService.openSettings(),
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Open location settings'),
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('place-search'),
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  labelText: 'City, neighborhood, address or ZIP',
                  hintText: 'e.g. Fremont, CA',
                  suffixIcon: IconButton(
                    tooltip: 'Search',
                    icon: const Icon(Icons.search),
                    onPressed: _search,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_searching) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ),
              if (results != null && results.isEmpty && !_searching)
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.search_off),
                  title: Text('No places found. Try adding the state, e.g. “Fremont, CA”.'),
                ),
              for (final place in results ?? const <Place>[])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(place.label),
                  subtitle: place.address == null
                      ? null
                      : Text(place.address!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => _usePlace(place),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
