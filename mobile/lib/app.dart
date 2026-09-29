import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'config.dart';
import 'screens/home_shell.dart';
import 'services/location_service.dart';
import 'services/token_store.dart';
import 'state/auth_state.dart';
import 'state/location_state.dart';
import 'theme.dart';

class BabaYelpApp extends StatelessWidget {
  const BabaYelpApp({
    super.key,
    required this.api,
    required this.auth,
    required this.location,
  });

  /// Wires up the app's services. Tests pass fakes for any of them.
  factory BabaYelpApp.create({
    ApiClient? api,
    TokenStore? tokenStore,
    LocationService? locationService,
  }) {
    final client = api ?? ApiClient(baseUrl: AppConfig.apiBaseUrl);
    final auth = AuthState(api: client, tokenStore: tokenStore ?? const SecureTokenStore())..restore();
    final location = LocationState(
      locationService: locationService ?? const DeviceLocationService(),
      api: client,
    );
    return BabaYelpApp(api: client, auth: auth, location: location);
  }

  final ApiClient api;
  final AuthState auth;
  final LocationState location;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: api),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: location),
      ],
      child: MaterialApp(
        title: 'Baba Yelp',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const HomeShell(),
      ),
    );
  }
}
