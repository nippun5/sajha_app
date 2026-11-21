import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/network/backend_config.dart';
import '../../../core/theme/app_colors.dart';
import '../data/marketplace_mock_store.dart';
import '../widgets/marketplace_actions.dart';
import 'live_marketplace_api.dart';

String serverKind(MarketKind kind) => switch (kind) {
      MarketKind.buySell => 'product',
      MarketKind.room => 'room',
      MarketKind.job => 'job',
    };

String? liveImageUrl(LiveListing listing) {
  if (listing.mediaUrls.isEmpty) return null;
  final raw = listing.mediaUrls.first;
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;
  if ((uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty)
    return raw;
  if (raw.startsWith('/api/v1/media/')) {
    return BackendConfig.resolve(raw).toString();
  }
  return null;
}

/// Restored Phase 1 marketplace layout, powered by Phase 4C/4D live records.
/// Never mixes demo listings or saved flags with live account data.
class LiveMarketplaceFeed extends StatefulWidget {
  const LiveMarketplaceFeed({super.key, required this.kind});
  final MarketKind kind;
  @override
  State<LiveMarketplaceFeed> createState() => _LiveMarketplaceFeedState();
}

class _LiveMarketplaceFeedState extends State<LiveMarketplaceFeed> {
  final _api = LiveMarketplaceApi();
  final _search = TextEditingController();
  Timer? _searchDebounce;
  List<LiveListing> _items = [];
  Set<String> _saved = {};
  String _category = 'All';
  String _sort = 'Newest';
  String? _error;
  bool _loading = false;
  int _nextPage = 0;
  bool _more = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void didUpdateWidget(covariant LiveMarketplaceFeed old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind) {
      _category = 'All';
      _sort = 'Newest';
      _search.clear();
      _load(reset: true);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Color get _accent => switch (widget.kind) {
        MarketKind.buySell => AppColors.buySell,
        MarketKind.room => AppColors.rentRoom,
        MarketKind.job => AppColors.jobSearch,
      };

  Future<void> _load({required bool reset}) async {
    if (_loading && !reset) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    final kind = widget.kind;
    final query = _search.text;
    try {
      final page = await _api.browse(
          kind: serverKind(kind), q: query, page: reset ? 0 : _nextPage);
      if (!mounted ||
          generation != _generation ||
          kind != widget.kind ||
          query != _search.text) return;
      setState(() {
        _items = reset ? page.items : [..._items, ...page.items];
        _nextPage = page.page + 1;
        _more = _nextPage < page.totalPages;
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
    } catch (_) {/* Never block public browsing if saved request fails. */}
  }

  void _notice(Object e) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
  }

  Future<void> _toggleSaved(LiveListing item) async {
    if (!AuthSession.instance.isSignedIn) {
      _notice('Sign in to save listings.');
      return;
    }
    try {
      if (_saved.contains(item.id)) {
        await _api.unsave(item.id);
        if (mounted) setState(() => _saved.remove(item.id));
      } else {
        await _api.save(item.id);
        if (mounted) setState(() => _saved.add(item.id));
      }
    } catch (e) {
      _notice(e);
    }
  }

  List<LiveListing> get _filtered {
    final list = _items
        .where((e) => _category == 'All' || e.category == _category)
        .toList();
    switch (_sort) {
      case 'Oldest':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Title A–Z':
        list.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  void _open(LiveListing item) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => LiveListingDetailScreen(
            listing: item,
            saved: _saved.contains(item.id),
            onToggleSave: () => _toggleSaved(item)),
      ));

  @override
  Widget build(BuildContext context) {
    final categories =
        <String>{'All', ..._items.map((e) => e.category)}.toList();
    final selected = categories.contains(_category) ? _category : 'All';
    final filtered = _filtered;
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (_) {
                  setState(() {});
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(const Duration(milliseconds: 450),
                      () => _load(reset: true));
                },
                onSubmitted: (_) {
                  _searchDebounce?.cancel();
                  _load(reset: true);
                },
                decoration: InputDecoration(
                  hintText: 'Search ${widget.kind.label.toLowerCase()}...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? IconButton(
                          tooltip: 'Search',
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => _load(reset: true))
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                            _load(reset: true);
                          }),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                  height: 45,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => ChoiceChip(
                      label: Text(categories[i]),
                      selected: selected == categories[i],
                      selectedColor: _accent.withValues(alpha: 0.16),
                      onSelected: (_) =>
                          setState(() => _category = categories[i]),
                    ),
                  )),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: Text('${filtered.length} loaded listings',
                        style:
                            const TextStyle(color: AppColors.textSecondary))),
                DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox.shrink(),
                  items: const ['Newest', 'Oldest', 'Title A–Z']
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _sort = value ?? 'Newest'),
                ),
              ]),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(children: [
                      Text(_error!,
                          style: const TextStyle(color: AppColors.error)),
                      TextButton(
                          onPressed: () => _load(reset: true),
                          child: const Text('Retry')),
                    ])),
            ]),
          )),
          if (_loading && _items.isEmpty)
            const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No listings match your search or filters.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary)))))
          else if (widget.kind == MarketKind.buySell)
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                sliver: SliverLayoutBuilder(
                    builder: (context, constraints) => SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      constraints.crossAxisExtent > 650 ? 3 : 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  mainAxisExtent: 265),
                          delegate: SliverChildBuilderDelegate(
                              (_, i) => _LiveMarketCard(
                                  item: filtered[i],
                                  grid: true,
                                  saved: _saved.contains(filtered[i].id),
                                  onSave: () => _toggleSaved(filtered[i]),
                                  onOpen: () => _open(filtered[i])),
                              childCount: filtered.length),
                        )))
          else
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _LiveMarketCard(
                                  item: filtered[i],
                                  grid: false,
                                  saved: _saved.contains(filtered[i].id),
                                  onSave: () => _toggleSaved(filtered[i]),
                                  onOpen: () => _open(filtered[i])),
                            ),
                        childCount: filtered.length))),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            child: _more
                ? OutlinedButton(
                    onPressed: _loading ? null : () => _load(reset: false),
                    child: Text(_loading ? 'Loading...' : 'Load more'))
                : const SizedBox.shrink(),
          )),
        ],
      ),
    );
  }
}

