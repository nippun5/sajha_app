import 'package:flutter/material.dart';
import 'package:sajha_app/features/home/buy_sell/product_detail_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/data/dummy_data.dart';
import '../../../shared/widgets/listing_card.dart';

class BuySellPage extends StatelessWidget {
  const BuySellPage({super.key});

  static const _categories = [
    'All', 'Electronics', 'Furniture', 'Vehicles',
    'Cameras', 'Appliances', 'Sports', 'Clothing',
  ];

  @override
  Widget build(BuildContext context) {
    final listings = DummyData.buySellListings;

    return CustomScrollView(
      slivers: [
        // ── Filter chips ────────────────────────────────
        SliverToBoxAdapter(
          child: _FilterRow(categories: _categories),
        ),

        // ── Section header ───────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${listings.length} listings',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary)),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Filter', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
          ),
        ),

        // ── 2-column grid ────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => ListingCard(
                listing: listings[i],
                onTap: () {
                 Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ProductDetailScreen(
      product: listings[i],
    ),
  ),
);
                },
              ),
              childCount: listings.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatefulWidget {
  final List<String> categories;
  const _FilterRow({required this.categories});

  @override
  State<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<_FilterRow> {
  String _selected = 'All';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: widget.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = widget.categories[i];
          final active = cat == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.buySell.withOpacity(0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      active ? AppColors.buySell : AppColors.border,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? AppColors.buySell
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}