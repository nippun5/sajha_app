import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/password_recovery_api.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Reuses SaJHa's original recovery route and brand theme.
/// In local mode, retrieve the one-time token from the Spring Boot terminal.
class LivePasswordRecoveryScreen extends StatefulWidget {
  const LivePasswordRecoveryScreen({super.key});

  @override
  State<LivePasswordRecoveryScreen> createState() =>
      _LivePasswordRecoveryScreenState();
}

class _LivePasswordRecoveryScreenState
    extends State<LivePasswordRecoveryScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _api = PasswordRecoveryApi();
  bool _submitted = false;
  bool _working = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _working) return;
    setState(() => _working = true);
    try {
      if (!_submitted) {
        await _api.requestReset(_email.text);
        if (!mounted) return;
        setState(() => _submitted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
            'If this account exists, follow the recovery instructions.',
          )),
        );
      } else {
        await _api.redeem(token: _token.text, newPassword: _password.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password changed. Please sign in again.')),
        );
        context.go(AppConstants.loginRoute);
      }
    } on PasswordRecoveryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to complete password recovery.')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Recover Account')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  const Icon(Icons.lock_reset_outlined,
                      size: 56, color: AppColors.coral),
                  const SizedBox(height: 24),
                  Text(
                    _submitted ? 'Set a new password' : 'Forgot your password?',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _submitted
                        ? 'Enter your recovery token and a new password.'
                        : 'Enter your account email to request password recovery.',
                    style: const TextStyle(
                        color: AppColors.textSecondary, height: 1.5),
                  ),
                  if (_submitted && kDebugMode) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Local testing: find [SaJHa LOCAL PASSWORD RESET] in the Spring Boot terminal. No email is sent.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (!_submitted)
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined)),
                      validator: (s) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch((s ?? '').trim())
                          ? null
                          : 'Enter a valid email',
                    )
                  else ...[
                    TextFormField(
                      controller: _token,
                      autocorrect: false,
                      decoration: const InputDecoration(
                          labelText: 'Recovery token',
                          prefixIcon: Icon(Icons.key_outlined)),
                      validator: (s) =>
                          (s ?? '').trim().isEmpty ? 'Enter the token' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'New password (10+ characters)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(_hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                        ),
                      ),
                      validator: (s) => (s ?? '').length < 10
                          ? 'Use at least 10 characters'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _working ? null : _submit,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: AppColors.primary),
                      child: _working
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_submitted ? 'Reset Password' : 'Continue'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                      child: TextButton(
                    onPressed: () => context.go(AppConstants.loginRoute),
                    child: const Text('Back to Sign In'),
                  )),
                ],
              ),
            ),
          ),
        ),
      );
}
