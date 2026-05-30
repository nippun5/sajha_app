import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _credentialCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isEmailMode = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Country picker state
  String _dialCode = AppConstants.defaultDialCode;
  String _flag = AppConstants.defaultCountryFlag;

  @override
  void dispose() {
    _credentialCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // TODO: call Java auth API
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go(AppConstants.shellRoute);
    }
  }

  void _socialLogin(String provider) {
    // TODO: Implement Google / Apple / Facebook SDK auth
    // After obtaining the social token, check if profile is complete.
    // If not → complete-profile. If yes → shell.
    context.push(
      AppConstants.completeProfileRoute,
      extra: {'provider': provider},
    );
  }

  void _openCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountryPickerSheet(
        selectedCode: _dialCode,
        onSelected: (code, flag) => setState(() {
          _dialCode = code;
          _flag = flag;
        }),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Logo ──────────────────────────────────
                Center(
                  child: Image.asset(AppConstants.logoPath,
                      width: 90, fit: BoxFit.contain),
                ),
                const SizedBox(height: 28),

                // ── Heading ───────────────────────────────
                Text('Welcome back',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 4),
                Text('Sign in to your SaJHa account',
                    style: tt.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),

                const SizedBox(height: 28),

                // ── Email / Phone toggle ──────────────────
                _SegmentedToggle(
                  isEmailMode: _isEmailMode,
                  onChanged: (v) => setState(() {
                    _isEmailMode = v;
                    _credentialCtrl.clear();
                  }),
                ),
                const SizedBox(height: 16),

                // ── Credential field ──────────────────────
                if (_isEmailMode)
                  _EmailField(controller: _credentialCtrl)
                else
                  _PhoneField(
                    controller: _credentialCtrl,
                    dialCode: _dialCode,
                    flag: _flag,
                    onPickerTap: _openCountryPicker,
                  ),

                const SizedBox(height: 12),

                // ── Password ──────────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon:
                        const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),

                // ── Forgot password ───────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: navigate to forgot password
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 8),
                    ),
                    child: const Text('Forgot password?',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),

                // ── Login button ──────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),

                const SizedBox(height: 24),

                // ── Divider ───────────────────────────────
                const _OrDivider(),
                const SizedBox(height: 20),

                // ── Social login ──────────────────────────
                _SocialButton(
                  label: 'Continue with Google',
                  iconWidget: const _GoogleG(),
                  onTap: () => _socialLogin('google'),
                ),
                const SizedBox(height: 10),
                _SocialButton(
                  label: 'Continue with Apple',
                  iconWidget:
                      const Icon(Icons.apple, size: 22, color: Colors.black),
                  onTap: () => _socialLogin('apple'),
                ),
                const SizedBox(height: 10),
                _SocialButton(
                  label: 'Continue with Facebook',
                  iconWidget: const Icon(Icons.facebook,
                      size: 22, color: Color(0xFF1877F2)),
                  onTap: () => _socialLogin('facebook'),
                ),

                const SizedBox(height: 32),

                // ── Register ──────────────────────────────
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account?  ",
                      style: tt.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // TODO: navigate to register
                            },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SegmentedToggle extends StatelessWidget {
  final bool isEmailMode;
  final ValueChanged<bool> onChanged;
  const _SegmentedToggle(
      {required this.isEmailMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _Pill(
              label: 'Email',
              active: isEmailMode,
              onTap: () => onChanged(true)),
          _Pill(
              label: 'Phone',
              active: !isEmailMode,
              onTap: () => onChanged(false)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? AppColors.textPrimary
                    : AppColors.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Email is required';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
          return 'Enter a valid email';
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Email address',
        prefixIcon: Icon(Icons.email_outlined, size: 20),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String dialCode;
  final String flag;
  final VoidCallback onPickerTap;
  const _PhoneField({
    required this.controller,
    required this.dialCode,
    required this.flag,
    required this.onPickerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Country code button
        GestureDetector(
          onTap: onPickerTap,
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
                Text(dialCode,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 2),
                const Icon(Icons.expand_more,
                    size: 16, color: AppColors.textHint),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Phone number is required';
              if (v.length < 8) return 'Enter a valid number';
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('or',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textHint)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final VoidCallback onTap;
  const _SocialButton(
      {required this.label, required this.iconWidget, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4285F4),
      ),
    );
  }
}

// ── Country Picker Bottom Sheet ───────────────────────────────────────────────
class _CountryPickerSheet extends StatefulWidget {
  final String selectedCode;
  final void Function(String code, String flag) onSelected;
  const _CountryPickerSheet(
      {required this.selectedCode, required this.onSelected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<Map<String, String>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = AppConstants.countries;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = AppConstants.countries
            .where((c) =>
                c['name']!.toLowerCase().contains(q) ||
                c['code']!.contains(q))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('Select country',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                  hintText: 'Search country…',
                  prefixIcon: Icon(Icons.search, size: 20)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                final selected = c['code'] == widget.selectedCode;
                return ListTile(
                  leading: Text(c['flag']!,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(c['name']!,
                      style: const TextStyle(fontSize: 14)),
                  trailing: Text(c['code']!,
                      style: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textHint,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 13)),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  onTap: () {
                    widget.onSelected(c['code']!, c['flag']!);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}