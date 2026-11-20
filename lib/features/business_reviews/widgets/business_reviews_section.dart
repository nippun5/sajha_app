import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/business_model.dart';
import '../data/business_review.dart';
import '../data/business_review_store.dart';

/// Local preview for Step 6C. Does not use authenticated accounts, send data,
/// or make a report visible to an administrator. Replace store with API later.
class BusinessReviewsSection extends StatelessWidget {
  const BusinessReviewsSection({super.key, required this.business});

  final BusinessModel business;

  Future<void> _write(BuildContext context, BusinessReview? existing) async {
    final draft = await showDialog<_ReviewDraft>(
      context: context,
      builder: (_) => _ReviewEditor(existing: existing),
    );
    if (draft == null || !context.mounted) return;
    try {
      BusinessReviewStore.instance.savePreviewReview(
        business: business,
        stars: draft.stars,
        comment: draft.comment,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Review saved locally for preview. Not published.'),
      ));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('Invalid argument(s): ', '')),
      ));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete preview review?'),
        content: const Text('This only removes the local demo review.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      BusinessReviewStore.instance.deleteMyPreviewReview(business);
    }
  }

  Future<void> _report(BuildContext context, BusinessReview review) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReportReviewDialog(),
    );
    if (reason == null || !context.mounted) return;
    try {
      BusinessReviewStore.instance.reportPreviewReview(
        business: business,
        reviewId: review.id,
        reason: reason,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Report recorded in local preview; no admin was notified.'),
      ));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString().replaceFirst('Bad state: ', '')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = BusinessReviewStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final summary = store.summaryFor(business);
        final demo = store.canWritePreview;
        final entries = store.reviewsFor(business);
        final mine = store.myReviewFor(business);
        final isOwnDemoBusiness =
            business.ownerId == BusinessReviewStore.demoReviewerId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ratings & reviews',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.star_rounded,
                      color: AppColors.warning, size: 32),
                  const SizedBox(width: 8),
                  Text(
                      summary.hasRatings
                          ? summary.average.toStringAsFixed(1)
                          : '—',
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                    '${summary.count} ${summary.count == 1 ? 'rating' : 'ratings'}'
                    '${demo ? ' · Local demo' : ''}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  )),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            if (demo)
              const Text(
                  'Example reviews below are for interface testing only. '
                  'Nothing is published or sent to an admin.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary))
            else
              const Text(
                  'Individual reviews and submissions will be available '
                  'after the backend is connected. Existing star totals are sample data.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            if (demo && !isOwnDemoBusiness) ...[
              FilledButton.icon(
                onPressed: () => _write(context, mine),
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.primary),
                icon: Icon(mine == null
                    ? Icons.rate_review_outlined
                    : Icons.edit_outlined),
                label: Text(
                    mine == null ? 'Write demo review' : 'Edit my demo review'),
              ),
              if (mine != null)
                TextButton.icon(
                  onPressed: () => _delete(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete my demo review'),
                ),
            ] else if (demo && isOwnDemoBusiness)
              const Text('Business owners cannot rate their own business.',
                  style: TextStyle(color: AppColors.textSecondary))
            else if (kDebugMode)
              const Text(
                  'To test writing reviews, turn on Profile demo mode '
                  'in the Profile tab.',
                  style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            if (demo && entries.isNotEmpty)
              ...entries.map((review) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(review.authorName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700))),
                            if (review.sample)
                              const Chip(
                                  label: Text('Sample'),
                                  visualDensity: VisualDensity.compact),
                          ]),
                          const SizedBox(height: 4),
                          Wrap(
                              spacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                for (var n = 1; n <= 5; n++)
                                  Icon(
                                    n <= review.stars
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 19,
                                    color: AppColors.warning,
                                  ),
                                const SizedBox(width: 6),
                                Text(_formatDate(review.updatedAt),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ]),
                          const SizedBox(height: 7),
                          Text(review.comment),
                          if (review.authorId !=
                              BusinessReviewStore.demoReviewerId)
                            Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: store.hasReported(review.id)
                                      ? null
                                      : () => _report(context, review),
                                  icon:
                                      const Icon(Icons.flag_outlined, size: 17),
                                  label: Text(store.hasReported(review.id)
                                      ? 'Reported in demo'
                                      : 'Report (demo)'),
                                )),
                        ],
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class _ReviewDraft {
  const _ReviewDraft(this.stars, this.comment);
  final int stars;
  final String comment;
}

class _ReviewEditor extends StatefulWidget {
  const _ReviewEditor({this.existing});
  final BusinessReview? existing;

  @override
  State<_ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<_ReviewEditor> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _text;
  late int _stars;

  @override
  void initState() {
    super.initState();
    _stars = widget.existing?.stars ?? 0;
    _text = TextEditingController(text: widget.existing?.comment ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.existing == null
            ? 'Write a demo review'
            : 'Edit demo review'),
        content: SingleChildScrollView(
            child: Form(
          key: _key,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Select 1–5 stars'),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= 5; i++)
                Flexible(
                    child: IconButton(
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(
                      i <= _stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.warning),
                  tooltip: '$i ${i == 1 ? 'star' : 'stars'}',
                ))
            ]),
            TextFormField(
              controller: _text,
              maxLength: 600,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your review (demo)',
                hintText: 'Describe your experience...',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value ?? '').trim().length < 10
                  ? 'Write at least 10 characters.'
                  : null,
            ),
            const Text('Saved on this device only while demo mode is enabled.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        )),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (_stars < 1) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Choose a star rating first.'),
                ));
                return;
              }
              if (!_key.currentState!.validate()) return;
              Navigator.pop(context, _ReviewDraft(_stars, _text.text.trim()));
            },
            child: const Text('Save preview'),
          ),
        ],
      );
}

class _ReportReviewDialog extends StatefulWidget {
  const _ReportReviewDialog();

  @override
  State<_ReportReviewDialog> createState() => _ReportReviewDialogState();
}

class _ReportReviewDialogState extends State<_ReportReviewDialog> {
  String? _reason;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Report this demo review'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Reporting here is a local preview; no administrator will receive it.'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            items: BusinessReviewStore.reportReasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (value) => setState(() => _reason = value),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _reason == null
                  ? null
                  : () => Navigator.pop(context, _reason),
              child: const Text('Report locally')),
        ],
      );
}
