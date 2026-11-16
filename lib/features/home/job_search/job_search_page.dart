import 'package:flutter/material.dart';
import '../../marketplace/data/marketplace_mock_store.dart';
import '../../marketplace/marketplace_category_page.dart';

class JobSearchPage extends StatelessWidget {
  const JobSearchPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const MarketplaceCategoryPage(kind: MarketKind.job);
}
