import 'package:flutter/material.dart';
import '../../../models/business_model.dart';
import '../../../core/theme/app_colors.dart';
import '../data/business_review_store.dart';
import 'live_business_review_api.dart';

/// Backend-driven section; the Step 6C demo section is preserved for offline preview.
class LiveBusinessReviewsSection extends StatefulWidget {
  const LiveBusinessReviewsSection({super.key, required this.business});
  final BusinessModel business;
  @override
  State<LiveBusinessReviewsSection> createState() =>
      _LiveBusinessReviewsSectionState();
}

class _LiveBusinessReviewsSectionState
    extends State<LiveBusinessReviewsSection> {
  final _api = LiveBusinessReviewApi();
  LiveReviewFeed? _feed;
  LiveReview? _mine;
  String? _error;
  bool _loading = true, _working = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant LiveBusinessReviewsSection old) {
    super.didUpdateWidget(old);
    if (old.business.id != widget.business.id) _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.feed(widget.business.id);
      LiveReview? mine;
      try {
        mine = await _api.mine(widget.business.id);
      } catch (_) {/* Public browsing must not require authentication. */}
      if (mounted)
        setState(() {
          _feed = data;
          _mine = mine;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = '$e';
          _loading = false;
        });
    }
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit() async {
    var comment = _mine?.comment ?? '';
    var stars = _mine?.stars ?? 0;
    final draft = await showDialog<({int stars, String comment})>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                  title: Text(
                      _mine == null ? 'Write a review' : 'Edit your review'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Rate this business (1–5 stars)'),
                    Wrap(children: [
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                            tooltip: '$i stars',
                            onPressed: () => update(() => stars = i),
                            icon: Icon(
                                i <= stars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppColors.warning))
                    ]),
                    TextFormField(
                        initialValue: comment,
                        onChanged: (value) => comment = value,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 600,
                        decoration: const InputDecoration(
                            labelText: 'Your review',
                            hintText: '10–600 characters',
                            border: OutlineInputBorder())),
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(
                            ctx, (stars: stars, comment: comment.trim())),
                        child: const Text('Save'))
                  ],
                )));
    if (draft == null) return;
    if (draft.stars < 1 ||
        draft.comment.length < 10 ||
        draft.comment.length > 600) {
      _notice('Select 1–5 stars and write 10–600 characters.');
      return;
    }
    setState(() => _working = true);
    try {
      await _api.save(widget.business.id, draft.stars, draft.comment);
      await _reload();
      _notice('Review published to SaJHa.');
    } catch (e) {
      _notice(e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Delete your review?'),
                content: const Text(
                    'This will remove your review from the public rating.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'))
                ]));
    if (yes != true) return;
    setState(() => _working = true);
    try {
      await _api.delete(widget.business.id);
      await _reload();
      _notice('Review removed.');
    } catch (e) {
      _notice(e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _report(LiveReview review) async {
    String? reason;
    final selected = await showDialog<String>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                  title: const Text('Report review'),
                  content: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: reason,
                      decoration:
                          const InputDecoration(labelText: 'Report reason'),
                      items: BusinessReviewStore.reportReasons
                          .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) => update(() => reason = v)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: reason == null
                            ? null
                            : () => Navigator.pop(ctx, reason),
                        child: const Text('Submit report'))
                  ],
                )));
    if (selected == null) return;
    setState(() => _working = true);
    try {
      await _api.report(widget.business.id, review.id, selected);
      _notice('Report submitted for administrator review.');
    } catch (e) {
      _notice(e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _feed;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Ratings & reviews',
          style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
      const SizedBox(height: 12),
      if (_loading) const Center(child: CircularProgressIndicator()),
      if (_error != null) ...[
        Text(_error!, style: const TextStyle(color: Colors.red)),
        TextButton(onPressed: _reload, child: const Text('Retry'))
      ],
      if (data != null && !_loading) ...[
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.star_rounded,
                      color: AppColors.warning, size: 32),
                  const SizedBox(width: 8),
                  Text(data.count == 0 ? '—' : data.average.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Text(
                      '${data.count} ${data.count == 1 ? 'rating' : 'ratings'}'),
                ]))),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          FilledButton.icon(
              onPressed: _working ? null : _edit,
              icon: Icon(_mine == null
                  ? Icons.rate_review_outlined
                  : Icons.edit_outlined),
              label: Text(_mine == null ? 'Write review' : 'Edit my review')),
          if (_mine != null)
            TextButton.icon(
                onPressed: _working ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete my review'))
        ]),
        const SizedBox(height: 12),
        if (data.items.isEmpty)
          const Text('No reviews yet. Be the first to share your experience.'),
        for (final review in data.items)
          Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(review.authorName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Row(children: [
                          for (var i = 1; i <= 5; i++)
                            Icon(
                                i <= review.stars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppColors.warning,
                                size: 19),
                          const SizedBox(width: 8),
                          Text(
                              '${review.updatedAt.year}-${review.updatedAt.month.toString().padLeft(2, '0')}-${review.updatedAt.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary))
                        ]),
                        const SizedBox(height: 6),
                        Text(review.comment),
                        if (_mine?.id != review.id)
                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                  onPressed:
                                      _working ? null : () => _report(review),
                                  icon: const Icon(Icons.flag_outlined),
                                  label: const Text('Report review'))),
                      ]))),
      ],
    ]);
  }
}
