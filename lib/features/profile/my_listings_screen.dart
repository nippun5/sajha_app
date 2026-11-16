import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_colors.dart';
import 'data/profile_demo_store.dart';
import 'profile_widgets.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  String _filter = 'All';
  final _store = ProfileDemoStore.instance;

  bool get _canView =>
      AuthSession.instance.isSignedIn || (kDebugMode && _store.previewEnabled);

  Future<void> _edit(ProfileListing item) async {
    final title = TextEditingController(text: item.title);
    final price = TextEditingController(text: item.priceLabel);
    try {
      final save = await showDialog<bool>(
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
                decoration:
                    const InputDecoration(labelText: 'Price / compensation')),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save locally')),
          ],
        ),
      );
      if (save == true &&
          title.text.trim().isNotEmpty &&
          price.text.trim().isNotEmpty) {
        _store.editListing(item.id,
            title: title.text.trim(), priceLabel: price.text.trim());
      }
    } finally {
      title.dispose();
      price.dispose();
    }
  }

  Future<void> _delete(ProfileListing item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete demo listing?'),
        content: Text('Remove "${item.title}" from this demo session?'),
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
    if (confirm == true) _store.removeListing(item.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Listings')),
      body: AnimatedBuilder(
        animation: Listenable.merge([_store, AuthSession.instance]),
        builder: (context, _) {
          if (!_canView) {
            return const ProfileEmptyState(
                icon: Icons.lock_outline,
                title: 'Sign in to manage listings',
                message: 'Your posts will appear here after authentication '
                    'and the marketplace API are connected.');
          }
          final items = _store.myListings
              .where((item) => _filter == 'All' || item.status.label == _filter)
              .toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (_store.previewEnabled) ...[
              const DemoBanner(),
              const SizedBox(height: 14),
            ],
            const Text('Manage your posts',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: 6),
            const Text('Preview listing edits, closing and deletion.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: ['All', 'Active', 'Closed', 'Draft']
                      .map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                        ),
                      )
                      .toList()),
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const ProfileEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No listings here',
                  message: 'Your listings in this category will appear here.')
            else
              ...items.map((item) => _buildCard(item)),
          ]);
        },
      ),
    );
  }

  Widget _buildCard(ProfileListing item) {
    final canEdit = _store.previewEnabled;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                    color: AppColors.periwinkle.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12)),
                child:
                    Icon(iconForListing(item.type), color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('${item.type.label} • ${item.location}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(item.priceLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: AppColors.coral)),
                ])),
            ProfileBadge(
                label: item.status.label,
                color: item.status == ListingStatus.active
                    ? AppColors.success
                    : item.status == ListingStatus.draft
                        ? AppColors.warning
                        : AppColors.textSecondary),
          ]),
          const SizedBox(height: 8),
          Text('Created ${displayDate(item.createdAt)}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          if (canEdit) ...[
            const Divider(height: 22),
            Wrap(spacing: 8, runSpacing: 4, children: [
              OutlinedButton.icon(
                  onPressed: () => _edit(item),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit')),
              if (item.status != ListingStatus.sold)
                OutlinedButton.icon(
                    onPressed: () =>
                        _store.setListingStatus(item.id, ListingStatus.sold),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Close')),
              if (item.status != ListingStatus.active)
                OutlinedButton.icon(
                    onPressed: () =>
                        _store.setListingStatus(item.id, ListingStatus.active),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Mark Active')),
              TextButton.icon(
                  onPressed: () => _delete(item),
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.error),
                  label: const Text('Delete',
                      style: TextStyle(color: AppColors.error))),
            ]),
          ],
        ]),
      ),
    );
  }
}
