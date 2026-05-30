import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/job_model.dart';
import '../../../shared/data/dummy_data.dart';
import '../../../shared/widgets/job_card.dart';

class JobSearchPage extends StatefulWidget {
  const JobSearchPage({super.key});

  @override
  State<JobSearchPage> createState() => _JobSearchPageState();
}

class _JobSearchPageState extends State<JobSearchPage> {
  String _selectedType = 'All';

  static const _types = [
    'All', 'Full-time', 'Part-time', 'Casual', 'Contract',
  ];

  List<JobModel> get _filtered {
    final all = DummyData.jobListings;
    if (_selectedType == 'All') return all;
    return all
        .where((j) => j.jobType.label == _selectedType)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _filtered;

    return CustomScrollView(
      slivers: [
        // ── Job type filter chips ─────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = _types[i];
                final active = t == _selectedType;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.jobSearch.withOpacity(0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? AppColors.jobSearch
                            : AppColors.border,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: active
                            ? AppColors.jobSearch
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
                Text('${jobs.length} jobs found',
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

        // ── Job list ──────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: JobCard(
                  job: jobs[i],
                  onTap: () {
                    // TODO: navigate to job detail
                  },
                ),
              ),
              childCount: jobs.length,
            ),
          ),
        ),
      ],
    );
  }
}