import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/auth/backend_auth.dart';
import '../../core/auth/social_provider_login.dart';
import '../../core/constants/app_constants.dart';

/// Linking requires BOTH a SaJHa session and a freshly verified provider credential.
class LinkedAccountsScreen extends StatefulWidget {
  const LinkedAccountsScreen({super.key});
  @override
  State<LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<LinkedAccountsScreen> {
  bool _busy = false;

  Future<void> _link(String provider) async {
    if (_busy || !AuthSession.instance.isSignedIn) return;
    setState(() => _busy = true);
    try {
      final proof = await SocialProviderLogin.obtain(provider);
      await BackendAuth.instance.linkSocialAccount(
        provider: proof.provider,
        credential: proof.credential,
        nonce: proof.nonce,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${provider[0].toUpperCase()}${provider.substring(1)} connected successfully.'),
      ));
    } on BackendAuthException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Connection failed. Check provider setup.')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke() async {
    if (_busy) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out on all devices?'),
        content: const Text(
            'All active sessions will be revoked, including this one.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out everywhere')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await BackendAuth.instance.signOutEverywhere();
      if (mounted) context.go(AppConstants.loginRoute);
    } on BackendAuthException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Connected accounts & security')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text(
              'Connect another sign-in provider to your existing SaJHa account.',
              style: TextStyle(fontSize: 15)),
          const SizedBox(height: 16),
          for (final provider in ['google', 'apple', 'facebook'])
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(
                  'Connect ${provider[0].toUpperCase()}${provider.substring(1)}'),
              subtitle: Text(provider == 'facebook'
                  ? 'Android classic login only for now'
                  : 'Requires provider configuration'),
              enabled: !_busy && AuthSession.instance.isSignedIn,
              onTap: () => _link(provider),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out on all devices'),
            subtitle: const Text('Revoke all access and refresh sessions'),
            enabled: !_busy && AuthSession.instance.isSignedIn,
            onTap: _revoke,
          ),
        ]),
      );
}
