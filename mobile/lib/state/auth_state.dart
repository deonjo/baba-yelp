import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../services/token_store.dart';

/// Who is signed in. Browsing works signed out; writing needs an account.
class AuthState extends ChangeNotifier {
  AuthState({required this.api, required this.tokenStore}) {
    api.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient api;
  final TokenStore tokenStore;

  User? _user;
  bool _restoring = true;

  User? get user => _user;
  bool get isSignedIn => _user != null;

  /// True until the saved session (if any) has been checked at startup.
  bool get restoring => _restoring;

  Future<void> restore() async {
    try {
      final token = await tokenStore.read();
      if (token == null) return;
      api.token = token;
      _user = await api.me();
    } on ApiException catch (error) {
      api.token = null;
      // Forget revoked tokens; keep the token if the server was just unreachable.
      if (error.isUnauthorized) await tokenStore.clear();
    } catch (_) {
      api.token = null;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<void> signIn({required String email, required String password}) async =>
      _startSession(await api.signIn(email: email, password: password));

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async =>
      _startSession(await api.signUp(name: name, email: email, password: password));

  Future<void> signOut() async {
    try {
      await api.signOut();
    } on ApiException {
      // Signing out locally is what matters.
    }
    await _endSession();
  }

  Future<void> deleteAccount(String password) async {
    await api.deleteAccount(password);
    await _endSession();
  }

  /// Re-fetches the profile, e.g. to update the review count.
  Future<void> refresh() async {
    if (!isSignedIn) return;
    try {
      _user = await api.me();
      notifyListeners();
    } on ApiException {
      // Keep the current profile.
    }
  }

  Future<void> _startSession(AuthResult result) async {
    api.token = result.token;
    _user = result.user;
    await tokenStore.write(result.token);
    notifyListeners();
  }

  Future<void> _endSession() async {
    api.token = null;
    _user = null;
    await tokenStore.clear();
    notifyListeners();
  }

  void _handleUnauthorized() {
    if (isSignedIn) _endSession();
  }
}
