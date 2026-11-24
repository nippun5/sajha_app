import 'linked_accounts_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../marketplace/data/marketplace_mock_store.dart';
import 'account_settings_screen.dart';
import 'business_requests_screen.dart';
import 'data/profile_demo_store.dart';
import 'my_listings_screen.dart';
import 'profile_widgets.dart';
import 'saved_listings_screen.dart';

import '../../core/auth/backend_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    final session = AuthSession.instance;
    final preview = ProfileDemoStore.instance.previewEnabled;
    if (!session.isSignedIn && !preview) {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_person_outlined,
                  size: 42, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text('Sign in to continue',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  'These personal pages are available to '
                  'authenticated accounts. You can browse without signing in.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push(AppConstants.loginRoute);
                },
                child: const Text('Sign In / Create Account'),
              ),
            ]),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final store = ProfileDemoStore.instance;
    final auth = AuthSession.instance;
    final market = MarketplaceMockStore.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Profile')),
      body: AnimatedBuilder(
        animation: Listenable.merge([auth, store, market]),
        builder: (context, _) {
          final signedIn = auth.isSignedIn;
          final preview = kDebugMode && store.previewEnabled;
          final displayName = signedIn
              ? (auth.account?.displayName ?? 'SaJHa Member')
              : preview
                  ? store.displayName
                  : 'Welcome to SaJHa';
          final initial = displayName.isNotEmpty
              ? displayName.substring(0, 1).toUpperCase()
              : 'S';
          return ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight]),
                  borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.coralLight,
                    child: Text(initial,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary))),
                const SizedBox(height: 14),
                Text(displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                    signedIn
                        ? (auth.isPhoneVerified
                            ? 'Phone verified'
                            : 'Phone verification required')
                        : preview
                            ? 'Demo user — NOT signed in'
                            : 'Guest browsing',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
                if (!signedIn) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary),
                    onPressed: () => context.push(AppConstants.loginRoute),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign In / Create Account'),
                  ),
                ] else if (!auth.isPhoneVerified) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        context.push(AppConstants.phoneVerificationRoute),
                    child: const Text('Verify Phone'),
                  ),
                ],
              ]),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile.adaptive(
                  value: preview,
                  onChanged: (value) =>
                      value ? store.enablePreview() : store.disablePreview(),
                  secondary: const Icon(Icons.science_outlined,
                      color: AppColors.coral),
                  title: const Text('Profile demo mode'),
                  subtitle: const Text('Temporary local sample data only. '
                      'Never signs you in or publishes listings.'),
                ),
              ),
            ],
            if (preview) ...[
              const SizedBox(height: 10),
              const DemoBanner(),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _SummaryCard(
                        value: '${market.myListings.length}',
                        label: 'My Listings',
                        icon: Icons.inventory_2_outlined)),
                const SizedBox(width: 8),
                Expanded(
                    child: _SummaryCard(
                        value: '${market.savedListings.length}',
                        label: 'Saved',
                        icon: Icons.bookmark_outline)),
                const SizedBox(width: 8),
                Expanded(
                    child: _SummaryCard(
                        value: '${store.businessRequests.length}',
                        label: 'Requests',
                        icon: Icons.storefront_outlined)),
              ]),
            ],
            const SizedBox(height: 24),
            const Text('Your marketplace',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: 10),
            _ProfileLink(
              icon: Icons.inventory_2_outlined,
              title: 'My Listings',
              subtitle: 'Edit, close and manage marketplace posts',
              onTap: () => _open(context, const MyListingsScreen()),
            ),
            _ProfileLink(
              icon: Icons.bookmark_outline,
              title: 'Saved Listings',
              subtitle: 'Items, rooms and jobs you bookmarked',
              onTap: () => _open(context, const SavedListingsScreen()),
            ),
            _ProfileLink(
              icon: Icons.storefront_outlined,
              title: 'My Business Requests',
              subtitle: 'Pending, Approved and Declined',
              onTap: () => _open(context, const BusinessRequestsScreen()),
            ),
            _ProfileLink(
              icon: Icons.settings_outlined,
              title: 'Account & Privacy',
              subtitle: 'Contact choices, profile and security',
              onTap: () => _open(context, const AccountSettingsScreen()),
            ),
            if (signedIn)
              _ProfileLink(
                icon: Icons.verified_user_outlined,
                title: 'Connected accounts & security',
                subtitle: 'Google, Apple, Facebook, and sign out everywhere',
                onTap: () => _open(context, const LinkedAccountsScreen()),
              ),
            const SizedBox(height: 12),
            if (signedIn)
              OutlinedButton.icon(
                onPressed: () async {
                  await BackendAuth.instance.signOut();
                  if (context.mounted) context.go(AppConstants.loginRoute);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            const SizedBox(height: 20),
          ]);
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Icon(icon, size: 20, color: AppColors.coral),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        Text(label,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: CircleAvatar(
            backgroundColor: AppColors.periwinkle.withOpacity(0.10),
            child: Icon(icon, color: AppColors.primary)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
