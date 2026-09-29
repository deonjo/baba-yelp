import 'package:flutter/foundation.dart';

/// Where the Rails API lives. Override at build time, e.g.
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000`
/// (a physical phone needs your computer's LAN address).
class AppConfig {
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    // The Android emulator reaches the host machine's localhost as 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}
