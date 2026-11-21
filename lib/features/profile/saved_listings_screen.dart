import '../marketplace/live/live_account_listings_screen.dart';
import '../../core/network/backend_config.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../marketplace/data/marketplace_mock_store.dart';
import '../marketplace/marketplace_detail_screen.dart';
import 'data/profile_demo_store.dart';
import 'profile_widgets.dart';

/// Reads the exact same listing IDs used in Marketplace and Detail screens.
/// The old separate sample catalog is no longer used.
class SavedListingsScreen extends StatelessWidget {
  const SavedListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (BackendConfig.configuredBase.isNotEmpty) {
      return const LiveAccountListingsScreen(mode: LiveAccountListMode.saved);
    }
    final market = MarketplaceMockStore.instance;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Saved Listings')),
      body: AnimatedBuilder(
        animation: Listenable.merge([market, ProfileDemoStore.instance]),
        builder: (context, _) {
          if (!ProfileDemoStore.instance.previewEnabled) {
            return const ProfileEmptyState(
              icon: Icons.bookmark_border,
              title: 'Save your favorite listings',
              message: 'Sign in to save listings. While developing, '
                  'turn on Profile demo mode to test bookmarks locally.',
            );
          }
          final items = market.savedListings;
          return ListView(padding: const EdgeInsets.all(16), children: [
            const DemoBanner(),
            const SizedBox(height: 12),
            const Text('Your saved listings',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: 6),
            const Text('Saved from the real marketplace preview cards.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const ProfileEmptyState(
                icon: Icons.bookmarks_outlined,
                title: 'No saved items yet',
                message: 'Open Marketplace and tap the bookmark icon.',
              )
            else
              ...items.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                          backgroundColor: AppColors.background,
                          child: Icon(Icons.bookmark, color: AppColors.coral)),
                      title: Text(item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${item.kind.label} · ${item.priceLabel}\n${item.location}'),
                      isThreeLine: true,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  MarketplaceDetailScreen(item: item))),
                      trailing: IconButton(
                        tooltip: 'Remove saved item',
                        icon: const Icon(Icons.bookmark_remove_outlined,
                            color: AppColors.coral),
                        onPressed: () => market.toggleSaved(item.id),
                      ),
                    ),
                  )),
          ]);
        },
      ),
    );
  }
}
