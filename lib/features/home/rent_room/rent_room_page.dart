import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/data/dummy_data.dart';
import '../../../shared/widgets/room_card.dart';

class RentRoomPage extends StatefulWidget {
  const RentRoomPage({super.key});

  @override
  State<RentRoomPage> createState() => _RentRoomPageState();
}

class _RentRoomPageState extends State<RentRoomPage> {
  String _selectedFilter = 'All';

  static const _filters = [
    'All', 'Single Room', 'Master Room', 'Apartment', 'Granny Flat',
  ];

  @override
  Widget build(BuildContext context) {
    final rooms = DummyData.roomListings;

    return CustomScrollView(
      slivers: [
        // ── Filter chips ─────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final active = f == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.rentRoom.withOpacity(0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? AppColors.rentRoom
                            : AppColors.border,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: active
                            ? AppColors.rentRoom
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ── Header ───────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${rooms.length} rooms available',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary)),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.tune, size: 16),
                  label:
                      const Text('Filter', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
          ),
        ),

        // ── Room list ─────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RoomCard(
                  room: rooms[i],
                  onTap: () {
                    // TODO: navigate to room detail
                  },
                ),
              ),
              childCount: rooms.length,
            ),
          ),
        ),
      ],
    );
  }
}