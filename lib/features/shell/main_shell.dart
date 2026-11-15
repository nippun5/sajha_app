
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

import '../home/community_home_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

import 'package:sajha_app/business_directory/business_directory_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Controls the selected Buy/Sell, Rooms or Jobs page.
  final ValueNotifier<int> _marketplaceCategory =
      ValueNotifier<int>(0);

  @override
  void dispose() {
    _marketplaceCategory.dispose();
    super.dispose();
  }

  // Open a specific marketplace category from Home.
  void _openMarketplaceCategory(int category) {
    _marketplaceCategory.value = category;
    setState(() => _currentIndex = 1);
  }

  void _selectTab(int index) {
    // The middle Post destination opens the existing
    // posting screen instead of changing tabs.
    if (index == 2) {
      context.push(AppConstants.postListingRoute);
      return;
    }

    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);
  }

  // There are five navigation destinations, but Post
  // is an action rather than a persistent page.
  int get _visiblePageIndex {
    switch (_currentIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // Marketplace
      case 3:
        return 2; // Businesses
      case 4:
        return 3; // Profile
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _visiblePageIndex,
        children: [
          CommunityHomeScreen(
            onMarketplaceCategory: _openMarketplaceCategory,
            onBusinesses: () => _selectTab(3),
            onProfile: () => _selectTab(4),
            onPost: () =>
                context.push(AppConstants.postListingRoute),
          ),

          // Your existing Buy/Sell, Rooms and Jobs pages.
          HomeScreen(
            categoryIndex: _marketplaceCategory,
            onProfileSelected: () => _selectTab(4),
          ),

          // Your existing business directory.
          const BusinessDirectoryScreen(),

          // New profile foundation.
          const ProfileScreen(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _currentIndex,
        backgroundColor: AppColors.surface,
        indicatorColor:
            AppColors.periwinkle.withOpacity(0.15),
        labelBehavior:
            NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home,
              color: AppColors.primary,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(
              Icons.shopping_bag,
              color: AppColors.primary,
            ),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.add_circle_outline,
              color: AppColors.coral,
              size: 29,
            ),
            selectedIcon: Icon(
              Icons.add_circle,
              color: AppColors.coral,
              size: 29,
            ),
            label: 'Post',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(
              Icons.storefront,
              color: AppColors.primary,
            ),
            label: 'Businesses',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(
              Icons.person,
              color: AppColors.primary,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
