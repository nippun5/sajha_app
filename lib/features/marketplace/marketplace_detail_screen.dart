import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../profile/data/profile_demo_store.dart';
import 'data/marketplace_mock_store.dart';
import 'widgets/marketplace_actions.dart';

class MarketplaceDetailScreen extends StatelessWidget {
  const MarketplaceDetailScreen({super.key, required this.item});

  final MarketItem item;

  @override
  Widget build(BuildContext context) {
    final store = MarketplaceMockStore.instance;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(item.kind.label),
        actions: [
          AnimatedBuilder(
            animation: store,
            builder: (context, _) => IconButton(
              tooltip: store.isSaved(item.id)
                  ? 'Remove saved listing'
                  : 'Save listing',
              icon: Icon(store.isSaved(item.id)
                  ? Icons.bookmark
                  : Icons.bookmark_border),
              onPressed: () => _save(context, store),
            ),
          ),
          IconButton(
            tooltip: 'Share listing',
            icon: const Icon(Icons.share_outlined),
            onPressed: item.status == MarketStatus.active
                ? () => MarketplaceActions.share(context, item)
                : null,
          ),
        ],
      ),
      bottomNavigationBar: item.status != MarketStatus.active
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Row(children: [
                  Expanded(
                      child: OutlinedButton.icon(
                    onPressed: () =>
                        MarketplaceActions.contact(context, item, sms: true),
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('SMS'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: FilledButton.icon(
                    onPressed: () =>
                        MarketplaceActions.contact(context, item, sms: false),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  )),
                ]),
              ),
            ),
      body: ListView(children: [
        SizedBox(
          height: 255,
          width: double.infinity,
          child: item.imageUrl == null
              ? const _PlaceholderImage()
              : Image.network(item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _PlaceholderImage()),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (item.ownedByDemo) ...[
              const Chip(label: Text('Local demo listing — not published')),
              const SizedBox(height: 10),
            ],
            Text(item.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                )),
            const SizedBox(height: 8),
            Text(item.priceLabel,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.coral,
                )),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              Chip(label: Text(item.category)),
              Chip(label: Text(item.location)),
            ]),
            const SizedBox(height: 20),
            const Text('Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(item.description.isEmpty
                ? 'No description provided.'
                : item.description),
            if (item.details.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text('Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...item.details.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Expanded(
                          child: Text(entry.key,
                              style: const TextStyle(
                                  color: AppColors.textSecondary))),
                      Expanded(
                          child: Text(entry.value, textAlign: TextAlign.end)),
                    ]),
                  )),
            ],
            const SizedBox(height: 22),
            const Text('Contact',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(item.contactName.isEmpty
                ? 'No contact name provided'
                : item.contactName),
            if (item.contactPhone.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Phone number not provided.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: item.status == MarketStatus.active
                  ? () => MarketplaceActions.share(context, item)
                  : null,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share this listing'),
            ),
          ]),
        ),
      ]),
    );
  }

  void _save(BuildContext context, MarketplaceMockStore store) {
    if (item.status != MarketStatus.active) return;
    if (!ProfileDemoStore.instance.previewEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sign in to save listings. For frontend testing, '
            'enable Profile demo mode in a debug build.'),
      ));
      return;
    }
    store.toggleSaved(item.id);
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.periwinkle.withOpacity(0.10),
        child: const Center(
            child: Icon(Icons.image_outlined,
                size: 72, color: AppColors.periwinkle)),
      );
}
