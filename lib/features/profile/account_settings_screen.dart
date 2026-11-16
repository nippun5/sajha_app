import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import 'data/profile_demo_store.dart';
import 'profile_widgets.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _store = ProfileDemoStore.instance;
  late final TextEditingController _name;
  late final TextEditingController _city;
  late bool _showContact;
  late bool _whatsapp;
  late bool _emailUpdates;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _store.displayName);
    _city = TextEditingController(text: _store.city);
    _showContact = _store.showContactOnListings;
    _whatsapp = _store.allowWhatsapp;
    _emailUpdates = _store.emailUpdates;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  void _save() {
    if (!_store.previewEnabled) return;
    if (_name.text.trim().length < 2) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a display name.')));
      return;
    }
    _store.updateDemoPreferences(
      displayName: _name.text.trim(),
      city: _city.text.trim(),
      showContactOnListings: _showContact,
      allowWhatsapp: _whatsapp,
      emailUpdates: _emailUpdates,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Demo preferences updated in memory only.')));
  }

  @override
  Widget build(BuildContext context) {
    final demo = kDebugMode && _store.previewEnabled;
    final signedIn = AuthSession.instance.isSignedIn;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Account & Privacy')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (demo) ...[
          const DemoBanner(),
          const SizedBox(height: 18),
          const Text('Personal details',
              style: TextStyle(
                  fontSize: 20,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Display name')),
          const SizedBox(height: 12),
          TextField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'City / Area')),
          const SizedBox(height: 22),
          const Text('Contact & notifications',
              style: TextStyle(
                  fontSize: 20,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            value: _showContact,
            onChanged: (value) => setState(() => _showContact = value),
            title: const Text('Show contact number on my listings'),
            subtitle: const Text('Off by default; actual listing visibility '
                'must be checked by the backend.'),
          ),
          SwitchListTile.adaptive(
            value: _whatsapp,
            onChanged: (value) => setState(() => _whatsapp = value),
            title: const Text('Allow WhatsApp contact'),
            subtitle: const Text('Only if you explicitly opt in.'),
          ),
          SwitchListTile.adaptive(
            value: _emailUpdates,
            onChanged: (value) => setState(() => _emailUpdates = value),
            title: const Text('Email updates'),
            subtitle: const Text('Sample preference; no emails are sent.'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save demo preferences')),
          const SizedBox(height: 20),
        ] else ...[
          const ProfileEmptyState(
              icon: Icons.manage_accounts_outlined,
              title: 'Account settings are coming',
              message: 'Authenticated profile editing, saved preferences, '
                  'and phone verification will be connected to Spring Boot.'),
          if (!signedIn)
            FilledButton(
                onPressed: () => context.push(AppConstants.loginRoute),
                child: const Text('Sign In / Create Account')),
        ],
        const Divider(),
        const SizedBox(height: 12),
        const ListTile(
          leading: Icon(Icons.security_outlined, color: AppColors.primary),
          title: Text('Security'),
          subtitle: Text('Password changes and active sessions will '
              'be available after the backend is connected.'),
        ),
        const ListTile(
          leading: Icon(Icons.delete_outline, color: AppColors.error),
          title: Text('Account deletion'),
          subtitle: Text('The actual deletion request must remove the '
              'server account and associated data after verification.'),
        ),
      ]),
    );
  }
}
