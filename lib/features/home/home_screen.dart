import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import 'buy_sell/buy_sell_page.dart';
import 'rent_room/rent_room_page.dart';
import 'job_search/job_search_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageCtrl = PageController();
  int _currentTab = 0;

  static const _tabs = [
    _TabMeta(label: 'Buy & Sell',  icon: Icons.sell_outlined,  color: AppColors.buySell),
    _TabMeta(label: 'Rent Room',   icon: Icons.home_outlined,  color: AppColors.rentRoom),
    _TabMeta(label: 'Jobs',        icon: Icons.work_outline,   color: AppColors.jobSearch),
  ];

  void _switchTab(int index) {
    if (index == _currentTab) return;
    setState(() => _currentTab = index);
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // ── Tab selector ────────────────────────────────
          _TabBar(
            tabs: _tabs,
            currentIndex: _currentTab,
            onTap: _switchTab,
          ),

          // ── Page content ────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _currentTab = i),
              children: const [
                BuySellPage(),
                RentRoomPage(),
                JobSearchPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      titleSpacing: 16,
      title: Image.asset(
        AppConstants.logoPath,
        height: 36,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
      actions: [
        // Search
        IconButton(
          icon: const Icon(Icons.search, size: 22),
          onPressed: () {
            // TODO: open global search
          },
        ),
        // Notifications
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 22),
          onPressed: () {
            // TODO: open notifications
          },
        ),
        // Avatar
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              // TODO: open profile
            },
            child: const CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.border,
              child: Icon(Icons.person_outline,
                  size: 18, color: AppColors.textHint),
            ),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────
class _TabMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _TabMeta({required this.label, required this.icon, required this.color});
}

class _TabBar extends StatelessWidget {
  final List<_TabMeta> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TabBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final active = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active
                      ? tab.color.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active
                        ? tab.color.withOpacity(0.5)
                        : AppColors.border,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 18,
                      color: active ? tab.color : AppColors.textHint,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? tab.color : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}