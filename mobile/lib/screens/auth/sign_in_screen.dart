import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../state/auth_state.dart';
import 'sign_up_screen.dart';

/// Returns true once the user is signed in, asking them to sign in if needed.
Future<bool> ensureSignedIn(BuildContext context, {String? reason}) async {
  if (context.read<AuthState>().isSignedIn) return true;
  final signedIn = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => SignInScreen(reason: reason)),
  );
  return signedIn ?? false;
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.reason});

  /// Why we're asking, e.g. "Sign in to post reviews."
  final String? reason;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthState>().signIn(email: _email.text.trim(), password: _password.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signUp() async {
    final signedUp = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
    if (signedUp == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(widget.reason ?? 'Welcome back!', style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
              TextFormField(
                key: const Key('sign-in-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => (value ?? '').contains('@') ? null : 'Enter your email address',
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('sign-in-password'),
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) => (value ?? '').isEmpty ? 'Enter your password' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('sign-in-submit'),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _submitting ? null : _signUp,
                child: const Text('New here? Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
