import 'package:flutter/material.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_colors.dart';
import '../data/marketplace_mock_store.dart';
import '../widgets/marketplace_actions.dart';
import 'live_marketplace_api.dart';

String serverKind(MarketKind kind) => switch (kind) {
      MarketKind.buySell => 'product',
      MarketKind.room => 'room',
      MarketKind.job => 'job',
    };

/// The LIVE path never reads the mock store. Guests can browse;
/// saving requires a real authenticated account.
class LiveMarketplaceFeed extends StatefulWidget {
  const LiveMarketplaceFeed({super.key, required this.kind});
  final MarketKind kind;
  @override
  State<LiveMarketplaceFeed> createState() => _LiveMarketplaceFeedState();
}

class _LiveMarketplaceFeedState extends State<LiveMarketplaceFeed> {
  final _api = LiveMarketplaceApi();
  final _search = TextEditingController();
  List<LiveListing> _listings = [];
  Set<String> _saved = {};
  bool _loading = false;
  String? _error;
  int _nextPage = 0;
  bool _hasMore = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void didUpdateWidget(covariant LiveMarketplaceFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) _load(reset: true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (_loading && !reset) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    final currentKind = widget.kind;
    final query = _search.text;
    try {
      final data = await _api.browse(
          kind: serverKind(currentKind), q: query, page: reset ? 0 : _nextPage);
      if (!mounted ||
          generation != _generation ||
          currentKind != widget.kind ||
          query != _search.text) return;
      setState(() {
        _listings = reset ? data.items : [..._listings, ...data.items];
        _nextPage = data.page + 1;
        _hasMore = _nextPage < data.totalPages;
      });
      if (reset) await _loadSaved();
    } catch (e) {
      if (mounted && generation == _generation)
        setState(() => _error = e.toString());
    } finally {
      if (mounted && generation == _generation)
        setState(() => _loading = false);
    }
  }

  Future<void> _loadSaved() async {
    if (!AuthSession.instance.isSignedIn) {
      if (mounted) setState(() => _saved = {});
      return;
    }
    try {
      final page = await _api.saved();
      if (mounted) setState(() => _saved = page.items.map((e) => e.id).toSet());
    } catch (_) {
      // Browsing should still work when the saved-list request fails.
    }
  }

  void _message(Object error) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _toggleSaved(LiveListing listing) async {
    if (!AuthSession.instance.isSignedIn) {
      _message('Sign in to bookmark listings.');
      return;
    }
    try {
      if (_saved.contains(listing.id)) {
        await _api.unsave(listing.id);
        if (mounted) setState(() => _saved.remove(listing.id));
      } else {
        await _api.save(listing.id);
        if (mounted) setState(() => _saved.add(listing.id));
      }
    } catch (e) {
      _message(e);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            Row(children: [
              const Icon(Icons.cloud_done_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Live ${widget.kind.label} listings',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18))),
              IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => _load(reset: true),
                  icon: const Icon(Icons.refresh)),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(reset: true),
              decoration: InputDecoration(
                labelText: 'Search public listings',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  onPressed: () => _load(reset: true),
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(children: [
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                  TextButton(
                      onPressed: () => _load(reset: true),
                      child: const Text('Retry')),
                ]),
              ),
            if (_loading && _listings.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator())),
            if (!_loading && _listings.isEmpty && _error == null)
              const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('No published listings yet.'))),
            ..._listings.map((listing) => Card(
                  margin: const EdgeInsets.only(top: 10),
                  child: ListTile(
                    title: Text(listing.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${listing.priceLabel} · ${listing.location}\n${listing.category}'),
                    isThreeLine: true,
                    leading: const CircleAvatar(
                      child: Icon(Icons.inventory_2_outlined),
                    ),
                    trailing: IconButton(
                      tooltip: _saved.contains(listing.id)
                          ? 'Unsave listing'
                          : 'Save listing',
                      onPressed: () => _toggleSaved(listing),
                      icon: Icon(
                          _saved.contains(listing.id)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: AppColors.coral),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            LiveListingDetailScreen(listing: listing),
                      ),
                    ),
                  ),
                )),
            if (_hasMore && _listings.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => _load(reset: false),
                    child: Text(_loading ? 'Loading...' : 'Load more'),
                  )),
          ],
        ),
      );
}

class LiveListingDetailScreen extends StatelessWidget {
  const LiveListingDetailScreen({super.key, required this.listing});
  final LiveListing listing;

  @override
  Widget build(BuildContext context) {
    final item = listing.toMarketItem();
    return Scaffold(
      appBar: AppBar(title: Text(listing.title)),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const Chip(label: Text('Live marketplace listing')),
        const SizedBox(height: 12),
        Text(listing.title,
            style: const TextStyle(
                fontSize: 24,
                color: AppColors.primary,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(listing.priceLabel,
            style: const TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.bold,
                fontSize: 19)),
        const SizedBox(height: 14),
        Text('${listing.category} · ${listing.location}'),
        const SizedBox(height: 20),
        Text(listing.description),
        const Divider(height: 32),
        Text('Contact: ${listing.ownerName}'),
        Text('Phone: ${listing.contactPhone}'),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: () =>
                      MarketplaceActions.contact(context, item, sms: true),
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('SMS'))),
          const SizedBox(width: 12),
          Expanded(
              child: FilledButton.icon(
                  onPressed: () =>
                      MarketplaceActions.contact(context, item, sms: false),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call'))),
        ]),
        const SizedBox(height: 18),
        ...listing.details.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${e.key}: ${e.value}'),
            )),
      ]),
    );
  }
}
