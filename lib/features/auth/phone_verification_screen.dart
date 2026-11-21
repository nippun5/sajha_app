import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/auth/backend_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Verifies the account's *registered* phone with Spring Boot + Twilio Verify.
/// If SMS is not configured the server rejects the request; never set trusted
/// status from a locally entered code.
class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  late final TextEditingController _phone;
  final TextEditingController _code = TextEditingController();
  String? _challengeId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(
      text: AuthSession.instance.account?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _requestCode() async {
    final registered = AuthSession.instance.account?.phone;
    if (!AuthSession.instance.isSignedIn || registered == null) {
      _notice('Sign in before verifying your phone.');
      return;
    }
    if (!RegExp(r'^\+[1-9][0-9]{6,14}$').hasMatch(registered)) {
      _notice('Registered phone must be in international format.');
      return;
    }
    setState(() => _busy = true);
    try {
      final challenge =
          await BackendAuth.instance.startPhoneVerification(registered);
      if (!mounted) return;
      setState(() => _challengeId = challenge);
      _notice('Verification code sent to $registered.');
    } on BackendAuthException catch (error) {
      _notice(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    final id = _challengeId;
    if (id == null) {
      _notice('Request a code first.');
      return;
    }
    if (!RegExp(r'^\d{4,10}$').hasMatch(_code.text.trim())) {
      _notice('Enter the SMS verification code.');
      return;
    }
    setState(() => _busy = true);
    try {
      final verified = await BackendAuth.instance.verifyPhone(
        challengeId: id,
        code: _code.text.trim(),
      );
      if (!mounted) return;
      if (!verified) {
        _notice('Your registered phone is not verified yet.');
        return;
      }
      context.go(AppConstants.shellRoute);
    } on BackendAuthException catch (error) {
      _notice(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verify Phone')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.phonelink_lock_outlined,
                  color: AppColors.primary, size: 62),
              const SizedBox(height: 18),
              const Text('Verify your contact number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 10),
              const Text(
                'Phone ownership must be confirmed by the server before you can post or review.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _phone,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Registered phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _requestCode,
                icon: const Icon(Icons.sms_outlined),
                label: const Text('Request SMS Code'),
              ),
              const SizedBox(height: 26),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'SMS verification code',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _verifyCode,
                child: const Text('Verify Code'),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => context.go(AppConstants.shellRoute),
                child: const Text('Browse while verification is pending'),
              ),
              const SizedBox(height: 10),
              const Text(
                'SMS requires Twilio Verify to be configured on the backend. No local demo code can verify an account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
