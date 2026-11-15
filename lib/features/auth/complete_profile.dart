
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class CompleteProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CompleteProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();

  String _dialCode = AppConstants.defaultDialCode;

  String get _provider {
    final provider =
        widget.userData['provider'] as String? ?? 'social';

    if (provider.isEmpty) return 'Social';

    return '${provider[0].toUpperCase()}'
        '${provider.substring(1)}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Frontend preview only.
    // After real authentication:
    // 1. Save contact information through backend.
    // 2. Verify the phone number through OTP.
    // 3. Allow publishing only after verification.
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Profile form ready'),
        content: const Text(
          'Your profile information passed validation. '
          'No data has been saved and your phone number '
          'has not been verified yet.',
        ),
        actions: [
          FilledButton(
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
      appBar: AppBar(
        title: const Text('Complete Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        AppColors.periwinkle.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$_provider profile setup preview. '
                          'No account has been authenticated.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Tell us about yourself',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Your profile helps other community '
                  'members connect with you.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 2) {
                      return 'Enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _dialCode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Country dial code',
                    prefixIcon: Icon(Icons.public),
                  ),
                  items: AppConstants.countries.map((country) {
                    return DropdownMenuItem<String>(
                      value: country['code']!,
                      child: Text(
                        '${country['flag']} ${country['name']} '
                        '(${country['code']})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _dialCode = value);
                    }
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    helperText:
                        'Required before publishing listings',
                  ),
                  validator: (value) {
                    final digits = (value ?? '')
                        .replaceAll(RegExp(r'\D'), '');

                    if (digits.length < 7 ||
                        digits.length > 15) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _cityCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'City (optional)',
                    prefixIcon:
                        Icon(Icons.location_city_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _regionCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'State / Region (optional)',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Your phone number will not be displayed '
                  'publicly unless you choose to show it '
                  'when publishing a listing.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
