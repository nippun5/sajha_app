import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/business_model.dart';
import '../shared/data/dummy_data.dart';
import 'business_detail_page.dart';

/// Step 6A: public discovery UI. Later replace only [businesses] with a real
/// repository that returns approved/active businesses. Do NOT merge requests.
class BusinessDirectoryScreen extends StatefulWidget {
  const BusinessDirectoryScreen({super.key});

  @override
  State<BusinessDirectoryScreen> createState() =>
      _BusinessDirectoryScreenState();
}

class _BusinessDirectoryScreenState extends State<BusinessDirectoryScreen> {
  final TextEditingController _search = TextEditingController();
  String _category = 'All';
  String _sort = 'Name A–Z';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BusinessModel> _filtered(List<BusinessModel> source) {
    final q = _search.text.trim().toLowerCase();
    final matches = source.where((b) {
      final categoryMatch = _category == 'All' || b.category == _category;
      final searchable = '${b.name} ${b.category} ${b.description} '
              '${b.address} ${b.city ?? ''} ${b.state ?? ''}'
          .toLowerCase();
      return categoryMatch && (q.isEmpty || searchable.contains(q));
    }).toList();
    if (_sort == 'Top rated') {
      matches.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sort == 'Most reviewed') {
      matches.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    } else {
      matches
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    // Never present seed data as real paid/approved businesses in release mode.
    final businesses = kDebugMode ? DummyData.businesses : <BusinessModel>[];
    final categories = [
      'All',
      ...{for (final b in businesses) b.category}
    ];
    final filtered = _filtered(businesses);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Discover Businesses')),
      body: Column(children: [
        Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16)),
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Support your local community',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 5),
                  Text(
                      'Discover restaurants, shops and trusted local services.',
                      style: TextStyle(color: Colors.white70)),
                ])),
        if (kDebugMode)
          const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Icon(Icons.science_outlined, size: 16),
                SizedBox(width: 6),
                Expanded(
                    child: Text(
                        'Preview: sample businesses only; not published or verified.',
                        style: TextStyle(fontSize: 12)))
              ])),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search businesses, city or category',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close))
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ))),
        SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                return ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    selectedColor: AppColors.periwinkleLight.withOpacity(.3),
                    onSelected: (_) => setState(() => _category = category));
              },
            )),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Row(children: [
              Expanded(
                  child: Text('${filtered.length} businesses',
                      style: const TextStyle(color: AppColors.textSecondary))),
              PopupMenuButton<String>(
                tooltip: 'Sort businesses',
                initialValue: _sort,
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => ['Name A–Z', 'Top rated', 'Most reviewed']
                    .map((v) => PopupMenuItem<String>(value: v, child: Text(v)))
                    .toList(),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.sort, size: 18),
                  const SizedBox(width: 6),
                  Text(_sort)
                ]),
              ),
            ])),
        Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.storefront_outlined,
                              size: 50, color: AppColors.periwinkle),
                          const SizedBox(height: 12),
                          Text(
                              businesses.isEmpty
                                  ? 'Business directory coming soon'
                                  : 'No matching businesses',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                              businesses.isEmpty
                                  ? 'Approved businesses will appear here '
                                      'after backend integration.'
                                  : 'Try another search or category.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ])))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final b = filtered[index];
                      return _BusinessCard(business: b);
                    },
                  )),
      ]),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.business});
  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => BusinessDetailPage(business: business))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              height: 160,
              width: double.infinity,
              child: Image.network(business.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppColors.border,
                      child: Center(
                          child: Icon(Icons.storefront,
                              size: 44, color: AppColors.periwinkle))))),
          Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Flexible(
                          child: Text(business.category,
                              style: const TextStyle(color: AppColors.coral))),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded,
                          size: 18, color: AppColors.warning),
                      Text(' ${business.rating.toStringAsFixed(1)}'
                          ' (${business.reviewCount})'),
                    ]),
                    const SizedBox(height: 6),
                    Text(business.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(
                          business.onlineOnly
                              ? Icons.public
                              : Icons.place_outlined,
                          color: AppColors.textSecondary,
                          size: 17),
                      const SizedBox(width: 5),
                      Expanded(
                          child: Text(
                              business.onlineOnly
                                  ? 'Online-only'
                                  : business.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textSecondary))),
                      const Icon(Icons.chevron_right),
                    ]),
                  ])),
        ]),
      ),
    );
  }
}