class _LiveMarketCard extends StatelessWidget {
  const _LiveMarketCard(
      {required this.item,
      required this.grid,
      required this.saved,
      required this.onSave,
      required this.onOpen});
  final LiveListing item;
  final bool grid, saved;
  final VoidCallback onSave, onOpen;
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onOpen,
          child: grid
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                      height: 123,
                      width: double.infinity,
                      child: _LivePreview(item: item)),
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Text(item.priceLabel,
                                    maxLines: 1,
                                    style: const TextStyle(
                                        color: AppColors.coral,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Text(item.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11)),
                                const Spacer(),
                                _actions(context),
                              ]))),
                ])
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    SizedBox(
                        width: 91,
                        height: 102,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _LivePreview(item: item))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(item.priceLabel,
                              style: const TextStyle(
                                  color: AppColors.coral,
                                  fontWeight: FontWeight.bold)),
                          Text(item.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(item.category,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          _actions(context),
                        ])),
                  ])),
        ),
      );
  Widget _actions(BuildContext context) => Row(children: [
        const Spacer(),
        IconButton(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          tooltip: saved ? 'Remove saved listing' : 'Save listing',
          onPressed: onSave,
          icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
              size: 21,
              color: saved ? AppColors.coral : AppColors.textSecondary),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          tooltip: 'Share listing',
          onPressed: () =>
              MarketplaceActions.share(context, item.toMarketItem()),
          icon: const Icon(Icons.share_outlined,
              size: 20, color: AppColors.textSecondary),
        ),
      ]);
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({required this.item});
  final LiveListing item;
  @override
  Widget build(BuildContext context) {
    final url = liveImageUrl(item);
    if (url == null) return _placeholder(false);
    return Image.network(url,
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(true));
  }

  Widget _placeholder(bool broken) => Container(
      color: AppColors.periwinkle.withValues(alpha: 0.12),
      child: Icon(broken ? Icons.broken_image_outlined : Icons.image_outlined,
          size: 40, color: AppColors.periwinkle));
}

/// Same visual hierarchy/contact actions as Phase 1 demo details, but live data.
class LiveListingDetailScreen extends StatelessWidget {
  const LiveListingDetailScreen(
      {super.key,
      required this.listing,
      this.saved = false,
      this.onToggleSave});
  final LiveListing listing;
  final bool saved;
  final VoidCallback? onToggleSave;
  @override
  Widget build(BuildContext context) {
    final item = listing.toMarketItem();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(listing.marketKind.label), actions: [
        if (onToggleSave != null)
          IconButton(
              tooltip: 'Save listing',
              onPressed: onToggleSave,
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border)),
        IconButton(
            tooltip: 'Share listing',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => MarketplaceActions.share(context, item)),
      ]),
      bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => MarketplaceActions.contact(
                            context, item,
                            sms: true),
                        icon: const Icon(Icons.sms_outlined),
                        label: const Text('SMS'))),
                const SizedBox(width: 12),
                Expanded(
                    child: FilledButton.icon(
                        onPressed: () => MarketplaceActions.contact(
                            context, item,
                            sms: false),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Call'))),
              ]))),
      body: ListView(children: [
        SizedBox(
            height: 255,
            width: double.infinity,
            child: _LivePreview(item: listing)),
        Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(listing.title,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 8),
              Text(listing.priceLabel,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.coral)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                Chip(label: Text(listing.category)),
                Chip(label: Text(listing.location))
              ]),
              const SizedBox(height: 20),
              const Text('Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(listing.description),
              if (listing.details.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text('Details',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...listing.details.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Expanded(
                            child: Text(e.key,
                                style: const TextStyle(
                                    color: AppColors.textSecondary))),
                        Expanded(
                            child:
                                Text('${e.value}', textAlign: TextAlign.end)),
                      ]),
                    )),
              ],
              const SizedBox(height: 22),
              const Text('Contact',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(listing.ownerName),
              Text(listing.contactPhone),
              if (listing.mediaUrls.length > 1) ...[
                const SizedBox(height: 22),
                const Text('More photos',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: listing.mediaUrls.length - 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final path = listing.mediaUrls[i + 1];
                        final url = path.startsWith('/api/v1/')
                            ? BackendConfig.resolve(path).toString()
                            : path;
                        return SizedBox(
                            width: 110,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image_outlined))));
                      },
                    )),
              ],
            ])),
      ]),
    );
  }
}
