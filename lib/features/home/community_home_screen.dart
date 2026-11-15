
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class CommunityHomeScreen extends StatelessWidget {
  final ValueChanged<int> onMarketplaceCategory;
  final VoidCallback onBusinesses;
  final VoidCallback onProfile;
  final VoidCallback onPost;

  const CommunityHomeScreen({
    super.key,
    required this.onMarketplaceCategory,
    required this.onBusinesses,
    required this.onProfile,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Image.asset(
          AppConstants.logoPath,
          height: 36,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            tooltip: 'Open profile',
            onPressed: onProfile,
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Community welcome banner
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.handshake_outlined,
                  color: AppColors.coralLight,
                  size: 34,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Your Community.\nYour Marketplace.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Buy, sell, find opportunities and '
                  'support local businesses.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => onMarketplaceCategory(0),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.search),
                  label: const Text('Explore Marketplace'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Explore Categories',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Discover what your community has to offer.',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _CategoryCard(
                  title: 'Buy & Sell',
                  subtitle: 'Community deals',
                  icon: Icons.shopping_bag_outlined,
                  color: AppColors.coral,
                  onTap: () => onMarketplaceCategory(0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryCard(
                  title: 'Rooms',
                  subtitle: 'Find your place',
                  icon: Icons.home_work_outlined,
                  color: AppColors.periwinkle,
                  onTap: () => onMarketplaceCategory(1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _CategoryCard(
                  title: 'Jobs',
                  subtitle: 'Find opportunities',
                  icon: Icons.work_outline,
                  color: AppColors.primary,
                  onTap: () => onMarketplaceCategory(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryCard(
                  title: 'Businesses',
                  subtitle: 'Support local',
                  icon: Icons.storefront_outlined,
                  color: AppColors.business,
                  onTap: onBusinesses,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Text(
            'Grow With Your Community',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 30,
                    color: AppColors.coral,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Have something to share?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Post an item, advertise a room, '
                    'share a job or submit your business '
                    'to reach the community.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onPost,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create a Listing'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
