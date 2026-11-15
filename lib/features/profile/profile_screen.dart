import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: AnimatedBuilder(
        animation: AuthSession.instance,
        builder: (context, _) {
          final session = AuthSession.instance;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!session.isSignedIn) ...[
                const Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.border,
                    child: Icon(Icons.person_outline,
                        color: AppColors.primary, size: 42),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Welcome to SaJHa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Browse freely. Sign in to manage listings, '
                  'post to the marketplace and rate businesses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.push(AppConstants.loginRoute),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In / Create Account'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => context.push(
                      AppConstants.phoneVerificationRoute,
                    ),
                    child: const Text('Preview phone verification UI (debug)'),
                  ),
                ],
              ] else ...[
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.border,
                    child: Text(
                      (session.account?.displayName.isNotEmpty ?? false)
                          ? session.account!.displayName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                          fontSize: 34, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  session.account?.displayName ?? 'SaJHa member',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  session.isPhoneVerified
                      ? 'Phone verified'
                      : 'Verify your phone before posting',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: session.isPhoneVerified
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                if (!session.isPhoneVerified) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push(
                      AppConstants.phoneVerificationRoute,
                    ),
                    child: const Text('Verify phone'),
                  ),
                ],
                if (session.account?.email != null) ...[
                  const SizedBox(height: 16),
                  Text(session.account!.email!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: call backend logout/revoke endpoint first.
                    session.clearLocalSession();
                    context.go(AppConstants.loginRoute);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const _ProfileSection(
                icon: Icons.list_alt_outlined,
                title: 'My Listings',
                subtitle: 'Manage posts and listing status — next stage',
              ),
              const _ProfileSection(
                icon: Icons.bookmark_outline,
                title: 'Saved Listings',
                subtitle: 'Your saved marketplace items — next stage',
              ),
              const _ProfileSection(
                icon: Icons.storefront_outlined,
                title: 'My Business Requests',
                subtitle: 'Pending, Approved, Declined — next stage',
              ),
              const _ProfileSection(
                icon: Icons.settings_outlined,
                title: 'Account & Privacy',
                subtitle:
                    'Contact preferences and account settings — next stage',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileSection({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
