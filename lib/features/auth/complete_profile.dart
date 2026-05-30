import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class CompleteProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const CompleteProfileScreen({super.key, required this.userData});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _suburbCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postcodeCtrl = TextEditingController();

  bool _isLoading = false;
  String _dialCode = AppConstants.defaultDialCode;
  String _flag = AppConstants.defaultCountryFlag;

  String get _provider =>
      widget.userData['provider'] as String? ?? 'social';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _suburbCtrl.dispose();
    _stateCtrl.dispose();
    _postcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // TODO: POST profile data to Java API
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go(AppConstants.shellRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Complete Profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.go(AppConstants.shellRoute),
            child: const Text('Skip',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Progress ──────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.7,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Text('70% complete',
                    style: tt.bodySmall
                        ?.copyWith(color: AppColors.textHint)),

                const SizedBox(height: 24),

                // ── Provider badge ────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Signed in with ${_capitalize(_provider)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text('Just a few more details',
                    style: tt.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Help us connect you with listings near you.',
                  style: tt.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),

                const SizedBox(height: 28),

                // ── Phone ─────────────────────────────────
                _SectionLabel(label: 'Contact number'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _DialButton(
                        flag: _flag,
                        code: _dialCode,
                        onTap: () {
                          // TODO: open country picker (reuse from login)
                        }),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Phone is required'
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'Mobile number',
                          prefixIcon:
                              Icon(Icons.phone_outlined, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Address ───────────────────────────────
                _SectionLabel(label: 'Address'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _streetCtrl,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Street address is required'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Street address',
                    prefixIcon:
                        Icon(Icons.location_on_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _suburbCtrl,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                        decoration:
                            const InputDecoration(labelText: 'Suburb'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _stateCtrl,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                        decoration:
                            const InputDecoration(labelText: 'State'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _postcodeCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                        decoration:
                            const InputDecoration(labelText: 'Postcode'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Submit ────────────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save & Continue'),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      );
}

class _DialButton extends StatelessWidget {
  final String flag;
  final String code;
  final VoidCallback onTap;
  const _DialButton(
      {required this.flag, required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            Text(code,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more,
                size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}