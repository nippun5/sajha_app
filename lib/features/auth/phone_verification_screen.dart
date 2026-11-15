import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_colors.dart';

/// UI-only preview. Never verifies a real number or changes AuthSession.
class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  late final TextEditingController _phoneController;
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: AuthSession.instance.account?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _previewNotice(String action) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$action — preview'),
        content: const Text(
          'Phone verification is not connected yet. '
          'No SMS was sent, no code was verified, and '
          'your account status has not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verify Phone')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.phonelink_lock_outlined,
                    color: AppColors.primary, size: 62),
                const SizedBox(height: 18),
                const Text(
                  'Keep the community trusted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                const Text(
                  'A verified phone number will be required '
                  'before publishing listings or reviews.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 26),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number with country code',
                    hintText: '+61412345678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
                      return 'Use international format, e.g. +61412345678';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _previewNotice('Request OTP');
                    }
                  },
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('Request Code'),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-digit verification code',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () => _previewNotice('Verify code'),
                  child: const Text('Verify Code'),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Frontend preview only — no SMS provider is connected.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
