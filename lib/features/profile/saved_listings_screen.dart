import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_colors.dart';
import 'data/profile_demo_store.dart';
import 'profile_widgets.dart';

class SavedListingsScreen extends StatefulWidget {
  const SavedListingsScreen({super.key});

  @override
  State<SavedListingsScreen> createState() => _SavedListingsScreenState();
}

class _SavedListingsScreenState extends State<SavedListingsScreen> {
  final _store = ProfileDemoStore.instance;
  bool _showCatalog = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Saved Listings')),
      body: AnimatedBuilder(
        animation: Listenable.merge([_store, AuthSession.instance]),
        builder: (context, _) {
          final allowed = AuthSession.instance.isSignedIn ||
              (kDebugMode && _store.previewEnabled);
          if (!allowed) {
            return const ProfileEmptyState(
                icon: Icons.bookmark_border,
                title: 'Save your favorite listings',
                message: 'Sign in to keep a list of products, rooms and jobs '
                    'you want to revisit.');
          }
          final items = _showCatalog ? _store.catalog : _store.savedListings;
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (_store.previewEnabled) ...[
              const DemoBanner(),
              const SizedBox(height: 14),
            ],
            const Text('Your favorites',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: 6),
            const Text('Save items to revisit them later.',
                style: TextStyle(color: AppColors.textSecondary)),
            if (_store.previewEnabled) ...[
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Saved')),
                  ButtonSegment(value: true, label: Text('Demo catalog')),
                ],
                selected: {_showCatalog},
                onSelectionChanged: (selected) =>
                    setState(() => _showCatalog = selected.first),
              ),
            ],
            const SizedBox(height: 14),
            if (items.isEmpty)
              ProfileEmptyState(
                icon: Icons.bookmarks_outlined,
                title: _showCatalog ? 'No demo items' : 'No saved listings',
                message: _showCatalog
                    ? 'The demo catalog is empty.'
                    : 'Items you bookmark will appear here.',
              )
            else
              ...items.map(_listingCard),
          ]);
        },
      ),
    );
  }

  Widget _listingCard(ProfileListing item) {
    final saved = _store.isSaved(item.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.periwinkle.withOpacity(0.12),
          child: Icon(iconForListing(item.type), color: AppColors.primary),
        ),
        title: Text(item.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle:
            Text('${item.priceLabel}  •  ${item.location}\n${item.type.label}'),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: saved ? 'Remove bookmark (demo)' : 'Save bookmark (demo)',
          onPressed:
              _store.previewEnabled ? () => _store.toggleSaved(item.id) : null,
          icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
              color: saved ? AppColors.coral : AppColors.textSecondary),
        ),
      ),
    );
  }
}
