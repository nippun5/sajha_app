import 'package:flutter/material.dart';
import '../../marketplace/data/marketplace_mock_store.dart';
import '../../marketplace/marketplace_category_page.dart';

/// Existing HomeScreen keeps using this class. Its data now comes from the
/// same mock store as Profile, Saved, and marketplace detail pages.
class BuySellPage extends StatelessWidget {
  const BuySellPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const MarketplaceCategoryPage(kind: MarketKind.buySell);
}
