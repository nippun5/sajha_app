import 'package:flutter/material.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_colors.dart';
import 'live_marketplace_api.dart';
import 'live_marketplace_feed.dart';

enum LiveAccountListMode { mine, saved }

/// Live replacement for Profile -> My Listings / Saved when API is configured.
class LiveAccountListingsScreen extends StatefulWidget {
  const LiveAccountListingsScreen({super.key, required this.mode});
  final LiveAccountListMode mode;
  @override
  State<LiveAccountListingsScreen> createState() =>
      _LiveAccountListingsScreenState();
}

class _LiveAccountListingsScreenState extends State<LiveAccountListingsScreen> {
  final _api = LiveMarketplaceApi();
  List<LiveListing> _items = [];
  String? _error;
  bool _busy = false;
  bool _more = false;
  int _next = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (_busy || !AuthSession.instance.isSignedIn) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = widget.mode == LiveAccountListMode.mine
          ? await _api.mine(page: reset ? 0 : _next)
          : await _api.saved(page: reset ? 0 : _next);
      if (!mounted) return;
      setState(() {
        _items = reset ? page.items : [..._items, ...page.items];
        _next = page.page + 1;
        _more = _next < page.totalPages;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notice(Object text) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(text.toString())));
  }

  Future<void> _delete(LiveListing listing) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
              title: const Text('Delete listing?'),
              content: Text('Delete ${listing.title}? This cannot be undone.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialog, true),
                    child: const Text('Delete')),
              ],
            ));
    if (yes != true) return;
    try {
      await _api.delete(listing.id);
      await _load(reset: true);
    } catch (e) {
      _notice(e);
    }
  }

  Future<void> _unsave(LiveListing listing) async {
    try {
      await _api.unsave(listing.id);
      await _load(reset: true);
    } catch (e) {
      _notice(e);
    }
  }

  Future<void> _edit(LiveListing listing) async {
    final title = TextEditingController(text: listing.title);
    final description = TextEditingController(text: listing.description);
    final location = TextEditingController(text: listing.location);
    try {
      final save = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
                title: const Text('Edit live listing'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: title,
                      maxLength: 120,
                      decoration: const InputDecoration(labelText: 'Title')),
                  TextField(
                      controller: description,
                      minLines: 3,
                      maxLines: 5,
                      decoration:
                          const InputDecoration(labelText: 'Description')),
                  TextField(
                      controller: location,
                      maxLength: 180,
                      decoration: const InputDecoration(labelText: 'Location')),
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Save')),
                ],
              ));
      if (save != true) return;
      if (title.text.trim().isEmpty ||
          description.text.trim().isEmpty ||
          location.text.trim().isEmpty) {
        _notice('All fields are required.');
        return;
      }
      await _api.edit(listing.id, {
        'title': title.text.trim(),
        'description': description.text.trim(),
        'location': location.text.trim(),
      });
      await _load(reset: true);
    } catch (e) {
      _notice(e);
    } finally {
      title.dispose();
      description.dispose();
      location.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.mode == LiveAccountListMode.mine
                ? 'My Listings'
                : 'Saved Listings')),
        body: !AuthSession.instance.isSignedIn
            ? const Center(
                child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text('Sign in to view your live listings.')))
            : RefreshIndicator(
                onRefresh: () => _load(reset: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('LIVE · Stored in Spring Boot / MySQL',
                        style: TextStyle(color: AppColors.textSecondary)),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.error)),
                      ),
                    if (_busy && _items.isEmpty)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator())),
                    if (!_busy && _items.isEmpty && _error == null)
                      const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No listings yet.'))),
                    ..._items.map((listing) => Card(
                            child: Column(children: [
                          ListTile(
                            title: Text(listing.title),
                            subtitle: Text(
                                '${listing.priceLabel} · ${listing.location}\n${listing.status}'),
                            isThreeLine: true,
                            onTap: listing.status == 'active'
                                ? () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                        builder: (_) => LiveListingDetailScreen(
                                            listing: listing)))
                                : null,
                          ),
                          ButtonBar(
                              children: widget.mode == LiveAccountListMode.mine
                                  ? [
                                      TextButton.icon(
                                          onPressed: () => _edit(listing),
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Edit')),
                                      TextButton.icon(
                                          onPressed: () => _delete(listing),
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          label: const Text('Delete')),
                                    ]
                                  : [
                                      TextButton.icon(
                                          onPressed: () => _unsave(listing),
                                          icon:
                                              const Icon(Icons.bookmark_remove),
                                          label: const Text('Unsave')),
                                    ]),
                        ]))),
                    if (_more)
                      OutlinedButton(
                        onPressed: _busy ? null : () => _load(reset: false),
                        child: Text(_busy ? 'Loading...' : 'Load more'),
                      ),
                  ],
                ),
              ),
      );
}
