import '../marketplace/live/live_account_listings_screen.dart';
import '../../core/network/backend_config.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../marketplace/data/marketplace_mock_store.dart';
import '../marketplace/marketplace_detail_screen.dart';
import 'data/profile_demo_store.dart';
import 'profile_widgets.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final _market = MarketplaceMockStore.instance;
  String _filter = 'All';

  @override
  Widget build(BuildContext context) => BackendConfig.configuredBase.isNotEmpty
      ? const LiveAccountListingsScreen(mode: LiveAccountListMode.mine)
      : Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('My Listings')),
          body: AnimatedBuilder(
            animation: Listenable.merge([_market, ProfileDemoStore.instance]),
            builder: (context, _) {
              if (!ProfileDemoStore.instance.previewEnabled) {
                return const ProfileEmptyState(
                  icon: Icons.lock_outline,
                  title: 'Sign in to manage listings',
                  message: 'This page will display your posts when '
                      'authentication and the marketplace API are connected. '
                      'Use Profile demo mode in a debug build to test locally.',
                );
              }
              final items = _market.myListings
                  .where((e) => _filter == 'All' || e.status.label == _filter)
                  .toList();
              return ListView(padding: const EdgeInsets.all(16), children: [
                const DemoBanner(),
                const SizedBox(height: 14),
                const Text('Your marketplace posts',
                    style: TextStyle(
                        fontSize: 20,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                    'Drafts are private. Activating a listing here '
                    'only makes it visible in this app\'s local demo marketplace.',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                      children: ['All', 'Active', 'Closed', 'Draft']
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(f),
                                  selected: _filter == f,
                                  onSelected: (_) =>
                                      setState(() => _filter = f),
                                ),
                              ))
                          .toList()),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const ProfileEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No listings in this category',
                    message: 'Create a test listing from the Post tab.',
                  )
                else
                  ...items.map(_card),
              ]);
            },
          ),
        );

  Widget _card(MarketItem item) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                backgroundColor: AppColors.periwinkle.withOpacity(0.12),
                child: Icon(_icon(item.kind), color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text('${item.kind.label} · ${item.location}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(item.priceLabel,
                      style: const TextStyle(
                          color: AppColors.coral, fontWeight: FontWeight.bold)),
                ],
              )),
              Chip(label: Text(item.status.label)),
            ]),
            const Divider(height: 24),
            Wrap(spacing: 8, runSpacing: 6, children: [
              OutlinedButton.icon(
                onPressed: () => _edit(item),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
              if (item.status == MarketStatus.active)
                OutlinedButton.icon(
                  onPressed: () =>
                      _market.updateMine(item.id, status: MarketStatus.closed),
                  icon: const Icon(Icons.pause_circle_outline, size: 16),
                  label: const Text('Close'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () =>
                      _market.updateMine(item.id, status: MarketStatus.active),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Activate demo'),
                ),
              if (item.status == MarketStatus.active)
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => MarketplaceDetailScreen(item: item))),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                ),
              TextButton.icon(
                onPressed: () => _delete(item),
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 16),
                label: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
              ),
            ]),
          ]),
        ),
      );

  IconData _icon(MarketKind kind) => switch (kind) {
        MarketKind.buySell => Icons.shopping_bag_outlined,
        MarketKind.room => Icons.home_outlined,
        MarketKind.job => Icons.work_outline,
      };

  Future<void> _edit(MarketItem item) async {
    final title = TextEditingController(text: item.title);
    final price = TextEditingController(text: item.priceLabel);
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Edit demo listing'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: title,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: price,
                maxLength: 50,
                decoration: const InputDecoration(labelText: 'Price / pay')),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () {
                  if (title.text.trim().isEmpty || price.text.trim().isEmpty) {
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Save demo')),
          ],
        ),
      );
      if (ok == true) {
        _market.updateMine(item.id,
            title: title.text.trim(), priceLabel: price.text.trim());
      }
    } finally {
      title.dispose();
      price.dispose();
    }
  }

  Future<void> _delete(MarketItem item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete demo listing?'),
        content: Text('Remove "${item.title}" from this device\'s demo data?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) _market.deleteMine(item.id);
  }
}
