import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'data/profile_demo_store.dart';

IconData iconForListing(ListingType type) {
  switch (type) {
    case ListingType.buySell:
      return Icons.shopping_bag_outlined;
    case ListingType.room:
      return Icons.home_work_outlined;
    case ListingType.job:
      return Icons.work_outline;
  }
}

Color colorForBusinessStatus(BusinessRequestStatus status) {
  switch (status) {
    case BusinessRequestStatus.pending:
      return AppColors.warning;
    case BusinessRequestStatus.approved:
      return AppColors.success;
    case BusinessRequestStatus.declined:
      return AppColors.error;
  }
}

String displayDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.periwinkle.withOpacity(0.10),
        border: Border.all(color: AppColors.periwinkle.withOpacity(0.30)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(children: [
        Icon(Icons.science_outlined, color: AppColors.primary),
        SizedBox(width: 10),
        Expanded(
            child: Text(
          'DEMO ONLY — temporary on-device data. Nothing is published, '
          'paid, or sent to an administrator.',
          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
        )),
      ]),
    );
  }
}

class ProfileEmptyState extends StatelessWidget {
  const ProfileEmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 16),
      child: Column(children: [
        Icon(icon, color: AppColors.periwinkle, size: 52),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: AppColors.textSecondary, height: 1.5)),
      ]),
    );
  }
}

class ProfileBadge extends StatelessWidget {
  const ProfileBadge({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
