import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../profile/data/profile_demo_store.dart';
import 'data/marketplace_mock_store.dart';
import 'marketplace_detail_screen.dart';
import 'widgets/marketplace_actions.dart';

class MarketplaceCategoryPage extends StatefulWidget {
  const MarketplaceCategoryPage({super.key, required this.kind});
  final MarketKind kind;

  @override
  State<MarketplaceCategoryPage> createState() =>
      _MarketplaceCategoryPageState();
}

class _MarketplaceCategoryPageState extends State<MarketplaceCategoryPage> {
  final _search = TextEditingController();
  String _category = 'All';
  String _sort = 'Newest';
  final _store = MarketplaceMockStore.instance;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Color get _accent => switch (widget.kind) {
        MarketKind.buySell => AppColors.buySell,
        MarketKind.room => AppColors.rentRoom,
        MarketKind.job => AppColors.jobSearch,
      };

  List<MarketItem> _filtered() {
    final query = _search.text.trim().toLowerCase();
    final items = _store.listingsFor(widget.kind).where((item) {
      final matchesCategory = _category == 'All' || item.category == _category;
      final matchesQuery = query.isEmpty ||
          '${item.title} ${item.description} ${item.location} ${item.category}'
              .toLowerCase()
              .contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    switch (_sort) {
      case 'Title A–Z':
        items.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'Oldest':
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      default:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_store, ProfileDemoStore.instance]),
      builder: (context, _) {
        final all = _store.listingsFor(widget.kind);
        final categories =
            <String>{'All', ...all.map((e) => e.category)}.toList();
        if (!categories.contains(_category)) _category = 'All';
        final filtered = _filtered();
        return CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.kind.label.toLowerCase()}...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _search.clear()),
                        ),
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
                    selected: _category == categories[i],
                    selectedColor: _accent.withOpacity(0.16),
                    onSelected: (_) =>
                        setState(() => _category = categories[i]),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: Text('${filtered.length} listings',
                        style:
                            const TextStyle(color: AppColors.textSecondary))),
                DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox.shrink(),
                  items: const ['Newest', 'Oldest', 'Title A–Z']
                      .map((text) =>
                          DropdownMenuItem(value: text, child: Text(text)))
                      .toList(),
                  onChanged: (v) => setState(() => _sort = v ?? 'Newest'),
                ),
              ]),
            ]),
          )),
          if (filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No listings match your search or filters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary)),
              )),
            )
          else if (widget.kind == MarketKind.buySell)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 110),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final columns = width > 650 ? 3 : 2;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 265,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _MarketCard(
                        item: filtered[i],
                        grid: true,
                        onOpen: () => _open(filtered[i]),
                      ),
                      childCount: filtered.length,
                    ),
                  );
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MarketCard(
                      item: filtered[i],
                      grid: false,
                      onOpen: () => _open(filtered[i]),
                    ),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
        ]);
      },
    );
  }

  void _open(MarketItem item) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MarketplaceDetailScreen(item: item),
        ),
      );
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({
    required this.item,
    required this.grid,
    required this.onOpen,
  });
  final MarketItem item;
  final bool grid;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final store = MarketplaceMockStore.instance;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        child: grid
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                    height: 123,
                    width: double.infinity,
                    child: _PreviewImage(item: item)),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
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
                                color: AppColors.textSecondary, fontSize: 11)),
                        const Spacer(),
                        _CardActions(item: item, store: store),
                      ]),
                )),
              ])
            : Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  SizedBox(
                      width: 91,
                      height: 102,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _PreviewImage(item: item),
                      )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(item.priceLabel,
                          style: const TextStyle(
                              color: AppColors.coral,
                              fontWeight: FontWeight.bold)),
                      Text(item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(item.category,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      _CardActions(item: item, store: store),
                    ],
                  )),
                ]),
              ),
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({required this.item, required this.store});
  final MarketItem item;
  final MarketplaceMockStore store;

  @override
  Widget build(BuildContext context) => Row(children: [
        if (item.ownedByDemo)
          const Expanded(
              child: Text('DEMO',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.periwinkle,
                      fontWeight: FontWeight.bold)))
        else
          const Spacer(),
        IconButton(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          tooltip:
              store.isSaved(item.id) ? 'Remove saved listing' : 'Save listing',
          icon: Icon(
              store.isSaved(item.id) ? Icons.bookmark : Icons.bookmark_border,
              size: 21,
              color: store.isSaved(item.id)
                  ? AppColors.coral
                  : AppColors.textSecondary),
          onPressed: () {
            if (!store.previewEnabled) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Sign in to save listings. In debug builds, '
                    'enable Profile demo mode to test.'),
              ));
              return;
            }
            store.toggleSaved(item.id);
          },
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          tooltip: 'Share listing',
          icon: const Icon(Icons.share_outlined,
              size: 20, color: AppColors.textSecondary),
          onPressed: () => MarketplaceActions.share(context, item),
        ),
      ]);
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.item});
  final MarketItem item;

  @override
  Widget build(BuildContext context) {
    if (item.imageUrl == null) {
      return Container(
        color: AppColors.periwinkle.withOpacity(0.12),
        child: const Icon(Icons.image_outlined,
            size: 40, color: AppColors.periwinkle),
      );
    }
    return Image.network(item.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
              color: AppColors.periwinkle.withOpacity(0.12),
              child: const Icon(Icons.broken_image_outlined,
                  color: AppColors.periwinkle),
            ));
  }
}
