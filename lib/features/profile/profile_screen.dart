
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.border,
            child: Icon(
              Icons.person_outline,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to SaJHa',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your community marketplace account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.push(AppConstants.loginRoute);
            },
            icon: const Icon(Icons.login),
            label: const Text('Open Sign In'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Authentication is currently a frontend preview. '
            'Real account information will be connected later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const _ProfileFeature(
            icon: Icons.list_alt_outlined,
            title: 'My Listings',
            subtitle: 'Manage your marketplace posts',
          ),
          const _ProfileFeature(
            icon: Icons.bookmark_border,
            title: 'Saved Listings',
            subtitle: 'View your favorite posts',
          ),
          const _ProfileFeature(
            icon: Icons.storefront_outlined,
            title: 'My Business Requests',
            subtitle: 'Track pending, approved and declined requests',
          ),
          const _ProfileFeature(
            icon: Icons.settings_outlined,
            title: 'Account Settings',
            subtitle: 'Manage contact details and privacy',
          ),
          const SizedBox(height: 16),
          const Text(
            'These sections will become interactive '
            'when we complete the profile feature.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
