import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_colors.dart';
import '../../models/room_model.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback? onTap;

  const RoomCard({super.key, required this.room, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // ── Image ─────────────────────────────────────────
            _RoomImagePlaceholder(bedrooms: room.bedrooms),

            // ── Details ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      room.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Bed · Bath · Furnished row
                    Row(
                      children: [
                        _RoomFeature(
                          icon: Icons.bed_outlined,
                          label: '${room.bedrooms} bd',
                        ),
                        const SizedBox(width: 10),
                        _RoomFeature(
                          icon: Icons.bathtub_outlined,
                          label: '${room.bathrooms} ba',
                        ),
                        const SizedBox(width: 10),
                        _RoomFeature(
                          icon: room.furnished
                              ? Icons.weekend_outlined
                              : Icons.weekend,
                          label: room.furnished ? 'Furnished' : 'Unfurnished',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Price + bills
                    Row(
                      children: [
                        Text(
                          '\$${room.weeklyRent.toStringAsFixed(0)}/wk',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rentRoom,
                          ),
                        ),
                        if (room.billsIncluded) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Bills incl.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Location · time
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            room.locationDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textHint),
                          ),
                        ),
                        Text(
                          timeago.format(room.postedAt, locale: 'en_short'),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomImagePlaceholder extends StatelessWidget {
  final int bedrooms;
  const _RoomImagePlaceholder({required this.bedrooms});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      color: AppColors.rentRoom.withOpacity(0.07),
      child: Center(
        child: Icon(
          bedrooms > 1 ? Icons.apartment_outlined : Icons.home_outlined,
          size: 36,
          color: AppColors.rentRoom.withOpacity(0.3),
        ),
      ),
    );
  }
}

class _RoomFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RoomFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}